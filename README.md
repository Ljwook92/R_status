# RStudio Status

RStudio에서 실행하는 R 코드의 상태를 macOS 메뉴바와 알림으로 보여주는 앱입니다.

대기 중에는 메뉴바에 RStudio 로고만 표시되고, Addin 또는 `rstatus_run()`으로 코드를 실행하면 상태가 다음과 같이 바뀝니다.

```text
[RStudio 로고]  →  Running ⏳ 00:12  →  Complete ✅
                                      ↘  Fail ⚠️
                                      ↘  Interrupted ⛔️
```

완료, 실패 또는 사용자 중단 시 macOS 알림도 전송됩니다. 모든 통신은 로컬 주소 `127.0.0.1:47821`에서만 이루어지며 R 코드나 데이터가 외부로 전송되지 않습니다.

## 기능

- RStudio 공식 로고를 사용하는 macOS 메뉴바 앱
- 실행 경과 시간 표시
- 완료·실패 시 macOS 알림
- 선택 영역 또는 현재 문서 전체를 실행하는 RStudio Addin
- 일반 R 코드에서 사용할 수 있는 `rstatus_run()` 함수
- 로그인 시 자동 실행, 상태 초기화, 알림 테스트 메뉴
- 현재 버전 표시 및 GitHub Release 업데이트 확인
- 앱과 Addin을 함께 설치하는 단일 설치 스크립트

## 필수 조건

