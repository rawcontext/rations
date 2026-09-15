#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

for tool in xcodebuild swiftlint shellcheck; do
  if ! command -v "$tool" >/dev/null; then
    echo "Missing $tool. See README.md for the pinned development tools." >&2
    exit 1
  fi
done

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}" xcodebuild -version
swiftlint version
shellcheck --version
./scripts/install-hook-tools.sh
./.build/tools/lefthook install
echo "Ready. Run make check, make dev, or make xcode."
