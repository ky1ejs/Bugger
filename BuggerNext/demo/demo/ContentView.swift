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

    private let gitHubOAuthConfig = GitHubOAuthAppConfig(
        clientId: "<TODO_GITHUB_CLIENT_ID>",
        clientSecret: "<TODO_GITHUB_CLIENT_SECRET>"
    )

    @State private var submitStrategy: SubmitStrategy = .noop
    @State private var providerOption: ProviderOption = .composerAndScreenshots
    @State private var gitHubOwner = ""
    @State private var gitHubRepository = ""
    @State private var gitHubLabels = ""
    @State private var gitHubToken: String? = GitHubTokenStore.load()
    @State private var isLoggingIn = false
    @State private var loginError: String?
    @State private var activeSetup: DemoSetup?

    init() {
        GitHubOAuthClient.shared.appConfiguration = gitHubOAuthConfig
    }

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
                    Text("Composer is always included.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if submitStrategy == .github {
                    Section("GitHub access") {
                        if GitHubOAuthClient.shared.isConfigured == false {
                            Text("Add your GitHub OAuth Client ID/Secret to enable login.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(gitHubToken == nil ? "Not connected" : "Connected")
                                    .font(.headline)
                                if gitHubToken != nil {
                                    Text("Token stored in Keychain.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if gitHubToken == nil {
                                Button {
                                    Task { await loginWithGitHub() }
                                } label: {
                                    if isLoggingIn {
                                        ProgressView()
                                    } else {
                                        Text("Sign in")
                                    }
                                }
                                .disabled(isLoggingIn || !GitHubOAuthClient.shared.isConfigured)
                            } else {
                                Button("Sign out") {
                                    GitHubTokenStore.clear()
                                    gitHubToken = nil
                                }
                            }
                        }

                        if let loginError {
                            Text(loginError)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Bugger Demo")
            .safeAreaInset(edge: .bottom) {
                Button {
                    activeSetup = DemoSetup(
                        bugger: makeBugger(),
                        includeScreenshots: providerOption.includeScreenshots,
                        showsOnDevicePackagePreview: submitStrategy == .noop
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
            return !gitHubOwner.isEmpty && !gitHubRepository.isEmpty && !(gitHubToken ?? "").isEmpty
        }
    }

    private func makeBugger() -> Bugger {
        switch submitStrategy {
        case .noop:
            return .onDevice
        case .github:
            guard let token = gitHubToken, !token.isEmpty else {
                return .onDevice
            }
            let labels = gitHubLabels
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let configuration = GitHubIssueConfiguration(
                owner: gitHubOwner,
                repository: gitHubRepository,
                token: token,
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

    @MainActor
    private func loginWithGitHub() async {
        loginError = nil
        isLoggingIn = true
        defer { isLoggingIn = false }
        do {
            let token = try await GitHubOAuthClient.shared.login()
            try GitHubTokenStore.save(token)
            gitHubToken = token
        } catch {
            loginError = error.localizedDescription
        }
    }
}

private struct DemoSetup: Identifiable {
    let id = UUID()
    let bugger: Bugger
    let includeScreenshots: Bool
    let showsOnDevicePackagePreview: Bool
}

private struct BuggerSheet: View {
    let setup: DemoSetup
    @Environment(\.dismiss) private var dismiss
    @State private var presentedPackage: PresentedBugReportPackage?

    var body: some View {
        NavigationStack {
            BuggerScreen(
                bugger: setup.bugger,
                includeScreenshots: setup.includeScreenshots,
                onSubmit: { package in
                    guard setup.showsOnDevicePackagePreview else { return }
                    presentedPackage = PresentedBugReportPackage(package: package)
                }
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
        .sheet(item: $presentedPackage) { item in
            BugReportPackageSheet(package: item.package)
        }
    }
}

private struct PresentedBugReportPackage: Identifiable {
    let id = UUID()
    let package: BugReportPackage
}

private struct BugReportPackageSheet: View {
    let package: BugReportPackage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    Text("Report ID: \(package.reportID.uuidString)")
                    Text("Attachments: \(package.attachments.count)")
                }

                Section("Saved files") {
                    if package.attachments.isEmpty {
                        Text("No attachment files were written.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(package.attachments) { attachment in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(attachment.filename)
                                    .font(.headline)
                                Text(attachment.mimeType)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(attachment.fileURL.path)
                                    .font(.caption2)
                                    .textSelection(.enabled)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section("Payload JSON") {
                    Text(payloadJSONString)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Saved Package")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var payloadJSONString: String {
        String(data: package.payload, encoding: .utf8) ?? "<Invalid UTF-8 payload>"
    }
}

#Preview {
    ContentView()
}