- macOS 13 Ventura 이상
- Apple Silicon Mac
- [RStudio Desktop](https://posit.co/download/rstudio-desktop/)
- R 4.1 이상
- Xcode Command Line Tools

Command Line Tools가 없다면 터미널에서 다음 명령으로 설치할 수 있습니다.

```sh
xcode-select --install
```

현재 Swift 앱은 Apple Silicon용으로 테스트했습니다. Intel Mac에서는 소스 빌드가 가능할 수 있지만 아직 검증하지 않았습니다.

## 설치

터미널에서 저장소를 clone하고 설치 스크립트를 실행합니다.

```sh
git clone https://github.com/Ljwook92/R_status.git
cd R_status
chmod +x install.sh uninstall.sh scripts/*.sh
./install.sh
```

설치 스크립트는 다음 작업을 자동으로 수행합니다.

1. Swift 메뉴바 앱 빌드
2. 설치된 RStudio에서 공식 아이콘 복사
3. `RStudio Status.app`을 `/Applications` 또는 `~/Applications`에 설치
4. `rstudioapi` 의존성과 `rstudiostatus` R 패키지 설치
5. 앱 실행 및 macOS 서비스 등록

설치 위치를 직접 지정할 수도 있습니다.

```sh
INSTALL_DIR="$HOME/Applications" ./install.sh
```

처음 실행하면 macOS가 알림 권한을 요청합니다. 완료·실패 알림을 받으려면 **허용**을 선택하세요.

## RStudio Addin 사용

설치 후 RStudio를 완전히 종료했다가 다시 실행합니다. 상단의 **Addins** 메뉴에 다음 두 항목이 표시됩니다.

- **Run Selection with Status**: 에디터에서 선택한 R 코드를 실행
- **Run Current Document with Status**: 현재 R 문서 전체를 실행

### `Run Selection with Status` 실행 방법

1. RStudio 에디터에 실행할 R 코드를 입력하거나 `.R` 파일을 엽니다.
2. 상태를 추적할 코드를 마우스로 드래그해 선택합니다. 문서 전체를 선택하려면 `Cmd + A`를 누릅니다.
3. RStudio 상단 메뉴에서 **Addins**를 클릭합니다.
4. **Run Selection with Status**를 클릭합니다.
5. 선택 코드가 RStudio Console의 일반 실행 명령으로 전달되고 Console이 Busy 상태가 되는지 확인합니다.
6. 메뉴바의 RStudio 로고가 `Running ⏳`으로 바뀌는지 확인합니다.
7. 코드가 정상적으로 끝나면 `Complete ✅`, 오류가 발생하면 `Fail ⚠️`가 표시됩니다.
8. 실행 중 RStudio Console의 **Stop** 버튼을 누르면 `Interrupted ⛔️`가 표시됩니다.

Addin은 코드를 내부에서 바로 평가하지 않습니다. Addin 콜백이 먼저 종료된 후 짧은 지연을 두고 RStudio Console로 실행 명령을 전달합니다. 따라서 일반적인 Console 실행과 동일하게 Busy 표시와 Stop 버튼이 활성화됩니다. Console에는 다음과 유사한 명령이 한 줄 표시됩니다.

```r
rstudiostatus::run_file_with_status(".../rstudio-status-123.R", name = "analysis.R", cleanup = TRUE)
```

선택 영역이 비어 있으면 Addin이 실행할 코드가 없다는 오류를 표시합니다. 파일 전체를 실행하려면 코드를 선택하지 않고 **Run Current Document with Status**를 사용할 수도 있습니다.

### 20초 확인용 예제

저장소의 [`examples/status-test-20-seconds.R`](examples/status-test-20-seconds.R)을 RStudio에서 엽니다. 파일 전체를 선택한 뒤 **Addins → Run Selection with Status**를 실행하세요.

예제 코드는 다음과 같습니다.

```r
message("20-second matrix computation started")

started_at <- proc.time()[["elapsed"]]
iteration <- 0L
checksum <- 0

while (proc.time()[["elapsed"]] - started_at < 20) {
  matrix_size <- 600L
  values <- matrix(rnorm(matrix_size * matrix_size), nrow = matrix_size)
  gram_matrix <- crossprod(values)
  checksum <- checksum + sum(diag(gram_matrix))
  iteration <- iteration + 1L
}

message("Matrix computation complete: ", iteration, " iterations")
```

예상되는 메뉴바 변화:

```text
[RStudio 로고] → Running ⏳ 00:01 → Running ⏳ 00:20 → Complete ✅
```

이 예제는 `Sys.sleep()`이 아니라 실제 행렬 생성과 곱셈을 반복합니다. Addin이 코드를 Console로 전달하므로 RStudio가 Busy 상태가 되고 **Stop** 버튼으로 중단할 수 있습니다. 실행 중 Stop을 누르면 다음처럼 표시됩니다.

```text
Running ⏳ 00:08 → Interrupted ⛔️
```

완료하거나 중단하면 macOS 알림도 표시됩니다. 중단하지 않으면 전체 과정은 약 20초가 걸립니다.

### 단축키 지정

RStudio에서 다음 메뉴를 엽니다.

```text
Tools → Modify Keyboard Shortcuts…
```

검색창에 `Status`를 입력하고 두 Addin 중 원하는 항목에 단축키를 지정합니다. 이후 해당 단축키로 실행하면 메뉴바 상태가 자동으로 변경됩니다.

일반적인 `Cmd + Enter` 실행을 앱이 외부에서 자동 감지하지는 않습니다. 상태 추적이 필요한 코드는 Addin 단축키 또는 아래의 `rstatus_run()`을 사용해야 합니다.

## R 함수로 사용

긴 작업을 `rstatus_run()`으로 감싸면 시작·완료·실패가 자동으로 보고됩니다.

```r
library(rstudiostatus)

rstatus_run({
  Sys.sleep(5)
  model <- lm(mpg ~ wt, data = mtcars)
  saveRDS(model, "model.rds")
}, name = "모델 학습")
```

상태를 직접 전송할 수도 있습니다.

```r
library(rstudiostatus)

rstatus_notify("running", "데이터 처리")
rstatus_notify("complete", "데이터 처리")
rstatus_notify("fail", "데이터 처리", "입력 파일을 찾을 수 없습니다")
rstatus_notify("interrupted", "데이터 처리", "사용자가 작업을 중단했습니다")
rstatus_notify("idle", "")
```

## 메뉴바 메뉴

RStudio 로고 또는 상태 텍스트를 클릭하면 다음 기능을 사용할 수 있습니다.

- 현재 작업 이름과 실행 시간 확인
- 상태 초기화
- 알림 테스트
- RStudio 열기
- 로그인 시 실행 설정
- 현재 설치 버전 확인
- **Check for Updates…**로 GitHub의 최신 공개 Release 확인
- 앱 종료

업데이트가 없으면 `You're using the latest version.` 팝업이 표시됩니다. 새 공개 Release가 있으면 버전 정보와 **Open Download Page** 버튼이 표시됩니다. Draft와 pre-release는 최신 안정 버전 확인 대상에 포함되지 않습니다.

## 제거

저장소 폴더에서 다음 명령을 실행합니다.

```sh
./uninstall.sh
```

이 명령은 `/Applications` 또는 `~/Applications`의 앱과 사용자 R 라이브러리의 `rstudiostatus` 패키지를 제거합니다.

## 문제 해결

### Addins 메뉴에 항목이 보이지 않음

RStudio를 완전히 종료하고 다시 실행하세요. 그래도 보이지 않으면 RStudio 콘솔에서 다음을 확인합니다.

```r
find.package("rstudiostatus")
system.file("rstudio", "addins.dcf", package = "rstudiostatus")
```

RStudio가 터미널의 R과 다른 버전을 사용한다면, RStudio의 **Tools → Global Options → General → R version**에서 사용하는 R 버전을 확인한 후 해당 R로 설치 스크립트를 다시 실행하세요.

### 메뉴바 상태가 바뀌지 않음

메뉴바 앱이 실행 중인지 확인하고 다음 명령으로 로컬 서버 상태를 점검합니다.

```sh
curl http://127.0.0.1:47821/health
```

정상 응답:

```json
{"ok":true,"app":"RStudio Status"}
```

포트 47821을 다른 프로그램이 사용 중인지 확인하려면 다음을 실행합니다.

```sh
lsof -nP -iTCP:47821 -sTCP:LISTEN
```

### 알림이 오지 않음

macOS **시스템 설정 → 알림 → RStudio Status**에서 알림 허용이 켜져 있는지 확인하세요. 메뉴바 앱을 클릭한 뒤 **알림 테스트**로 확인할 수 있습니다.

### RStudio 아이콘을 찾지 못함

RStudio가 기본 위치가 아닌 곳에 설치되어 있다면 아이콘 경로를 지정합니다.

```sh
RSTUDIO_ICON_PATH="/path/to/RStudio.icns" ./install.sh
```

## 개발

앱만 빌드:

```sh
make build
```

Swift 빌드와 R 패키지 검사:

```sh
make check
```

### 새 버전 공개

앱의 업데이트 확인 기능은 GitHub의 최신 공개 Release를 기준으로 합니다. 새 버전을 배포할 때는 앱과 R 패키지 버전을 맞춘 뒤 `v0.1.4`와 같은 태그로 GitHub Release를 공개하세요. Release를 공개하기 전에는 설치된 로컬 버전을 최신 버전으로 안내합니다.

주요 디렉터리:

```text
Sources/RStudioStatus/   macOS 메뉴바 앱
Resources/               앱 Info.plist
r-package/               R 패키지 및 RStudio Addin
scripts/                 빌드·검사·설치 보조 스크립트
examples/                동작 확인용 R 예제
```

## 보안과 개인정보

- 서버는 `127.0.0.1`에만 바인딩됩니다.
- R 코드는 앱으로 전송되지 않습니다.
- 앱에는 상태, 작업 이름, 오류 메시지만 전달됩니다.
- 인터넷 연결은 최초 설치 시 `rstudioapi` 패키지가 없는 경우에만 필요합니다.

## 라이선스 및 상표

이 프로젝트의 코드는 [MIT License](LICENSE)로 배포됩니다.

RStudio 및 RStudio 로고는 Posit Software, PBC의 상표입니다. 이 프로젝트는 Posit의 공식 제품이 아니며 Posit과 제휴하거나 보증받지 않았습니다. 저장소는 RStudio 로고 파일을 포함하지 않고, 설치 과정에서 사용자의 로컬 RStudio 설치본에서 아이콘을 가져옵니다.
