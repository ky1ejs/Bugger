//
//  BuggerReporterComposer.swift
//  Bugger
//
//  Created by Fabio Milano on 2/8/26.
//

import SwiftUI
import UIKit

struct BuggerReporterComposer: View {

    @Bindable
    var viewModel: BuggerReporterComposerViewModel
    let categoriesViewModel: BuggerCategorySelectionViewModel?
    let speechViewModel: BuggerComposerSpeechInputViewModel?

    init(
        viewModel: BuggerReporterComposerViewModel,
        categoriesViewModel: BuggerCategorySelectionViewModel?,
        speechViewModel: BuggerComposerSpeechInputViewModel? = nil
    ) {
        self.viewModel = viewModel
        self.categoriesViewModel = categoriesViewModel
        self.speechViewModel = speechViewModel
    }

    var body: some View {
        VStack(spacing: 8) {
            BuggerComposerTextView(
                text: $viewModel.text,
                scrollToEndTrigger: viewModel.scrollToEndTrigger
            )
                .frame(minHeight: 120, maxHeight: 200)
                .overlay(alignment: .center) {
                    if let speechViewModel,
                       speechViewModel.isRecording || speechViewModel.isTranscribing {
                        BuggerComposerSpeechStatusOverlay(viewModel: speechViewModel)
                    }
                }
            HStack(spacing: 8) {
                Spacer()
                if let categoriesViewModel, !(speechViewModel?.isRecording ?? false) {
                    BuggerComposerCategoryButton(viewModel: categoriesViewModel)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            )
                        )
                }
                if let speechViewModel {
                    BuggerComposerSpeechButton(viewModel: speechViewModel)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: speechViewModel?.isRecording ?? false)
            if let speechViewModel, let failure = speechViewModel.failure {
                BuggerComposerSpeechFailureView(failure: failure) {
                    speechViewModel.dismissFailure()
                }
            }
        }
    }
}

@Observable
@MainActor
final class BuggerReporterComposerViewModel: BuggerReportProviding, SectionTitleProviding {
    
    let sectionTitle = "What happened"
    
    var text = ""
    private(set) var scrollToEndTrigger = 0

    func appendTranscription(_ transcription: String) {
        let trimmed = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            text = trimmed
            scrollToEndTrigger += 1
            return
        }

        text += "\n\n\(trimmed)"
        scrollToEndTrigger += 1
    }

    func apply(to draft: BuggerReportDraft) async throws -> BuggerReportDraft {
        var draft = draft
        draft.description = text
        return draft
    }
}

@Observable
@MainActor
final class BuggerComposerSpeechInputViewModel {
    enum State {
        case idle
        case startingRecording
        case recording
        case transcribing
    }

    /// Why the last recording didn't produce text, worded for the reporter.
    struct Failure: Equatable {
        let message: String
        /// True when the user can fix the failure by changing a permission in Settings.
        let offersSettings: Bool

        init(message: String, offersSettings: Bool = false) {
            self.message = message
            self.offersSettings = offersSettings
        }

        init(_ error: any Error) {
            switch error as? BuggerSpeechTranscriptionError {
            case .speechAuthorizationDenied:
                self.init(
                    message: "Speech recognition is turned off for this app. You can turn it on in Settings.",
                    offersSettings: true
                )
            case .microphoneAuthorizationDenied:
                self.init(
                    message: "Microphone access is turned off for this app. You can turn it on in Settings.",
                    offersSettings: true
                )
            case .audioInputUnavailable:
                self.init(message: "The microphone isn't available right now.")
            case .recognizerUnavailable, .onDeviceRecognitionUnsupported:
                self.init(message: "Speech recognition isn't available on this device right now.")
            case .emptyTranscription:
                self.init(message: "No speech was detected. Try again.")
            case .recordingNotStarted, .recognitionFailed, nil:
                self.init(message: "The recording couldn't be transcribed. Try again.")
            }
        }
    }

