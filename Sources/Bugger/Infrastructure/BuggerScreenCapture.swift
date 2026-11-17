import UIKit

/// Captures what the app is showing, as a PNG attachment for a bug report.
///
/// Capture before presenting `BuggerScreen`, then pass the result in, so the
/// screenshot shows the app and not Bugger:
///
/// ```swift
/// let screenshot = BuggerScreenCapture.captureForegroundScene()
/// // present:
/// BuggerScreen(bugger: bugger, screenshots: screenshot.map { [$0] } ?? [])
/// ```
///
/// Only the app's own windows are captured. The keyboard, system alerts and the
/// status bar are drawn by other processes, so they are not in the image.
@MainActor
public enum BuggerScreenCapture {
    public static let defaultFilename = "screenshot.png"

    /// Captures every visible window of the app's foreground scene, composited in window-level order.
    ///
    /// - Parameter scene: The scene to capture. Defaults to the active foreground scene.
    /// - Returns: A PNG attachment, or `nil` if there is no scene or nothing visible to capture.
    public static func captureForegroundScene(_ scene: UIWindowScene? = nil) -> BugReportAttachment? {
        guard let scene = scene ?? foregroundScene() else { return nil }
        return capture(
            windows: scene.windows,
            bounds: scene.coordinateSpace.bounds,
            scale: scene.traitCollection.displayScale
        )
    }

    /// Captures the given windows into one image covering `bounds`.
    ///
    /// Window frames are drawn at their position within `bounds`. Hidden and fully
    /// transparent windows are skipped.
    static func capture(windows: [UIWindow], bounds: CGRect, scale: CGFloat) -> BugReportAttachment? {
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

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale > 0 ? scale : 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
        let data = renderer.pngData { context in
            UIColor.systemBackground.setFill()
            context.fill(bounds)
            for window in visibleWindows {
                // drawHierarchy captures what is on screen, including visual effects.
                // It returns false for a window that isn't on screen; fall back to the layer tree.
                if !window.drawHierarchy(in: window.frame, afterScreenUpdates: false) {
                    context.cgContext.saveGState()
                    context.cgContext.translateBy(x: window.frame.minX, y: window.frame.minY)
                    window.layer.render(in: context.cgContext)
                    context.cgContext.restoreGState()
                }
            }
        }
        return BugReportAttachment(data: data, mimeType: "image/png", filename: defaultFilename)
    }

    private static func foregroundScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.activationState == .foregroundInactive }
    }
}
