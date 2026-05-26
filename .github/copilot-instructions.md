# ONMU 저장소 가이드라인

## 기준 문서

- 제품과 릴리스 아키텍처: `docs/architecture/release-architecture.md`
- 플랫폼 세팅: `docs/development/platform-setup.md`
- Git 작업 흐름: `docs/development/git-workflow.md`
- Jira/GitHub/Notion 자동화: `docs/integrations/jira-github-notion.md`
- 공용 Windows 백엔드 서버: `docs/operations/windows-backend-server.md`

## 제품 맥락

ONMU는 Flutter 우선 모바일 제품입니다. 웹 앱은 브랜드와 프로젝트 소개만 담당합니다. 핵심 흐름은 Flutter 앱과 백엔드 API를 기준으로 설계해야 합니다.

## 아키텍처 방향

- 처음부터 릴리스 가능한 아키텍처를 기준으로 설계합니다.
- 목표 플랫폼에는 AKS, 관리형 PostgreSQL/PostGIS, Redis, 오브젝트 스토리지, 이벤트 버스, 관측성, CI/CD를 포함합니다.
- Docker Compose는 로컬 의존성 일치 용도로만 사용합니다.
- 첫 세로 프로토타입은 프로필, 약속/실시간, 장소/외부 API, 기록/캐릭터 도메인을 모두 연결해야 합니다.

## 저장소 작업 흐름

- 기본 통합 브랜치는 `dev`입니다.
- `dev` 또는 `main`에 직접 push하지 않습니다.
- Jira 이슈를 먼저 만들고 브랜치를 만듭니다.
- 브랜치 형식은 `type/SCRUM-123-short-description`입니다.
- 허용 브랜치 type은 `feat`, `fix`, `hotfix`, `chore`, `refactor`, `docs`, `set`, `test`입니다.
- 모든 merge는 pull request를 거칩니다.

## 커밋과 PR 규칙

- 커밋 형식은 `type(scope): SCRUM-123 short description`입니다.
- 허용 커밋 type은 `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `ci`, `build`, `perf`입니다.
- 권장 scope는 `mobile`, `brand-web`, `api`, `realtime`, `worker`, `place`, `memory`, `profile`, `infra`, `ci`, `docs`입니다.
- PR 제목 형식은 `[Type] SCRUM-123 한국어 요약`입니다.
- PR 본문에는 요약, 변경 사항, 검증, 관련 이슈가 있어야 합니다.

## 보안 규칙

- secret, API key, signing key, Firebase 실제 설정 파일, 실제 credential을 커밋하지 않습니다.
- `.env.example`은 커밋하고 `.env`는 커밋하지 않습니다.
- 운영 credential은 Azure Key Vault 또는 platform secret에 저장합니다.
- 실제 사용자 데이터, export된 사진, CSV 파일, DB dump, 위치 dataset을 커밋하지 않습니다.

## Flutter 규칙

- flavor는 `dev`, `staging`, `prod`를 사용합니다.
- domain state는 widget 밖에 둡니다.
- 백엔드 계약이 있으면 OpenAPI로 생성한 client를 우선 사용합니다.
- 실시간 흐름에는 reconnect와 방 상태 resync 동작이 필요합니다.

## 언어 규칙

- README와 `docs/**/*.md`는 한국어로 작성합니다.
- 사람이 읽는 주석은 한국어로 작성합니다.
- 기술 용어, 명령어, identifier, API 이름, product name은 필요한 경우 원문을 유지할 수 있습니다.
- Gradle wrapper, Flutter generated registrant, `pubspec.lock`처럼 외부 도구가 재생성하는 표준 파일은 동작 안정성을 우선하고, 사람이 직접 작성하는 주변 문서에서 의미를 한국어로 설명합니다.
