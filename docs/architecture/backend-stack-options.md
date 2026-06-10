# ONMU 백엔드 결정 원본과 기술스택

## 결정 상태

이 문서는 백엔드 관련 결정의 원본 문서다. 아키텍처 다이어그램, API 계약, mock-to-api 전환 문서는 이 문서의 확정값을 기준으로 맞춘다.

Flutter는 확정 스택이고, 백엔드는 `C안: Spring Boot Main API + FastAPI Worker`로 결정한다.

Spring Boot는 모바일 앱이 직접 호출하는 공식 API, 인증/인가, 권한, 트랜잭션, DB migration을 맡는다. FastAPI Worker는 AI, 추천, 분석, 외부 데이터 해석처럼 Python 생태계가 유리한 비동기 작업을 맡는다.

현재 Windows `dev`와 `integration-staging` backend-host는 `services/api-spring` Spring Boot Main API를 기준으로 실행한다. `/healthz`, `/readyz`, 터널, Key Vault, 로그 수집도 Spring Boot Main API 계약으로 검증한다.

## 확정안

| 영역 | 확정 기술 | 책임 |
| --- | --- | --- |
| Main API | `services/api-spring`, Spring Boot 3, Java 21, Spring Security, JPA/Querydsl, Flyway | full social OAuth, 사용자/session, groups/plans/places/settlements/records 도메인 API, 권한, 트랜잭션, core DB migration |
| AI/Data Worker | `services/workers/ai-data-worker`, FastAPI, Pydantic, Alembic | 장소 후보 설명, 취향/추천 계산, OOTD/기록 설명 생성, AI 호출, 비동기 분석, worker 전용 schema migration |
| Public API 경계 | Spring Boot Main API | Flutter 앱이 호출하는 `/api/v1` 계약의 단일 진입점 |
| Worker 경계 | Queue/Outbox | 모바일 앱에서 직접 호출하지 않고 Spring Boot가 작업 요청과 결과 반영을 관리 |
| 첫 OAuth Provider | Naver | OAuth 전용 `NAVER_OAUTH_CLIENT_ID`, `NAVER_OAUTH_CLIENT_SECRET`을 Spring 서버 env/Key Vault에서 주입해 인증 smoke를 시작 |
| Session/Token | access token + refresh token + Flutter secure storage | Spring Boot가 provider token을 검증하고 ONMU 자체 token을 발급 |

## 검토했던 선택지

| 선택지 | 설명 | 장점 | 결론 |
| --- | --- | --- | --- |
| Spring Boot Main API 단독 | 공식 API를 Spring Boot 한 서비스로 구현 | 인증/권한/정산/트랜잭션에 강함 | AI/추천 Python 작업 분리가 필요해 확장안으로 부족 |
| FastAPI Main API 단독 | 공식 API를 FastAPI 한 서비스로 구현 | 구현 속도와 Python AI 연계가 빠름 | 권한/트랜잭션 운영 기준을 Spring보다 더 엄격히 설계해야 함 |
| Spring Boot Main API + FastAPI Worker | Spring은 공식 API, FastAPI는 AI/Data worker | 운영 API 안정성과 AI 확장성을 동시에 확보 | 확정 |
| FastAPI Main API + worker 없음 | Python 한 서비스로 빠르게 시작 | prototype 속도 우수 | 운영형 확장 시 worker 분리 기준이 늦게 생김 |
| Node/TypeScript Main API | 현재 smoke API를 확장 | 현재 Node 서버와 이어가기 쉬움 | Flutter와 타입 공유 이점이 작고 팀의 백엔드 방향과 다름 |

## 결정 이유

- `groups/plans/settlements`는 참여자 권한, 정산 대상자, 일정 상태처럼 트랜잭션 정합성이 중요하다.
- full social OAuth와 session/refresh 흐름은 Spring Security 기반으로 운영 기준을 잡기 쉽다.
- 장소 추천 설명, OOTD 분석, 기록 설명 생성은 Python AI/Data worker가 자연스럽다.
- Main API와 Worker 경계가 분리되어 발표와 협업에서 책임을 설명하기 쉽다.
- Flutter repository는 Spring Boot API contract만 바라보고, FastAPI는 내부 작업자로 숨길 수 있다.

## Sprint 0 구현 검증

이제 Sprint 0의 목적은 선택지 비교가 아니라 확정안의 세로 흐름을 작게 검증하는 것이다.

