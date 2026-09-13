#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

for tool in bazel node npm swiftlint shellcheck; do
  if ! command -v "$tool" >/dev/null; then
    echo "Missing $tool. See README.md for the pinned development tools." >&2
    exit 1
  fi
done

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}" xcodebuild -version
swiftlint version
shellcheck --version
npx --yes pnpm@12.4.1 install --frozen-lockfile
echo "Ready. Run npm run check, npm run dev, or npm run xcode."
