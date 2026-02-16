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

    var body: some View {
        TextEditor(text: $viewModel.text)
            .frame(minHeight: 120, maxHeight: 200)
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
