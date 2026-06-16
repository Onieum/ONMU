# Azure staging smoke checklist

이 문서는 ONMU Azure staging이 실제로 동작한다고 판정하기 위한 smoke 기준이다. Terraform apply, container image push, 또는 build 성공만으로 배포 성공으로 보지 않는다.

## 1. 보고 원칙

- secret, API key, token, DB password, OAuth code/state/idToken, Authorization header, raw request/response body, provider raw body, 사용자 개인정보 실제 값은 출력하지 않는다.
- 보고에는 endpoint path, HTTP status, count, resource id/reference, env var name, Key Vault secret name, PID 또는 revision id만 포함한다.
- 실패는 runtime, migration, API contract, network/CDN, observability, unknown으로 분류한다.

## 2. API 기본 smoke

| 항목 | 기준 |
| --- | --- |
| `GET /healthz` | 200 |
| `GET /readyz` | 200 |
| no-token `GET /api/v1/users/me` | 401 |
| authenticated `GET /api/v1/users/me` | 실제 OAuth 로그인 기반 200 |
| Spring startup | container revision ready, startup failure count 0 |
| Domain smoke | `staging-api.onmu.cloud` 연결 후 동일한 200/200/401 |

Staging smoke는 mock login 또는 `user-me` 우회 대신 실제 OAuth 로그인으로 보호 API를 확인한다. OAuth code/state/idToken, Authorization header, raw response body는 출력하지 않는다.

Auth/OAuth fresh 검증은 항상 최신 `origin/dev` 또는 staging 배포 commit 기준으로 수행한다. 이전 commit에서 생성된 보고서는 참고 자료로만 사용하고 최종 판정으로 승격하지 않는다.

OAuth-only dart-define에는 JWT 우회 key를 넣지 않는다. 모바일 smoke 시작 전 다음 public define의 존재 여부만 확인하고 실제 값은 출력하지 않는다.

