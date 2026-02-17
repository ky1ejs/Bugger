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
        var includeScreenshots: Bool {
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

    var body: some View {
        NavigationStack {
            Form {
                Section("Submit strategy") {
                    Text("On device (No-op)")
                        .foregroundStyle(.secondary)
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
                    activeSetup = DemoSetup(
                        bugger: .onDevice,
                        includeScreenshots: providerOption.includeScreenshots,
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
