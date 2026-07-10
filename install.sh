#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
APP_NAME="RStudio Status.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "오류: RStudio Status는 macOS에서만 설치할 수 있습니다." >&2
    exit 1
fi

for command_name in swift R Rscript codesign; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "오류: '$command_name' 명령을 찾을 수 없습니다." >&2
        echo "README의 필수 조건을 확인해 주세요." >&2
        exit 1
    fi
done

if [[ -n "${INSTALL_DIR:-}" ]]; then
    APP_DIR="$INSTALL_DIR"
elif [[ -w /Applications ]]; then
    APP_DIR="/Applications"
else
    APP_DIR="$HOME/Applications"
fi

APP_PATH="$APP_DIR/$APP_NAME"

echo "[1/4] macOS 메뉴바 앱 빌드"
"$ROOT/scripts/build-app.sh"

echo "[2/4] 앱 설치: $APP_PATH"
pkill -x RStudioStatus 2>/dev/null || true
if [[ -d "$APP_PATH" ]]; then
    "$LSREGISTER" -u "$APP_PATH" 2>/dev/null || true
fi
mkdir -p "$APP_DIR"
ditto "$ROOT/dist/$APP_NAME" "$APP_PATH"
xattr -cr "$APP_PATH"
codesign --force --deep --sign - "$APP_PATH"
codesign --verify --deep "$APP_PATH"
"$LSREGISTER" -f "$APP_PATH"
"$LSREGISTER" -u "$ROOT/dist/$APP_NAME" 2>/dev/null || true

echo "[3/4] RStudio Addin 설치"
"$ROOT/scripts/install-r-package.sh"

echo "[4/4] 앱 실행"
open "$APP_PATH"

echo
echo "설치가 완료되었습니다."
echo "앱: $APP_PATH"
echo "RStudio를 다시 시작한 뒤 Addins 메뉴를 확인하세요."
echo "첫 실행 시 macOS 알림 권한을 허용해 주세요."
