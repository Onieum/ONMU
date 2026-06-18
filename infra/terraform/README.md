# ONMU Terraform skeleton

이 디렉터리는 ONMU의 Azure staging/production 전환을 위한 Terraform skeleton이다. 실제 Azure 리소스 생성, DNS 전환, DB migration, Key Vault secret 값 작성은 이 PR의 범위가 아니다.

## 범위

- `environments/staging`, `environments/prod` 폴더 분리
- Azure Storage blob backend 기준 선언
- module interface와 output 정의
- Spring Main API, optional Worker, PostgreSQL/PostGIS, Redis, Blob, Front Door tile/static edge 후보, Event Hubs, Key Vault, observability 리소스 경계 표현
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
| [Azure tfstate bootstrap state migration runbook](../../docs/operations/azure-tfstate-bootstrap-state-migration.md) | bootstrap local state를 `onmu/bootstrap/tfstate-backend.tfstate` remote key로 이전하는 승인 운영 절차 |
| [Azure ACA 앱 배포 사전 점검](../../docs/operations/azure-aca-app-preflight.md) | ACR image, AcrPull, Key Vault secret reference, Redis/object storage 병목, app split wave 기준 |

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

staging/prod provider는 `resource_provider_registrations = "none"`으로 고정한다. ONMU staging GitHub OIDC identity는 resource group 범위 최소 권한을 유지하므로, subscription scope Resource Provider auto-registration을 Terraform에 맡기지 않는다. 필요한 Azure namespace는 운영자 또는 상위 권한 계정이 사전에 등록해 둔다.

Staging Wave 1은 적용 완료된 기준으로 본다. `environments/staging/terraform.tfvars.example`의 기본 feature flag는 기존 resource group `3dt-final-team1`을 재사용하고 `observability`, `container_registry`만 켠다.

후속 GitHub Actions wave는 다음 입력으로 선택한다.

- `acr_observability`: ACR Basic, Log Analytics 30일 retention, workspace-based Application Insights.
- `core_foundation`: Blob Storage origin, Event Hubs Standard, Key Vault, user-assigned managed identity, ACA Environment.
- `key_vault_rbac`: runtime managed identity에 Key Vault Secrets User role assignment 연결. RBAC assignment 권한 승인 후 실행.
- `core_diagnostics`: `core_foundation` apply 후 foundation 리소스 diagnostic setting을 Log Analytics로 연결.
- `managed_redis_ready`: Azure Managed Redis만 별도 생성한다.
- `managed_redis_diagnostics`: Managed Redis diagnostic setting만 별도 생성한다.
- `frontdoor_tile_edge`: Azure Front Door Standard profile/endpoint/origin group/origin/route. 기본료 발생으로 apply 전 별도 비용 승인 필요. staging 기준 route는 Blob `tiles` container를 `origin_path=/tiles`로 prefix한다. 이미 Front Door가 적용된 staging에서는 이 wave가 `azurerm_cdn_frontdoor_route` update 1건으로 수렴할 수 있다.
- `frontdoor_origin_access`: 기존 staging Blob origin의 `tiles` public access와 tile/static browser CORS boundary를 보정하는 patch wave. 현재 state에 따라 storage account update 1건만 나올 수도 있고, `tiles` container access correction이 필요하면 container update 1건이 함께 나올 수 있다. public tile/static은 Front Door cache와 충돌하지 않게 wildcard CORS(`Access-Control-Allow-Origin: *`)를 기본값으로 둔다.
- `frontdoor_diagnostics`: `frontdoor_tile_edge` apply 후 지원되는 Front Door scope의 diagnostic setting을 Log Analytics로 연결. 현재 staging 기준으로는 profile scope만 대상이다.
- `postgres_ready`: PostgreSQL Flexible Server와 database/extension만 먼저 적용한다.
- `api_app_ready`: Spring API Container App만 적용한다.
- `worker_app_ready`: worker Container App만 적용한다.
- `ai_foundation`: OOTD AI generation을 위한 Azure ML Workspace, Azure OpenAI-compatible vision account, optional vision deployment, worker runtime RBAC, worker AI env/secret reference를 준비한다. 기본값은 꺼져 있으며, `storage`, `observability`, `container_registry`가 먼저 준비되어 있어야 한다.
- `db_and_app_ready`: 기존 호환용 alias다. 실제 운영 순서는 split wave를 기준으로 본다.

