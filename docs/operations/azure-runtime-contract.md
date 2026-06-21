# Azure runtime contract

이 문서는 Azure staging/production에서 ONMU runtime 컴포넌트가 어떤 책임과 health/readiness 기준을 가져야 하는지 정의한다.

## 1. Runtime 구성

| 컴포넌트 | 책임 | 외부 노출 | 상태 |
| --- | --- | --- | --- |
| Spring Boot Main API | 인증, 권한, 공식 API, 트랜잭션, Flyway, notification outbox | 모바일/웹/API gateway | 필수 |
| FastAPI Worker | AI/추천/분석/비동기 보조, worker schema | 외부 직접 노출 금지 | 단계적 |
| Realtime Gateway | presence/fan-out/WebSocket 후보 | API gateway 뒤 | 후속 |
| Spring SSE | chat/activity event delivery | Spring API route | 현재 유지 가능 |
| Notification Worker/Adapter | provider delivery, dev-safe delivery record | 외부 직접 노출 금지 | 단계적 |
| Tile/static gateway | manifest/style/PMTiles/media asset | CDN/Blob/Front Door 후보 | 필수 |

## 2. Spring Main API contract

Spring Main API는 다음을 소유한다.

- OAuth provider token/code/idToken 검증 경계
- ONMU access/refresh token 발급
- 사용자, 모임, 약속, 후보, 투표, 정산, 기록, 채팅, 알림 원장
- Flyway migration
- Notification row 생성과 `notification.requested` outbox 생성
- Place/Search/Route provider adapter 호출과 cache
- file upload/download presign API
- records/OOTD media upload boundary와 `record_media` metadata 연결

Spring Main API는 다음을 직접 노출하지 않는다.

- provider secret 값
- raw OAuth token/code/state
- DB password
- Worker internal endpoint
- 실제 push provider credential
- object storage credential 또는 raw Blob/MinIO write endpoint

## 3. Health/readiness 기준

| Endpoint | 의미 | Azure probe 사용 |
| --- | --- | --- |
| `/healthz` | process liveness | liveness |
| `/readyz` | DB/Redis 등 필수 의존성 준비 | readiness |
| `/api/v1/users/me` no-token | 보호 API 인증 경계 | smoke에서 401 기대 |

Readiness가 실패하면 traffic을 받지 않아야 한다. 단, provider 외부 API의 일시 실패는 핵심 readiness와 분리하고 기능 smoke에서 판단한다.

## 4. Env binding 기준

Spring container는 다음 env var name을 기준으로 한다.

