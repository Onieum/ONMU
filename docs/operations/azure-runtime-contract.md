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

Spring Main API는 다음을 직접 노출하지 않는다.

- provider secret 값
- raw OAuth token/code/state
- DB password
- Worker internal endpoint
- 실제 push provider credential

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
- `REDIS_URL`
- `SPRING_DATA_REDIS_URL`
- `ONMU_CORS_ORIGINS`
- `KAKAO_REST_API_KEY`
- `KAKAO_CLIENT_SECRET`
- `NAVER_OAUTH_CLIENT_ID`
- `NAVER_OAUTH_CLIENT_SECRET`
- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`
- `NAVER_SEARCH_CLIENT_ID`
- `NAVER_SEARCH_CLIENT_SECRET`
- `OPENROUTESERVICE_API_KEY`

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

## 6. FastAPI Worker contract

FastAPI Worker는 다음 작업을 담당한다.

- 장소추천 설명 생성 같은 AI 보조
- 주간/월간 리포트 후보 생성
- 검색/RAG/분석 worker job
- 장기적으로 Azure OpenAI, Azure AI Search, Databricks/Lakehouse 연동

Worker는 Spring Main API의 인증/권한 결정을 우회하지 않는다. 모바일 앱은 Worker를 직접 호출하지 않는다.

## 7. Chat/notification contract

- Chat source of truth는 DB의 chat/activity 원장이다.
- SSE는 delivery layer이며 source of truth가 아니다.
- 메시지 생성 시 notification row와 outbox event가 생성된다.
- `notification_deliveries`에는 dev-safe provider/status 기록이 남는다.
- unread/read/read-all/preferences는 사용자 단위 권한을 지킨다.

## 8. Place/Search/Route/Map contract

- provider 검색 결과는 provider/source/coordinate count 중심으로 smoke한다.
- provider 이름은 제품 UI에 직접 노출하지 않는 기준을 유지한다.
- Redis는 짧은 TTL provider cache에만 사용한다.
- PostgreSQL에는 후보/일정에 추가된 최소 snapshot만 저장한다.
- tile manifest/style/Range/CORS는 앱 지도 안정화의 필수 smoke다.
