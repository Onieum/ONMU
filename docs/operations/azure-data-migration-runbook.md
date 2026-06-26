# Azure 데이터 이전 runbook

이 문서는 Windows dev backend, on-prem backup backend, Azure staging/production 사이에서 데이터 저장소를 이전할 때의 절차와 책임 경계를 정리한다. 실제 이전은 go/no-go 체크포인트, 백업, smoke 계획, rollback point가 확정된 뒤 수행한다.

## 1. 이전 대상과 비대상

| 저장소 | 현재 | Azure 목표 | 이전 방식 |
| --- | --- | --- | --- |
| PostgreSQL/PostGIS | Docker Postgres | Azure Database for PostgreSQL Flexible Server | dump/restore 또는 migration job |
| Redis | Docker Redis | Azure Cache for Redis | 영속 이전 없음, cache warm-up |
| MinIO media | MinIO bucket | Azure Blob Storage container | object copy + checksum/sample smoke |
| Record media metadata | `record_media` table | PostgreSQL `record_media` table | DB migration/dump와 함께 이전, object key 정합성 smoke |
| Curated place catalog | `external_places.provider='ONMU_CATALOG'` | PostgreSQL `external_places` | 대량 정적/공공 catalog import job. Flyway에는 data row를 넣지 않음 |
| Tile assets | MinIO/gateway | Blob/CDN/Front Door 후보 | manifest/style/PMTiles object copy |
| Outbox/events | PostgreSQL table | PostgreSQL + Event Hubs | DB 원장 유지, consumer group/checkpoint/replay 전환 |

Redis는 원장 저장소가 아니므로 migration 대상이 아니다. 필요한 경우 place-search cache, presence, rate-limit은 Azure 배포 후 자연 재생성한다.

## 2. 사전 조건

- source와 target PostgreSQL 버전/extension 호환성 확인
- PostGIS extension 활성화 가능 여부 확인
- Flyway migration이 target DB에서 clean하게 실행되는지 확인
- target Key Vault secret name과 runtime env binding 확인
- object storage container와 access policy 확인
- tile hosting target을 Blob Storage + CDN, Front Door, gateway fallback 중 어떤 조합으로 둘지 확정
- tile cache invalidation/rollback 담당자와 실행 권한 확인
- Azure Pricing Calculator 기준 staging/prod 비용 산출물 존재 확인
- rollback snapshot 또는 source freeze 기준 확정
- smoke checklist와 cutover window 확정

## 3. PostgreSQL 이전 절차

1. Source DB read/write 상태와 active connection을 확인한다.
2. Source snapshot 또는 logical dump를 생성한다.
3. Target PostgreSQL server/database를 준비한다.
4. PostGIS extension을 활성화한다.
5. Flyway baseline/migration 전략을 결정한다.
6. dump/restore 또는 migration job을 실행한다.
7. Spring Main API를 target DB에 연결해 `/healthz`, `/readyz`를 확인한다.
8. domain smoke를 실행한다.
9. row count, key table presence, migration version을 값 노출 없이 count/status 중심으로 확인한다.

`pg_restore` 또는 migration job이 non-zero exit으로 끝나면 기본 판정은 실패다. owner/role/extension 차이처럼 사전에 승인된 warning만 있는 경우에도 error type을 분류하고 extension, Flyway, schema/index, 핵심 table count를 각각 확인한 뒤 go/no-go 회의에 올린다. row count만 맞는 것은 target DB가 대체 운영 가능한 상태라는 근거로 부족하다.

```bash
rg -n "ERROR|FATAL|could not|permission denied|constraint|extension|role|already exists" \
  "$RUN_DIR/logs/pg_restore.err.log"
psql "$TARGET_DATABASE_URL" -Atc "select extname from pg_extension order by 1;"
psql "$TARGET_DATABASE_URL" -Atc "select installed_rank, version, success from flyway_schema_history order by installed_rank desc limit 5;"
```