- `DATABASE_URL`
- `POSTGRES_PASSWORD`
- `ONMU_ACCESS_TOKEN_SECRET`
- `ONMU_AUTH_ISSUER`
- `ONMU_AUTH_AUDIENCE`
- `ONMU_ACCESS_TOKEN_TTL`
- `ONMU_REFRESH_TOKEN_TTL`
- `REDIS_URL`
- `SPRING_DATA_REDIS_URL`
- `ONMU_CORS_ORIGINS`
- `ONMU_DEV_CORS_ORIGINS` dev fallback
- `ONMU_ALLOWED_ORIGINS` AuthProperties fallback 후보
- `KAKAO_REST_API_KEY`
- `KAKAO_CLIENT_SECRET`
- `NAVER_OAUTH_CLIENT_ID`
- `NAVER_OAUTH_CLIENT_SECRET`
- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`
- `NAVER_SEARCH_CLIENT_ID`
- `NAVER_SEARCH_CLIENT_SECRET`
- `OPENROUTESERVICE_API_KEY`
- `OBJECT_STORAGE_PROVIDER`
- `OBJECT_STORAGE_ENDPOINT`
- `OBJECT_STORAGE_BUCKET`
- `AZURE_CLIENT_ID` 또는 `OBJECT_STORAGE_MANAGED_IDENTITY_CLIENT_ID`

값은 Key Vault/managed identity/secret reference로 주입한다. 문서와 PR에는 값이 아니라 env var name과 secret name만 적는다.

## 5. Startup order

1. PostgreSQL/PostGIS 준비
2. Redis 준비
3. Blob/object storage 준비
4. Spring Main API migration과 startup
5. Spring `/readyz` 통과
6. Worker startup
7. Event/queue consumer activation
8. Smoke
9. Traffic 전환

## 6. Home/plan/vote domain contract

홈/약속/투표 영역은 Spring Main API가 source of truth와 transaction boundary를 소유한다. Azure staging smoke는 API status만 보지 않고 read model, 참여자 projection, outbox side effect까지 함께 확인한다.

도메인 계약:

- `GET /api/v1/home/summary`는 viewer 기준 홈 read model의 canonical 후보이며, Flutter가 group/plans 조합 fallback을 쓰는지 구분해서 보고한다.
- `plans`와 `plan_participants`는 약속과 참여자의 source of truth다.
- `votes`, `vote_options`, `vote_responses`는 투표와 응답 집계의 source of truth다.
- 생성 화면의 후보 멤버가 시간 추천/경고에 쓰이려면 `GET /api/v1/groups/{groupId}/plans/participant-candidates`가 실제 선택된 userIds에 대해서만 `preferenceProfile`을 반환하고 Flutter mapper가 이를 `PlanMember`로 전달해야 한다. `GET /groups/{groupId}/members`는 lightweight 목록 계약으로 유지한다.
- 일반 약속 수정은 명시 status 변경이 없으면 기존 status를 보존한다. 상태 변경은 별도 action 또는 명시 UX로 분리한다.
- 투표 상세는 option별 `responseCount`, `progress`, voter preview 또는 별도 voters projection 중 하나를 안정적으로 제공해야 한다.
- 홈 summary, 약속 상세, 투표 상세는 write 이후 재조회에서 새 상태를 반영해야 한다.

Side effect 계약:

| Transaction | 필수 outbox 확인 |
| --- | --- |
| plan create | `plan.created` count/status, `groupId`, `planId` field presence |
| plan update | `plan.updated` count/status, `status` field presence |
| participant add | `plan.participant_added` count/status, target user field presence |
| vote create | `vote.created` count/status, `voteId`, `targetType`, `targetId` field presence |

이 이벤트들은 Azure Event Hubs/Notification/Realtime으로 확장될 수 있지만, DB schema는 Spring Flyway가 소유하고 Terraform은 event hub, consumer group, managed identity, monitor, runtime env만 소유한다.

## 7. FastAPI Worker contract

FastAPI Worker는 다음 작업을 담당한다.

- 장소추천 설명 생성 같은 AI 보조. 현재 rule-based 추천 이유는 Spring이 즉시 생성하고, `place_candidate.created`/`ai.summary.requested`는 Worker `/tasks/place-reason`에서 비동기 보강할 수 있다.
- 주간/월간 리포트 후보 생성
- 검색/RAG/분석 worker job
- 장기적으로 Azure OpenAI, Azure AI Search, Databricks/Lakehouse 연동

Worker는 Spring Main API의 인증/권한 결정을 우회하지 않는다. 모바일 앱은 Worker를 직접 호출하지 않는다.

Worker 운영 결정 항목:

| 항목 | 1차 기준 | 후속 결정 |
| --- | --- | --- |
| 접근 경계 | 외부 공개 금지, Spring 또는 queue consumer만 접근 | private network, Container Apps internal ingress, APIM internal route 중 선택 |
| 호출 방식 | MVP는 Spring 내부 HTTP 또는 no-consumer/dev-safe 상태 허용 | Event Hubs 기반 비동기 fan-out으로 전환 |
| 결과 저장 | worker 전용 schema 또는 metadata table 후보 | Main API read model에 반영될 때는 Spring API contract를 거침 |
| retry | idempotency key와 attempt count 필요 | dead-letter queue와 replay runbook |
| timeout | Spring request path를 막지 않는 짧은 timeout | 장기 AI 작업은 queue/job으로 분리 |
| AI 결과물 | summary/recommendation/reason metadata/thumbnail metadata 중심 | image 결과물은 Blob object + DB metadata로 분리 |

## 8. Chat/notification contract

- Chat source of truth는 DB의 chat/activity 원장이다.
- SSE는 delivery layer이며 source of truth가 아니다.
- 메시지 생성 시 notification row와 outbox event가 생성된다.
- `notification_deliveries`에는 dev-safe provider/status 기록이 남는다.
- unread/read/read-all/preferences는 사용자 단위 권한을 지킨다.

Azure staging 1차에서는 Spring SSE 유지가 가능하지만, scale-out 전에는 다음을 gate로 둔다.

- Container Apps revision/instance가 2개 이상이 될 때 SSE broadcaster가 instance-local인지 확인한다.
- 사용자가 instance 1에 SSE로 연결되고 event 생성이 instance 2에서 발생해도 delivery가 가능한지 검증한다.
- 불가능하면 Redis pub/sub, Event Hubs fan-out, 별도 Realtime Gateway 중 하나를 선택한다.
- long-lived connection timeout, idle timeout, reconnect/backoff, heartbeat 기준을 smoke에 포함한다.
- push token은 `user_devices` 원장이며 FCM/APNs secret은 Key Vault/runtime에만 둔다.
- notification provider 실패 retry는 `notification_deliveries` status/count와 dead-letter 또는 retry policy로 추적한다.

## 9. Place/Search/Route/Map contract

- provider 검색 결과는 provider/source/coordinate count 중심으로 smoke한다.
- provider 이름은 제품 UI에 직접 노출하지 않는 기준을 유지한다.
- Redis는 짧은 TTL provider cache에만 사용한다.
- PostgreSQL에는 후보/일정에 추가된 최소 snapshot만 저장한다.
- tile manifest/style/Range/CORS는 앱 지도 안정화의 필수 smoke다.

## 10. Records/Media/OOTD contract

- Flutter는 records/OOTD 사진을 MinIO 또는 Azure Blob Storage에 직접 쓰지 않는다.
- Spring Main API가 `POST /api/v1/media/upload`, media public read/proxy, memories create/update와 `record_media` metadata 연결을 소유한다.
- DB에는 원본 image bytes를 저장하지 않고 object key, public URL, content type, size, sort order, comment 같은 metadata만 저장한다.
- Azure staging/prod의 target object storage는 Azure Blob Storage이며 local/dev는 `minio` provider를 사용한다.
- `POST /api/v1/media/upload`, `GET /api/v1/media/public?key=...`, `POST /api/v1/uploads/presigned-url` 계약은 object storage provider와 무관하게 유지한다.
- `type=DAILY`와 `type=OOTD`는 같은 날짜에 공존할 수 있고, OOTD record가 없으면 캐릭터 썸네일을 표시하지 않는다.
- 저장된 diary 화면은 `layoutType`과 decoration seed 또는 selected asset key로 재현 가능해야 한다.
- media upload smoke는 status/count/field presence 중심으로 보고하고 실제 사용자 사진 URL, raw filename, object credential은 출력하지 않는다.

## 11. Observability contract

Azure staging부터 request id 또는 trace id를 모든 runtime log와 smoke summary에 연결한다.

필수 로그/metric 후보:

- request method/path/status/duration/runtime/commit 또는 image tag
- `/readyz` failure count와 dependency error type
- API latency p95/p99 후보와 5xx/4xx error rate
- DB connection pool saturation/error count
- Redis/cache dependency failure count
- storage upload/read failure count
- OAuth provider exchange failure count와 provider latency
- SSE reconnect/error count
- notification delivery status count

로그 금지 항목:

- Authorization header, bearer token, refresh token
- OAuth code/state/idToken/provider access token
- DB password, Key Vault secret value
- raw request/response body
- 사용자 이름, 이메일, 지역명, 사진 URL 같은 PII 원문
