#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

swift_files=()
build_files=()
shell_files=()
while IFS= read -r -d '' file; do
  [[ -f "$file" ]] || continue
  case "$file" in
    docs/*) continue ;;
    *.swift) swift_files+=("$PWD/$file") ;;
    BUILD.bazel|*/BUILD.bazel|*.BUILD|MODULE.bazel|REPO.bazel|*.bzl) build_files+=("$PWD/$file") ;;
    *.sh|tools/bazel) shell_files+=("$PWD/$file") ;;
  esac
done < <(git ls-files --cached --others --exclude-standard -z)

pnpm exec biome ci .
if ((${#build_files[@]})); then
  bazel run @buildifier_prebuilt//:buildifier -- -mode=check -lint=warn "${build_files[@]}"
fi
if ((${#shell_files[@]})); then
  shellcheck "${shell_files[@]}"
fi
if ((${#swift_files[@]})); then
  swiftlint lint --strict --no-cache --config .swiftlint.yml "${swift_files[@]}"
  bazel run //tools/cognitive-complexity:check -- "${swift_files[@]}"
fi
pnpm exec jscpd --config .jscpd.json --exit-code=1 --no-colors --no-tips