    private let engine: any BuggerSpeechTranscriptionEngine
    private let onTranscription: @MainActor (String) -> Void
    private var transcriptionTask: Task<Void, Never>?

    private(set) var state: State = .idle
    private(set) var failure: Failure?

    init(
        engine: any BuggerSpeechTranscriptionEngine,
        onTranscription: @escaping @MainActor (String) -> Void
    ) {
        self.engine = engine
        self.onTranscription = onTranscription
    }

    deinit {
        let engine = engine
        Task {
            await engine.cancelRecording()
        }
    }

    var isRecording: Bool {
        state == .startingRecording || state == .recording
    }

    var isTranscribing: Bool {
        state == .transcribing
    }

    var isBusy: Bool {
        state == .startingRecording || state == .transcribing
    }

    func toggleRecording() {
        switch state {
        case .idle:
            startRecording()
        case .startingRecording:
            break
        case .recording:
            startTranscription()
        case .transcribing:
            break
        }
    }

    func dismissFailure() {
        failure = nil
    }

    /// Waits for the current start or transcription to finish. Used by tests.
    func waitForPendingWork() async {
        await transcriptionTask?.value
    }

    private func startRecording() {
        transcriptionTask?.cancel()
        failure = nil
        state = .startingRecording
        transcriptionTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.engine.startRecording()
                try Task.checkCancellation()
                self.finishStartRecording()
            } catch {
                await self.fail(with: error)
            }
        }
    }

    private func startTranscription() {
        guard state == .recording else { return }
        transcriptionTask?.cancel()
        state = .transcribing
        transcriptionTask = Task { [weak self] in
            guard let self else { return }
            do {
                let transcription = try await self.engine.stopRecordingAndTranscribe()
                try Task.checkCancellation()
                self.finishTranscription(transcription)
            } catch {
                await self.fail(with: error)
            }
        }
    }

    private func finishStartRecording() {
        guard state == .startingRecording else { return }
        state = .recording
    }

    /// Stops the engine and returns to idle. A cancellation isn't shown to the user; any other error is.
    private func fail(with error: any Error) async {
        await engine.cancelRecording()
        state = .idle
        if !(error is CancellationError) {
            failure = Failure(error)
        }
    }

    private func finishTranscription(_ transcription: String) {
        onTranscription(transcription)
        state = .idle
    }
}

private struct BuggerComposerTextView: UIViewRepresentable {
    @Binding var text: String
    let scrollToEndTrigger: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, scrollToEndTrigger: scrollToEndTrigger)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .init(top: 8, left: 3, bottom: 8, right: 3)
        textView.text = text
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.text = $text
        if uiView.text != text {
            uiView.text = text
        }

        if context.coordinator.lastScrollToEndTrigger != scrollToEndTrigger {
            context.coordinator.lastScrollToEndTrigger = scrollToEndTrigger
            moveCursorAndScrollToEnd(textView: uiView)
        }
    }

    private func moveCursorAndScrollToEnd(textView: UITextView) {
        let endPosition = textView.endOfDocument
        let endRange = textView.textRange(from: endPosition, to: endPosition)
        textView.becomeFirstResponder()
        textView.selectedTextRange = endRange
        textView.scrollRangeToVisible(NSRange(location: textView.text.utf16.count, length: 0))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var lastScrollToEndTrigger: Int

        init(text: Binding<String>, scrollToEndTrigger: Int) {
            self.text = text
            self.lastScrollToEndTrigger = scrollToEndTrigger
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }
}

private struct BuggerComposerCategoryButton: View {
    @Bindable var viewModel: BuggerCategorySelectionViewModel

    private var selectedCategoryName: String? {
        guard let selectedID = viewModel.selectedCategoryIdentifier else { return nil }
        return viewModel.categories.first(where: { $0.identifier == selectedID })?.displayName
    }

