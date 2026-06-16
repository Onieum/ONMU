# ONMU Terraform skeleton

이 디렉터리는 ONMU의 Azure staging/production 전환을 위한 Terraform skeleton이다. 실제 Azure 리소스 생성, DNS 전환, DB migration, Key Vault secret 값 작성은 이 PR의 범위가 아니다.

## 범위

- `environments/staging`, `environments/prod` 폴더 분리
- Azure Storage blob backend 기준 선언
- module interface와 output 정의
- Spring Main API, optional Worker, PostgreSQL/PostGIS, Redis, Blob + CDN, Event Hubs, Key Vault, observability 리소스 경계 표현
- secret 값이 아니라 env var name, Key Vault secret name, secret URI reference만 사용
- WAF 검토와 승인 게이트는 `.azure/staging-waf-review.md`, `.azure/infrastructure-plan.json`에 기록

이번 확정 결정은 `environments/staging` 기준이다. `environments/prod`는 production hardening 후보를 표현하는 placeholder이며, 별도 production approval, 비용 산출, private networking/DNS/cutover gate 전에는 apply하지 않는다.

## 관련 계획 문서

| 문서 | 역할 |
| --- | --- |
| [Azure staging plan](../../.azure/staging-plan.md) | staging 리소스 후보와 Terraform module/environment 구조 |
| [Azure staging smoke checklist](../../docs/operations/azure-staging-smoke-checklist.md) | staging 성공 판정 smoke gate |
| [Azure staging data rehearsal plan](../../docs/operations/azure-staging-data-rehearsal.md) | PostgreSQL, Redis, Blob/CDN 이전 rehearsal 기준 |
| [Azure staging cost and permission review](../../docs/operations/azure-cost-permission-review.md) | 비용 산출 항목과 권한 경계 |
| [Azure Terraform state backend bootstrap](../../docs/operations/azure-terraform-state-backend.md) | `대한상공회의소 Data School` subscription과 `3dt-final-team1` resource group 기준 storage account, blob container, RBAC, optional delete lock, 2-phase fallback 기준 |
| [Azure tfstate bootstrap apply runbook](../../docs/operations/azure-tfstate-bootstrap-apply-runbook.md) | apply 전 read-only 확인, budget gate, phase 1/2, Workload Identity 후속 계획 |

## 금지

- `terraform apply`
- DNS 변경
- Key Vault secret value 작성
- DB table/index/column DDL 작성
- OAuth code/state/idToken, DB password, provider secret 값을 파일이나 PR 본문에 기록

## 로컬 검증

Terraform CLI가 설치되어 있으면 다음을 실행한다.

```powershell
cd infra\terraform
terraform fmt -recursive

cd environments\staging
terraform init -backend=false
terraform validate
terraform plan -refresh=false -var-file=terraform.tfvars.example
```

`terraform plan`은 Azure provider 인증과 실제 subscription 권한이 필요할 수 있다. plan 결과를 공유할 때도 secret value, provider token, connection string, 사용자 데이터는 출력하지 않는다. `TF_VAR_postgres_administrator_password` 값은 로컬 shell 또는 protected CI secret으로만 주입하고 파일에 기록하지 않는다.

## state/backend 기준

- `environments/staging/backend.tf`, `environments/prod/backend.tf`는 `azurerm` backend만 선언한다.
- 실제 backend config 값은 `terraform init -backend-config=...` 또는 CI secret으로 주입한다.
- 확정 state key 형식:
  - staging: `onmu/staging/terraform.tfstate`
  - prod: `onmu/prod/terraform.tfstate`
- backend용 Storage Account, container, RBAC bootstrap은 `bootstrap/state-backend` root module로 앱 리소스와 분리하며, 기본 target resource group은 `3dt-final-team1`이다.
- 첫 backend bootstrap은 remote backend가 없으므로 local state와 `terraform init -backend=false`로 plan한다.
- Azure AD/RBAC 전파 지연이 있으면 `create_state_container=false`로 Storage Account와 RBAC를 먼저 적용하고, 권한 전파 확인 후 container를 생성한다.
- backend 리소스 생성은 별도 사용자 승인 전까지 보류한다.

## 다음 gate

1. Azure subscription/account name 확인과 `onmutfstatekrc001`부터 storage name availability 확인
2. 2026-06-26까지 총 1,000,000원 상한 기준 budget impact 확인
3. Terraform state backend bootstrap 승인, read-only preflight, 승인된 principal object id, 실행 주체 data-plane 권한, `bootstrap/state-backend` phase 1/2 apply window 승인
4. Workload Identity + GitHub Environment `azure-staging-apply` 후속 CI PR
5. ACR 신규 생성과 Azure Pricing Calculator 기준 staging 비용 산출
6. Blob CDN Range/CORS/purge/rollback smoke 기준 확정
7. Event Hubs `worker`/`analytics` consumer group, checkpoint storage, replay smoke 기준 확정
8. provider console redirect/package/SHA-1 확인
9. `staging-api.onmu.cloud` DNS/provider console 연결 승인
10. Windows dev backend smoke를 rollback 기준으로 유지
