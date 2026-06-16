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

## 2.1 기존 RG 재사용 guardrails

현재 기본 경로는 `3dt-final-team1` resource group 재사용이다. 전용 RG 생성은 lifecycle/RBAC/삭제 방지 측면에서 권장될 수 있지만, 구독의 resource group 생성 제한 가능성이 있으므로 기본값으로 사용하지 않는다.

- `create_resource_group = false`를 기본으로 둔다.
- Storage Account scope에 RBAC를 부여해 state 접근 경계를 좁힌다.
- 공통 tag로 `managed_by = terraform-bootstrap`, `data_classification = internal`을 남긴다.
- 앱 리소스 destroy와 tfstate backend destroy를 같은 작업으로 묶지 않는다.
- 첫 bootstrap 실행은 remote backend가 아직 없으므로 local state와 `terraform init -backend=false` 기준으로 plan/apply한다.
- `create_state_container = false`를 사용하면 Storage Account와 RBAC만 먼저 만들고 private container 생성을 2단계로 미룰 수 있다.
- `enable_storage_account_delete_lock = true`는 별도 승인 후에만 켠다.

## 3. Lock 기준

Terraform `azurerm` backend는 Azure Blob lease로 state lock을 잡는다.

- Staging과 prod는 같은 storage account/container를 사용하되 state key를 분리한다.
- 동시 apply는 blob lease lock으로 차단한다.
- lock이 남아 있는 경우에는 실행 중인 job이 없는지 확인한 뒤, Terraform CLI의 lock 처리 절차를 따른다.
- state file 또는 lease를 수동 삭제하지 않는다.
- 선택적으로 Storage Account scope에 `CanNotDelete` management lock을 설정할 수 있다.

## 4. RBAC 기준

| Principal | Scope | Role |
| --- | --- | --- |
| 운영자 object id | tfstate storage account | `Storage Blob Data Contributor` |
| 운영자 object id | tfstate resource group | `Reader` |
| GitHub Actions workload identity principal object id | tfstate storage account | `Storage Blob Data Contributor` |
| GitHub Actions workload identity principal object id | tfstate resource group | `Reader` |

GitHub Actions OIDC federated credential 자체 생성은 별도 identity/CI PR에서 다룬다. 이 bootstrap module은 승인된 principal object id를 입력받아 role assignment만 만든다.

실제 apply 승인 전에는 `operator_principal_object_ids` 또는 `github_actions_principal_object_ids` 중 최소 하나 이상이 승인된 값으로 채워져 있어야 한다. 빈 principal list로 plan하면 RBAC role assignment가 생성되지 않아 backend 접근 검증이 무의미해질 수 있다. 또한 `shared_access_key_enabled = false`와 `storage_use_azuread = true`를 사용하므로 Terraform 실행 주체가 기존 resource group, subscription 또는 storage scope에서 `Storage Blob Data Contributor`와 동등한 data-plane 권한을 이미 갖고 있는지 확인한다.

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
- Storage Account 삭제 방지 lock 적용 여부 승인
- Terraform 실행 주체의 Azure AD/RBAC data-plane 권한 확인
- `operator_principal_object_ids` 또는 `github_actions_principal_object_ids` 승인값 주입 확인
- 첫 bootstrap plan은 local ignored path에만 저장하고, 공유는 resource/action 요약으로 제한
- backend bootstrap apply window 승인
- rollback 또는 삭제 금지 기준 확인

Apply 전 read-only preflight:

```powershell
.\scripts\windows\test-tfstate-backend-preflight.ps1
```

이 스크립트는 active subscription 이름, resource group 존재/location, storage account name availability 또는 기존 계정의 public access/shared key/TLS 설정만 확인한다. `terraform apply`는 수행하지 않는다.

## 6.1 RBAC propagation 2-phase fallback

Storage Account 생성, RBAC 부여, private container 생성을 같은 apply에서 처리하면 Azure RBAC 전파 지연 때문에 container 생성이 `403`으로 실패할 수 있다. 이 경우 아래 2-phase 경로로 되돌린다.

Phase 1:

- local state와 `terraform init -backend=false`를 사용한다.
- 승인된 principal object id를 로컬 tfvars 또는 protected CI 변수로 전달한다.
- `create_state_container = false`로 plan/apply한다.
- Storage Account, RBAC role assignment, 선택적 delete lock까지만 준비한다.

Phase 2:

- RBAC 전파가 끝났는지 Terraform 실행 주체의 data-plane 권한을 확인한다.
- `create_state_container = true`로 private `tfstate` container를 생성한다.
- backend config 예시로 `terraform init` smoke를 수행한다.
- raw plan output, principal 실제 값, subscription id는 채팅, 문서, PR 본문에 공유하지 않는다.

## 7. Rollback/삭제 주의사항

- tfstate storage account와 container는 앱 리소스보다 오래 유지한다.
- staging/prod 앱 리소스 destroy와 tfstate backend destroy를 같은 작업으로 묶지 않는다.
- state file이 있는 storage container는 실수로 삭제하지 않는다.
- backend 리소스 삭제는 모든 environment state를 안전하게 이전한 뒤 별도 승인으로만 수행한다.
- Storage Account delete lock이 활성화되어 있으면 lock 해제 자체를 별도 승인 작업으로 분리한다.

## 8. 검증

```powershell
cd infra\terraform\bootstrap\state-backend
terraform init -backend=false
terraform validate
```

검증 후 생성되는 `.terraform` 디렉터리와 `.terraform.lock.hcl`은 PR에 포함하지 않는다.
