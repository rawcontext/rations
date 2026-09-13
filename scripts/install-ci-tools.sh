#!/usr/bin/env bash
set -euo pipefail

# Release artifacts and digests were verified against the upstream release APIs.
tools_dir="${RUNNER_TEMP:?}/rations-tools"
mkdir -p "$tools_dir"
cd "$tools_dir"

curl -fsSL --retry 3 -o swiftlint.zip \
  https://github.com/realm/SwiftLint/releases/download/0.65.1/portable_swiftlint.zip
echo 'c1e429b0599cf1b516f369a2d9ec04eaf0e436f3c12b637df8851fa52ff694d0  swiftlint.zip' | shasum -a 256 -c -
ditto -x -k swiftlint.zip "$tools_dir"

curl -fsSL --retry 3 -o shellcheck.tar.xz \
  https://github.com/koalaman/shellcheck/releases/download/v0.11.0/shellcheck-v0.11.0.darwin.aarch64.tar.xz
echo '56affdd8de5527894dca6dc3d7e0a99a873b0f004d7aabc30ae407d3f48b0a79  shellcheck.tar.xz' | shasum -a 256 -c -
tar -xJf shellcheck.tar.xz
cp shellcheck-v0.11.0/shellcheck "$tools_dir/shellcheck"
echo "$tools_dir" >> "${GITHUB_PATH:?}"
