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

## 2. Demo catalog direct import

시현 안정화를 위한 장소 catalog data는 schema migration이 아니라 승인된 staging/demo data import로 취급할 수 있다. 이 예외는 Kakao Local API 심사 지연 또는 provider result 수 제한 때문에 장소 검색 품질이 불안정한 경우에만 사용하며, production seed 정책이나 Flyway schema ownership을 대체하지 않는다.

| 항목 | 기준 |
| --- | --- |
| 대상 테이블 | `external_places` |
| provider | `ONMU_CATALOG` |
| source 후보 | LALA-next `public_mvp_places.json` 변환본 + ONMU 수동 큐레이션 |
| 적재 방식 | temp/staging table에 로드 후 `ON CONFLICT (provider, provider_place_id) DO UPDATE` |
| batch 추적 | `provider_payload.importBatchId` 필수 |
| rollback | `provider='ONMU_CATALOG'`와 `importBatchId` 기준 delete |
| 보고 방식 | row count, region count, coordinate null count, error type 중심 |

LALA-next의 local dev seed SQL은 ONMU staging DB에 직접 실행하지 않는다. LALA-next snapshot은 ONMU `external_places` 형식으로 변환하고, `place_id`는 `provider_place_id`, `name_ko`는 `name`, `category`는 ONMU 표시 카테고리, `address_ko`는 `address`, `lat/lng`는 `latitude/longitude`, score/source metadata는 `provider_payload`로 매핑한다.

직접 import 전 확인:

- import 대상 DB가 staging/demo인지 확인한다.
- `importBatchId`, input file checksum, expected row count, rollback predicate를 기록한다.
- secret, DB password, connection string, token, raw provider response body는 문서, PR, 로그, 채팅에 출력하지 않는다.
- 실제 사용자 위치, 사진, 정산, profile raw value와 결합한 export/import는 이 경로에서 금지한다.
- import 후 `/api/v1/place-search`에서 catalog row가 보이려면 Spring에 DB-backed curated provider가 배포되어 있어야 한다. DB row만 넣는 작업은 검색 노출을 보장하지 않는다.

## 3. Redis rehearsal

Redis는 migration 대상이 아니다.

- Cache, presence, rate-limit, place-search/route/provider response TTL cache는 staging 배포 후 자연 재생성한다.
- Redis outage 시 PostgreSQL 원장 데이터가 유지되는지 확인한다.
- Smoke는 ping/readiness, key count, TTL policy, cleanup 여부 중심으로만 보고한다.
- Redis dump/import는 기본 rehearsal 범위에서 제외한다.

## 4. Blob/CDN rehearsal

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

## 5. Private media 경계

- Private user media는 public CDN cache 대상이 아니다.
- 공개 가능한 asset과 private media는 container, path, cache-control, access policy로 분리한다.
- Signed access, private endpoint, proxy delivery, CDN token 정책이 확정되기 전까지 private media를 public delivery로 보지 않는다.
- 실제 사용자 사진, 위치, 정산, profile raw value는 rehearsal 로그나 PR 본문에 출력하지 않는다.

## 6. Route/Place/Search cache rehearsal

- Provider search/route response는 Redis TTL cache로만 둔다.
- Provider secret은 Key Vault reference로 주입하고 Terraform state에 넣지 않는다.
- Place/Search smoke는 status, result_count, provider_counts, source_counts, coordinate_count 중심으로 보고한다.
- Route smoke는 status, route_count, distance presence, duration presence 중심으로 보고한다.
- Provider raw body, query 원문, token은 출력하지 않는다.
- Curated catalog smoke는 provider_counts/source_counts에서 `ONMU_CATALOG` 또는 API가 정한 catalog provider name의 count, region별 result count, coordinate_count만 보고한다.

## 7. Rollback rehearsal

| 영역 | Rollback 기준 |
| --- | --- |
| PostgreSQL clean rehearsal | staging DB drop/recreate 또는 새 DB로 재실행 |
| Demo catalog direct import | `provider='ONMU_CATALOG'`와 승인된 `importBatchId` 기준 delete 후 place-search smoke |
| Snapshot rehearsal | 승인된 snapshot restore 절차 또는 forward fix |
| Blob tile asset | manifest pointer rollback 또는 versioned path 복구 |
| CDN cache | purge/invalidation 또는 새 versioned path |
| Runtime | 이전 Container Apps revision 또는 Windows dev fallback |
| Event Hubs | producer disable, consumer stop, checkpoint/replay 기준 확인 |

Destructive rollback은 별도 승인 없이 수행하지 않는다.

## 8. 승인 gate

다음 작업은 별도 승인 전까지 금지한다.

- dev snapshot dump/restore
- production 또는 active user data 복제
- demo catalog direct import 실행
- private media public delivery 전환
- DNS 변경
- DB destructive migration
- Key Vault secret value 작성
- `terraform apply`
