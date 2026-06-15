# Current-to-target 아키텍처 인덱스

이 문서는 ONMU의 도메인별 현재 구현과 목표 구조 문서를 Azure/Terraform 전환 관점에서 찾아볼 수 있게 묶은 인덱스다. Terraform 작업자는 여기서 기능 경계와 운영 경계를 먼저 확인한 뒤 module/resource 계획을 잡는다.

## 1. 전환 문서 빠른 길

| 목적 | 문서 |
| --- | --- |
| 전체 목표 구조 | [현재 아키텍처 다이어그램과 기술 스택 결정안](./current-architecture-diagram.md) |
| 릴리스 목표 | [릴리스 아키텍처](./release-architecture.md) |
| Terraform 소유권 | [Terraform 리소스 소유권](./terraform-resource-ownership.md) |
| Cloud resource 비교 | [ONMU Cloud Resource Comparison](./cloud-resource-comparison.md) |
| Azure 전환 runbook | [Azure Terraform 전환 운영 가이드](../operations/azure-terraform-migration.md) |
| 환경별 값/host/runtime | [Azure 환경 매트릭스](../operations/azure-environment-matrix.md) |
| secret name/env var | [Azure secret 인벤토리](../operations/azure-secret-inventory.md) |
| 데이터 이전 | [Azure 데이터 이전 runbook](../operations/azure-data-migration-runbook.md) |
| runtime contract | [Azure runtime contract](../operations/azure-runtime-contract.md) |
| CI/CD | [Azure CI/CD runbook](../operations/azure-ci-cd-runbook.md) |
| smoke | [Azure smoke checklist](../operations/azure-smoke-checklist.md) |
| cutover/rollback | [Azure cutover/rollback runbook](../operations/azure-cutover-rollback.md) |

## 2. 도메인별 current-to-target 문서

| 도메인 | 기준 문서 | Azure/Terraform에서 확인할 것 |
| --- | --- | --- |
| Auth/User/Profile | [ONMU Auth/User/Profile 아키텍처](./auth-user-profile-architecture.md) | OAuth secret, callback, JWT signing secret, `/users/me`, onboarding/profile smoke |
| User/Profile/Character/Friends | [User/Profile/Character/Friends 아키텍처](./user-profile-character-friends-architecture.md) | profile privacy, user code, character asset, friend lookup 경계 |
| Groups / Plans / Members | [홈 / 약속 / 투표 아키텍처](./home-plans-vote-architecture.md) | 모임, 약속, 참여자, 권한, read model |
| Vote / Decision | [홈 / 약속 / 투표 아키텍처](./home-plans-vote-architecture.md) | 투표 원장, decision/action card, notification side effect |
| Chat/Activity | [채팅 및 ChatActivity 아키텍처](./chat-activity-architecture.md) | SSE는 delivery layer, DB 원장, notification outbox, latency smoke |
| Notification/Push/Devices | [Notification/Push/Devices 아키텍처](./notification-push-devices-architecture.md) | push token secret 금지, provider adapter, delivery record, unread/read-all |
| Place/Search/Route/Map | [Place / Search / Route / Map 아키텍처](./place-search-route-map-architecture.md) | Naver/Kakao/route provider secret, Redis cache, tile asset, PostGIS |
| Settlement | [정산 아키텍처](./settlement-architecture.md) | payment/settlement 원장, privacy, notification side effect |
| Records/Memories/Media/OOTD | [Records/Memories/Media/OOTD 아키텍처](./records-memories-media-ootd-architecture.md) | Blob storage, signed URL, media privacy, lifecycle |
| Worker / AI / Outbox | [백엔드 결정 원본과 기술스택](./backend-stack-options.md) | Spring Main API와 FastAPI Worker, queue/outbox 경계 |
| Frontend | [Flutter 프론트 아키텍처](./frontend-architecture.md) | flavor/base URL, public OAuth define, secure storage |
| Data/Analytics | [데이터/분석/리포팅 로드맵](./data-analytics-reporting-roadmap.md) | Databricks/Lakehouse/Event Hubs는 후속 경계 |
| API contracts | [API Contract Map](./api-contract-map.md) | Spring API smoke와 mobile repository contract |

## 3. Terraform 전환 시 우선순위

1. Spring Main API가 사용하는 DB/Redis/secret/object storage를 먼저 맞춘다.
2. Place/Search/Route/Map은 provider secret, provider cache, tile asset smoke를 분리한다.
3. Chat/Notification은 DB 원장과 SSE/delivery layer를 분리해서 검증한다.
4. Mobile OAuth는 공개 define과 서버 secret을 분리한다.
5. AI/추천/분석은 FastAPI Worker와 queue를 후속 단계로 분리한다.
6. Production cutover 전에는 Windows dev fallback과 Azure staging smoke를 동시에 유지한다.

## 4. PR 분리 기준

- 인프라/Terraform PR: resource/module/state/backend/identity.
- Runtime config PR: env binding, health/readiness, Key Vault reference.
- Data migration PR: Flyway/Alembic/job/runbook.
- Mobile PR: API base URL, 공개 OAuth define, platform 설정.
- Domain feature PR: API/UI/business logic.
- Verification PR 또는 report: smoke 결과와 regression evidence.

도메인 기능 PR에서 Terraform resource를 만들지 않고, Terraform PR에서 앱 business logic을 바꾸지 않는 것이 기본 원칙이다.