Spring API/worker image는 `.github/workflows/build-staging-images.yml`에서 먼저 build하고, 필요 시 protected environment approval 뒤 staging ACR에 push한다. 최초 `api_app_ready`, `worker_app_ready`는 image ref를 `STAGING_SPRING_API_IMAGE`, `STAGING_WORKER_IMAGE`로 갱신한 뒤 실행한다.

Spring API Container App이 이미 생성된 뒤의 일반 코드 변경 배포는 `.github/workflows/deploy-staging-api.yml`을 사용한다. 이 workflow는 Spring API image를 staging ACR에 push하고 기존 ACA Spring API revision의 image만 갱신한 뒤 smoke를 수행한다. Terraform app wave는 인프라 wiring, 최초 app 생성, worker rollout처럼 resource graph 변경이 필요한 경우에 사용한다.

`ai_foundation`은 OOTD 생성 기능의 실제 모델 호출을 위한 foundation wave다. 이 wave는 Azure ML Workspace와 Vision 계정을 만들고, worker managed identity가 Blob, Event Hubs, Azure ML, Vision 리소스에 접근할 수 있는 RBAC 경계를 준비한다. 단, Hugging Face token, Azure ML endpoint key, Vision API key 같은 secret value는 Terraform state에 넣지 않는다. Terraform은 Key Vault secret name과 Container Apps secret reference만 선언하고, 값 주입은 운영자가 Key Vault에서 별도 수행한다.

`ootd_generation_provider`의 기본값은 `mock`이다. 따라서 `ai_foundation`을 켜지 않아도 worker mock pipeline, Spring job API, Flutter polling UI는 먼저 구현하고 검증할 수 있다. 실제 Azure ML 호출이 필요할 때만 `ootd_generation_provider = "azure_ml"`로 바꾸고 아래 secret이 Key Vault에 존재하는지 확인한다.

| Env var | Staging Key Vault secret name 후보 | 비고 |
| --- | --- | --- |
| `ONMU_HF_TOKEN` | `staging-hf-token` | Hugging Face gated model 접근 token. secret value는 Terraform에 쓰지 않는다. |
| `ONMU_OOTD_MODEL_ID` | `staging-ootd-model-id` | Hugging Face model id. MVP 기본값은 `black-forest-labs/FLUX.1-Kontext-dev`로 주입한다. |
| `ONMU_OOTD_MODEL_REVISION` | `staging-ootd-model-revision` | Hugging Face model revision. full commit SHA로 주입한다. |
| `ONMU_AZUREML_ENDPOINT_URL` | `staging-azureml-endpoint-url` | Azure ML Managed Online Endpoint URL. |
| `ONMU_AZUREML_ENDPOINT_KEY` | `staging-azureml-endpoint-key` | Endpoint key를 쓰는 경우의 secret. 가능하면 managed identity 전환을 후속으로 검토한다. |
| `ONMU_VISION_API_KEY` | `staging-vision-api-key` | Vision 모델 호출 key. |

`ONMU_OOTD_MODEL_ID`, `ONMU_OOTD_MODEL_REVISION`은 secret 값은 아니지만 Key Vault secretRef로 관리한다. FLUX.1-Kontext-dev는 non-commercial license이므로, 상업 배포 또는 production service phase에서 모델 교체가 필요할 수 있기 때문이다. `ONMU_VISION_MODEL_DEPLOYMENT`는 Azure OpenAI deployment name으로 현재 plain runtime config에 둔다.

`core_foundation`은 Redis, PostgreSQL, Spring API Container App, worker Container App, CDN/edge, RBAC role assignment, diagnostics, DNS, DB migration, Key Vault secret value 작성을 포함하지 않는다. Terraform은 Blob origin까지만 만든다. Storage account는 nested public item 허용을 켜고, `tiles` container만 public blob access를 허용하며 `media` container는 private로 유지한다. Public tile/static delivery는 Front Door wave에서 검증한다. Edge는 `frontdoor_tile_edge` wave에서 Azure Front Door Standard로 별도 plan/apply한다. staging Front Door route는 Blob account root가 아니라 `tiles` container를 `origin_path=/tiles`로 바라본다. 따라서 edge smoke 전에는 `tiles` container 안에 `manifest.json`, `styles/onmu-light.json`, `pmtiles/korea-dev.pmtiles` 같은 공개 tile object가 실제로 업로드되어 있어야 한다. 기존 staging state가 private `tiles`를 이미 가졌거나 browser CORS가 빠져 있으면 `frontdoor_origin_access` patch wave로 storage account와 `tiles` access/CORS boundary를 보정한다. Diagnostic setting은 신규 resource id가 remote state에 기록된 뒤 별도 diagnostics wave로 붙인다. Front Door wave에서도 이미 적용된 foundation diagnostic target은 no-op로 유지해야 하며 delete되면 안 된다. Redis는 `managed_redis_ready`, `managed_redis_diagnostics` 전용 wave로 분리한다.