```text
Naver full social OAuth
  -> Spring Boot /healthz, /readyz
  -> GET /api/v1/users/me
  -> GET/POST /api/v1/groups
  -> GET/POST /api/v1/groups/{groupId}/plans
  -> POST /api/v1/place-search
  -> GET/POST /api/v1/groups/{groupId}/plans/{planId}/place-candidates
  -> POST /api/v1/groups/{groupId}/votes
  -> POST /api/v1/groups/{groupId}/plans/{planId}/settlements/preview
  -> outbox_events에 worker 요청 적재
  -> FastAPI ai-data-worker가 worker_ai schema에 job 상태 기록
```

검증 기준:

- Flutter mock repository와 API repository가 같은 read model을 쓸 수 있는가
- Spring Boot가 인증, 권한, 트랜잭션, DB migration을 책임질 수 있는가
- Spring Boot가 `/healthz`, `/readyz`, Windows dev tunnel 검증 계약을 안정적으로 제공할 수 있는가
- queue/outbox 기반 worker 요청이 유실 없이 기록되고, 소비자 없는 이벤트를 `no_consumer` 또는 `skipped_dev`로 안전하게 표시할 수 있는가
- FastAPI Worker 실패 시 Spring Boot가 안전한 fallback 응답을 줄 수 있는가
- CI에서 Spring Boot test, FastAPI test, Flutter contract fixture test를 분리해 돌릴 수 있는가

## 세부 결정과 선택지 비교

아래 항목은 C안 자체를 흔드는 결정이 아니라, C안을 어떤 구현 방식으로 시작할지 정한 세부 결정이다. 각 항목에는 채택한 선택지와 검토했던 대안을 함께 남긴다.

### Spring Boot 폴더 위치

| 선택지 | 장점 | 주의점 | 판단 |
| --- | --- | --- | --- |
| `services/api-spring` | 현재 저장소의 `services/*` 서비스 경계와 맞고, Flutter 앱이 있는 `apps/*`와 역할이 분리된다. | 서비스가 많아지면 `services` 아래 구조가 커질 수 있다. | 확정 |
| `apps/api-spring` | 앱 단위 산출물이라는 관점으로 볼 수 있다. | `apps/mobile-flutter`와 같은 client app과 server app이 섞여 모노레포 경계가 흐려진다. | 비추천 |
| 별도 backend repository | 백엔드 배포/권한/CI를 독립시킬 수 있다. | 초기 협업과 API contract 변경 속도가 느려지고, 프론트 선구현 흐름에서 friction이 크다. | MVP 이후 검토 |

결정은 `services/api-spring`이다. 지금은 Flutter와 API contract를 빠르게 맞추는 시기라 같은 repo 안에 두되, 서비스 경계는 `services`로 분리하는 편이 가장 덜 헷갈린다.

### FastAPI Worker 폴더 위치

| 선택지 | 장점 | 주의점 | 판단 |
| --- | --- | --- | --- |
| `services/worker-fastapi` | Main API와 다른 배포 단위임이 이름에서 바로 보인다. | worker가 여러 개로 늘면 이름을 다시 바꾸거나 구조를 옮겨야 한다. | 비채택 |
| `services/workers/ai-data-worker` | 여러 worker가 생길 때 확장성이 좋고, 기술명보다 역할명이 드러난다. | 첫 worker만 있는 Sprint 0-1에는 디렉터리가 한 단계 깊어진다. | 확정 |
| `services/api-spring/worker` | Spring API 옆에 두어 한눈에 보기 쉽다. | FastAPI가 독립 서비스라는 경계가 약해지고 배포 단위가 흐려진다. | 비추천 |

결정은 `services/workers/ai-data-worker`이다. 실제 실행 가능한 worker는 처음에 `ai-data-worker` 하나만 만들고, `notification-worker`, `media-worker`는 Sprint 2 이후 팀 논의로 추가 여부를 결정한다.

### 첫 OAuth Provider

| 선택지 | 장점 | 주의점 | 판단 |
| --- | --- | --- | --- |
| Google 우선 | Flutter SDK, 서버 token 검증, 테스트 계정 준비가 비교적 쉽다. | 현재 repo의 `GOOGLE_MAPS_API_KEY`는 OAuth credential이 아니며, 국내 서비스 감성에서는 Kakao/Naver보다 덜 자연스러울 수 있다. | 비채택 |
| Kakao 우선 | 국내 사용자가 가장 자연스럽게 받아들인다. | 앱 설정, redirect, 테스트 계정/검수 조건을 더 꼼꼼히 봐야 한다. | 발표 데모가 국내 UX 중심이면 가능 |
| Naver 우선 | 국내 계정 접근성이 좋고 장소/지도 흐름과 브랜드 인지가 맞는다. `dev-naver-oauth-client-id`, `dev-naver-oauth-client-secret`을 OAuth 전용 secret으로 사용한다. | `dev-naver-client-id`, `dev-naver-client-secret`은 이름이 모호하므로 OAuth 로그인에는 쓰지 않는다. | 확정 |
| 세 provider 동시 시작 | 최종 UX를 빨리 보여줄 수 있다. | Sprint 0에서 인증 이슈가 동시에 터져 core API 검증이 늦어진다. | 비추천 |

