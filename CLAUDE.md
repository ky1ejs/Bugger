# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bugger is an iOS framework (Swift, UIKit) for in-app bug reporting. It captures screenshots, device information, and allows users to annotate and submit reports to bug tracking systems (GitHub Issues, Linear).

## Build Commands

```bash
# Build a specific scheme
xcodebuild -scheme Bugger -destination "name=iPhone 14 Pro" | xcpretty

# Resolve Swift package dependencies
swift package resolve

# Run tests
swift test

# Build BuggerLinear (requires GraphQL code generation first)
swift run --package-path .build/checkouts/apollo-ios/ apollo-ios-cli generate -p Sources/BuggerLinear/apollo-codegen-config.json
xcodebuild -scheme BuggerLinear -destination "name=iPhone 14 Pro" | xcpretty
```

Available schemes: `Bugger`, `BuggerGitHub`, `BuggerImgurStore`, `BuggerLinear`, `HelpfulUI`

## Architecture

### Module Structure

The package publishes 5 libraries with clear dependency boundaries:

- **Bugger** - Core framework: state management, screenshot capture, device info collection, annotation UI
- **BuggerGitHub** - GitHub Issues integration (depends on Bugger, BuggerImgurStore, HelpfulUI)
- **BuggerLinear** - Linear.app integration via GraphQL (depends on Bugger, HelpfulUI, Apollo)
- **BuggerImgurStore** - Imgur image hosting for screenshots (depends on Bugger)
- **HelpfulUI** - Reusable UI components (no dependencies)

### Key Patterns

**State Machine**: `BuggerState` enum (`.notWatching`, `.watching`, `.active`) manages the bug reporter lifecycle

**Report Building**: `BuggerReportBuilder` protocol allows different integrations to build reports in their own format. Implementations in `GitHubReportBuilder` and `LinearReportBuilder`

**Shake-to-Trigger**: Uses UIResponder swizzling to detect shake gestures when in `.watching` state

### Key Files

- `Sources/Bugger/Bugger.swift` - Main entry point with static state management
- `Sources/Bugger/BuggerReportBuilder.swift` - Report builder protocol
- `Sources/Bugger/Device.swift` - Device metadata capture
- `Sources/BuggerLinear/queries.graphql` - Linear API queries (regenerate with apollo-ios-cli)

## Testing

Tests are in `Tests/BuggerTests/`. Run with `swift test` or via Xcode.

Test files:
- `BuggerTests.swift` - Core state management tests
- `ReportTests.swift` - Report building tests
- `DummyStore.swift` - Mock store for testing

## CI/CD

GitHub Actions workflow (`.github/workflows/build.yml`) builds all schemes. BuggerLinear has a separate job that runs GraphQL code generation before building.
