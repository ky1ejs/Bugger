//
//  ContentView.swift
//  demo
//
//  Created by Fabio Milano on 2/16/26.
//

import SwiftUI
import Bugger

struct ContentView: View {
    enum ProviderOption: String, CaseIterable, Identifiable {
        case composerOnly = "Just Composer"
        case composerAndScreenshots = "Screenshots"

        var id: String { rawValue }
        var allowsScreenshots: Bool {
            switch self {
            case .composerOnly:
                return false
            case .composerAndScreenshots:
                return true
            }
        }
    }

    @State private var providerOption: ProviderOption = .composerAndScreenshots
    @State private var activeSetup: DemoSetup?
    @State private var reportingEnabled = true
    @State private var shakeTrigger = true
    @State private var screenshotTrigger = true
    @State private var lastSubmittedReport: String?

    private var triggers: BuggerTrigger {
        var triggers: BuggerTrigger = []
        if shakeTrigger { triggers.insert(.shake) }
        if screenshotTrigger { triggers.insert(.screenshot) }
        return triggers
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Submit strategy") {
                    Text("On device (No-op)")
                        .foregroundStyle(.secondary)
                        // Shows redaction: this row is blacked out in captured screenshots.
                        .buggerRedacted()
                }

                Section {
                    Toggle("Reporting enabled", isOn: $reportingEnabled)
                    Toggle("Shake to report", isOn: $shakeTrigger)
                        .disabled(!reportingEnabled)
                    Toggle("Screenshot to report", isOn: $screenshotTrigger)
                        .disabled(!reportingEnabled)
                    ReportBugButton()
                    if let lastSubmittedReport {
                        Text("Last report: \(lastSubmittedReport)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Triggers")
                } footer: {
                    Text("With reporting disabled, shakes and screenshots do nothing and the button is hidden.")
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
            }
            .navigationTitle("Bugger Demo")
            .safeAreaInset(edge: .bottom) {
                Button {
                    // Capture before presenting, so the screenshot shows the demo and not Bugger.
                    let screenshot = providerOption.allowsScreenshots
                        ? BuggerScreenCapture.capture()
                        : nil
                    activeSetup = DemoSetup(
                        bugger: makeDemoBugger(),
                        allowsPhotoLibrary: providerOption.allowsScreenshots,
                        screenshots: [screenshot].compactMap { $0 },
                        speechTranscriptionEngine: OnDeviceSpeechTranscriptionEngine(),
                        showsOnDevicePackagePreview: true
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
            }
        }
        .sheet(item: $activeSetup) { setup in
            BuggerSheet(setup: setup)
        }
        .buggerReporting(
            makeDemoBugger(),
            isEnabled: reportingEnabled,
            triggers: triggers,
            speechTranscriptionEngine: OnDeviceSpeechTranscriptionEngine(),
            onSubmit: { package in
                lastSubmittedReport = package.reportID.uuidString
            }
        )
    }
}

/// Opens Bugger from app code. Hidden while reporting is disabled.
private struct ReportBugButton: View {
    @Environment(\.buggerReport) private var buggerReport

    var body: some View {
        if let buggerReport {
            Button("Report a bug") {
                buggerReport()
            }
        }
    }
}

private struct DemoSetup: Identifiable {
    let id = UUID()
    let bugger: Bugger
    let allowsPhotoLibrary: Bool
    let screenshots: [BugReportAttachment]
    let speechTranscriptionEngine: (any BuggerSpeechTranscriptionEngine)?
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
                allowsPhotoLibrary: setup.allowsPhotoLibrary,
                screenshots: setup.screenshots,
                speechTranscriptionEngine: setup.speechTranscriptionEngine,
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

private func makeDemoBugger() -> Bugger {
    Bugger(
        deviceInfoProvider: DefaultDeviceInfoProvider(),
        screenshotProvider: nil,
        categoriesProvider: DemoCategoriesProvider(),
        packer: JSONReportPacker(),
        submitter: NoopReportSubmitter()
    )
}

private struct DemoCategoriesProvider: CategoriesProviding {
    func fetchCategories() async throws -> [BugReportCategory] {
        [
            BugReportCategory(identifier: "ui", displayName: "UI"),
            BugReportCategory(identifier: "performance", displayName: "Performance"),
            BugReportCategory(identifier: "network", displayName: "Network")
        ]
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
