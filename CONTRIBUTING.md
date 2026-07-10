# Contributing

버그 제보와 개선 제안은 GitHub Issues를 이용해 주세요.

코드를 수정한 뒤 Pull Request를 만들기 전에 다음 검사를 실행합니다.

```sh
chmod +x scripts/*.sh
make check
```

변경 범위에 따라 다음 항목을 함께 확인해 주세요.

- 메뉴바의 대기·실행·완료·실패 상태
- RStudio Addin의 선택 영역 및 현재 문서 실행
- 완료·실패 알림
- `README.md`의 설치 및 사용 설명

Pull Request에는 변경 목적, 확인한 macOS/R/RStudio 버전, 수행한 테스트를 적어 주세요.
