# Azure 데이터 이전 runbook

이 문서는 Windows dev backend의 데이터 저장소를 Azure staging/production으로 이전할 때의 절차와 책임 경계를 정리한다. 실제 이전은 별도 승인, 백업, smoke 계획이 확정된 뒤 수행한다.

## 1. 이전 대상과 비대상

| 저장소 | 현재 | Azure 목표 | 이전 방식 |
| --- | --- | --- | --- |
| PostgreSQL/PostGIS | Docker Postgres | Azure Database for PostgreSQL Flexible Server | dump/restore 또는 migration job |
| Redis | Docker Redis | Azure Cache for Redis | 영속 이전 없음, cache warm-up |
| MinIO media | MinIO bucket | Azure Blob Storage container | object copy + checksum/sample smoke |
| Tile assets | MinIO/gateway | Blob/CDN/Front Door 후보 | manifest/style/PMTiles object copy |
| Outbox/events | PostgreSQL table | PostgreSQL + Service Bus/Event Hubs | DB 원장 유지, consumer 전환 |

Redis는 원장 저장소가 아니므로 migration 대상이 아니다. 필요한 경우 place-search cache, presence, rate-limit은 Azure 배포 후 자연 재생성한다.

## 2. 사전 조건

- source와 target PostgreSQL 버전/extension 호환성 확인
- PostGIS extension 활성화 가능 여부 확인
- Flyway migration이 target DB에서 clean하게 실행되는지 확인
- target Key Vault secret name과 runtime env binding 확인
- object storage container와 access policy 확인
- rollback snapshot 또는 source freeze 기준 확정
- smoke checklist와 cutover window 승인

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

## 4. Flyway 경계

Flyway는 Spring Main API schema를 소유한다.

- `users`, `groups`, `plans`, `places`, `chat`, `notifications`, `devices`, `settlements` 등 Main API 원장 schema는 Flyway가 관리한다.
- Terraform은 DB server/database/extension/identity/network만 관리한다.
- 이미 적용된 migration은 되돌리지 않고 forward migration으로 보정한다.
- destructive migration은 production cutover 전 별도 승인과 backup 이후에만 수행한다.

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
6. tile asset은 manifest/style/PMTiles Range smoke를 별도로 수행한다.

파일명 또는 실제 사용자 media URL은 보고하지 않고, key prefix/count/status 중심으로 보고한다.

## 7. Tile asset 이전

Tile asset은 앱의 지도 안정성과 직접 연결되므로 일반 media와 분리한다.

- `manifest.json` 200
- `styles/onmu-light.json` 200
- PMTiles Range 206
- `Access-Control-Allow-Origin`, `Accept-Ranges`, `Content-Range`, `Access-Control-Expose-Headers` 유지
- style source URL과 manifest tileset URL 일치
- Android emulator에서 blank/fallback/water-style 회귀 확인

## 8. 검증 smoke

최소 smoke는 [Azure smoke checklist](./azure-smoke-checklist.md)를 따른다.

PostgreSQL 이전 이후에는 다음을 우선 확인한다.

- no-token `/api/v1/users/me` 401
- authenticated `/api/v1/users/me` 200
- `userCode` field 존재와 형식만 확인
- notification unread/list/preferences status/count
- chat messages/read-state/SSE status
- place-search provider/source/coordinate count
- push token route validation status

## 9. Rollback 기준

- DNS cutover 전이면 Windows dev backend 또는 이전 Azure deployment로 되돌린다.
- DB migration이 target에만 적용된 상태라면 source DB는 그대로 보존한다.
- production source DB에 destructive migration이 적용된 뒤에는 자동 rollback을 금지하고 forward fix 또는 snapshot restore를 별도 승인한다.
- object storage는 overwrite 전 backup key 또는 versioning이 있어야 한다.
