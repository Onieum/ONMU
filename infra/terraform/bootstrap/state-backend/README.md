# Terraform state backend bootstrap

이 root module은 ONMU Terraform state 저장소만 준비한다. 앱 리소스인 Container Apps, PostgreSQL, Redis, Event Hubs, CDN, DNS, Key Vault secret value는 만들지 않는다.

## 생성 후보

- 승인된 subscription: `대한상공회의소 Data School`
- 승인된 resource group: `3dt-final-team1`
- StorageV2 account
- private `tfstate` blob container
- 운영자와 GitHub Actions workload identity principal의 최소 RBAC

기본값은 기존 `3dt-final-team1` resource group을 사용한다. 별도 tfstate 전용 resource group을 새로 만들려면 `create_resource_group = true`로 바꾸고 별도 승인을 받아야 한다.

첫 bootstrap은 remote backend가 아직 없으므로 local state와 `terraform init -backend=false` 기준으로 plan한다. Plan 파일이 필요하면 로컬 ignored path에만 만들고, PR/채팅에는 resource/action 요약만 공유한다.

Azure AD data-plane RBAC 전파 지연이 의심되면 `create_state_container = false`로 Storage Account와 RBAC를 먼저 준비한 뒤, 권한 전파 확인 후 `create_state_container = true`로 private container를 만드는 2-phase fallback을 사용한다.

Storage Account 삭제 방지 lock은 `enable_storage_account_delete_lock = true`로 켤 수 있지만, 최초 bootstrap apply 전 별도 승인이 필요하다.

## Blob lease lock 기준

Terraform `azurerm` backend는 Azure Blob lease를 사용해 state lock을 잡는다. Staging과 prod는 같은 storage account/container를 사용할 수 있지만 state key를 분리한다.

| 환경 | State key |
| --- | --- |
| staging | `onmu/staging/terraform.tfstate` |
| prod | `onmu/prod/terraform.tfstate` |

## 로컬 검증

```powershell
cd infra\terraform\bootstrap\state-backend
terraform init -backend=false
terraform validate
```

`terraform apply`는 별도 사용자 승인 전까지 수행하지 않는다.

Apply 전 read-only preflight:

```powershell
# repo root에서 실행
.\scripts\windows\test-tfstate-backend-preflight.ps1
```

## Backend config 예시

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

로컬에서 apply가 승인된 경우 먼저 Azure CLI 또는 CI context가 `대한상공회의소 Data School` subscription을 가리키는지 확인한다. Subscription id 값은 문서나 PR에 기록하지 않는다.

## RBAC 기준

- 운영자와 GitHub Actions workload identity principal에는 storage account scope의 `Storage Blob Data Contributor`를 부여한다.
- 같은 principal에는 tfstate resource group scope의 `Reader`를 부여한다.
- GitHub Actions OIDC federated credential 생성은 이 module 범위가 아니다. 필요한 principal object id만 승인된 경로로 주입한다.
- 실제 apply 승인 전에는 `operator_principal_object_ids` 또는 `github_actions_principal_object_ids` 중 최소 하나 이상이 승인된 값으로 채워져 있어야 한다.
- `shared_access_key_enabled = false`와 provider `storage_use_azuread = true` 경로이므로 Terraform 실행 주체도 `Storage Blob Data Contributor` 또는 동등한 data-plane 권한을 미리 확인한다.

## 금지

- 앱 Container Apps 생성
- PostgreSQL/Redis/Event Hubs/CDN 생성
- DNS 변경
- DB migration 실행
- Key Vault secret value 작성
- production apply
