# Spring Boot Main API Scaffold

`services/api-spring`은 ONMU의 확정 Main API 위치입니다. Flutter 앱이 직접 호출하는 공개 `/api/v1` 계약은 이 서비스가 구현합니다.

현재 PR 범위에서는 실행 가능한 Spring Boot 프로젝트를 완성하지 않고, 다음 구현자가 바로 시작할 수 있도록 책임, endpoint TODO, Flyway migration ownership, outbox contract만 먼저 고정합니다.

PR #63에서는 이 디렉터리를 CD 실행 대상으로 보지 않습니다. Windows dev backend CD의 기본 runtime은 `node-stub`이고, `spring` runtime은 다음 PR에서 실행 가능한 Spring Boot 앱이 추가된 뒤 전환합니다. 현재 `scripts/windows/deploy-dev-backend.ps1 -Runtime spring`은 dry-run에서는 예정 명령만 보여주고, 일반 실행에서는 실행 가능한 Gradle/Maven 프로젝트가 없다는 명확한 메시지와 함께 실패합니다.

Spring Boot 구현 PR에서 넘겨받아야 하는 운영 계약은 다음과 같습니다.

- `GET /healthz`
- `GET /readyz`
- `dev-api.onmu.cloud -> localhost:8080`
- `logs/api-access.log`에 준하는 request log 또는 동등한 관측성
- `/api/v1` canonical API 계약
- `POST /api/v1/groups/{groupId}/votes`
- `POST /api/v1/place-search`

## 확정 책임

- Spring Boot 3 + Java 21
- Spring Security 기반 Naver OAuth 우선 구현
- ONMU access token + refresh token 발급
- Flutter secure storage에 저장될 token contract 제공
- `/healthz`, `/readyz`
- `/api/v1/users/me`
- `/api/v1/groups`
- `/api/v1/groups/{groupId}/plans`
- `/api/v1/place-search`
- `/api/v1/groups/{groupId}/plans/{planId}/place-candidates`
- `/api/v1/groups/{groupId}/votes`
- `/api/v1/groups/{groupId}/plans/{planId}/settlement-draft`
- `/api/v1/groups/{groupId}/plans/{planId}/settlements/preview`
- `/api/v1/groups/{groupId}/plans/{planId}/settlements`
- core DB transaction과 Flyway migration
- `outbox_events` 기록과 queue publisher interface

## Dev Compatibility

Node smoke/contract stub의 아래 route는 Spring Boot 구현에서 canonical route로 보지 않습니다.

| Compatibility route | Canonical route |
| --- | --- |
| `POST /api/v1/groups/{groupId}/plans/{planId}/votes` | `POST /api/v1/groups/{groupId}/votes` |
| `GET /api/v1/place-search?query=...` | `POST /api/v1/place-search` |

Spring Boot에는 canonical route를 먼저 구현합니다. 호환 route가 필요하면 controller adapter에서 명시적으로 deprecated 또는 compatibility로 표시합니다.

## Migration Ownership

Spring Boot Flyway는 core schema를 소유합니다.

- users
- auth_identities
- groups
- plans
- place_candidates
- schedule_places
- votes
- settlement_drafts
- settlements
- records
- consent/privacy
- outbox_events

FastAPI Worker의 Alembic은 `worker_ai` schema만 소유합니다. FastAPI Worker는 core domain table을 수정하지 않습니다.

## Outbox Contract

Spring Boot는 domain transaction과 같은 transaction 안에서 `outbox_events`에 이벤트를 기록합니다.

필수 필드:

- `id`
- `event_type`
- `aggregate_type`
- `aggregate_id`
- `payload`
- `status`
- `created_at`
- `published_at`
- `locked_at`
- `retry_count`
- `last_error`

Sprint 0에서 실제 queue consumer가 없으면 `no_consumer` 또는 `skipped_dev` 상태를 사용할 수 있습니다.

## Secret Policy

Naver OAuth client secret, JWT signing secret, DB password, Cloudflare token, Azure OpenAI key는 커밋하지 않습니다. 로컬 `.env`, GitHub Secrets, Azure Key Vault 중 하나로 관리합니다.
