#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
R_USER_LIBRARY="$(Rscript --vanilla -e 'cat(path.expand(Sys.getenv("R_LIBS_USER")))')"

mkdir -p "$R_USER_LIBRARY"

Rscript --vanilla - "$R_USER_LIBRARY" <<'RSCRIPT'
args <- commandArgs(trailingOnly = TRUE)
user_library <- args[[1L]]
dependencies <- c("rstudioapi", "later")
missing <- dependencies[!vapply(
  dependencies,
  requireNamespace,
  logical(1),
  quietly = TRUE,
  lib.loc = c(user_library, .libPaths())
)]
if (length(missing)) {
  message("필수 R 패키지를 설치합니다: ", paste(missing, collapse = ", "))
  install.packages(missing, lib = user_library, repos = "https://cloud.r-project.org")
}
RSCRIPT

R CMD INSTALL --library="$R_USER_LIBRARY" "$ROOT/r-package"
echo "R 패키지 설치 위치: $R_USER_LIBRARY/rstudiostatus"
