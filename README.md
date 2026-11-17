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
- `ReportSubmitting` (default: `NoopReportSubmitter`)
- `BugReporterProviding` / `DeviceInfoProviding` / `ScreenshotProviding` / `CategoriesProviding`
- `BugReportCategory`: category type with `identifier` and `displayName`.

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
