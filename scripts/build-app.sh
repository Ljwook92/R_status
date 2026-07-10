#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP="$ROOT/dist/RStudio Status.app"
RSTUDIO_ICON="${RSTUDIO_ICON_PATH:-}"

if [[ -z "$RSTUDIO_ICON" ]]; then
    for candidate in \
        "/Applications/RStudio.app/Contents/Resources/RStudio.icns" \
        "$HOME/Applications/RStudio.app/Contents/Resources/RStudio.icns"; do
        if [[ -f "$candidate" ]]; then
            RSTUDIO_ICON="$candidate"
            break
        fi
    done
fi

if [[ -z "$RSTUDIO_ICON" || ! -f "$RSTUDIO_ICON" ]]; then
    echo "오류: RStudio 공식 아이콘을 찾을 수 없습니다." >&2
    echo "RStudio Desktop을 설치하거나 RSTUDIO_ICON_PATH를 지정해 주세요." >&2
    exit 1
fi

cd "$ROOT"
swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/RStudioStatus" "$APP/Contents/MacOS/RStudioStatus"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$RSTUDIO_ICON" "$APP/Contents/Resources/RStudio.icns"
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"

echo "$APP"
