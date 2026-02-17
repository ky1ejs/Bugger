//
//  BuggerReporter.swift
//  Bugger
//
//  Created by Fabio Milano on 2/8/26.
//

import SwiftUI

struct BuggerReporterView: View {
    @Bindable
    var viewModel: BuggerReporterViewModel

    public init(
        bugger: Bugger,
        screenshotSource: BuggerScreenshotSource = .photoLibrary,
        includeScreenshots: Bool = true,
        onSubmit: (@MainActor (BugReportPackage) -> Void)? = nil
    ) {
        self.viewModel = BuggerReporterViewModel(
            bugger: bugger,
            screenshotSource: screenshotSource,
            includeScreenshots: includeScreenshots,
            onSubmit: onSubmit
        )
    }

    public var body: some View {
        Form {
            Section(viewModel.composer.sectionTitle) {
                BuggerReporterComposer(viewModel: viewModel.composer)
            }
            if let screenshots = viewModel.screenshots {
                Section(screenshots.sectionTitle) {
                    BuggerScreenshotCarousel(viewModel: screenshots)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button {
                    viewModel.submit()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSubmitting {
                            ProgressView()
                        }
                        Text(viewModel.isSubmitting ? "Submitting..." : "Submit")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isSubmitting || !viewModel.hasDescription)
                if viewModel.submitFailed {
                    Text("Submit failed. Please try again.")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }
}

@Observable
@MainActor
final class BuggerReporterViewModel {
    enum State {
        case idle
        case submitting
        case submitDidFail
    }

    private let bugger: Bugger
    private let onSubmit: (@MainActor (BugReportPackage) -> Void)?
    private var submitTask: Task<Void, Error>? = nil
    private var state: State = .idle

    let composer = BuggerReporterComposerViewModel()
    let screenshots: BuggerScreenshotCarouselViewModel?

    init(
        bugger: Bugger,
        screenshotSource: BuggerScreenshotSource = .photoLibrary,
        includeScreenshots: Bool = true,
        onSubmit: (@MainActor (BugReportPackage) -> Void)? = nil
    ) {
        self.bugger = bugger
        self.onSubmit = onSubmit
        self.screenshots = includeScreenshots
        ? BuggerScreenshotCarouselViewModel(source: screenshotSource)
        : nil
    }

    private var providers: [any BuggerReportProviding] {
        var providers: [any BuggerReportProviding] = [composer]
        if let screenshots {
            providers.append(screenshots)
        }
        return providers
    }

    var isSubmitting: Bool {
        state == .submitting
    }

    var submitFailed: Bool {
        state == .submitDidFail
    }

    var hasDescription: Bool {
        !composer.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Submit flow after the user taps "Submit":
    ///
    /// +-----------------------+
    /// | User taps Submit      |
    /// +-----------+-----------+
    ///             |
    ///             v
    /// +-----------------------+
    /// | state = .submitting   |
    /// | cancel previous task  |
    /// +-----------+-----------+
    ///             |
    ///             v
    /// +-----------------------+
    /// | buildDraft()          |
    /// | - composer text       |
    /// | - screenshots data    |
    /// +-----------+-----------+
    ///             |
    ///             v
    /// +-----------------------+
    /// | bugger.draftReport()  |
    /// | - device info         |
    /// | - merge screenshots   |
    /// +-----------+-----------+
    ///             |
    ///             v
    /// +-----------------------+
    /// | bugger.submit()       |
    /// | - pack BugReport      |
    /// | - submit package      |
    /// +-----+-----------+-----+
    ///       |           |
    ///       | success   | failure/error
    ///       v           v
    /// +-----------+   +------------------+
    /// | onSubmit? |   | state =          |
    /// | callback  |   | .submitDidFail   |
    /// +-----+-----+   +------------------+
    ///       |
    ///       v
    /// +------------------+
    /// | state = .idle    |
    /// +------------------+
    func submit() {
        submitTask?.cancel()

        state = .submitting
        submitTask = Task { [bugger] in
            do {
                let draft = try await buildDraft()
                let bugreport = try await bugger.draftReport(
                    description: draft.description,
                    screenshots: draft.screenshots
                )

                guard !Task.isCancelled else { return }
                let package = try await bugger.submit(bugreport)
                onSubmit?(package)
                state = .idle
            } catch {
                /// We could not draft a response, the user can try again
                state = .submitDidFail
            }
        }
    }

    private func buildDraft() async throws -> BuggerReportDraft {
        var draft = BuggerReportDraft()
        for provider in providers {
            draft = try await provider.apply(to: draft)
        }
        return draft
    }
}


struct BuggerReportDraft {
    var description: String = ""
    var screenshots: [Data] = []
}

protocol SectionTitleProviding {
    var sectionTitle: String { get }
}

@MainActor
protocol BuggerReportProviding {
    func apply(to bugger: BuggerReportDraft) async throws -> BuggerReportDraft
}

#Preview {
    BuggerReporterView(
        bugger: .test,
        screenshotSource: .previewMock
    )
}
