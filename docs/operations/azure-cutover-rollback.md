# Azure cutover/rollback runbook

이 문서는 Azure staging/production으로 traffic을 전환하거나 문제가 생겼을 때 되돌리는 절차를 정리한다. Cutover는 별도 승인된 window에서만 수행한다.

현재 팀의 일상 배포/검증 기본선은 Azure staging이다. 이 문서는 일상 staging 운영 문서가 아니라 cutover, public domain 전환, rollback 판단이 필요한 시점에만 사용한다. 현재 staging 기준 운영 경계는 [staging cutover status](./staging-cutover-status.md), 일반 배포 순서는 [Azure staging 배포/운영 runbook](./azure-staging-deploy-runbook.md)을 먼저 본다.

## 1. Cutover 전 조건

- Terraform plan/apply 결과 승인
- DB migration rehearsal 통과
- object storage copy와 tile smoke 통과
- Spring/Worker health/readiness 통과
- OAuth provider console 설정 확인
- mobile build의 API base URL과 공개 OAuth define 확인
- rollback 담당자와 판단 기준 확정
- Windows dev backend 또는 이전 Azure deployment가 rollback 기준으로 살아 있음
- cutover 직전 DB snapshot 또는 logical dump 생성 완료
- snapshot restore 시 허용 가능한 RPO, 예상 데이터 유실 window, 승인권자 확정
- 쓰기 트래픽을 받을 수 없는 상태라면 maintenance/read-only 전환 기준 확정

## 2. Cutover 순서

1. production image digest와 commit 확인
2. production Key Vault secret presence 확인
3. cutover snapshot 또는 logical dump 확인
4. 필요 시 짧은 maintenance/read-only window 시작
5. DB migration job 실행
6. Spring Main API rollout
7. Worker rollout
8. internal smoke
9. edge/API Management/Front Door smoke
10. DNS 또는 traffic routing 변경
11. public smoke
12. Android/iOS smoke
13. monitoring window 유지

## 3. Public smoke 기준

최소 smoke는 다음 순서로 수행한다.

- `/healthz` 200
- `/readyz` 200
- no-token `/api/v1/users/me` 401
- authenticated `/api/v1/users/me` 200
- chat/notification status/count
- place-search status/provider/source/coordinate count
- tile manifest/style/Range/CORS
- OAuth login provider별 최소 1회

## 4. Rollback 판단

| 상황 | 판단 |
| --- | --- |
| Edge만 502/530/1033 | container health와 edge config 분리 후 routing rollback |
| Container crash/readiness fail | previous revision/image rollback |
| DB migration 전 실패 | deploy 중단, 이전 runtime 유지 |
| DB migration 후 schema mismatch | forward fix 우선, snapshot restore는 별도 승인 |
| OAuth provider fail | provider console/config rollback 또는 해당 provider disable 판단 |
| Tile blank/fallback | style/manifest object rollback |
| Notification/push fail | provider delivery disable, in-app notification 유지 |

## 5. Snapshot restore 정책

DB snapshot restore는 forward fix, image/revision rollback, provider disable로 복구할 수 없을 때만 선택한다. 자동화하지 않고 별도 승인된 incident 절차로만 수행한다.

restore 승인 전 반드시 다음을 확인한다.

- restore 기준 시각과 RPO를 명시한다.
- cutover window 동안 유입된 write data 유실 가능성을 제품/운영 책임자가 승인한다.
- 유실 가능 데이터 범위를 raw value 없이 table/domain/count 중심으로 추정한다.
- 사용자 공지, 재시도 안내, 보상/재입력 필요 여부를 결정한다.
- source DB 또는 직전 snapshot을 보존하고, 원인 분석 전 삭제하지 않는다.

쓰기 트래픽이 이미 production DB에 유입된 뒤에는 destructive rollback을 기본 금지한다. 이 경우 forward fix를 우선하고, snapshot restore는 위 조건을 모두 만족할 때만 진행한다. cutover 전에 데이터 유실을 허용할 수 없다면 DNS/traffic 전환 전 maintenance/read-only mode를 켜거나 cutover를 연기한다.

## 6. Rollback 순서

1. 장애 범위를 runtime, migration, edge, provider, mobile로 분리한다.
2. DB destructive migration 여부를 확인한다.
3. 이전 image/revision으로 traffic을 되돌린다.
4. DNS/edge routing을 이전 endpoint로 되돌린다.
5. public smoke를 다시 실행한다.
6. 장애 보고에 commit, environment, endpoint status, count, error type만 남긴다.

## 7. Windows dev fallback

Azure cutover 전까지 Windows dev backend는 팀 개발 기준 fallback으로 유지한다.

- `https://dev-api.onmu.cloud` public smoke
- local `127.0.0.1:8080` smoke
- Docker Postgres/Redis/MinIO 상태
- tile gateway 상태
- Cloudflare tunnel 상태

Windows dev fallback은 production traffic 영구 대체가 아니라 cutover rehearsal와 개발 지속을 위한 기준이다.

## 8. 금지 사항

- 승인 없는 DNS 변경
- 승인 없는 production secret 교체
- rollback 중 secret 값 출력
- DB destructive rollback 자동화
- 앱 기능 hotfix와 infra rollback을 한 PR에 섞기
