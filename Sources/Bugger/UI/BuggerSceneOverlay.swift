import ObjectiveC
import SwiftUI
import UIKit

/// A transparent window above the app's own, for Bugger's prompt bar and report.
///
/// Bugger's UI lives here rather than in the app's controllers, so it appears over the app's
/// sheets, and the app can keep presenting and dismissing its own UI without affecting it.
/// Touches that don't land on Bugger's views pass through to the app.
final class BuggerOverlayWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view === rootViewController?.view ? nil : view
    }
}

/// Draws the coordinator's prompt and report in one scene's overlay window.
@MainActor
final class BuggerSceneOverlay: NSObject, BuggerOverlayPresenting, UIAdaptivePresentationControllerDelegate {
    private weak var scene: UIWindowScene?
    private var window: BuggerOverlayWindow?
    private weak var previousKeyWindow: UIWindow?

    private var promptController: UIViewController?
    private var reportController: UIViewController?
    private var reportSession: BuggerReportSession?
    private var onReportFinish: (@MainActor () -> Void)?

    init(scene: UIWindowScene) {
        self.scene = scene
    }

    // MARK: Prompt

    func showPrompt(onReport: @escaping @MainActor () -> Void, onClose: @escaping @MainActor () -> Void) {
        guard promptController == nil, let window = makeWindowVisible(), let root = window.rootViewController else { return }

        let controller = UIHostingController(rootView: BuggerPromptBar(onReport: onReport, onClose: onClose))
        controller.view.backgroundColor = .clear
        controller.sizingOptions = .intrinsicContentSize
        root.addChild(controller)
        root.view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        // As wide as the screen allows, minus margins, up to 500 points on large screens.
        let fullWidth = controller.view.widthAnchor.constraint(
            equalTo: root.view.safeAreaLayoutGuide.widthAnchor,
            constant: -32
        )
        fullWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            controller.view.centerXAnchor.constraint(equalTo: root.view.safeAreaLayoutGuide.centerXAnchor),
            controller.view.bottomAnchor.constraint(equalTo: root.view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            fullWidth,
            controller.view.widthAnchor.constraint(lessThanOrEqualTo: root.view.safeAreaLayoutGuide.widthAnchor, constant: -32),
            controller.view.widthAnchor.constraint(lessThanOrEqualToConstant: 500),
        ])
        controller.didMove(toParent: root)
        promptController = controller

