# Bugger

`Bugger` is a small bug-reporting core for iOS apps.

## Main Models

- `BugReport`: in-memory report draft with `description`, `reporter`, `deviceInfo`, `categories` (`BugReportCategory`), and attachments.
- `BugReporter`: reporter identity (`id`, `displayName`, optional `reachoutIdentifier`).
- `DeviceInfo`: normalized device metadata captured at submit time.
- `BugReportPackage`: packaged output ready for delivery (`payload` JSON + `attachments` persisted on disk).
- `Bugger`: orchestrator that builds a `BugReport` (`draftReport`) and then packs/submits it (`submit`).

Supporting extension points:

- `BugReportPacking` (default: `JSONReportPacker`)
- `ReportSubmitting` (default: `NoopReportSubmitter`; `HTTPReportSubmitter` uploads to your server)
- `BugReporterProviding` / `DeviceInfoProviding` / `ScreenshotProviding` / `CategoriesProviding`
- `BugReportCategory`: category type with `identifier` and `displayName`.

## Sending Reports to Your Server

`HTTPReportSubmitter` uploads each report as one `multipart/form-data` POST:

```swift
let bugger = Bugger(
    deviceInfoProvider: DefaultDeviceInfoProvider(),
    screenshotProvider: nil,
    packer: JSONReportPacker(),
    submitter: HTTPReportSubmitter(
        url: URL(string: "https://api.example.com/bug-reports")!,
        headers: { ["Authorization": "Bearer \(try await session.accessToken())"] }
    )
)
```

`headers` runs before every upload, so a token can be refreshed in between. If it throws, nothing is sent and the reporter sees "Submit failed".

### The request

```
POST /bug-reports
Content-Type: multipart/form-data; boundary=Bugger-<uuid>
<your headers>

--Bugger-<uuid>
Content-Disposition: form-data; name="report"; filename="report.json"
Content-Type: application/json

<report JSON, below>
--Bugger-<uuid>
Content-Disposition: form-data; name="attachment"; filename="screenshot.png"
Content-Type: image/png

<file bytes>
--Bugger-<uuid>--
```

There is one `attachment` part per file, possibly none. The report JSON:

```json
{
  "id": "19DE9A9B-DB9A-4B3A-A716-AA58EB9649B9",
  "createdAt": "2026-11-19T10:11:41Z",
  "description": "Tapping Save froze the app",
  "categories": [{ "identifier": "ui", "displayName": "UI" }],
  "reporter": { "id": "...", "displayName": "...", "reachoutIdentifier": "..." },
  "deviceInfo": {
    "systemName": "iOS",
    "systemVersion": "26.1",
    "model": "iPhone",
    "localizedModel": "iPhone",
    "identifierForVendor": "..."
  },
  "attachments": [
    { "id": "AE6CAF7A-640B-47E7-894B-060D23DC4FFC", "filename": "screenshot.png", "mimeType": "image/png" }
  ]
}
```

- `attachments[].filename` matches the `filename` of an `attachment` part. Filenames are unique within a report: a repeated name gets "-2", "-3" before the extension.
- `id` is a new UUID for every submit attempt, so a retry after a failed upload arrives with a new `id`. Deduplicate on content if that matters to you.
- `reachoutIdentifier` and `identifierForVendor` are left out when there is no value.
- Dates are ISO 8601, in UTC.

### Responses

Any 2xx response counts as success, and Bugger closes. Anything else throws `HTTPReportSubmitter.Error.unexpectedStatus(code, body:)`. The reporter sees "Submit failed" and can try again, with their report intact.

After each attempt, the submitter deletes the temporary attachment files, because a retry packs the report again.

To check that a server accepts the format, run the opt-in live test against it, for example a local one:

```sh
TEST_RUNNER_BUGGER_LIVE_SUBMIT_URL=http://127.0.0.1:8080/bug-reports \
  xcodebuild test -scheme Bugger -destination "platform=iOS Simulator,name=iPhone 17" \
  -only-testing:BuggerTests/HTTPReportSubmitterTests/testLiveServerIfConfigured
```

## Opening Bugger

Apply `.buggerReporting(...)` once, near the root of each scene:

```swift
WindowGroup {
    ContentView()
        .buggerReporting(
            bugger,
            isEnabled: reportingEnabled,      // e.g. from remote config or a user setting
            triggers: [.shake, .screenshot]   // the default; [] opens it only from code
        )
}
```

When the user shakes the device or takes a screenshot, Bugger captures the screen straight away, so the image matches what they saw. Then a "Found a bug?" bar slides up from the bottom of the screen for a few seconds, or longer with VoiceOver. Tapping "Report a Bug" opens the report with that screenshot attached. Ignoring the bar, or closing it, does nothing. With `asksBeforeOpening: false`, the report opens straight away instead.