결정은 Naver 우선이다. 단, auth identity 모델은 provider-neutral하게 만들어 Kakao/Google을 나중에 추가할 수 있게 한다.

### Session / Token 방식

| 선택지 | 장점 | 주의점 | 판단 |
| --- | --- | --- | --- |
| 짧은 수명의 JWT access token + 서버 저장 refresh token + Flutter secure storage | 모바일 앱에서 표준적으로 다루기 쉽고 API 호출 경계가 명확하다. access token은 API 요청 검증에 쓰고, refresh token은 서버에서 저장/회전한다. | refresh token rotation, logout, 탈취 대응 규칙을 문서화해야 한다. | 확정 |
| server session cookie | 웹에서는 자연스럽고 CSRF/session 관리가 익숙하다. | Flutter 모바일 앱에서는 cookie persistence와 cross-device 처리 설명이 더 번거롭다. | 웹 surface 확대 시 검토 |
| OAuth provider token 직접 사용 | 초기 구현이 빨라 보인다. | 내부 권한, token 만료, provider별 차이를 앱이 떠안게 된다. | 비추천 |

결정은 짧은 수명의 JWT access token과 서버 저장 refresh token 방식이다. 현재 MVP/dev 단계에서는 이미 동작 중인 HS256 JWT access token, `sub=<users.public_id>`, Spring의 DB 사용자 조회 흐름을 유지한다. Databricks, CDC, analytics 기준을 이유로 MVP/dev 인증 구현이나 DB schema를 선제 변경하지 않는다.

Azure/Terraform 기반 prod 전환 시에는 아래 흐름을 공식 기준으로 삼는다.

```text
Flutter OAuth login
  -> Spring provider token/code 검증
  -> Spring이 access JWT + refresh token 발급
  -> Flutter secure storage 저장
```

운영 클라이언트에는 JWT signing secret을 넣지 않는다. Prod token 발급은 Spring Boot Main API만 담당하고, signing secret과 TTL은 Terraform/Key Vault/env 기준으로 관리한다.

SCRUM-46 Kakao OAuth 연결도 이 결정을 바꾸지 않는다. Flutter는 Kakao provider access token 또는 authorization code를 Spring에 전달하고, Spring이 provider 검증 뒤 ONMU access JWT와 refresh token을 발급한다. `KAKAO_CLIENT_SECRET`은 Spring 서버 환경변수 또는 Key Vault secret 역할로만 관리하며 Flutter에 넣지 않는다. Kakao redirect URI 후보는 다음과 같이 둔다.

- `http://localhost:8080/api/v1/auth/oauth/kakao/callback`
- `https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback`
- prod later: `https://api.onmu.cloud/api/v1/auth/oauth/kakao/callback`

SCRUM-47 Naver OAuth 연결도 같은 경계를 따른다. Flutter는 Naver provider access token 또는 authorization code를 Spring에 전달하고, Spring이 provider 검증 뒤 ONMU access JWT와 refresh token을 발급한다. `NAVER_OAUTH_CLIENT_SECRET`은 Spring 서버 환경변수 또는 Key Vault secret 역할로만 관리하며 Flutter에 넣지 않는다. OAuth 전용 Key Vault 이름은 dev `dev-naver-oauth-client-id`, `dev-naver-oauth-client-secret`, integration `int-naver-oauth-client-id`, `int-naver-oauth-client-secret`이다. Naver redirect URI 후보는 다음과 같이 둔다.

- `http://localhost:8080/api/v1/auth/oauth/naver/callback`
- `https://dev-api.onmu.cloud/api/v1/auth/oauth/naver/callback`
- `https://int-api.onmu.cloud/api/v1/auth/oauth/naver/callback`
- future prod: `https://api.onmu.cloud/api/v1/auth/oauth/naver/callback`

### Spring Boot와 FastAPI Worker 연결 방식

| 선택지 | 장점 | 주의점 | 판단 |
| --- | --- | --- | --- |
| 내부 HTTP 호출 | Sprint 0에서 가장 빠르게 연결하고 디버깅하기 쉽다. | 긴 작업, 실패 재시도, 유실 방지에는 약하다. | 비채택 |
| queue/outbox | DB 저장과 worker 요청 사이의 유실을 줄이고 재시도/비동기에 강하다. | 초기 세팅과 모니터링 비용이 생긴다. | 확정 |
| Worker가 DB 직접 읽기/쓰기 | 구현 경로가 짧아 보인다. | core domain 소유권이 깨지고 정합성/권한 관리가 어려워진다. | 비추천 |

