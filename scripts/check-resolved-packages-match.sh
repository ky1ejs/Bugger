#!/bin/sh

SWIFTPM="Package.resolved"
XCODE="xcode-project/Bugger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

if cmp --silent $SWIFTPM $XCODE; then
  echo "Swift package's resolved dependencies and Xcode projects resolved depencies don't match"
  diff $SWIFTPM $XCODE
  exit 1
else
  echo "Resolved Swift packages match."
fi