Bugger shows the bar and the report in its own window above the app. It appears over the app's sheets, and the app can keep presenting and dismissing its own UI underneath. One bar or one report shows per scene at a time.

To open it from your own UI, read the action from the environment. It is `nil` while reporting is disabled, so the button can hide itself. Opening from code never shows the bar:

```swift
@Environment(\.buggerReport) private var buggerReport

var body: some View {
    if let buggerReport {
        Button("Report a bug") { buggerReport() }
    }
}
```

All of these can change at any time:

- `isEnabled: false` turns everything off. Shakes and screenshots do nothing, `buggerReport` is `nil`, and a bar or report that is open closes without sending.
- `triggers:` picks the automatic triggers. `[]` leaves only your own button.
- `asksBeforeOpening:` shows the bar first (the default), or opens the report directly.
- `attachesScreenshot: false` opens Bugger without capturing the screen.

While the reporter has typed something or changed the screenshots, swiping the report down is blocked, and Cancel asks before discarding. Cancel is disabled while a report is being submitted.

Notes:

- SwiftUI has no shake event, so Bugger hooks `UIWindow.motionEnded(_:with:)` the first time a shake trigger is turned on. It posts its own notification and then calls the original implementation. Bugger reacts first, so if your app already uses shake for something else, such as a debug menu, turn off the `.shake` trigger. A view controller that handles the shake without calling `super` stops it before Bugger sees it.
- iOS also offers "Undo Typing" when the user shakes while editing text. Set `UIApplication.shared.applicationSupportsShakeToEdit = false` if both appearing is a problem.
- The screenshot trigger uses Bugger's own capture, not the user's screenshot, so it needs no photo library access.
- The one-at-a-time rule covers reports opened by `.buggerReporting`. A `BuggerScreen` that your app presents itself is separate.

## Screenshots

`BuggerScreenCapture` captures the app's screen as a PNG attachment. Capture before presenting `BuggerScreen`, so the image shows the app and not Bugger, then pass it in:

```swift
let screenshot = BuggerScreenCapture.capture()
// later, when presenting:
BuggerScreen(bugger: bugger, screenshots: [screenshot].compactMap { $0 })
```

The reporter sees the screenshot in the report and can annotate or remove it. With `allowsPhotoLibrary: true` (the default), an "Add" tile also lets them attach screenshots from the photo library. With `false`, only the screenshots you pass in are shown.

`BuggerScreen` reads its arguments once, when it first appears. A parent view re-rendering doesn't reset what the reporter typed, attached or removed.

### What the capture includes

The screenshot is uploaded with the report, so check what it can contain:

- Every visible window of the scene, including alerts, sheets and overlays that the app or its SDKs present in-process. Pass `includingWindow:` to leave windows out.
- Not the keyboard, its suggestions or input accessory views: their UIKit windows are left out by default (`BuggerScreenCapture.isAppWindow`).
- Not system permission prompts or the status bar, which other processes draw.

Black out sensitive views, such as account numbers or messages, with `.buggerRedacted()` in SwiftUI or `BuggerScreenCapture.redact(view)` in UIKit.

In an app with more than one scene, pass the scene to capture, for example `BuggerScreenCapture.capture(scene: view.window?.windowScene)`. Otherwise Bugger picks the foreground scene that holds the key window.

The image is a lossless PNG at the screen's full resolution, so text stays legible. A full-screen capture can be a few megabytes.

## Speech Input

Reporters can dictate the description instead of typing it. Pass an engine to turn it on:

```swift
BuggerScreen(speechTranscriptionEngine: OnDeviceSpeechTranscriptionEngine())
```

Without an engine, the composer has no microphone button.

`OnDeviceSpeechTranscriptionEngine` uses Apple's speech recognizer and keeps the audio on the device. If the device can't recognize the locale on-device, the composer says speech isn't available rather than sending audio to Apple. Most simulators have no on-device recognition, so try it on a real device. On iOS 26 and later, when Apple Intelligence is available, the transcription is rewritten on the device into a short "What happened / Expected" report.

Add both of these keys to the host app's Info.plist. iOS terminates the app on the first permission request if either is missing:

- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`

If the reporter denies either permission, the composer explains why and links to Settings.

To use another speech service, implement `BuggerSpeechTranscriptionEngine`.

## Demo App

The repository includes a demo Xcode app in `Demo/`.

1. Open `Demo/Demo.xcodeproj` in Xcode.
2. Select the `demo` scheme.
3. Run on an iOS Simulator.

The demo lets you configure submit strategy and providers, then launch `BuggerScreen`.
