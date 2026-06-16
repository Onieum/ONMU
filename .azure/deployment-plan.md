# ONMU Azure 배포 계획

상태: Draft - Terraform 전환 문서화 단계
기준 브랜치: `origin/dev`
목적: Windows dev backend에서 Azure staging/production으로 이동할 때 필요한 인프라, secret, 데이터, 배포, smoke, cutover 기준을 한곳에 모은다.

이 문서는 실제 Azure 리소스를 만들거나 변경하는 실행 문서가 아니다. Terraform `plan`/`apply`, DNS 전환, DB migration, secret 생성/갱신은 별도 승인 이후에만 수행한다.

## 1. 범위

포함한다.

- Terraform으로 관리할 Azure 리소스 후보
- local, Windows dev, integration-staging, Azure staging, Azure production 환경 차이
- Spring Main API, FastAPI Worker, tile/static asset, realtime/notification 경계
- Key Vault secret name과 env var name 인벤토리
- PostgreSQL/PostGIS, Redis, object storage, tile asset 이전 기준
- CI/CD, smoke, cutover, rollback runbook

포함하지 않는다.

- 실제 secret 값
- 실제 Terraform state backend 생성
- 실제 Azure 리소스 생성 또는 삭제
- DB 테이블/컬럼 schema 변경 SQL 작성
- provider 콘솔의 실제 key/code/state/token 값

## 2. 배포 방향 결정

초기 Azure staging은 운영 단순성을 우선해 Azure Container Apps를 1차 후보로 둔다. Production/portfolio 목표 구조는 AKS까지 확장 가능하게 설계한다.

| 영역 | Azure staging 1차 후보 | Production 목표 |
| --- | --- | --- |
| Edge | Azure Front Door 또는 Application Gateway WAF 후보 검증 | WAF + API Management |
| API ingress | Container Apps ingress | AKS Ingress 또는 Container Apps ingress |
| Main API | Spring Boot container | Spring Boot container |
| Worker | FastAPI Worker container, 필요 시 비활성 배포 | FastAPI Worker + async queue |
| DB | Azure Database for PostgreSQL Flexible Server + PostGIS | 동일, HA/backup 강화 |
| Cache | Azure Cache for Redis | 동일, SKU/zone 강화 |
| Object storage | Azure Blob Storage + Azure CDN | Azure Blob Storage + CDN, WAF/Front Door 후보 |
| Event/queue | Event Hubs 우선 | Event Hubs consumer group/checkpoint/replay 정책 강화 |
| Secret | Azure Key Vault + Managed Identity | 동일, RBAC/rotation 강화 |
| Observability | Log Analytics + Application Insights | SLO/alert/dashboard 강화 |

## 3. 기준 문서

- [Azure Terraform 전환 운영 가이드](../docs/operations/azure-terraform-migration.md)
- [Azure 환경 매트릭스](../docs/operations/azure-environment-matrix.md)
- [Terraform 리소스 소유권](../docs/architecture/terraform-resource-ownership.md)
- [Cloud resource comparison](../docs/architecture/cloud-resource-comparison.md)
- [Azure secret 인벤토리](../docs/operations/azure-secret-inventory.md)
- [Azure 데이터 이전 runbook](../docs/operations/azure-data-migration-runbook.md)
- [Azure runtime contract](../docs/operations/azure-runtime-contract.md)
- [Azure CI/CD runbook](../docs/operations/azure-ci-cd-runbook.md)
- [Azure smoke checklist](../docs/operations/azure-smoke-checklist.md)
- [Azure cutover/rollback runbook](../docs/operations/azure-cutover-rollback.md)
- [Current-to-target 아키텍처 인덱스](../docs/architecture/current-to-target-index.md)

## 4. 승인 게이트

| 단계 | 산출물 | 승인 전 금지 사항 |
| --- | --- | --- |
| 문서화 | 이 문서와 운영/아키텍처 문서 세트 | 리소스 생성, secret 값 출력 |
| Terraform skeleton | `infra/terraform` 구조, module 변수, backend 계획 | `terraform apply`, DNS 변경 |
| Staging plan | `terraform plan` 결과, 비용/권한 검토 | production 리소스 생성 |
| Staging apply | staging 리소스, migration dry-run, smoke 결과 | production traffic 전환 |
| Production plan | prod plan, rollback, cutover window | cutover 실행 |
| Cutover | smoke pass, DNS/edge 전환, rollback 대기 | DB destructive rollback |

## 5. 운영 원칙

- `dev`와 `main`에 직접 push하지 않는다.
- Terraform state, provider credentials, DB password, OAuth secret, JWT signing secret은 문서와 PR에 기록하지 않는다.
- Key Vault 문서에는 secret 값이 아니라 env var name과 secret name만 기록한다.
- Spring Main API는 인증/권한/트랜잭션/Flyway의 원장이다.
- FastAPI Worker는 AI/추천/분석/비동기 보조 역할이며, 모바일 앱이 직접 호출하지 않는다.
- Terraform은 Azure 리소스를 소유하고, DB schema는 Flyway/Alembic이 소유한다.
- Windows dev backend는 Azure staging cutover 전까지 rollback 기준으로 유지한다.
