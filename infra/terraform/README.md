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
- backend용 Storage Account, container, RBAC, Managed Identity bootstrap은 앱 리소스 skeleton PR과 분리한다.
- backend 리소스 생성은 별도 사용자 승인 전까지 보류한다.

## 다음 gate

1. Azure subscription과 resource naming suffix 확정
2. Terraform state backend bootstrap 승인
3. Azure Pricing Calculator 기준 staging 비용 산출
4. Blob CDN Range/CORS/purge/rollback smoke 기준 확정
5. Event Hubs consumer group, checkpoint storage, replay smoke 기준 확정
6. provider console redirect/package/SHA-1 확인
7. `staging-api.onmu.cloud` DNS/provider console 연결 승인
8. Windows dev backend smoke를 rollback 기준으로 유지
