//
//  ContentView.swift
//  demo
//
//  Created by Fabio Milano on 2/16/26.
//

import SwiftUI
import Bugger
import BuggerGitHub

struct ContentView: View {
    enum SubmitStrategy: String, CaseIterable, Identifiable {
        case noop = "On device (No-op)"
        case github = "GitHub Issue"

        var id: String { rawValue }
    }

    enum ProviderOption: String, CaseIterable, Identifiable {
        case composerOnly = "Composer"
        case composerAndScreenshots = "Screenshots"

        var id: String { rawValue }
        var includeScreenshots: Bool {
            switch self {
            case .composerOnly:
                return false
            case .composerAndScreenshots:
                return true
            }
        }
    }

    @State private var submitStrategy: SubmitStrategy = .noop
    @State private var providerOption: ProviderOption = .composerAndScreenshots
    @State private var gitHubOwner = ""
    @State private var gitHubRepository = ""
    @State private var gitHubToken = ""
    @State private var gitHubLabels = ""
    @State private var activeSetup: DemoSetup?

    var body: some View {
        NavigationStack {
            Form {
                Section("Submit strategy") {
                    Picker("Submit strategy", selection: $submitStrategy) {
                        ForEach(SubmitStrategy.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    if submitStrategy == .github {
                        TextField("Owner", text: $gitHubOwner)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Repository", text: $gitHubRepository)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Token", text: $gitHubToken)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Labels (comma separated)", text: $gitHubLabels)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }

                Section("Providers") {
                    Picker("Providers", selection: $providerOption) {
                        ForEach(ProviderOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

            }
            .navigationTitle("Bugger Demo")
            .safeAreaInset(edge: .bottom) {
                Button {
                    activeSetup = DemoSetup(
                        bugger: makeBugger(),
                        includeScreenshots: providerOption.includeScreenshots
                    )
                } label: {
                    Text("Build it!")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .disabled(!canBuild)
            }
        }
        .sheet(item: $activeSetup) { setup in
            BuggerSheet(setup: setup)
        }
    }

    private var canBuild: Bool {
        switch submitStrategy {
        case .noop:
            return true
        case .github:
            return !gitHubOwner.isEmpty && !gitHubRepository.isEmpty && !gitHubToken.isEmpty
        }
    }

    private func makeBugger() -> Bugger {
        switch submitStrategy {
        case .noop:
            return .onDevice
        case .github:
            let labels = gitHubLabels
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let configuration = GitHubIssueConfiguration(
                owner: gitHubOwner,
                repository: gitHubRepository,
                token: gitHubToken,
                defaultLabels: labels
            )
            return Bugger(
                deviceInfoProvider: DefaultDeviceInfoProvider(),
                screenshotProvider: nil,
                packer: JSONReportPacker(),
                submitter: GitHubIssueSubmitter(configuration: configuration)
            )
        }
    }
}

private struct DemoSetup: Identifiable {
    let id = UUID()
    let bugger: Bugger
    let includeScreenshots: Bool
}

private struct BuggerSheet: View {
    let setup: DemoSetup
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BuggerScreen(
                bugger: setup.bugger,
                includeScreenshots: setup.includeScreenshots
            )
            .navigationTitle("Bugger")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
