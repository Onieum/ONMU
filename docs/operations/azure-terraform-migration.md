# Azure Terraform 전환 운영 가이드

이 문서는 ONMU를 Windows dev backend 중심 운영에서 Terraform 기반 Azure staging/production 운영으로 옮기기 위한 상위 runbook이다. 실제 배포 명령보다 전환 순서, 책임 경계, 승인 게이트를 먼저 고정하는 데 목적이 있다.

## 1. 전환 목표

- 현재 `dev-api.onmu.cloud` Windows backend 운영을 안정화 기준으로 유지한다.
- Azure staging을 먼저 만들고, smoke와 데이터 이전 절차가 안정화된 뒤 production 목표 구조로 확장한다.
- Terraform은 Azure 리소스와 권한 경계를 재현 가능하게 관리한다.
- Spring Main API, FastAPI Worker, PostgreSQL/PostGIS, Redis, Blob, Event/Queue, Monitor를 target architecture와 같은 이름/역할로 정렬한다.
- secret 값은 Key Vault와 CI/CD runtime에만 존재하게 하고, 문서/PR/로그에는 값이 남지 않게 한다.

## 2. 현재에서 목표로 가는 단계

| 단계 | 설명 | 성공 기준 |
| --- | --- | --- |
| Windows dev 유지 | 현재 팀 개발 API와 tile gateway를 계속 serving | `/healthz`, `/readyz`, no-token `/users/me` 401 |
| Terraform 문서화 | 리소스/secret/data/runtime/CI/CD/runbook 문서 확정 | 문서 링크와 secret hygiene 검증 |
| Terraform skeleton | provider, backend, environment variables, module 구조 작성 | `terraform fmt`, `terraform validate`, `plan` 가능 |
| Azure staging 생성 | 최소 리소스와 staging API 배포 | local/public smoke pass |
| 데이터 이전 rehearsals | dev snapshot 기반 Postgres/Blob/Redis 전략 검증 | migration 로그와 rollback 절차 확인 |
| CI/CD 연결 | GitHub Actions plan/apply/deploy/smoke 환경 보호 | manual approval gate 동작 |
| Production cutover | DNS/edge/API smoke 통과 후 traffic 전환 | rollback window 동안 error budget 유지 |

## 3. 환경별 기본 전략

- Local: 개발자 PC의 Flutter/Spring/Docker Compose를 유지한다.
- Windows dev: 팀 공유 dev API, dev DB, dev tile gateway의 기준 환경이다.
- Integration staging: Windows에서 dev와 분리된 연동 검증이 필요한 경우만 유지한다.
- Azure staging: Terraform 전환의 1차 목표 환경이다.
- Azure production: staging smoke와 운영 runbook이 안정화된 뒤 승격한다.

세부 값은 [Azure 환경 매트릭스](./azure-environment-matrix.md)를 기준으로 한다.

## 3.1 Staging plan 산출물

Azure staging 전환은 다음 plan-only 문서를 기준으로 구체화한다. 이 문서들은 실제 Azure 리소스 생성, `terraform apply`, DNS 변경, DB migration, Key Vault secret value 작성을 포함하지 않는다.

| 문서 | 역할 |
| --- | --- |
| [Azure staging plan](../../.azure/staging-plan.md) | 확정 결정, 리소스 후보, Terraform 구조, Blob/CDN와 Event Hubs 경계 |
| [Azure staging smoke checklist](./azure-staging-smoke-checklist.md) | API, dependency, Blob/CDN, tile, provider, observability smoke 기준 |
| [Azure staging data rehearsal plan](./azure-staging-data-rehearsal.md) | clean DB Flyway, Redis 비이전, Blob/CDN 이전 rehearsal 기준 |
| [Azure staging cost and permission review](./azure-cost-permission-review.md) | Azure Pricing Calculator 입력 항목, 무료 크레딧 방어 가능성, 권한 경계 |

## 4. Terraform 작성 전제

