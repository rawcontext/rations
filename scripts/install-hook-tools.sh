#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

tools_dir="$PWD/.build/tools"
download_dir="$(mktemp -d)"
trap 'rm -rf "$download_dir"' EXIT
mkdir -p "$tools_dir"

case "$(uname -m)" in
  arm64)
    jscpd_arch=arm64
    jscpd_sha=b5646c1ab79a67773d3bb54c8ab48751466f39d7df47f7859e6493a6d5acc76a
    lefthook_arch=arm64
    lefthook_sha=22881605cdf99b3d7da67005d6a08d4bb90fed4730dde6e2d39e316750be1afe
    ;;
  x86_64)
    jscpd_arch=x64
    jscpd_sha=d07ab62c5fd6a8946f467ae4b54a3cd6d6a44b763349e89c4915a93814090d7c
    lefthook_arch=x86_64
    lefthook_sha=6b72981f76138abcd5af4eab65eb72435f4c0b48ba20abadd12b0aaad551d647
    ;;
  *) echo "Unsupported Mac architecture: $(uname -m)" >&2; exit 1 ;;
esac

download() {
  curl -fsSL --retry 3 -o "$download_dir/$1" "$2"
  echo "$3  $download_dir/$1" | shasum -a 256 -c -
}

download jscpd.tar.gz \
  "https://github.com/kucherenko/jscpd/releases/download/v5.2.0/jscpd-darwin-$jscpd_arch.tar.gz" \
  "$jscpd_sha"
tar -xzf "$download_dir/jscpd.tar.gz" -C "$tools_dir" jscpd

download lefthook \
  "https://github.com/evilmartians/lefthook/releases/download/v2.1.14/lefthook_2.1.14_MacOS_$lefthook_arch" \
  "$lefthook_sha"
install -m 755 "$download_dir/lefthook" "$tools_dir/lefthook"
