#!/usr/bin/env bash
set -euo pipefail

cp "$SRCROOT/apps/macos/Resources/Info.plist" "$SCRIPT_OUTPUT_FILE_0"
if [[ "$CONFIGURATION" == Release ]]; then
  /usr/libexec/PlistBuddy -c "Merge $SRCROOT/apps/macos/Resources/Distribution.plist" "$SCRIPT_OUTPUT_FILE_0"
fi
cp "$SRCROOT/LICENSE" "$SCRIPT_OUTPUT_FILE_1"
cp "$SRCROOT/third_party/sparkle/LICENSE" "$SCRIPT_OUTPUT_FILE_2"
