# Terraform state backend bootstrap

이 root module은 ONMU Terraform state 저장소만 준비한다. 앱 리소스인 Container Apps, PostgreSQL, Redis, Event Hubs, CDN, DNS, Key Vault secret value는 만들지 않는다.

## 생성 후보

- tfstate 전용 resource group
- StorageV2 account
- private `tfstate` blob container
- 운영자와 GitHub Actions workload identity principal의 최소 RBAC

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

## Backend config 예시

Staging:

```hcl
resource_group_name  = "rg-onmu-tfstate-krc-001"
storage_account_name = "stonmutfstatekrc001"
container_name       = "tfstate"
key                  = "onmu/staging/terraform.tfstate"
use_azuread_auth     = true
```

Production:

```hcl
resource_group_name  = "rg-onmu-tfstate-krc-001"
storage_account_name = "stonmutfstatekrc001"
container_name       = "tfstate"
key                  = "onmu/prod/terraform.tfstate"
use_azuread_auth     = true
```

초기화 예시:

```powershell
terraform init `
  -backend-config="resource_group_name=rg-onmu-tfstate-krc-001" `
  -backend-config="storage_account_name=stonmutfstatekrc001" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=onmu/staging/terraform.tfstate" `
  -backend-config="use_azuread_auth=true"
```

## RBAC 기준

- 운영자와 GitHub Actions workload identity principal에는 storage account scope의 `Storage Blob Data Contributor`를 부여한다.
- 같은 principal에는 tfstate resource group scope의 `Reader`를 부여한다.
- GitHub Actions OIDC federated credential 생성은 이 module 범위가 아니다. 필요한 principal object id만 승인된 경로로 주입한다.

## 금지

- 앱 Container Apps 생성
- PostgreSQL/Redis/Event Hubs/CDN 생성
- DNS 변경
- DB migration 실행
- Key Vault secret value 작성
- production apply