| 항목 | Go 기준 | No-Go 기준 |
| --- | --- | --- |
| restore/migration exit | `0` 또는 분류된 warning만 존재 | 원인 미분류 non-zero exit, data/constraint/permission error |
| extension | PostGIS 등 필수 extension presence 확인 | 필수 extension 누락 |
| Flyway | 최신 migration success 확인 | failed migration, checksum 불일치, Flyway table 누락 |
| schema/index | 핵심 table, PK/FK/index spot check 통과 | 핵심 constraint/index 누락 |
| data count | source/target 핵심 count 차이 설명 가능 | 설명 불가 mismatch |

### Migration rehearsal 결정 항목

| 항목 | 선택지 | 기본 기준 |
| --- | --- | --- |
| dev DB snapshot | logical dump, physical snapshot 후보 | staging rehearsal은 logical dump 우선. raw user data 값은 보고하지 않음 |
| staging DB 초기화 | 새 database 생성, schema drop/recreate, dump restore | 팀 공유 staging은 go/no-go 체크포인트 없이 drop 금지 |
| Flyway baseline | clean DB full migration, baseline 후 migrate | Azure staging 1차는 clean DB full migration을 우선 검증 |
| checksum mismatch | 기존 migration 수정 금지, 새 V번호 migration으로 forward fix | checksum mismatch가 나면 배포 중단 후 원인 분석 |
| seed/test data | Flyway seed, Spring script, 별도 import | production seed와 demo/test data를 분리 |
| 실패 rollback | migration 전이면 deploy 중단, migration 후면 forward fix 우선 | snapshot restore는 rollback point와 go/no-go 기록 이후 수행 |

rehearsal 결과는 migration version, table count, row count, duration, error type 중심으로 기록한다. 사용자 raw value, secret, connection string, token은 기록하지 않는다.

## 4. Flyway 경계

Flyway는 Spring Main API schema를 소유한다.

- `users`, `groups`, `plans`, `places`, `chat`, `notifications`, `devices`, `settlements` 등 Main API 원장 schema는 Flyway가 관리한다.
- Terraform은 DB server/database/extension/identity/network만 관리한다.
- 이미 merge된 `V1`-`Vn` migration 파일은 수정하지 않는다.
- schema 변경은 항상 새 `V{n+1}__...sql` migration으로 추가한다.
- `external_places` schema와 catalog 조회 인덱스는 Flyway가 소유하지만, `ONMU_CATALOG` 대량 row 적재/교체/rollback은 별도 운영 import 절차가 소유한다.
- checksum mismatch는 팀원 DB와 staging DB를 깨뜨릴 수 있으므로, 로컬에서만 맞추려고 기존 migration을 고치지 않는다.
- baseline/repair는 production/staging에서 go/no-go 체크포인트 없이 실행하지 않는다.
- 이미 적용된 migration은 되돌리지 않고 forward migration으로 보정한다.
- destructive migration은 production cutover 전 backup과 go/no-go 체크포인트 이후에만 수행한다.

## 5. FastAPI Worker schema 경계

Worker 전용 schema가 생기는 경우:

- schema name은 예: `worker_ai` 후보로 분리한다.
- Alembic이 worker schema를 관리한다.
- Spring Main API transaction과 Worker migration을 같은 job에 섞지 않는다.
- AI/추천 결과가 Main API 원장으로 승격되는 순간에는 Spring API contract를 거친다.

## 6. Object storage 이전

1. Source MinIO bucket/key 목록을 count 중심으로 확인한다.
2. Target Blob container와 lifecycle 정책을 준비한다.
3. object copy를 수행한다.
4. sample object의 size/checksum/content-type을 확인한다.
5. presigned URL 또는 managed access 방식의 API smoke를 실행한다.
6. `record_media.storage_key` 또는 public URL이 target object와 매칭되는지 count/presence 중심으로 확인한다.
7. records/OOTD 사진은 `/api/v1/media/public` 또는 target media read API를 통해 조회하고, Flutter가 Blob/MinIO endpoint를 직접 호출하지 않는지 확인한다.
8. tile asset은 manifest/style/PMTiles Range smoke를 별도로 수행한다.

