# Azure tfstate bootstrap state migration runbook

> **상태**: 이 문서는 **정식 운영 target(검증된 관리형, Azure PaaS) 러북**이다. 현재 개발 단계 임시 운영은 VM 경로([`vm-hosting-migration-runbook.md`](./vm-hosting-migration-runbook.md))를 본다. 정식 운영 전환 시 이 러북을 따른다.


이 문서는 이미 생성된 Terraform state backend 리소스를 관리하는 bootstrap root module의 local state를 remote backend key로 이전하는 절차다. 앱 리소스 생성, DNS 변경, DB migration, Key Vault secret value 작성, production apply는 포함하지 않는다.

## 1. 고정 결정

| 항목 | 기준 |
| --- | --- |
| Resource group | `3dt-final-team1` |
| Storage Account | `onmutfstatekrc001` |
| Container | `tfstate` |
| Bootstrap state key | `onmu/bootstrap/tfstate-backend.tfstate` |
| Staging state key | `onmu/staging/terraform.tfstate` |
| Prod state key | `onmu/prod/terraform.tfstate` |
| Backend auth | Azure AD auth, storage account key 미사용 |

subscription ID, principal object ID, raw state, raw plan output은 문서, PR, 채팅, 로그 요약에 기록하지 않는다.

## 2. 사전 조건

- PR #168 이후 최신 `origin/dev` 기준 작업 tree를 사용한다.
- `infra/terraform/bootstrap/state-backend/terraform.tfstate` local state가 존재해야 한다.
- `tfstate` container가 private이고 Azure AD data-plane 접근이 가능해야 한다.
- `onmu/staging/terraform.tfstate`와 `onmu/prod/terraform.tfstate`는 이미 분리되어 있어야 한다.
- `onmu/bootstrap/tfstate-backend.tfstate`가 아직 없거나, 이전 migration 시도에서 실패한 상태가 아닌지 확인한다.
- `terraform apply`는 migration 전후 plan 요약 확인 전까지 수행하지 않는다.

## 3. Local state backup

backup은 repo 밖 또는 ignored 경로에만 둔다. 예:

```powershell
$stamp = Get-Date -Format "yyyyMMddHHmmss"
$backupRoot = Join-Path $env:TEMP "onmu-tfstate-bootstrap-backup-$stamp"
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
Copy-Item `
  -LiteralPath "infra\terraform\bootstrap\state-backend\terraform.tfstate" `
  -Destination (Join-Path $backupRoot "terraform.tfstate")
```

backup 파일 원문은 출력하거나 PR에 첨부하지 않는다.

## 4. Migration 명령

아래 명령은 사용자 승인 후에만 실행한다. 현재 `infra/terraform/bootstrap/state-backend` root module에는 active `backend "azurerm"` 선언을 커밋하지 않는다. migration 승인 시에만 git ignored 임시 파일 `backend.migration.local.tf`를 만들어 local state를 remote key로 옮긴다. 이번 runbook PR은 migration 절차와 backend config 값을 문서화할 뿐 실제 migration을 실행하지 않는다.

```powershell
cd infra\terraform\bootstrap\state-backend

$backendConfig = @'
terraform {
  backend "azurerm" {}
}
'@
[System.IO.File]::WriteAllText(
  (Join-Path (Get-Location) "backend.migration.local.tf"),
  $backendConfig,
  [System.Text.UTF8Encoding]::new($false)
)

terraform init -migrate-state -input=false `
  -backend-config="resource_group_name=3dt-final-team1" `
  -backend-config="storage_account_name=onmutfstatekrc001" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=onmu/bootstrap/tfstate-backend.tfstate" `
  -backend-config="use_azuread_auth=true"
```

Terraform이 state migration 여부를 묻는 경우, local state backup이 있고 backend config가 위 값과 일치할 때만 승인한다.

## 5. Migration 후 smoke

원문 state를 출력하지 않고 count/status만 확인한다.

```powershell
terraform state list | Measure-Object
terraform plan -input=false -no-color
```

공유 가능한 보고 범위:

- backend init exit status
- state resource count
- plan resource/action summary
- `tfstate` container blob key 존재 여부
- repo에 `.tfstate`, `.tfplan`, `.terraform/`, `.terraform.lock.hcl`이 tracked/staged 되지 않았는지

## 6. Blob key 확인

Azure AD data-plane 접근으로 key 분리만 확인한다.

```powershell
az storage blob list `
  --account-name onmutfstatekrc001 `
  --container-name tfstate `
  --auth-mode login `
  --query "[].name" `
  --output json
```

기대 key:

- `onmu/bootstrap/tfstate-backend.tfstate`
- `onmu/staging/terraform.tfstate`
- `onmu/prod/terraform.tfstate`

## 7. 실패와 rollback 기준

- `terraform init -migrate-state` 전에 실패하면 local state를 유지하고 원인만 수정한다.
- migration 중 실패하면 자동 삭제하지 않는다. `tfstate` container의 blob key 존재 여부와 local backup 존재 여부를 확인한 뒤 cleanup 승인을 받는다.
- remote bootstrap state가 생성됐지만 plan이 예상과 다르면 remote state를 수동 삭제하지 않는다. backup과 remote state를 보존하고 backend config/RBAC/provider 상태를 분리 진단한다.
- `CanNotDelete` lock은 migration 안정화 이후 별도 승인으로만 적용한다.

## 8. 후속 연결

bootstrap state migration이 완료되면 다음 PR에서 GitHub Actions Workload Identity와 protected environment `azure-staging-apply`를 연결한다. staging app infra apply는 ACR/observability, DB/Redis, Blob/CDN, Event Hubs, ACA 순서로 분리한다.
