# ONMU Agent Rules

## 기준 문서

작업을 시작하기 전에 변경 범위에 맞는 문서를 먼저 확인한다.

- 팀 AI 도구, MCP, Skill 운영: `docs/development/team-ai-tooling.md`
- 디자인 토큰과 컴포넌트 기준: `docs/design/DESIGN.md`
- 릴리스 아키텍처: `docs/architecture/release-architecture.md`
- 현재 아키텍처 다이어그램: `docs/architecture/current-architecture-diagram.md`
- Git/Jira workflow: `docs/development/git-workflow.md`

## 언어

- README, `docs/**/*.md`, 사람이 읽는 코드 주석은 한국어로 작성한다.
- 클래스명, 함수명, 패키지명, API 이름, 외부 제품명은 원문을 유지할 수 있다.

## Git 작업

- `dev`와 `main`에 직접 push하지 않는다.
- 브랜치는 Jira 이슈를 기준으로 만든다.
- 커밋과 PR 규칙은 `docs/development/git-workflow.md`를 따른다.
- 자동 생성 코드도 사람이 리뷰 가능한 크기로 나눈다.

## Flutter UI 규칙

- 디자인 기준은 `docs/design/DESIGN.md`를 우선한다.
- 참고 이미지를 앱에 통째로 붙이지 않는다. UI는 수정 가능한 Flutter 위젯과 공통 컴포넌트로 다시 만든다.
- 색상은 `AppColors`, `ColorScheme`, `ThemeExtension`에서 가져온다.
- 텍스트 스타일은 `Theme.of(context).textTheme` 또는 ONMU typography extension을 사용한다.
- 간격은 8px 단위 토큰을 우선한다.
- 공통 버튼, 카드, 입력, 선택 칩, 단계 표시기는 `shared/widgets`의 컴포넌트를 우선 사용한다.
- 한 화면을 하나의 거대한 build method로 만들지 말고 작은 widget으로 분리한다.

## 보안

- secret, API key, credential, 실제 사용자 데이터, 실제 위치/사진/정산 데이터를 커밋하지 않는다.
- `.env.example`은 커밋할 수 있지만 `.env`는 커밋하지 않는다.
- 운영 secret은 Azure Key Vault, GitHub Secrets, 로컬 `.env` 중 하나로 관리한다.
- MCP 설정 파일에 토큰이나 개인 로컬 경로가 들어가면 커밋하지 않는다.

## 검증

- Flutter 코드를 바꾸면 가능한 범위에서 `flutter analyze`와 관련 `flutter test`를 실행한다.
- 문서 링크나 이미지 경로를 바꾸면 로컬 링크를 확인한다.
- 디자인 시스템을 바꾸면 관련 문서와 테스트를 함께 갱신한다.
