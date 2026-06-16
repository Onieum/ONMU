# Azure Terraform state backend bootstrap

이 문서는 ONMU Terraform state backend를 준비하기 위한 운영 기준이다. 목적은 앱 리소스가 아니라 Terraform state 저장소 준비다.

## 1. 범위

포함한다.

- tfstate 전용 resource group
- Azure Storage Account
- private blob container
- Azure Blob lease lock 사용 기준
- GitHub Actions 또는 운영자 RBAC
- naming/tagging
- backend config 예시

포함하지 않는다.

- 앱 Container Apps 생성
- PostgreSQL, Redis, Event Hubs, CDN 생성
- DNS 변경
- DB migration 실행
- Key Vault secret value 작성
- production apply

## 2. 리소스 기준

| 리소스 | 후보 |
| --- | --- |
| Subscription | `대한상공회의소 Data School` |
| Resource group | `3dt-final-team1` |
| Storage Account | `stonmutfstatekrc001` |
| Blob container | `tfstate` |
| Region | `koreacentral` |
| Replication | `LRS` |
| Staging state key | `onmu/staging/terraform.tfstate` |
| Prod state key | `onmu/prod/terraform.tfstate` |

Storage Account 이름은 전역 유일해야 하므로 실제 apply 전 `storage_account_name` suffix를 조정할 수 있다. Subscription id는 문서나 PR에 기록하지 않고, Azure CLI 또는 CI context에서 `대한상공회의소 Data School`을 선택한다.

## 3. Lock 기준

Terraform `azurerm` backend는 Azure Blob lease로 state lock을 잡는다.

- Staging과 prod는 같은 storage account/container를 사용하되 state key를 분리한다.
- 동시 apply는 blob lease lock으로 차단한다.
- lock이 남아 있는 경우에는 실행 중인 job이 없는지 확인한 뒤, Terraform CLI의 lock 처리 절차를 따른다.
- state file 또는 lease를 수동 삭제하지 않는다.

## 4. RBAC 기준

| Principal | Scope | Role |
| --- | --- | --- |
| 운영자 object id | tfstate storage account | `Storage Blob Data Contributor` |
| 운영자 object id | tfstate resource group | `Reader` |
| GitHub Actions workload identity principal object id | tfstate storage account | `Storage Blob Data Contributor` |
| GitHub Actions workload identity principal object id | tfstate resource group | `Reader` |

GitHub Actions OIDC federated credential 자체 생성은 별도 identity/CI PR에서 다룬다. 이 bootstrap module은 승인된 principal object id를 입력받아 role assignment만 만든다.

## 5. Backend config 예시

Staging:

```hcl
resource_group_name  = "3dt-final-team1"
storage_account_name = "stonmutfstatekrc001"
container_name       = "tfstate"
key                  = "onmu/staging/terraform.tfstate"
use_azuread_auth     = true
```

Production:

```hcl
resource_group_name  = "3dt-final-team1"
storage_account_name = "stonmutfstatekrc001"
container_name       = "tfstate"
key                  = "onmu/prod/terraform.tfstate"
use_azuread_auth     = true
```

초기화 예시:

```powershell
terraform init `
  -backend-config="resource_group_name=3dt-final-team1" `
  -backend-config="storage_account_name=stonmutfstatekrc001" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=onmu/staging/terraform.tfstate" `
  -backend-config="use_azuread_auth=true"
```

## 6. Apply 전 승인 gate

다음을 확인하기 전까지 `terraform apply`를 수행하지 않는다.

- Azure subscription 확인
- storage account name availability 확인
- `3dt-final-team1` resource group 사용 승인 확인
- 운영자 principal object id 승인
- GitHub Actions workload identity principal object id 승인
- tfstate resource group과 storage account naming 승인
- backend bootstrap apply window 승인
- rollback 또는 삭제 금지 기준 확인

## 7. Rollback/삭제 주의사항

- tfstate storage account와 container는 앱 리소스보다 오래 유지한다.
- staging/prod 앱 리소스 destroy와 tfstate backend destroy를 같은 작업으로 묶지 않는다.
- state file이 있는 storage container는 실수로 삭제하지 않는다.
- backend 리소스 삭제는 모든 environment state를 안전하게 이전한 뒤 별도 승인으로만 수행한다.

## 8. 검증

```powershell
cd infra\terraform\bootstrap\state-backend
terraform init -backend=false
terraform validate
```

검증 후 생성되는 `.terraform` 디렉터리와 `.terraform.lock.hcl`은 PR에 포함하지 않는다.
