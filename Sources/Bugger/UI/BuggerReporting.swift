import SwiftUI
import UIKit

/// Events that open Bugger without the app calling it.
public struct BuggerTrigger: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The user shakes the device.
    public static let shake = BuggerTrigger(rawValue: 1 << 0)
    /// The user takes a screenshot with the device buttons.
    public static let screenshot = BuggerTrigger(rawValue: 1 << 1)

    public static let all: BuggerTrigger = [.shake, .screenshot]
}

/// Opens Bugger from the app's own code, such as a "Report a bug" button.
///
/// Read it from the environment. It is `nil` outside `.buggerReporting(...)` and while
/// reporting is disabled, so a view can hide its button:
///
/// ```swift
/// @Environment(\.buggerReport) private var buggerReport
///
/// if let buggerReport {
///     Button("Report a bug") { buggerReport() }
/// }
/// ```
public struct BuggerReportAction {
    private let action: @MainActor () -> Void

    init(_ action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    /// Captures the screen, if the configuration attaches screenshots, then opens Bugger
    /// straight away. Replaces the "Report a Bug" bar if it is showing. Does nothing while a
    /// report is already open in this scene.
    @MainActor
    public func callAsFunction() {
        action()
    }
}

extension EnvironmentValues {
    /// Opens Bugger. `nil` outside `.buggerReporting(...)` or while it is disabled.
    @Entry public var buggerReport: BuggerReportAction? = nil
}

extension View {
    /// Lets the user report a bug from anywhere below this view, by the given triggers or
    /// through `@Environment(\.buggerReport)`.
    ///
    /// Apply it once, near the root of each scene. Bugger appears in its own window above the
    /// app, including over sheets, so the app can keep presenting its own UI.
    ///
    /// - Parameters:
    ///   - bugger: Builds, packs and submits reports.
    ///   - isEnabled: Turns reporting off entirely: no triggers, and `buggerReport` is `nil`.
    ///     Turning it off also closes a prompt or report that is open, without sending it.
    ///     Can change at any time, for example from remote config or a user setting.
    ///   - triggers: Which events open Bugger by themselves. Pass `[]` to open it only from code.
    ///   - asksBeforeOpening: After a shake or screenshot, shows a "Report a Bug" bar at the bottom
    ///     of the screen for a few seconds instead of opening the report straight away.
    ///     Opening from code never asks.
    ///   - attachesScreenshot: Captures the screen when the trigger fires and attaches it to the report.
    ///   - allowsPhotoLibrary: Lets the reporter add screenshots from the photo library.
    ///   - speechTranscriptionEngine: Turns on dictation in the composer.
    ///   - onSubmit: Called with the package after a report was submitted, before Bugger closes.
    public func buggerReporting(
        _ bugger: Bugger,
        isEnabled: Bool = true,
        triggers: BuggerTrigger = .all,
        asksBeforeOpening: Bool = true,
        attachesScreenshot: Bool = true,
        allowsPhotoLibrary: Bool = true,
        speechTranscriptionEngine: (any BuggerSpeechTranscriptionEngine)? = nil,
        onSubmit: (@MainActor (BugReportPackage) -> Void)? = nil
    ) -> some View {
        modifier(
            BuggerReportingModifier(
                configuration: BuggerReportingConfiguration(
                    bugger: bugger,
                    attachesScreenshot: attachesScreenshot,
                    allowsPhotoLibrary: allowsPhotoLibrary,
                    speechTranscriptionEngine: speechTranscriptionEngine,
                    onSubmit: onSubmit
                ),
                isEnabled: isEnabled,
                triggers: triggers,
                asksBeforeOpening: asksBeforeOpening
            )
        )
    }
}

struct BuggerReportingConfiguration {
    let bugger: Bugger
    let attachesScreenshot: Bool
    let allowsPhotoLibrary: Bool
    let speechTranscriptionEngine: (any BuggerSpeechTranscriptionEngine)?
    let onSubmit: (@MainActor (BugReportPackage) -> Void)?
}

struct BuggerReportingModifier: ViewModifier {
    let configuration: BuggerReportingConfiguration
    let isEnabled: Bool
    let triggers: BuggerTrigger
    let asksBeforeOpening: Bool

    @State private var sceneReader = BuggerSceneReader()

    /// Whether `trigger` should open Bugger, given the developer's settings.
    static func responds(to trigger: BuggerTrigger, isEnabled: Bool, triggers: BuggerTrigger) -> Bool {
        isEnabled && triggers.contains(trigger)
    }

    func body(content: Content) -> some View {
        content
            .background(BuggerWindowReader { window in
                sceneReader.window = window
            })
            .environment(
                \.buggerReport,
                isEnabled ? BuggerReportAction { sceneReader.coordinator?.open(configuration) } : nil
            )
            .onChange(of: Self.responds(to: .shake, isEnabled: isEnabled, triggers: triggers), initial: true) { _, shakeIsOn in
                if shakeIsOn {
                    BuggerShakeDetector.install()
                }
            }
            .onChange(of: isEnabled) { _, isEnabled in
                if !isEnabled {
                    sceneReader.coordinator?.disable()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .buggerWindowDidShake)) { notification in
                guard
                    Self.responds(to: .shake, isEnabled: isEnabled, triggers: triggers),
                    sceneReader.owns(notification.object as? UIWindow)
                else { return }
                sceneReader.coordinator?.handleTrigger(configuration, asksFirst: asksBeforeOpening)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
                // The notification is app-wide; only the scene the user is looking at responds.
                guard
                    Self.responds(to: .screenshot, isEnabled: isEnabled, triggers: triggers),
                    sceneReader.isFrontmost
                else { return }
                sceneReader.coordinator?.handleTrigger(configuration, asksFirst: asksBeforeOpening)
            }
    }
}

/// Finds the modifier's scene, and with it the scene's coordinator.
@MainActor
final class BuggerSceneReader {
    /// The window the modifier is in. Set by `BuggerWindowReader`.
    weak var window: UIWindow?

    var scene: UIWindowScene? {
        window?.windowScene
    }

    var coordinator: BuggerReportCoordinator? {
        scene.map(BuggerSceneOverlay.coordinator(for:))
    }

    /// True when `window` belongs to this modifier's scene.
    func owns(_ window: UIWindow?) -> Bool {
        guard let scene, let window else { return false }
        return window.windowScene === scene
    }

    /// True when the scene is active and holds the key window.
    var isFrontmost: Bool {
        guard let scene, scene.activationState == .foregroundActive else { return false }
        return scene.windows.contains(where: \.isKeyWindow)
    }
}

/// Reports the `UIWindow` it ends up in.
private struct BuggerWindowReader: UIViewRepresentable {
    let onWindowChange: @MainActor (UIWindow?) -> Void

    func makeUIView(context: Context) -> WindowReportingView {
        let view = WindowReportingView()
        view.onWindowChange = onWindowChange
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: WindowReportingView, context: Context) {
        uiView.onWindowChange = onWindowChange
    }

    final class WindowReportingView: UIView {
        var onWindowChange: (@MainActor (UIWindow?) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            onWindowChange?(window)
        }
    }
}
