#!/bin/bash

if [ $TRAVIS_XCODE_SCHEME == "BuggerExample" ]; then
  carthage bootstrap --platform ios
fi
xcodebuild -project Bugger.xcodeproj -scheme $TRAVIS_XCODE_SCHEME -destination 'platform=iOS Simulator,name=iPhone X,OS=latest' build test | xcpretty
