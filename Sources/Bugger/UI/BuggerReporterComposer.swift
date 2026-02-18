//
//  BuggerReporterComposer.swift
//  Bugger
//
//  Created by Fabio Milano on 2/8/26.
//

import SwiftUI

struct BuggerReporterComposer: View {
    @Bindable
    var viewModel: BuggerReporterComposerViewModel
    let categoriesViewModel: BuggerCategorySelectionViewModel?

    var body: some View {
        TextEditor(text: $viewModel.text)
            .frame(minHeight: 120, maxHeight: 200)
            .padding(.bottom, 28)
            .overlay(alignment: .bottomTrailing) {
                if let categoriesViewModel {
                    BuggerComposerCategoryButton(viewModel: categoriesViewModel)
                }
            }
    }
}

@Observable
@MainActor
final class BuggerReporterComposerViewModel: BuggerReportProviding, SectionTitleProviding {
    
    let sectionTitle = "What happened"
    
    var text = ""

    func apply(to draft: BuggerReportDraft) async throws -> BuggerReportDraft {
        var draft = draft
        draft.description = text
        return draft
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
            BuggerReporterComposer(
                viewModel: composer,
                categoriesViewModel: .previewMock
            )
        }
    }
}