Terraform module은 다음 기준을 따른다.

- 환경별 variable은 `dev`, `int`, `staging`, `prod`를 구분한다.
- resource name, tag, diagnostic setting, managed identity, RBAC는 module 표준으로 통일한다.
- Terraform state backend와 lock은 별도 승인 후 만든다.
- Key Vault secret value는 Terraform 코드에 직접 넣지 않는다.
- 이미 수동 생성된 secret은 import 또는 data source 경계를 별도 검토한다.

리소스 소유권은 [Terraform 리소스 소유권](../architecture/terraform-resource-ownership.md)을 따른다.

Terraform skeleton 최소 범위:

```text
infra/terraform/
  environments/
    staging/
    prod/
  modules/
    naming/
    resource-group/
    key-vault/
    container-apps/
    postgres/
    redis/
    storage/
    observability/
```

첫 skeleton PR은 provider/backend 설정, environment variable shape, module interface, output만 포함하고 실제 production traffic cutover는 포함하지 않는다. state backend는 Azure Storage Account blob backend와 blob lease lock을 기본 후보로 두며, environment는 초기에는 workspace보다 폴더 분리를 우선한다.

## 5. API/runtime 전환 기준

Azure runtime은 [Azure runtime contract](./azure-runtime-contract.md)를 따른다.

- Spring Main API가 모바일 앱의 공식 API surface다.
- FastAPI Worker는 Spring 내부 작업 또는 queue 기반 비동기 작업으로만 노출한다.
- Realtime Gateway는 1차 Azure staging에서는 Spring SSE 유지가 가능하다.
- Notification delivery는 dev-safe 기록과 provider adapter를 분리한다.
- Place/Search/Route/Map은 provider secret, tile asset, cache TTL, fallback 정책을 분리 검증한다.
- 지도 tile traffic 전환 전에는 hosting 최종안, manifest rollback, edge cache invalidation, Android MapLibre/PMTiles 회귀, Azure Pricing Calculator 산출물을 별도 gate로 닫는다.

## 6. 데이터 전환 기준

데이터 전환은 [Azure 데이터 이전 runbook](./azure-data-migration-runbook.md)을 따른다.

- PostgreSQL schema는 Flyway migration이 소유한다.
- FastAPI Worker 전용 schema가 생기면 Alembic이 소유한다.
- Redis는 cache/presence/rate-limit 성격이므로 영속 이전 대상이 아니다.
- MinIO object는 Azure Blob Storage로 복제하고, manifest/style/PMTiles 경로를 smoke한다.
- 실사용자 데이터 정리는 별도 승인과 백업 이후에만 수행한다.

## 7. CI/CD 전환 기준

CI/CD는 [Azure CI/CD runbook](./azure-ci-cd-runbook.md)을 따른다.

- PR 단계: lint/test/build/terraform validate/plan.
- Protected environment 단계: manual approval 이후 staging/prod apply.
- Deploy 단계: image build/push, migration job, rollout, smoke.
- Failure 단계: rollback job 또는 Windows dev 기준 복구 판단.
- Maven/package 성공은 deploy 성공이 아니며, Spring process startup과 `/readyz`까지 통과해야 한다.

## 8. Cutover 기준

Cutover는 [Azure cutover/rollback runbook](./azure-cutover-rollback.md)을 따른다.

- DNS/edge 변경 전 staging smoke가 모두 통과해야 한다.
- DB migration 이후 destructive rollback은 금지하고, forward fix 또는 snapshot restore 절차를 별도로 승인한다.
- Cloudflare tunnel 기반 Windows dev endpoint는 production cutover 전까지 fallback 기준으로 유지한다.

## 9. 진행 중 금지 사항

- secret 값 출력 또는 문서화
- `dev`/`main` 직접 push
- 승인 없는 Terraform `apply`
- 승인 없는 DNS/redirect URI 변경
- 승인 없는 DB destructive migration
- 앱 기능 PR과 runtime infra PR을 섞는 작업
