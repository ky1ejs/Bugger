import SwiftUI
import UIKit

/// Captures what the app is showing, as a PNG attachment for a bug report.
///
/// Capture before presenting `BuggerScreen`, then pass the result in, so the
/// screenshot shows the app and not Bugger:
///
/// ```swift
/// let screenshot = BuggerScreenCapture.capture()
/// // present:
/// BuggerScreen(bugger: bugger, screenshots: [screenshot].compactMap { $0 })
/// ```
///
/// What is in the image:
/// - Every visible window of the scene, including alerts, sheets and overlays the app or
///   its SDKs present in-process. Pass `includingWindow` to leave windows out.
/// - Not the keyboard or its input accessory views: their system windows are left out by default.
/// - Not system permission prompts or the status bar, which other processes draw.
///
/// Views marked with `.buggerRedacted()` (SwiftUI) or `BuggerScreenCapture.redact(_:)` (UIKit)
/// are filled with black.
@MainActor
public enum BuggerScreenCapture {
    static let filename = "screenshot.png"

    /// Captures the visible windows of a scene, composited in window-level order.
    ///
    /// - Parameters:
    ///   - scene: The scene to capture. Pass it in apps with more than one scene, e.g. from
    ///     `view.window?.windowScene`. Defaults to the foreground scene holding the key window.
    ///   - includingWindow: Decides which windows are drawn. Defaults to `isAppWindow(_:)`,
    ///     which leaves out the keyboard's system windows.
    /// - Returns: A PNG attachment, or `nil` if there is no scene or nothing visible to capture.
    public static func capture(
        scene: UIWindowScene? = nil,
        includingWindow: @MainActor (UIWindow) -> Bool = isAppWindow
    ) -> BugReportAttachment? {
        guard let scene = scene ?? defaultScene() else { return nil }
        return capture(
            windows: scene.windows.filter(includingWindow),
            bounds: scene.coordinateSpace.bounds,
            scale: scene.traitCollection.displayScale
        )
    }

    /// False for UIKit's keyboard and text-effects windows, which can show what the user is typing,
    /// and for Bugger's own overlay window.
    public static func isAppWindow(_ window: UIWindow) -> Bool {
        if window is BuggerOverlayWindow { return false }
        let className = NSStringFromClass(type(of: window))
        return !systemWindowClassNames.contains(className)
    }

    /// Fills `view` with black in every capture while it is on screen.
    /// The view is held weakly, so there is nothing to undo when it goes away.
    public static func redact(_ view: UIView) {
        redactedViews.add(view)
    }

    /// Stops filling `view` with black.
    public static func unredact(_ view: UIView) {
        redactedViews.remove(view)
    }

    private static let systemWindowClassNames: Set<String> = [
        "UIRemoteKeyboardWindow",
        "UITextEffectsWindow",
    ]

    private static let redactedViews = NSHashTable<UIView>.weakObjects()

    /// Captures the given windows into one image covering `bounds`, then blacks out redacted views.
    ///
    /// Window frames are drawn at their position within `bounds`. Hidden and fully
    /// transparent windows are skipped. `draw` renders one window; tests replace it.
    static func capture(
        windows: [UIWindow],
        bounds: CGRect,
        scale: CGFloat,
        draw: @MainActor (UIWindow, CGContext) -> Void = drawWindow
    ) -> BugReportAttachment? {
        let visibleWindows = windows
            .filter { !$0.isHidden && $0.alpha > 0 }
            .enumerated()
            .sorted { lhs, rhs in
                // Keep the scene's order for windows at the same level.
                lhs.element.windowLevel == rhs.element.windowLevel
                    ? lhs.offset < rhs.offset
                    : lhs.element.windowLevel < rhs.element.windowLevel
            }
            .map(\.element)
        guard !visibleWindows.isEmpty, bounds.width > 0, bounds.height > 0 else { return nil }

        let redactedRects = redactedRects(in: visibleWindows)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale > 0 ? scale : 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
        let data = renderer.pngData { context in
            UIColor.systemBackground.setFill()
            context.fill(bounds)
            for window in visibleWindows {
                draw(window, context.cgContext)
            }
            UIColor.black.setFill()
            for rect in redactedRects {
                context.fill(rect)
            }
        }
        return BugReportAttachment(data: data, mimeType: "image/png", filename: filename)
    }

    /// Frames of the redacted views that are on screen in `windows`, in scene coordinates.
    static func redactedRects(in windows: [UIWindow]) -> [CGRect] {
        let windowSet = Set(windows.map(ObjectIdentifier.init))
        return redactedViews.allObjects.compactMap { view in
            guard
                let window = view.window,
                windowSet.contains(ObjectIdentifier(window)),
                !isHiddenInHierarchy(view)
            else { return nil }
            let rectInWindow = view.convert(view.bounds, to: window)
            return rectInWindow.offsetBy(dx: window.frame.minX, dy: window.frame.minY)
        }
    }

    /// Draws `window` at its frame. `drawHierarchy` captures what is on screen, including
    /// visual effects; it returns false for a window that isn't on screen, so fall back to the layer tree.
    static func drawWindow(_ window: UIWindow, in context: CGContext) {
        if window.drawHierarchy(in: window.frame, afterScreenUpdates: false) { return }
        context.saveGState()
        context.translateBy(x: window.frame.minX, y: window.frame.minY)
        window.layer.render(in: context)
        context.restoreGState()
    }

    private static func isHiddenInHierarchy(_ view: UIView) -> Bool {
        var current: UIView? = view
        while let candidate = current {
            if candidate.isHidden || candidate.alpha == 0 { return true }
            current = candidate.superview
        }
        return false
    }

    private static func defaultScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.session.role != .windowExternalDisplayNonInteractive }
        let active = scenes.filter { $0.activationState == .foregroundActive }
        return active.first { $0.windows.contains(where: \.isKeyWindow) }
            ?? active.first
            ?? scenes.first { $0.activationState == .foregroundInactive }
    }
}

extension View {
    /// Fills this view with black in screenshots taken by `BuggerScreenCapture`.
    /// Use it for account numbers, messages and other content that shouldn't leave the device.
    public func buggerRedacted() -> some View {
        background(BuggerRedactionMarker())
    }
}

/// An invisible view, sized like the view it backs, that registers itself for redaction.
private struct BuggerRedactionMarker: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        BuggerScreenCapture.redact(view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        BuggerScreenCapture.unredact(uiView)
    }
}