결정은 queue/outbox 방식이다. Sprint 0에서 실제 queue 연결이 어렵다면 `outbox_events` table과 publisher/consumer interface, `no_consumer` 또는 `skipped_dev` 상태까지 scaffold로 남긴다.

### 모임 전체 투표의 리소스 성격

| 선택지 | 장점 | 주의점 | 판단 |
| --- | --- | --- | --- |
| `groups/{groupId}/votes` aggregate read view | 채팅에서 여러 약속의 투표를 모아 보기 좋고, 실제 생성 기준은 plan 하위로 유지된다. | 약속과 직접 연결되지 않은 모임 전체 투표를 만들기 어렵다. | 비채택 |
| `groups/{groupId}/votes` 자체 생성 리소스 | 모임 단위 공지/일반 투표부터 약속 관련 장소/일정/정산/준비물 투표까지 확장 가능하다. | vote가 연결 대상과 유형을 명확히 가져야 한다. | 확정 |
| plan vote만 제공 | 도메인 경계가 가장 단순하다. | 채팅방에서 “투표 목록 보기”를 만들 때 여러 plan의 투표를 모아보기 어렵다. | MVP UX에는 부족 |

결정은 `groups/{groupId}/votes` 자체 생성 리소스다. 장소/일정/정산/준비물/일반 투표를 하나의 `Vote` 리소스로 다루고, `targetType`, `targetId`, `voteType`으로 연결 대상을 표현한다.

### 장소 검색 API 방식

| 선택지 | 장점 | 주의점 | 판단 |
| --- | --- | --- | --- |
| `GET /api/v1/place-search?query=...` | 단순 키워드 검색에 직관적이고 캐시/로그 분석이 쉽다. | 취향, 태그, 참여자 선호, 지도 bounds, 시간 조건이 붙으면 query string이 길어지고 의미가 흐려진다. | dev 호환용 |
| `POST /api/v1/place-search` | 복합 조건, 지도 bounds, 참여자 취향 병합 같은 body가 커지는 검색에 적합하다. | 단순 검색에는 과할 수 있다. | 확정 |
| plan 하위 검색 `GET /groups/{groupId}/plans/{planId}/place-search` | 약속 맥락을 URL에서 바로 알 수 있다. | 외부 장소 검색 자체와 약속 후보 추가가 섞인다. | 약속 맥락 필터가 필수일 때 검토 |

결정은 `POST /api/v1/place-search`를 canonical로 둔다. 검색 결과를 일정에 바로 등록하거나 후보에 추가하는 action은 별도 endpoint로 분리한다.

### DB Migration 소유권

| 선택지 | 장점 | 주의점 | 판단 |
| --- | --- | --- | --- |
| Spring Boot Flyway 단일 | core domain DB 변경의 소유권이 Main API에 모인다. | AI/분석/리포트 준비용 worker schema까지 Spring 쪽에서 관리해야 한다. | 비채택 |
| Spring Boot Flyway + FastAPI Alembic 병행 | core domain은 Flyway, worker 전용 schema는 Alembic이 관리한다. | 같은 PostgreSQL DB를 쓰더라도 schema 소유권과 migration 순서를 엄격히 분리해야 한다. | 확정 |
| 수동 SQL | 초기에는 간단해 보인다. | 협업, staging/prod 배포, rollback 추적이 어렵다. | 비추천 |

결정은 Spring Boot Flyway + FastAPI Alembic 병행이다. Spring Boot Flyway는 `public` 또는 core schema의 users, auth_identities, groups, plans, votes, settlements, records, consent/privacy, outbox_events를 소유한다. FastAPI Alembic은 `worker_ai` schema의 ai_job_runs, prompt_runs, feature_extraction_jobs 같은 worker 전용 테이블만 소유한다. FastAPI Alembic은 core domain table을 수정하지 않는다.

## 미래 데이터/리포팅 레이어

기업 대상 주간/월간 리포트, 광고 세그먼트, OOTD/persona feature, Databricks 기반 analytics/reporting layer는 미래 확장으로 문서화만 한다. 현재 scaffold 구현 범위에는 Databricks, 광고 API 연동, persona segmentation, Bronze/Silver/Gold table 구현을 포함하지 않는다.

단, 나중에 analytics layer를 붙일 수 있도록 core 설계에는 consent/privacy, outbox_events, 익명화 가능한 subject 식별자, feature taxonomy 여지를 남긴다.
