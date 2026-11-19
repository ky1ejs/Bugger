import UIKit

/// What the coordinator asks the screen to show. `BuggerSceneOverlay` draws it; tests use a fake.
@MainActor
protocol BuggerOverlayPresenting: AnyObject {
    func showPrompt(onReport: @escaping @MainActor () -> Void, onClose: @escaping @MainActor () -> Void)
    func hidePrompt()
    /// Presents the report. Must call `onFinish` once it is gone, however it was closed.
    func presentReport(
        configuration: BuggerReportingConfiguration,
        screenshots: [BugReportAttachment],
        onFinish: @escaping @MainActor () -> Void
    )
    func dismissReport()
}

/// Decides when the prompt bar and the report appear, for one scene.
///
/// There is at most one prompt or one report per scene. Triggers that arrive while either is
/// on screen are ignored.
@MainActor
final class BuggerReportCoordinator {
    enum State {
        case idle
        case prompting
        case reporting
    }

    private(set) var state: State = .idle

    private let overlay: any BuggerOverlayPresenting
    private let captureScreen: @MainActor () -> BugReportAttachment?
    private let promptDuration: @MainActor () -> Duration
    private var promptTimeout: Task<Void, Never>?
    /// The screenshot and configuration from the trigger that raised the prompt.
    private var pendingReport: (configuration: BuggerReportingConfiguration, screenshot: BugReportAttachment?)?

    init(
        overlay: any BuggerOverlayPresenting,
        captureScreen: @escaping @MainActor () -> BugReportAttachment?,
        promptDuration: @escaping @MainActor () -> Duration = BuggerReportCoordinator.defaultPromptDuration
    ) {
        self.overlay = overlay
        self.captureScreen = captureScreen
        self.promptDuration = promptDuration
    }

    /// Long enough to read and reach the bar; longer with VoiceOver, which reads it out first.
    static func defaultPromptDuration() -> Duration {
        UIAccessibility.isVoiceOverRunning ? .seconds(15) : .seconds(6)
    }

    /// A shake or screenshot. Captures the screen now, so the image matches what the user saw,
    /// then either asks first or opens the report.
    func handleTrigger(_ configuration: BuggerReportingConfiguration, asksFirst: Bool) {
        guard state == .idle else { return }
        let screenshot = configuration.attachesScreenshot ? captureScreen() : nil
        guard asksFirst else {
            openReport(configuration, screenshot: screenshot)
            return
        }

        state = .prompting
        pendingReport = (configuration, screenshot)
        overlay.showPrompt(
            onReport: { [weak self] in self?.acceptPrompt() },
            onClose: { [weak self] in self?.closePrompt() }
        )
        let duration = promptDuration()
        promptTimeout = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.closePrompt()
        }
    }

    /// The app's own button. Never asks first; replaces a prompt that is showing.
    func open(_ configuration: BuggerReportingConfiguration) {
        if state == .prompting {
            closePrompt()
        }
        guard state == .idle else { return }
        openReport(configuration, screenshot: configuration.attachesScreenshot ? captureScreen() : nil)
    }

    func acceptPrompt() {
        guard state == .prompting, let pendingReport else { return }
        endPrompt()
        openReport(pendingReport.configuration, screenshot: pendingReport.screenshot)
    }

    func closePrompt() {
        guard state == .prompting else { return }
        endPrompt()
        state = .idle
    }

    /// Reporting was turned off: removes the prompt, and closes an open report without sending it.
    func disable() {
        switch state {
        case .idle:
            break
        case .prompting:
            closePrompt()
        case .reporting:
            overlay.dismissReport()
        }
    }

    private func endPrompt() {
        promptTimeout?.cancel()
        promptTimeout = nil
        pendingReport = nil
        overlay.hidePrompt()
    }

    private func openReport(_ configuration: BuggerReportingConfiguration, screenshot: BugReportAttachment?) {
        state = .reporting
        overlay.presentReport(
            configuration: configuration,
            screenshots: [screenshot].compactMap { $0 },
            onFinish: { [weak self] in self?.state = .idle }
        )
    }
}