## state/backend 기준

- `environments/staging/backend.tf`, `environments/prod/backend.tf`는 `azurerm` backend만 선언한다.
- 실제 backend config 값은 `terraform init -backend-config=...` 또는 CI secret으로 주입한다.
- 확정 state key 형식:
  - bootstrap: `onmu/bootstrap/tfstate-backend.tfstate`
  - staging: `onmu/staging/terraform.tfstate`
  - prod: `onmu/prod/terraform.tfstate`
- backend용 Storage Account, container, RBAC bootstrap은 `bootstrap/state-backend` root module로 앱 리소스와 분리하며, 기본 target resource group은 `3dt-final-team1`이다.
- 첫 backend bootstrap은 remote backend가 없으므로 local state와 `terraform init -backend=false`로 plan한다.
- bootstrap local state migration은 별도 승인 후 git ignored `backend.migration.local.tf`를 사용해 `onmu/bootstrap/tfstate-backend.tfstate`로 이전한다.
- Azure AD/RBAC 전파 지연이 있으면 `create_state_container=false`로 Storage Account와 RBAC를 먼저 적용하고, 권한 전파 확인 후 container를 생성한다.
- backend 리소스 생성은 별도 사용자 승인 전까지 보류한다.

## 다음 gate

1. `core_foundation` plan-only에서 예상 resource/action summary 확인
2. `tiles` container가 partial apply로 이미 존재하지만 state에 없으면 remote state import 후 plan 재확인
3. `core_foundation` apply 승인과 적용 후 Blob/Event Hubs/Key Vault/ACA Environment smoke
4. `key_vault_rbac` 전 RBAC assignment 권한 승인 또는 운영자 수동 role assignment 결정
5. `core_diagnostics` plan/apply 승인과 diagnostic setting smoke
6. `managed_redis_ready` plan/apply 승인과 Azure Managed Redis 생성 확인
7. 운영자가 `staging-redis-url`을 수동 갱신하고, state 접근 통제와 access key rotation 절차를 정리
8. `managed_redis_diagnostics` plan/apply 승인과 Redis diagnostic setting smoke
9. Front Door Standard 기본료와 egress/request 비용 승인 후 `frontdoor_tile_edge` plan/apply 여부 결정
10. 기존 staging Blob origin이 private tiles로 남아 있으면 `frontdoor_origin_access` plan/apply와 Front Door default endpoint smoke 수행
11. `frontdoor_diagnostics` plan/apply 승인과 diagnostic setting smoke
12. Cost Management 조회 권한 또는 비용 확인 담당자 확정
13. `postgres_ready` 전 protected Postgres password 승인과 state rotation 절차 결정
14. `api_app_ready` 전 ACR push image ref, runtime identity의 `AcrPull`, 재사용 Key Vault의 `Key Vault Secrets User` 확인
15. Spring object storage adapter와 `/readyz`의 MinIO-compatible 전제 유지 여부 또는 Azure Blob 전환 방향 결정
16. `worker_app_ready` 전 worker image ref와 queue/runtime scope 확인
17. `ai_foundation` 전 Azure ML GPU quota, Vision model availability, FLUX.1-Kontext-dev license scope, Key Vault secret 존재 여부 확인
18. `ai_foundation` plan/apply 승인 후 Azure ML Workspace, Vision endpoint, worker RBAC, mock/azure_ml provider 전환 smoke 확인
19. Clean DB + Flyway full migration smoke 기준 확정
20. ACA Spring API/worker rollout 후 실제 OAuth smoke를 승격 기준으로 사용
21. Front Door PMTiles Range/CORS/purge/rollback smoke 기준 확정
22. Event Hubs `worker`/`analytics` consumer group, checkpoint storage, replay smoke 기준 확정
23. provider console redirect/package/SHA-1 확인
24. `staging-api.onmu.cloud` DNS/provider console 연결 승인
25. Windows dev backend smoke를 rollback 기준으로 유지

`core_diagnostics`가 foundation 리소스 create/update를 다시 만들지 않게 하려면, ACA Environment의 기본 `Consumption` workload profile이 Terraform module에도 명시되어 있어야 한다. 그렇지 않으면 diagnostics wave에서 environment update drift가 섞일 수 있다.
