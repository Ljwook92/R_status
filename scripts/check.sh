#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
CHECK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/rstatus-check.XXXXXX")"
trap 'rm -rf "$CHECK_ROOT"' EXIT

echo "Swift release 빌드 검사"
cd "$ROOT"
swift build -c release

echo "R 패키지 검사"
cd "$CHECK_ROOT"
R CMD build "$ROOT/r-package"
R CMD check --no-manual rstudiostatus_*.tar.gz

echo "모든 검사를 통과했습니다."