        // Slide up from below the screen edge.
        root.view.layoutIfNeeded()
        let offscreen = root.view.bounds.height - controller.view.frame.minY
        controller.view.transform = CGAffineTransform(translationX: 0, y: offscreen)
        UIView.animate(
            withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.45,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0
        ) {
            controller.view.transform = .identity
        }
        UIAccessibility.post(notification: .announcement, argument: "Report a bug? The Report button is at the bottom of the screen.")
    }

    func hidePrompt() {
        guard let controller = promptController else { return }
        promptController = nil
        let offscreen = (controller.view.superview?.bounds.height ?? 0) - controller.view.frame.minY
        UIView.animate(
            withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.25,
            animations: { controller.view.transform = CGAffineTransform(translationX: 0, y: offscreen) },
            completion: { [weak self] _ in
                controller.willMove(toParent: nil)
                controller.view.removeFromSuperview()
                controller.removeFromParent()
                self?.hideWindowIfIdle()
            }
        )
    }

    // MARK: Report

    func presentReport(
        configuration: BuggerReportingConfiguration,
        screenshots: [BugReportAttachment],
        onFinish: @escaping @MainActor () -> Void
    ) {
        guard reportController == nil, let scene, let window = makeWindowVisible(), let root = window.rootViewController else {
            onFinish()
            return
        }

        // The report needs the keyboard, so its window becomes key; the previous one is restored after.
        previousKeyWindow = scene.windows.first { $0.isKeyWindow && $0 !== window }
        window.makeKey()

        let session = BuggerReportSession()
        let controller = UIHostingController(
            rootView: BuggerReportSheet(
                configuration: configuration,
                screenshots: screenshots,
                session: session,
                close: { [weak self] in self?.dismissReport() }
            )
        )
        controller.presentationController?.delegate = self
        reportController = controller
        reportSession = session
        onReportFinish = onFinish
        root.present(controller, animated: true)
    }

    func dismissReport() {
        guard let root = window?.rootViewController, reportController != nil else { return }
        // Dismissing from the root closes the report and anything it presented, such as the
        // annotation sheet or photo picker.
        root.dismiss(animated: true) { [weak self] in
            self?.finishReport()
        }
    }

    // Swipe-down is allowed only while closing loses nothing.
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        guard let reportSession else { return true }
        return !reportSession.isSubmitting && !reportSession.hasChanges
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        guard let reportSession, !reportSession.isSubmitting else { return }
        reportSession.confirmsDiscard = true
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finishReport()
    }

    private func finishReport() {
        guard reportController != nil else { return }
        reportController = nil
        reportSession = nil
        let onFinish = onReportFinish
        onReportFinish = nil
        hideWindowIfIdle()
        previousKeyWindow?.makeKey()
        previousKeyWindow = nil
        onFinish?()
    }

    // MARK: Window

    private func makeWindowVisible() -> BuggerOverlayWindow? {
        if let window {
            window.isHidden = false
            return window
        }
        guard let scene else { return nil }
        let window = BuggerOverlayWindow(windowScene: scene)
        window.windowLevel = .normal + 1
        window.backgroundColor = .clear
        let root = UIViewController()
        root.view.backgroundColor = .clear
        window.rootViewController = root
        window.isHidden = false
        self.window = window
        return window
    }

    private func hideWindowIfIdle() {
        guard promptController == nil, reportController == nil else { return }
        window?.isHidden = true
    }
}

extension BuggerSceneOverlay {
    private static var coordinatorKey: UInt8 = 0

    /// The coordinator for a scene, created the first time it's needed and kept with the scene.
    static func coordinator(for scene: UIWindowScene) -> BuggerReportCoordinator {
        if let existing = objc_getAssociatedObject(scene, &coordinatorKey) as? BuggerReportCoordinator {
            return existing
        }
        let overlay = BuggerSceneOverlay(scene: scene)
        let coordinator = BuggerReportCoordinator(
            overlay: overlay,
            captureScreen: { [weak scene] in
                scene.flatMap { BuggerScreenCapture.capture(scene: $0) }
            }
        )
        objc_setAssociatedObject(scene, &coordinatorKey, coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return coordinator
    }
}

/// The bar that slides up after a shake or screenshot.
private struct BuggerPromptBar: View {
    let onReport: @MainActor () -> Void
    let onClose: @MainActor () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "ladybug.fill")
                .font(.title3)
                .foregroundStyle(.red)
                .accessibilityHidden(true)
            Text("Found a bug?")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            Button {
                onReport()
            } label: {
                Text("Report a Bug")
                    .lineLimit(1)
                    .fixedSize()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }
}

/// Bugger's report as presented by the overlay: a form with Cancel, closed after submitting.
private struct BuggerReportSheet: View {
    let configuration: BuggerReportingConfiguration
    let screenshots: [BugReportAttachment]
    @Bindable var session: BuggerReportSession
    let close: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            BuggerScreen(
                bugger: configuration.bugger,
                allowsPhotoLibrary: configuration.allowsPhotoLibrary,
                screenshots: screenshots,
                speechTranscriptionEngine: configuration.speechTranscriptionEngine,
                onSubmit: { package in
                    configuration.onSubmit?(package)
                    close()
                }
            )
            .environment(\.buggerReportSession, session)
            .navigationTitle("Report a Bug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if session.hasChanges {
                            session.confirmsDiscard = true
                        } else {
                            close()
                        }
                    }
                    .disabled(session.isSubmitting)
                }
            }
            .confirmationDialog(
                "Discard this report?",
                isPresented: $session.confirmsDiscard,
                titleVisibility: .visible
            ) {
                Button("Discard Report", role: .destructive) {
                    close()
                }
                Button("Keep Editing", role: .cancel) {}
            }
        }
    }
}
