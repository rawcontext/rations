#!/usr/bin/env bash
set -euo pipefail

mode=run
app_args=()
signed="${SIGNED:-0}"
while (($#)); do
  argument="$1"
  shift
  case "$argument" in
    run|--run|--debug|--logs|--telemetry|--verify) mode="$argument" ;;
    --settings) app_args+=("$argument") ;;
    --connection-report)
      if (($# == 0)); then echo "--connection-report requires a path" >&2; exit 2; fi
      app_args+=(--connection-report "$1")
      shift
      ;;
    --signed) signed=1 ;;
    *) echo "usage: $0 [--verify|--debug|--logs|--telemetry] [--signed] [--settings]" >&2; exit 2 ;;
  esac
done

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"
app_bundle="$root_dir/dist/Rations.app"

make build CONFIGURATION=Debug SIGNED="$signed"
pkill -x Rations >/dev/null 2>&1 || true
mkdir -p "$root_dir/dist"
staging_dir="$(mktemp -d "$root_dir/dist/.rations.XXXXXX")"
trap 'rm -rf "$staging_dir"' EXIT
ditto "$root_dir/.build/Xcode/Build/Products/Debug/Rations.app" "$staging_dir/Rations.app"
rm -rf "$app_bundle"
mv "$staging_dir/Rations.app" "$app_bundle"

if [[ "$mode" == --debug ]]; then
  DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}" \
    xcrun lldb -- "$app_bundle/Contents/MacOS/Rations" ${app_args[@]+"${app_args[@]}"}
  exit
fi

/usr/bin/open -n "$app_bundle" --args ${app_args[@]+"${app_args[@]}"}
case "$mode" in
  --logs)
    /usr/bin/log stream --info --style compact --predicate 'process == "Rations"'
    ;;
  --telemetry)
    /usr/bin/log stream --info --style compact --predicate 'subsystem == "com.rawcontext.rations.dev"'
    ;;
  --verify)
    sleep 2
    pgrep -x Rations >/dev/null
    echo "Rations launched from $app_bundle"
    ;;
esac
