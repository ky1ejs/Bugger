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
        guard let method = class_getInstanceMethod(windowClass, selector) else { return }
        isInstalled = true

        // The original is called with the original selector. UIResponder's implementation passes
        // the event on to the next responder using that selector, so it must stay unchanged:
        // swapping selectors would forward a selector the next responder doesn't have.
        let original = unsafeBitCast(method_getImplementation(method), to: MotionEnded.self)
        let hook: @convention(block) (UIWindow, UIEvent.EventSubtype, UIEvent?) -> Void = { window, motion, event in
            if motion == .motionShake {
                NotificationCenter.default.post(name: .buggerWindowDidShake, object: window)
            }
            original(window, selector, motion, event)
        }
        let hookImplementation = imp_implementationWithBlock(hook)

        // If UIWindow only inherits motionEnded from UIResponder, add the hook to UIWindow alone,
        // so other responders keep UIResponder's implementation.
        if !class_addMethod(windowClass, selector, hookImplementation, method_getTypeEncoding(method)) {
            method_setImplementation(method, hookImplementation)
        }
    }
}
