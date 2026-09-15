#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

swift_files=()
shell_files=()
while IFS= read -r -d '' file; do
  [[ -f "$file" ]] || continue
  case "$file" in
    docs/*) continue ;;
    *.swift) swift_files+=("$PWD/$file") ;;
    *.sh) shell_files+=("$PWD/$file") ;;
  esac
done < <(git ls-files --cached --others --exclude-standard -z)

if ((${#shell_files[@]})); then
  shellcheck "${shell_files[@]}"
fi
if ((${#swift_files[@]})); then
  swiftlint lint --strict --no-cache --config .swiftlint.yml "${swift_files[@]}"
  swift run --package-path tools/cognitive-complexity cognitive-check "${swift_files[@]}"
fi
./.build/tools/jscpd --config .jscpd.json --exit-code=1 --no-colors --no-tips
