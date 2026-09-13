#!/usr/bin/env bash
set -euo pipefail

mode="${1:-run}"
case "$mode" in
  run|--debug|--logs|--telemetry|--verify) ;;
  *) echo "usage: $0 [--debug|--logs|--telemetry|--verify]" >&2; exit 2 ;;
esac

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"
app_bundle="$root_dir/dist/Rations.app"

pkill -x Rations >/dev/null 2>&1 || true
bazel build //apps/macos:app
archive="$root_dir/$(bazel cquery //apps/macos:app --output=files)"
mkdir -p "$root_dir/dist"
staging_dir="$(mktemp -d "$root_dir/dist/.rations.XXXXXX")"
trap 'rm -rf "$staging_dir"' EXIT
ditto -x -k "$archive" "$staging_dir"
rm -rf "$app_bundle"
mv "$staging_dir/Rations.app" "$app_bundle"

if [[ "$mode" == --debug ]]; then
  DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}" \
    xcrun lldb -- "$app_bundle/Contents/MacOS/Rations"
  exit
fi

/usr/bin/open -n "$app_bundle"
case "$mode" in
  --logs)
    /usr/bin/log stream --info --style compact --predicate 'process == "Rations"'
    ;;
  --telemetry)
    /usr/bin/log stream --info --style compact --predicate 'subsystem == "com.ccheney.rations.dev"'
    ;;
  --verify)
    sleep 2
    pgrep -x Rations >/dev/null
    echo "Rations launched from $app_bundle"
    ;;
esac
