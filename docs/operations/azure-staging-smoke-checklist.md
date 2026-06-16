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
| Spring startup | container revision ready, startup failure count 0 |
| Domain smoke | `staging-api.onmu.cloud` 연결 후 동일한 200/200/401 |

## 3. Dependency smoke

| 항목 | 기준 |
| --- | --- |
| PostgreSQL readiness | connection success, Flyway schema up to date 또는 migration result count |
| PostGIS readiness | extension presence count |
| Redis readiness | ping/readiness success, cache source of truth 아님 확인 |
| Key Vault reference | required secret reference resolved count, missing count 0 |
| Managed identity | required role assignment presence count |

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
| route provider | status, route_count, distance presence, duration presence |
| provider fallback | fallback 여부와 provider별 availability count |
| cache | cache key count, TTL policy, cleanup 여부 |

Provider raw body, query 원문, token, Authorization header는 출력하지 않는다.

## 7. Notification/Event smoke

Event Hubs는 analytics/event stream fan-out 계층이다. Transactional outbox 원장은 Spring/PostgreSQL에 남는다.

| 항목 | 기준 |
| --- | --- |
| outbox source | `notification.requested` count 중심 확인 |
| Event Hubs publish | status/count 중심 확인 |
| consumer group | expected group presence |
| replay/checkpoint | checkpoint storage presence, offset/count 중심 확인 |
| delivery record | dev-safe provider/status/count 중심 확인 |

## 8. Observability smoke

| 항목 | 기준 |
| --- | --- |
| Application Insights request | request count 확인 |
| Application Insights dependency | DB/Redis/HTTP dependency count 확인 |
| Application Insights exception | unexpected exception count |
| Log Analytics ingestion | ingestion 여부와 table count |
| Telemetry hygiene | secret/token/raw body/user PII 미수집 확인 |
| Diagnostic settings | Container Apps, PostgreSQL, Redis, Storage, CDN, Event Hubs 로그 route 확인 |

## 9. 최종 판정

Staging 성공 판정은 다음을 모두 만족해야 한다.

1. Spring startup/readiness/domain smoke 통과
2. DB/Redis/Key Vault reference smoke 통과
3. Blob/CDN/tile smoke 통과
4. Place/Search/Route smoke 통과
5. Observability smoke 통과
6. secret 미출력/미수집 확인
7. rollback 또는 versioned path 복구 기준 확인
