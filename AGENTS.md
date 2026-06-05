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
- Flutter 모바일 앱 작업의 커밋 scope는 `mobile`을 사용한다. 앱 또는 세션 컨텍스트에 `frontend(ios)` 같은 다른 scope가 보이더라도 이 프로젝트에서는 사용하지 않는다.
- Windows PowerShell에서 한글 PR/Issue 본문을 만들 때는 파이프나 stdin 대신 UTF-8 no BOM 파일을 `gh --body-file`로 넘기고, 생성 후 `gh pr view --json body` 또는 `gh issue view --json body`로 깨짐 여부를 확인한다.
- 자동 생성 코드도 사람이 리뷰 가능한 크기로 나눈다.

## Flutter UI 규칙

- 디자인 기준은 `docs/design/DESIGN.md`를 우선한다.
- 참고 이미지를 앱에 통째로 붙이지 않는다. UI는 수정 가능한 Flutter 위젯과 공통 컴포넌트로 다시 만든다.
- 색상은 `AppColors`, `ColorScheme`, `ThemeExtension`에서 가져온다.
- 텍스트 스타일은 `Theme.of(context).textTheme` 또는 ONMU typography extension을 사용한다.
- 간격은 8px 단위 토큰을 우선한다.
- 공통 버튼, 카드, 입력, 선택 칩, 단계 표시기는 `shared/widgets`의 컴포넌트를 우선 사용한다.
- 한 화면을 하나의 거대한 build method로 만들지 말고 작은 widget으로 분리한다.

## Flutter 아키텍처 규칙

- Flutter 기능 구현은 MVVM 구조를 기본으로 한다.
- 새 화면, 새 기능, 큰 UI 변경을 만들 때는 View, ViewModel, Model/Data 역할을 분리한다.
- View는 화면 렌더링과 사용자 입력 전달만 담당한다.
- `Widget` 안에서 API 호출, DB 접근, 복잡한 비즈니스 로직, 데이터 가공 로직을 직접 작성하지 않는다.
- View는 ViewModel의 상태를 읽고, 사용자 이벤트를 ViewModel 메서드로 위임한다.
- ViewModel은 화면 상태, 사용자 액션 처리, 유효성 검증, 로딩/에러 상태 전환을 담당한다.
- ViewModel은 특정 Widget 구현에 의존하지 않는다.
- ViewModel에 `BuildContext`를 저장하지 않는다.
- navigation, snackbar, dialog 같은 UI 효과는 View 또는 별도 UI event 패턴으로 처리한다.
- API, local storage, Firebase, database 접근은 ViewModel이나 View에서 직접 하지 않고 repository/service를 통해 수행한다.
- 기능 단위 구조는 기존 코드 패턴을 우선하되, 새 구조가 필요하면 다음 형태를 기준으로 한다.

```text
lib/features/<feature>/
  view/
  view_model/
  model/
  repository/ 또는 service/
  widgets/
```

## Flutter OOP 및 재사용성 규칙

- 클래스와 위젯은 단일 책임 원칙을 따른다.
- 하나의 `build` method가 커지면 private widget method보다 재사용 가능한 작은 `Widget` 클래스로 분리하는 것을 우선한다.
- 중복 UI는 `shared/widgets`의 공통 컴포넌트로 추출하거나 기존 공통 컴포넌트를 재사용한다.
- 중복 비즈니스 로직은 ViewModel에 복사하지 않고 service, repository, use case, helper 등 명확한 책임의 객체로 분리한다.
- 의존성은 구체 구현보다 추상 역할에 의존하도록 설계한다. 단, 실제 중복이나 교체 가능성이 없는 경우 불필요한 추상화는 만들지 않는다.
- 생성자 주입을 우선 사용해 테스트 가능한 구조로 만든다.
- 상태 객체는 가능한 불변 객체로 다루고, 상태 변경 흐름이 ViewModel 안에서 추적 가능해야 한다.
- 클래스명, 파일명, 메서드명은 역할이 드러나게 작성한다.
- 모호한 이름인 `Manager`, `Helper`, `Util`, `Data`는 구체적 책임이 없으면 사용하지 않는다.

## Flutter 변경 전 체크리스트

- 이 로직이 View에 있어야 하는가, ViewModel에 있어야 하는가, repository/service에 있어야 하는가?
- 기존 `shared/widgets`, theme, token, extension으로 해결 가능한 UI인가?
- 새 클래스가 하나의 책임만 갖는가?
- 테스트하기 어려운 구조가 생기지 않았는가?
- 같은 로직이나 UI가 다른 화면에 이미 존재하지 않는가?

## 보안

- secret, API key, credential, 실제 사용자 데이터, 실제 위치/사진/정산 데이터를 커밋하지 않는다.
- `.env.example`은 커밋할 수 있지만 `.env`는 커밋하지 않는다.
- 운영 secret은 Azure Key Vault, GitHub Secrets, 로컬 `.env` 중 하나로 관리한다.
- MCP 설정 파일에 토큰이나 개인 로컬 경로가 들어가면 커밋하지 않는다.

## 검증

- Flutter 코드를 바꾸면 가능한 범위에서 `flutter analyze`와 관련 `flutter test`를 실행한다.
- 문서 링크나 이미지 경로를 바꾸면 로컬 링크를 확인한다.
- 디자인 시스템을 바꾸면 관련 문서와 테스트를 함께 갱신한다.
