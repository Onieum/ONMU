# ONMU

ONMU는 Flutter 모바일 앱을 중심으로 약속 큐레이션과 기록을 연결하는 서비스입니다. 사용자가 함께 약속을 만들고, 만날 장소를 정하고, 실시간 도착 상태를 공유한 뒤, 사진과 캐릭터 요소가 들어간 기억 카드로 남기는 흐름을 지원합니다.

## 제품 방향

- **모바일 우선:** 핵심 제품 경험은 iOS와 Android Flutter 네이티브 앱에서 제공합니다.
- **릴리스 수준 아키텍처:** 관리형 데이터 서비스, 관측성, CI/CD, 보안을 초기 기준에 포함합니다. 정식 운영 target은 `infra/terraform/`의 Azure 관리형(검증된 관리형) 아키텍처다.
- **임시 운영 런타임:** 개발 단계 비용($0/월, 무료 한도) 때문에 정식 운영 전까지 Azure VM + Docker Compose + Cloudflare(R2/Tunnel/Pages) + Azure PostgreSQL Flexible(관리형 DB 잔류) 조합을 임시 운영 런타임으로 사용합니다. `dev` 머지 시 `deploy-staging-vm.yml`이 VM에 자동 배포합니다.
- **애자일 전달:** 모든 제품 도메인을 얇게 연결하는 세로 프로토타입부터 만들고, 스프린트마다 각 도메인을 깊게 확장합니다.
- **웹 범위:** 웹은 브랜드와 프로젝트 소개만 담당합니다. 핵심 제품 흐름은 Flutter 앱에 둡니다.

## 저장소 구조

```text
apps/
  mobile-flutter/        # Flutter 앱
  brand-web/             # 정적 브랜드/프로젝트 소개 웹
services/
  api/                   # 메인 도메인 API
  realtime-gateway/      # WebSocket 방 상태와 fan-out
  workers/               # 추천, 장소 리스크, 경로, 기록, 알림 워커
infra/
  compose/               # 로컬/VM 운영용 compose 스택
  k8s/                   # Kubernetes base와 overlay
  terraform/             # Azure 인프라 (정식 운영 target, 검증된 관리형 명세)
packages/
  api-contracts/         # OpenAPI와 생성된 계약 산출물
  shared-schemas/        # 공유 스키마 정의
docs/
  architecture/          # 릴리스 아키텍처와 도메인 경계
  development/           # 개발 환경과 워크플로 가이드
  integrations/          # Jira, GitHub, Notion 자동화
  operations/            # 릴리스, 관측성, 운영 문서
```

## 첫 프로토타입

첫 프로토타입은 네 파트가 하나의 얇은 사용자 여정으로 이어져야 합니다.

```text
프로필/취향
  -> 약속 방
  -> 실시간 참여 상태
  -> 장소 후보 검색/점수화
  -> 장소 결정
  -> 사진 또는 기억 카드
  -> 캐릭터/스티커 결과
```

## 작업 흐름

- 기본 통합 브랜치: `dev`
- 안정 릴리스 브랜치: `main`
- 작업 브랜치 형식: `type/SCRUM-123-short-description`
- 커밋 형식: `type(scope): SCRUM-123 short description`
- 모든 머지는 pull request를 거칩니다.
- 공개 저장소 기준으로 `dev`와 `main`에는 브랜치 보호를 적용합니다.
- Jira는 일정과 작업 상태의 기준이고, GitHub는 코드 리뷰와 CI의 기준입니다.
- README, `docs/**/*.md`, 사람이 읽는 주석은 한국어로 작성합니다.

주요 문서:

- `docs/architecture/release-architecture.md`
- `docs/development/git-workflow.md`
- `docs/development/platform-setup.md`
- `docs/integrations/jira-github-notion.md`
- `docs/operations/windows-backend-server.md`

## 현재 저장소 기준

- 저장소 공개 범위: public
- 기본 브랜치: `dev`
- 보호 브랜치: `dev`, `main`
- 필수 CI check: `Repository checks`, `Flutter app`(analyze만 게이트)
- 임시 운영 런타임: Azure VM + Docker Compose + Cloudflare(`dev` 머지 시 자동 배포). 정식 운영 target은 `infra/terraform/`의 관리형 아키텍처. 자세한 분기는 [staging cutover status](docs/operations/staging-cutover-status.md) 참고.
- 의존성 자동 점검: GitHub Actions, npm, Flutter pub 기준 Dependabot
- Android Gradle wrapper: 저장소에 포함하며 팀원과 CI가 같은 Gradle 버전을 사용합니다.
