import ObjectiveC
import UIKit

extension Notification.Name {
    /// Posted when a window receives a shake. The object is the `UIWindow`.
    static let buggerWindowDidShake = Notification.Name("BuggerWindowDidShake")
}

/// Reports device shakes as `buggerWindowDidShake` notifications.
///
/// UIKit only delivers shakes through the responder chain, which ends at the window
/// (then the application). Bugger replaces `UIWindow.motionEnded(_:with:)` once with an
/// implementation that posts the notification and then calls the original, so the app's own
/// shake handling is unchanged. A view controller that handles the shake without calling
/// `super` stops it before it reaches the window.
@MainActor
enum BuggerShakeDetector {
    private(set) static var isInstalled = false

    private typealias MotionEnded = @convention(c) (UIWindow, Selector, UIEvent.EventSubtype, UIEvent?) -> Void

    /// Installs the hook. Calling it again does nothing.
    static func install() {
        guard !isInstalled else { return }

        let windowClass: AnyClass = UIWindow.self
        let selector = #selector(UIResponder.motionEnded(_:with:))
        guard
            let method = class_getInstanceMethod(windowClass, selector),
            let superclass = class_getSuperclass(windowClass)
        else { return }
        isInstalled = true

        // If UIWindow has its own implementation, the hook replaces it and calls it directly.
        // If UIWindow only inherits one, the hook is added to UIWindow alone, so other responders
        // are unaffected, and it looks up the inherited implementation each time it runs, so a
        // library that hooks UIResponder later still gets called.
        let ownImplementation: IMP? = class_getInstanceMethod(superclass, selector).map { inherited in
            method_getImplementation(inherited) == method_getImplementation(method) ? nil : method_getImplementation(method)
        } ?? method_getImplementation(method)

        // The original is always called with the original selector. UIResponder's implementation
        // passes the event on to the next responder using that selector, so swapping selectors
        // would forward one the next responder doesn't have.
        let hook: @convention(block) (UIWindow, UIEvent.EventSubtype, UIEvent?) -> Void = { window, motion, event in
            if motion == .motionShake {
                NotificationCenter.default.post(name: .buggerWindowDidShake, object: window)
            }
            let implementation = ownImplementation ?? class_getMethodImplementation(superclass, selector)
            guard let implementation else { return }
            unsafeBitCast(implementation, to: MotionEnded.self)(window, selector, motion, event)
        }
        let hookImplementation = imp_implementationWithBlock(hook)

        if ownImplementation == nil {
            class_addMethod(windowClass, selector, hookImplementation, method_getTypeEncoding(method))
        } else {
            method_setImplementation(method, hookImplementation)
        }
    }
}
