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

    /// Captures the screen, if the configuration attaches screenshots, then presents Bugger.
    /// Does nothing while Bugger is already on screen.
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
    /// Apply it once, near the root of each scene. Bugger is presented over whatever the
    /// app is showing, including sheets.
    ///
    /// - Parameters:
    ///   - bugger: Builds, packs and submits reports.
    ///   - isEnabled: Turns reporting off entirely: no triggers, and `buggerReport` is `nil`.
    ///     Can change at any time, for example from remote config or a user setting.
    ///   - triggers: Which events open Bugger by themselves. Pass `[]` to open it only from code.
    ///   - attachesScreenshot: Captures the screen before Bugger opens and attaches it to the report.
    ///   - allowsPhotoLibrary: Lets the reporter add screenshots from the photo library.
    ///   - speechTranscriptionEngine: Turns on dictation in the composer.
    ///   - onSubmit: Called with the package after a report was submitted, before Bugger closes.
    public func buggerReporting(
        _ bugger: Bugger,
        isEnabled: Bool = true,
        triggers: BuggerTrigger = .all,
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
                triggers: triggers
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

    @State private var presenter = BuggerReportPresenter()

    private var activeTriggers: BuggerTrigger {
        isEnabled ? triggers : []
    }

    func body(content: Content) -> some View {
        content
            .background(BuggerWindowReader { window in
                presenter.window = window
            })
            .environment(
                \.buggerReport,
                isEnabled ? BuggerReportAction { presenter.present(configuration) } : nil
            )
            .onChange(of: activeTriggers.contains(.shake), initial: true) { _, shakeIsOn in
                if shakeIsOn {
                    BuggerShakeDetector.install()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .buggerWindowDidShake)) { notification in
                guard
                    activeTriggers.contains(.shake),
                    presenter.owns(shakenWindow: notification.object as? UIWindow)
                else { return }
                presenter.present(configuration)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
                // The notification is app-wide; only the scene the user is looking at responds.
                guard activeTriggers.contains(.screenshot), presenter.isInFrontmostScene else { return }
                presenter.present(configuration)
            }
    }
}

/// Presents Bugger over the topmost view controller of the modifier's scene.
@MainActor
final class BuggerReportPresenter {
    /// The window the modifier is in. Set by `BuggerWindowReader`.
    weak var window: UIWindow?

    /// Bugger's controller while it is on screen, across all presenters, so two triggers
    /// (or two modifiers) never stack two reports.
    private static weak var presentedController: UIViewController?

    static var isPresenting: Bool {
        guard let presentedController else { return false }
        return presentedController.presentingViewController != nil && !presentedController.isBeingDismissed
    }

    var scene: UIWindowScene? {
        window?.windowScene
    }

    /// True when `shakenWindow` belongs to this presenter's scene.
    func owns(shakenWindow: UIWindow?) -> Bool {
        guard let scene, let shakenWindow else { return false }
        return shakenWindow.windowScene === scene
    }

    /// True when this presenter's scene is active and holds the key window.
    var isInFrontmostScene: Bool {
        guard let scene, scene.activationState == .foregroundActive else { return false }
        return scene.windows.contains(where: \.isKeyWindow)
    }

    func present(_ configuration: BuggerReportingConfiguration) {
        guard
            !Self.isPresenting,
            let scene,
            let presenting = Self.topViewController(in: scene)
        else { return }

        // Capture before presenting, so the screenshot shows the app and not Bugger.
        let screenshot = configuration.attachesScreenshot ? BuggerScreenCapture.capture(scene: scene) : nil

        let dismissal = BuggerDismissal()
        let controller = UIHostingController(
            rootView: BuggerReportSheet(
                configuration: configuration,
                screenshots: [screenshot].compactMap { $0 },
                dismiss: { dismissal.dismiss() }
            )
        )
        dismissal.controller = controller
        Self.presentedController = controller
        presenting.present(controller, animated: true)
    }

    /// The controller to present from: the key window's root, then down through whatever it presents.
    static func topViewController(in scene: UIWindowScene) -> UIViewController? {
        let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
        return topViewController(from: window?.rootViewController)
    }

    static func topViewController(from root: UIViewController?) -> UIViewController? {
        var current = root
        while let presented = current?.presentedViewController, !presented.isBeingDismissed {
            current = presented
        }
        return current
    }
}

@MainActor
private final class BuggerDismissal {
    weak var controller: UIViewController?

    func dismiss() {
        controller?.dismiss(animated: true)
    }
}

private struct BuggerReportSheet: View {
    let configuration: BuggerReportingConfiguration
    let screenshots: [BugReportAttachment]
    let dismiss: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            BuggerScreen(
                bugger: configuration.bugger,
                allowsPhotoLibrary: configuration.allowsPhotoLibrary,
                screenshots: screenshots,
                speechTranscriptionEngine: configuration.speechTranscriptionEngine,
                onSubmit: { package in
                    configuration.onSubmit?(package)
                    dismiss()
                }
            )
            .navigationTitle("Report a Bug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
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
