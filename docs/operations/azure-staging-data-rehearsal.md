# Azure staging data rehearsal plan

이 문서는 ONMU Azure staging 전환 전 데이터 이전 rehearsal 기준을 정리한다. 실제 dev snapshot dump/restore, destructive migration, private media 공개 전환은 별도 승인 전까지 수행하지 않는다.

## 1. PostgreSQL rehearsal

첫 staging DB 검증은 clean DB full Flyway migration으로 시작한다.

| 단계 | 기준 |
| --- | --- |
| Clean DB 준비 | 비어 있는 staging database 사용 |
| Flyway full migration | 모든 migration이 순서대로 성공 |
| PostGIS 확인 | extension presence count 확인 |
| Schema ownership | table/index/column은 Flyway 소유, Terraform 소유 아님 |
| Domain smoke | `/readyz`, `/users/me`, 주요 read endpoint status/count |

Dev snapshot dump/restore rehearsal은 지금 수행하지 않는다. Clean staging smoke 통과 후 별도 승인, 백업, PII 보호 기준, 접근 권한 확인을 거친 sanitized/minimal dump rehearsal만 검토한다. Snapshot 공유본이나 로그에는 사용자 실제 값과 raw row를 출력하지 않는다.

### Curated place catalog rehearsal

`external_places.provider='ONMU_CATALOG'` 행은 앱 schema migration과 분리된 정적/공공 catalog import 산출물이다. 행 수가 많으므로 Flyway SQL로 데이터를 직접 넣지 않는다. Flyway는 `external_places` schema와 catalog 조회 인덱스만 소유하고, catalog row 적재/교체/rollback은 별도 운영 import 절차가 담당한다.

검증은 raw row dump가 아니라 count/status 중심으로만 수행한다.

| 항목 | 기준 |
| --- | --- |
| Catalog row count | `ONMU_CATALOG` provider count가 기대 범위 이상 |
| Coordinate coverage | catalog row의 lat/lng coverage count 확인 |
| Import batch | `provider_payload.importBatchId` presence count 확인 |
| App visibility | Spring `onmu_catalog` provider 배포 후 `place-search`의 `provider_counts` 또는 `source_counts`에 `onmu_catalog`가 나타남 |
| Category smoke | `가볼만한곳`은 catalog-first, 음식점/카페는 Naver-first 후 catalog supplement |

보고에는 row 원문, provider raw payload, 실제 사용자 위치/검색 원문을 출력하지 않는다.

## 2. Redis rehearsal

Redis는 migration 대상이 아니다.

- Cache, presence, rate-limit, place-search/route/provider response TTL cache는 staging 배포 후 자연 재생성한다.
- Redis outage 시 PostgreSQL 원장 데이터가 유지되는지 확인한다.
- Smoke는 ping/readiness, key count, TTL policy, cleanup 여부 중심으로만 보고한다.
- Redis dump/import는 기본 rehearsal 범위에서 제외한다.

## 3. Blob/CDN rehearsal

Blob은 object origin이자 source of truth이며 CDN은 public edge delivery 계층이다.

| 단계 | 기준 |
| --- | --- |
| Blob origin copy | source/target path, object count, size 합계 중심 확인 |
| Checksum 검증 | checksum 또는 ETag/sample read 확인 |
| Tile asset 분리 | manifest/style/PMTiles를 일반 media와 분리 |
| CDN edge smoke | 200, content-type, cache-control, CORS 확인 |
| PMTiles smoke | Range 206, `Accept-Ranges`, `Content-Range`, expose headers |
| Rollback | versioned object path 또는 manifest pointer 복구 기준 |

PMTiles는 versioned path를 우선하고, manifest pointer를 되돌리는 방식으로 rollback 가능성을 유지한다. CDN purge는 보조 복구 수단으로 둔다.

## 4. Private media 경계

- Private user media는 public CDN cache 대상이 아니다.
- 공개 가능한 asset과 private media는 container, path, cache-control, access policy로 분리한다.
- Signed access, private endpoint, proxy delivery, CDN token 정책이 확정되기 전까지 private media를 public delivery로 보지 않는다.
- 실제 사용자 사진, 위치, 정산, profile raw value는 rehearsal 로그나 PR 본문에 출력하지 않는다.

## 5. Route/Place/Search cache rehearsal

- Provider search/route response는 Redis TTL cache로만 둔다.
- Provider secret은 Key Vault reference로 주입하고 Terraform state에 넣지 않는다.
- Place/Search smoke는 status, result_count, provider_counts, source_counts, coordinate_count 중심으로 보고한다.
- 같은 category/search를 2회 실행해 Redis cache hit 또는 `place-search:v4:*` prefix key count만 확인한다. Redis value 원문은 출력하지 않는다.
- Route smoke는 status, route_count, distance presence, duration presence 중심으로 보고한다.
- Provider raw body, query 원문, token은 출력하지 않는다.

## 6. Rollback rehearsal

| 영역 | Rollback 기준 |
| --- | --- |
| PostgreSQL clean rehearsal | staging DB drop/recreate 또는 새 DB로 재실행 |
| Snapshot rehearsal | 승인된 snapshot restore 절차 또는 forward fix |
| Blob tile asset | manifest pointer rollback 또는 versioned path 복구 |
| CDN cache | purge/invalidation 또는 새 versioned path |
| Runtime | 이전 Container Apps revision 또는 Windows dev fallback |
| Event Hubs | producer disable, consumer stop, checkpoint/replay 기준 확인 |

Destructive rollback은 별도 승인 없이 수행하지 않는다.

## 7. 승인 gate

다음 작업은 별도 승인 전까지 금지한다.

- dev snapshot dump/restore
- production 또는 active user data 복제
- private media public delivery 전환
- DNS 변경
- DB destructive migration
- Key Vault secret value 작성
- `terraform apply`