- `ONMU_API_BASE_URL`
- `KAKAO_REST_API_KEY`
- `KAKAO_OAUTH_REDIRECT_URI`
- `NAVER_OAUTH_CLIENT_ID`
- `NAVER_OAUTH_REDIRECT_URI`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`

## 3. Dependency smoke

| 항목 | 기준 |
| --- | --- |
| PostgreSQL readiness | connection success, Flyway schema up to date 또는 migration result count |
| PostGIS readiness | extension presence count |
| Redis readiness | ping/readiness success, cache source of truth 아님 확인 |
| Key Vault reference | required secret reference resolved count, missing count 0 |
| Managed identity | required role assignment presence count |

`core_foundation` wave 직후에는 앱 배포 성공이 아니라 기반 리소스 준비만 판정한다. Diagnostic setting은 이 wave에서 만들지 않고 `core_diagnostics`로 분리한다. 최소 확인은 다음이다.

- Redis Basic C0 존재와 provisioning status 확인
- Blob containers count와 public tile/static, private media access boundary 확인
- CDN/edge resource가 `core_foundation`으로 생성되지 않았는지 확인한다. `core_diagnostics` wave 이후에는 foundation 리소스 diagnostic setting 연결을 확인한다. `frontdoor_tile_edge` wave 이후에는 Azure Front Door Standard profile/endpoint/origin group/origin/route 존재를 확인한다. Front Door diagnostic setting은 resource id가 remote state에 안정화된 뒤 `frontdoor_diagnostics` wave에서 연결한다.
- Event Hubs namespace, hubs `notification-requested`/`worker-jobs`, consumer groups `worker`/`analytics` count 확인
- Key Vault RBAC enabled, secret value count/status만 확인하고 값은 출력하지 않음
- user-assigned managed identity 존재와 Key Vault Secrets User role assignment status 확인
- ACA Environment 존재, Spring API/worker Container App 미생성 확인
- diagnostic settings가 Log Analytics workspace로 연결됐는지 count/status 확인

`db_and_app_ready` wave는 protected Postgres password, Spring image, worker image, Flyway 실행 계획, Key Vault secret value 준비가 끝난 뒤 별도 승인으로만 실행한다.

## 4. Blob/CDN smoke

| 항목 | 기준 |
| --- | --- |
| Blob origin object | 존재, size/checksum/sample read 가능 |
| CDN edge URL | 200 |
| Content-Type | object type과 일치 |
| Cache-Control | manifest/style은 rollback 가능한 TTL, versioned PMTiles는 긴 TTL 가능 |
| CORS | 허용 origin과 method/header 확인 |
| Rollback | purge/invalidation 또는 versioned path + manifest pointer rollback 경로 확인 |

Private user media는 public CDN cache 대상으로 smoke하지 않는다. 공개 가능한 asset과 private media는 container/path/cache policy를 분리해서 검증한다.

Front Door Standard 적용 후에는 custom domain/TLS 없이 기본 endpoint를 먼저 smoke한다. PMTiles는 Range `206`, `Accept-Ranges`, `Content-Range`, `Access-Control-Allow-Origin`, `Access-Control-Expose-Headers`를 확인한다. Custom domain/TLS와 DNS 변경은 별도 승인 전까지 수행하지 않는다.

## 5. Tile smoke

| 항목 | 기준 |
| --- | --- |
| Manifest | 200 |
| Style JSON | 200 |
| Style source URL | manifest tileset URL과 일치 |
| PMTiles Range | 206 |
| `Accept-Ranges` | present |
| `Content-Range` | present |
| `Access-Control-Allow-Origin` | present |
| `Access-Control-Expose-Headers` | `Accept-Ranges`, `Content-Length`, `Content-Range` 포함 |
| Android MapLibre | blank/fallback grid/water-style 회귀 없음 |

Android 검증은 emulator 또는 실기기에서 수행한다. Web smoke는 보조 신호로만 사용한다.

## 6. Place/Search/Route smoke

| 항목 | 보고 기준 |
| --- | --- |
| place-search | status, result_count, provider_counts, source_counts, coordinate_count |
| route provider | status, route_count, distance presence, duration presence, provider가 `dev-mock`이 아님 |
| provider fallback | fallback 여부와 provider별 availability count |
| cache | cache key count, TTL policy, cleanup 여부 |

Provider raw body, query 원문, token, Authorization header는 출력하지 않는다.

Route smoke에서 status와 distance/duration이 있어도 provider가 `dev-mock`이면 live provider 성공으로 판정하지 않는다. 이 경우 `OPENROUTESERVICE_API_KEY` 또는 route provider feature flag/runtime 주입 상태를 secret-safe 방식으로 분리 확인한 뒤 재검증한다.

## 7. Notification/Event smoke

Event Hubs는 analytics/event stream fan-out 계층이다. Transactional outbox 원장은 Spring/PostgreSQL에 남는다.

| 항목 | 기준 |
| --- | --- |
| outbox source | `notification.requested` count 중심 확인 |
| Event Hubs publish | status/count 중심 확인 |
| consumer group | expected group presence |
| replay/checkpoint | checkpoint storage presence, offset/count 중심 확인 |
| delivery record | dev-safe provider/status/count 중심 확인 |

Chat UI smoke와 notification E2E는 분리해서 판정한다. Android/iOS에서 채팅 화면 로딩, 입력창 표시, pending bubble, sent 정착이 통과해도 다음 항목은 별도 알림 E2E smoke로 남긴다.

- 채팅 메시지 생성 후 상대 사용자 notification row 생성
- `notification.requested` outbox 처리
- `notification_deliveries` dev-safe 기록
- unread badge, read, read-all, preferences 저장/복원
- push token readiness POST/DELETE와 raw token 미노출 확인
- 실제 FCM/APNs provider 발송은 별도 승인 전까지 범위 밖

Dev-safe 알림 E2E에서는 `provider=dev`, `status=skipped_dev` delivery 기록을 staging pre-push smoke 통과 기준으로 인정한다. `read-all`은 기존 dev/staging 사용자 알림을 함께 읽음 처리할 수 있으므로, 전용 테스트 사용자 또는 synthetic notification fixture가 준비된 경우에만 자동 실행한다.

## 8. Mobile flow smoke

Staging API가 ACA에서 기동된 뒤 최소 1회 Android emulator 기준으로 다음 흐름을 묶어서 확인한다. 시간 제약이 있으면 다른 팀원 PC 검증은 생략할 수 있지만, 이 경우 보고서에 단일 emulator 기준임을 명시한다.

| 흐름 | 최소 기준 |
| --- | --- |
| Auth/OAuth | provider 버튼 표시, provider 화면 진입, 앱 복귀, `/api/v1/users/me` 200 |
| My/Profile | 마이페이지 진입, 깨진 JSON/mojibake 없음, 지역/공개범위 표시, 저장 전후 field presence |
| Groups/Plans/Votes | 그룹 목록, 상세, plan, vote read 화면 렌더링 |
| Record/Memory | 기록/추억 목록 화면 렌더링, recent records/memories count 확인, 에러 toast/snackbar 없음 |
| Place/Search/Map | 지도 blank/fallback/water-style 회귀 없음, place-search result/count 확인 |
| Chat | 메시지 목록/입력창 표시, pending -> sent 정착, crash 없음 |

My/Profile smoke는 실제 display name, region/address 값을 출력하지 않는다. 보고에는 `preferenceProfile`, `region`, `regionVisibility` presence와 field/key count만 포함한다.

## 9. Observability smoke

| 항목 | 기준 |
| --- | --- |
| Application Insights request | request count 확인 |
| Application Insights dependency | DB/Redis/HTTP dependency count 확인 |
| Application Insights exception | unexpected exception count |
| Log Analytics ingestion | ingestion 여부와 table count |
| Telemetry hygiene | secret/token/raw body/user PII 미수집 확인 |
| Diagnostic settings | Container Apps, PostgreSQL, Redis, Storage, CDN, Event Hubs 로그 route 확인 |

Staging 기본값은 Log Analytics retention 30일, Application Insights sampling on, daily cap 설정이다. 구체 cap 값은 budget gate 승인 시 확정한다.

## 10. 최종 판정

Staging 성공 판정은 다음을 모두 만족해야 한다.

1. Spring startup/readiness/domain smoke 통과
2. 실제 OAuth 로그인 기반 authenticated smoke 통과
3. DB/Redis/Key Vault reference smoke 통과
4. Blob/CDN/tile smoke 통과
5. Place/Search/Route smoke 통과
6. Observability smoke 통과
7. secret 미출력/미수집 확인
8. rollback 또는 versioned path 복구 기준 확인
