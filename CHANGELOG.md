# Changelog

## 0.1.3 - 2026-07-09

- Addin 콜백이 종료된 뒤 Console 명령을 비동기로 전달하도록 변경
- 일부 RStudio 버전에서 Busy/Stop UI가 나타나지 않던 문제 수정

## 0.1.2 - 2026-07-09

- Addin 실행을 RStudio Console에 전달해 일반 실행과 동일한 Busy/Stop UI 제공
- 선택 코드와 현재 문서를 임시 파일로 안전하게 전달하고 실행 후 자동 정리

## 0.1.1 - 2026-07-09

- RStudio Stop으로 작업을 중단하면 `Interrupted` 상태와 알림 표시
- 20초 예제를 `Sys.sleep()` 대신 실제 행렬 연산으로 변경
- 메뉴가 열린 동안에도 실행 경과 시간 타이머가 계속 갱신되도록 수정

## 0.1.0 - 2026-07-09

- macOS 메뉴바 상태 앱 최초 공개
- Running, Complete, Fail 상태 및 실행 시간 표시
- 완료·실패 macOS 알림
- 선택 영역과 현재 문서 실행용 RStudio Addin
- `rstatus_run()` 및 `rstatus_notify()` 제공
- 통합 설치·제거 스크립트 추가
- 20초 동작 확인 예제와 Addin 단계별 사용 설명 추가
