#!/bin/zsh
set -euo pipefail

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
APP_CANDIDATES=(
    "/Applications/RStudio Status.app"
    "$HOME/Applications/RStudio Status.app"
)

pkill -x RStudioStatus 2>/dev/null || true

for app_path in "${APP_CANDIDATES[@]}"; do
    if [[ -d "$app_path" ]]; then
        "$LSREGISTER" -u "$app_path" 2>/dev/null || true
        rm -rf "$app_path"
        echo "앱 제거: $app_path"
    fi
done

Rscript --vanilla - <<'RSCRIPT'
user_library <- path.expand(Sys.getenv("R_LIBS_USER"))
if (dir.exists(user_library) && "rstudiostatus" %in% rownames(installed.packages(lib.loc = user_library))) {
  remove.packages("rstudiostatus", lib = user_library)
  message("R Addin 제거: ", user_library)
} else {
  message("사용자 R 라이브러리에 설치된 rstudiostatus 패키지가 없습니다.")
}
RSCRIPT

echo "RStudio Status 제거가 완료되었습니다."
