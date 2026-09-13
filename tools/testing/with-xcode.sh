#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" == Darwin ]]; then
  developer_dir="${DEVELOPER_DIR:-$(xcode-select -p)}"
  platform_dir="$developer_dir/Platforms/MacOSX.platform/Developer"
  export DYLD_FRAMEWORK_PATH="$platform_dir/Library/Frameworks:$platform_dir/Library/PrivateFrameworks"
  export DYLD_LIBRARY_PATH="$platform_dir/usr/lib"
fi
exec "$@"