파일명 또는 실제 사용자 media URL은 보고하지 않고, key prefix/count/status 중심으로 보고한다.

records/OOTD media 전환 기준:

- 현재 records/OOTD 사진 저장은 Spring API upload boundary를 거친다. Flutter는 MinIO 또는 Azure Blob Storage를 직접 호출하지 않는다.
- DB에는 원본 이미지 bytes를 저장하지 않고 `record_media` metadata, object key, content type, sort order, optional comment만 저장한다.
- local/dev는 MinIO compatibility를 유지할 수 있지만 Azure staging/prod는 Azure Blob Storage를 기본 target으로 둔다.
- storage provider 전환은 Spring env/profile 또는 runtime config가 소유한다. Flutter API contract는 `/api/v1/media/upload`, `/api/v1/media/public`, `/api/v1/memories` 기준으로 유지한다.
- 기존 dev 이미지 데이터가 production으로 승격될 대상인지, seed/demo data로 버릴 대상인지는 cutover 전 별도 결정한다.

## 7. Tile asset 이전

Tile asset은 앱의 지도 안정성과 직접 연결되므로 일반 media와 분리한다.

- Terraform `apply` 전에 tile hosting target을 확정한다. Blob Storage + CDN, Front Door, gateway fallback 중 production traffic을 받을 경로가 정해지지 않으면 cutover하지 않는다.
- `manifest.json`, style JSON, PMTiles object는 versioned prefix나 build 식별자가 있는 key로 먼저 복제한다. 기존 current object를 덮어쓰는 방식은 rollback과 cache 검증이 어려우므로 피한다.
- 새 PMTiles object의 size/checksum/content-type과 Range header를 확인한 뒤 manifest current pointer를 전환한다.
- `manifest.json` 200
- `styles/onmu-light.json` 200
- PMTiles Range 206
- `Access-Control-Allow-Origin`, `Accept-Ranges`, `Content-Range`, `Access-Control-Expose-Headers` 유지
- style source URL과 manifest tileset URL 일치
- 이전 manifest/style/PMTiles pointer가 rollback용으로 보존되어 있는지 확인
- edge cache를 사용하는 경우 cache purge 또는 invalidation 실행 여부와 stale response count를 기록
- Android emulator에서 blank/fallback/water-style 회귀 확인

rollback은 앱 재배포보다 manifest pointer 복구를 먼저 시도한다. edge cache가 이전/신규 manifest를 오래 잡고 있으면 purge 또는 invalidation을 실행한다. 보고에는 object key prefix, count, checksum/status만 남기고 실제 사용자 media URL이나 credential은 남기지 않는다.

## 8. 검증 smoke

최소 smoke는 [Azure smoke checklist](./azure-smoke-checklist.md)를 따른다.

PostgreSQL 이전 이후에는 다음을 우선 확인한다.

- no-token `/api/v1/users/me` 401
- authenticated `/api/v1/users/me` 200
- `userCode` field 존재와 형식만 확인
- records DAILY/OOTD create/read/update/delete status
- 사진 포함 record의 storage key/content-type/sort order presence
- record delete 후 list/detail 재조회 제거 확인
- notification unread/list/preferences status/count
- chat messages/read-state/SSE status
- place-search provider/source/coordinate count
- push token route validation status

## 9. Rollback 기준

- DNS cutover 전이면 Windows dev backend 또는 이전 Azure deployment로 되돌린다.
- DB migration이 target에만 적용된 상태라면 source DB는 그대로 보존한다.
- production source DB에 destructive migration이 적용된 뒤에는 자동 rollback을 금지하고 forward fix 또는 snapshot restore를 go/no-go 체크포인트로 분리한다.
- object storage는 overwrite 전 backup key 또는 versioning이 있어야 한다.
- record delete는 DB soft delete와 object cleanup이 원자적이지 않으므로, 실패 시 object cleanup worker/outbox를 재시도하고 사용자-facing record는 `deleted_at` 기준으로 숨긴다.