    var body: some View {
        if viewModel.hasAvailableCategories {
            Menu {
                Button("No category") {
                    viewModel.selectedCategoryIdentifier = nil
                }
                ForEach(viewModel.categories, id: \.identifier) { category in
                    Button(category.displayName) {
                        viewModel.selectedCategoryIdentifier = category.identifier
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedCategoryName ?? "No category")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemFill))
                )
            }
        }
    }
}

private struct BuggerComposerSpeechButton: View {
    @Bindable var viewModel: BuggerComposerSpeechInputViewModel

    private var iconName: String {
        switch viewModel.state {
        case .idle, .startingRecording, .transcribing:
            return "mic.fill"
        case .recording:
            return "stop.fill"
        }
    }

    var body: some View {
        Button {
            viewModel.toggleRecording()
        } label: {
            Image(systemName: iconName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(viewModel.isRecording ? .white : .secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(viewModel.isRecording ? .red : Color(uiColor: .tertiarySystemFill))
                )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isBusy)
        .accessibilityLabel(
            viewModel.isRecording ? "Stop speech recording" : "Start speech recording"
        )
    }
}

private struct BuggerComposerSpeechFailureView: View {
    let failure: BuggerComposerSpeechInputViewModel.Failure
    let onDismiss: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(failure.message)
                if failure.offersSettings,
                   let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    Button("Open Settings") {
                        openURL(settingsURL)
                    }
                    .buttonStyle(.borderless)
                }
            }
            Spacer(minLength: 0)
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Dismiss")
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BuggerComposerSpeechStatusOverlay: View {
    @Bindable var viewModel: BuggerComposerSpeechInputViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .startingRecording:
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Preparing microphone...")
                        .font(.footnote)
                }
            case .recording:
                VStack(spacing: 8) {
                    Image(systemName: "waveform.and.mic")
                        .font(.title3)
                    Text("Recording in progress, speak about what is going wrong.")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                }
            case .transcribing:
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Processing audio...")
                        .font(.footnote)
                }
            case .idle:
                EmptyView()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .allowsHitTesting(false)
    }
}


@Observable
@MainActor
final class BuggerCategorySelectionViewModel: BuggerReportProviding {
    private let bugger: Bugger
    private var loadTask: Task<[BugReportCategory], Never>?

    private(set) var categories: [BugReportCategory] = []
    var selectedCategoryIdentifier: String? = nil

    init(bugger: Bugger) {
        self.bugger = bugger
    }

    init(
        previewCategories: [BugReportCategory],
        selectedCategoryIdentifier: String? = nil
    ) {
        self.bugger = .onDevice
        self.categories = previewCategories
        self.selectedCategoryIdentifier = selectedCategoryIdentifier
        self.loadTask = Task { previewCategories }
    }

    var hasAvailableCategories: Bool {
        !categories.isEmpty
    }

    func loadIfNeeded() async {
        if loadTask == nil {
            loadTask = Task { [bugger] in
                do {
                    return try await bugger.availableCategories()
                } catch {
                    return []
                }
            }
        }

        if let loadedCategories = await loadTask?.value {
            categories = loadedCategories
            if let selectedCategoryIdentifier,
               !categories.contains(where: { $0.identifier == selectedCategoryIdentifier }) {
                self.selectedCategoryIdentifier = nil
            }
        }
    }

    func apply(to draft: BuggerReportDraft) async throws -> BuggerReportDraft {
        var draft = draft
        if let selectedCategoryIdentifier,
           let category = categories.first(where: { $0.identifier == selectedCategoryIdentifier }) {
            draft.categories = [category]
        } else {
            draft.categories = []
        }
        return draft
    }
}

#Preview("Composer") {
    let composer = BuggerReporterComposerViewModel()
    composer.text = """
    Steps to reproduce:
    1. Open Settings
    2. Tap Save
    3. Observe freeze
    """

    return Form {
        Section(composer.sectionTitle) {
            let speech = BuggerComposerSpeechInputViewModel.previewMock(composer: composer)
            BuggerReporterComposer(
                viewModel: composer,
                categoriesViewModel: .previewMock,
                speechViewModel: speech
            )
        }
    }
}
