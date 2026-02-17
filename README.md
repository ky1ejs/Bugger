# Bugger

`Bugger` is a small bug-reporting core for iOS apps.

## Main Models

- `BugReport`: in-memory report draft with `description`, `deviceInfo`, and screenshot `Data`.
- `DeviceInfo`: normalized device metadata captured at submit time.
- `BugReportPackage`: packaged output ready for delivery (`payload` JSON + `attachments` persisted on disk).
- `Bugger`: orchestrator that builds a `BugReport` (`draftReport`) and then packs/submits it (`submit`).

Supporting extension points:

- `BugReportPacking` (default: `JSONReportPacker`)
- `ReportSubmitting` (default: `NoopReportSubmitter`)
- `DeviceInfoProviding` / `ScreenshotProviding`

## Demo App

The repository includes a demo Xcode app in `Demo/`.

1. Open `Demo/Demo.xcodeproj` in Xcode.
2. Select the `demo` scheme.
3. Run on an iOS Simulator.

The demo lets you configure submit strategy and providers, then launch `BuggerScreen`.
