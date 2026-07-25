# Azure CI/CD runbook

> **상태**: 이 문서는 **정식 운영 target(검증된 관리형, Azure PaaS) 러북**이다. 현재 개발 단계 임시 운영은 VM 경로([`vm-hosting-migration-runbook.md`](./vm-hosting-migration-runbook.md))를 본다. 정식 운영 전환 시 이 러북을 따른다.


이 문서는 ONMU의 Terraform 기반 Azure 배포를 GitHub Actions로 연결할 때의 단계와 보호 장치를 정의한다.

## 1. 원칙

- `dev`와 `main`에 직접 push하지 않는다.
- PR에서는 validate/plan/test까지만 자동 수행한다.
- `terraform apply`, DB migration, production deploy는 protected environment approval 이후에만 수행한다.
- secret 값은 GitHub logs, PR body, artifact에 남기지 않는다.
- Windows deploy/runtime 문제와 Azure deploy 문제를 같은 원인으로 단정하지 않는다.
- Azure apply는 GitHub Actions OIDC/Workload Identity와 protected environment gate를 묶어 제어한다.

## 2. Workflow 후보

| Workflow | Trigger | 역할 |
| --- | --- | --- |
| `pr-check.yml` | PR | docs/secret scan, Spring/Flutter test, Docker build 후보 |
| `terraform-plan.yml` | PR 또는 manual | fmt/validate/plan, artifact 저장 |
| `terraform-staging.yml` | PR/push + manual | Terraform fmt/validate, protected staging backend init smoke, approved staging wave plan/apply |
| `build-staging-images.yml` | PR + manual | Spring API/worker Docker build, optional staging ACR push |
| `deploy-staging-api.yml` | `dev` push + manual | Spring API image build/push, ACA image rollout, staging API smoke |
| `deploy-staging.yml` | future candidate | worker, migration job, app phase orchestration을 하나로 묶는 후속 workflow 후보 |
| `deploy-prod.yml` | manual + approval | staging 검증 image digest 승격, production migration/cutover smoke |
| `smoke-staging.yml` | manual 또는 deploy 후 | smoke checklist 실행 |
| `rollback.yml` | manual + approval | previous revision/image/DNS rollback |

production은 자동 apply하지 않는다. `terraform plan -> approval -> apply -> infra readiness -> migration dry-run/check -> approval -> migration -> deploy -> smoke -> monitoring window` 순서를 기본 gate로 둔다.

Staging apply job은 GitHub Environment `azure-staging-apply`를 사용한다. Required reviewers와 branch 제한을 적용하고, plan identity와 apply identity/권한은 가능하면 분리한다. Workload Identity principal 실제 값은 GitHub protected variable 또는 environment secret으로만 관리하고 문서/로그/PR에는 출력하지 않는다.

현재 1차 연결은 `.github/workflows/terraform-staging.yml`이다. 이 workflow는 PR/push에서 `terraform fmt`, `terraform init -backend=false`, `terraform validate`만 수행한다. Azure OIDC login은 `workflow_dispatch`에서만 실행하며, `backend_smoke=true`일 때는 `azure-staging-apply` environment approval 뒤 staging backend init smoke만 수행한다. `wave` 입력을 선택하면 같은 protected environment approval 뒤 plan summary를 확인하고, `apply_wave=true`일 때만 별도 apply job을 실행한다. Raw plan/state/log 값은 출력하지 않고 resource type/action/count summary만 공유한다.

`azure-staging-apply` environment에는 아래 이름의 protected variable 또는 secret을 설정한다. 값은 문서, PR, workflow log에 출력하지 않는다.

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `STAGING_POSTGRES_ADMINISTRATOR_PASSWORD`
- `STAGING_SPRING_API_IMAGE`
- `STAGING_WORKER_IMAGE`

staging backend smoke는 Azure AD auth로 `3dt-final-team1` / `onmutfstatekrc001` / `tfstate` / `onmu/staging/terraform.tfstate`를 초기화한다. GitHub Actions workload identity에는 tfstate storage account scope의 `Storage Blob Data Contributor`와 resource group scope의 `Reader`가 필요하다.

Terraform staging provider는 `subscription_id` variable을 사용하므로, protected Wave plan/apply job은 `AZURE_SUBSCRIPTION_ID`와 `AZURE_TENANT_ID`를 값 출력 없이 `TF_VAR_subscription_id`, `TF_VAR_tenant_id`로 전달한다. `AZURE_*` 실제 값은 workflow log, PR, 문서에 출력하지 않는다.

staging/prod provider는 `resource_provider_registrations = "none"`을 사용한다. 현재 GitHub OIDC Workload Identity는 `3dt-final-team1` resource group 중심의 최소 권한으로 운영하므로, Terraform이 subscription scope에서 Azure Resource Provider auto-registration을 시도하면 plan/apply가 초기에 실패할 수 있다. 필요한 namespace는 운영자 또는 상위 권한 계정이 미리 등록해 둔 상태를 전제로 한다.

### Staging Wave 1: ACR + Observability

Wave 1은 앱 리소스 배포가 아니라 staging에서 이미 승인된 resource group `3dt-final-team1`에 최소 기반 리소스만 준비하는 단계다. `workflow_dispatch`에서 `wave=acr_observability`를 선택하면 protected environment 승인 뒤 plan summary를 확인한다. `apply_wave=true`를 함께 선택한 경우에만 별도 approval 이후 apply job이 실행된다.

Wave 1에서 켜는 Terraform module은 다음 두 개뿐이다.

- `container_registry`: Azure Container Registry Basic, admin user disabled
- `observability`: Log Analytics 30일 retention, workspace-based Application Insights

Wave 1에서 명시적으로 제외한다.

- PostgreSQL / Redis
- Blob Storage / CDN app assets
- Event Hubs
- Container Apps
- Key Vault secret value 작성
- DNS 변경
- DB migration

Plan과 apply job은 raw Terraform plan/state를 log나 artifact로 공유하지 않는다. 공유 가능한 결과는 resource type, action, count 중심의 summary다. Wave 1 성공 기준은 ACR, Log Analytics workspace, Application Insights가 생성되고 staging backend state에 기록되는 것이며, Spring app 배포 성공으로 보지 않는다.

### Staging Core Foundation

`workflow_dispatch`에서 `wave=core_foundation`을 선택하면 Wave 2~5 중 앱 secret/image 없이 안전하게 만들 수 있는 기반 리소스만 plan/apply한다. 기준은 기존 resource group `3dt-final-team1`, region `koreacentral`, 2026-06-26까지 총 1,000,000원 상한이다.

`core_foundation`에서 켜는 Terraform module은 다음이다.

- `observability`, `container_registry`: Wave 1 리소스를 유지하며 recreate하지 않는다.
- `key_vault`: Key Vault, user-assigned managed identity. Key Vault Secrets User role assignment은 `key_vault_rbac` wave로 분리한다.
- `storage`: Blob Storage account, public tiles/static container, private media container.
- `eventhubs`: Event Hubs Standard namespace, `notification-requested`, `worker-jobs`, consumer groups `worker`, `analytics`.
- `container_apps_environment`: ACA Environment만 생성.

`core_foundation`에서 명시적으로 제외한다.

- PostgreSQL Flexible Server
- Redis. `managed_redis_ready`와 `managed_redis_diagnostics` 전용 wave로 분리한다. Spring/Flutter 계약은 `REDIS_URL`, `SPRING_DATA_REDIS_URL`, 기존 Key Vault secret naming을 유지한다.
- Spring API Container App
- Worker Container App
- CDN/edge resource. Terraform foundation은 Blob origin까지만 만든다.
- Key Vault role assignment. Workload Identity에 RBAC assignment 권한이 없으면 실패하므로 `key_vault_rbac`에서 별도 승인 후 실행한다.
- Diagnostic settings. 신규 resource id는 plan 시점에 unknown이므로 리소스 생성 wave와 분리한다.
- Key Vault secret value 작성
- DNS/custom domain 변경
- DB migration 실행

Plan summary가 Storage, Event Hubs, Key Vault, managed identity, ACA Environment 외의 create/update/delete를 포함하면 apply하지 않고 중단한다. Storage account는 nested public item 허용을 켜되, 공개는 `tiles` container에만 제한하고 `media` container는 계속 private로 유지한다. Tile/static public delivery는 Front Door route, cache policy, Range/CORS smoke로 검증한다.

부분 apply 실패 뒤 Azure에는 `tiles` container가 존재하지만 remote state에는 없을 수 있다. 이 경우 재-apply 전에 raw state를 출력하지 않고 아래 address만 import한다.

```text
module.storage[0].azurerm_storage_container.tiles
```

Import 후 plan summary가 `azurerm_container_app_environment` create와 기존 리소스 no-op 중심인지 확인한다. `azurerm_storage_container` create가 계속 보이면 apply하지 않는다. `Terraform Staging` workflow도 `core_foundation`에서 `azurerm_storage_container` create를 감지하면 import gate 오류로 중단한다.

### Staging Key Vault RBAC

`wave=key_vault_rbac`는 runtime managed identity에 Key Vault Secrets User 역할을 연결하는 전용 wave다. 이 wave는 Workload Identity 또는 운영자가 resource group/Key Vault scope에서 role assignment를 만들 권한을 갖는지 확인한 뒤 실행한다.

Key Vault는 기존/재활용 vault를 사용할 수 있다. 현재 staging runtime secret source는 재사용 Key Vault를 기준으로 맞추고, Terraform이 기존에 만든 staging 전용 vault는 cleanup 승인 전까지 그대로 둔다. 이 경우에도 runtime managed identity가 secret reference를 읽으려면 재사용 Key Vault scope의 `Key Vault Secrets User` role assignment가 필요하다. Contributor 권한만으로 role assignment 생성이 막히면 apply를 반복하지 않는다. 속도 우선 기본값은 운영자가 기존 Key Vault scope에서 runtime managed identity에 `Key Vault Secrets User`를 수동 부여하는 것이다. IaC 일관성을 우선할 때만 Key Vault scope 한정 `Key Vault Data Access Administrator`, `User Access Administrator`, 또는 `Role Based Access Control Administrator` 부여를 별도 승인한다.

### Staging Core Diagnostics

`wave=core_diagnostics`는 `core_foundation` apply가 성공하고 remote state에 resource id가 기록된 뒤에만 실행한다. 이 wave는 foundation 리소스의 diagnostic setting을 Log Analytics로 연결한다.

`core_diagnostics`에서 기대하는 변경은 diagnostic setting create 중심이다. Storage, Event Hubs, Key Vault, managed identity, ACA Environment 자체가 create로 다시 잡히면 core foundation이 아직 적용되지 않았거나 state가 맞지 않는 상태이므로 apply하지 않고 중단한다.

ACA Environment는 foundation apply 이후 Azure state에 기본 `Consumption` workload profile이 기록될 수 있다. Terraform module도 같은 기본 profile을 명시적으로 유지해 `core_diagnostics`에서 environment update drift가 섞이지 않게 한다.

`frontdoor_tile_edge`처럼 diagnostics를 새로 만들지 않는 wave에서도, 이미 적용된 foundation diagnostic setting은 Terraform target 집합에 계속 포함해야 한다. 그렇지 않으면 Front Door plan이 기존 diagnostic setting delete를 같이 잡는다.

### Staging Managed Redis

`wave=managed_redis_ready`는 `core_foundation`, `core_diagnostics`, 그리고 Front Door를 쓰는 경우 `frontdoor_tile_edge`, `frontdoor_origin_access`, `frontdoor_diagnostics` 이후에 Azure Managed Redis만 별도로 생성한다. 이 wave는 기존 foundation, Front Door, diagnostic setting을 no-op/read로 유지한 채 `azurerm_managed_redis` create 1건만 허용한다.

`wave=managed_redis_diagnostics`는 Managed Redis resource id가 remote state에 기록된 뒤 diagnostic setting만 별도로 붙인다. 이 wave도 기존 foundation, Front Door, diagnostic setting은 no-op/read만 허용한다.

Managed Redis는 access key 인증을 켜서 현재 Spring의 `REDIS_URL`, `SPRING_DATA_REDIS_URL` 계약을 그대로 유지한다. 다만 Terraform이 Key Vault secret value를 직접 쓰지는 않는다. 운영자는 Managed Redis apply 후 Azure Portal 또는 승인된 운영 경로에서 access key를 확인하고, 재사용 runtime Key Vault의 기존 `staging-redis-url` secret value를 수동 갱신해야 한다.

AzureRM provider는 access key 인증을 켠 Managed Redis의 계산된 access key를 remote state에 보관할 수 있다. 따라서 이 wave는 state 접근 통제와 key rotation 절차를 별도 운영 gate로 둔다. PR 본문, workflow log, 문서에는 access key 실제 값을 기록하지 않는다.

App phase 전 사전 조건과 현재 병목은 [Azure ACA 앱 배포 사전 점검](./azure-aca-app-preflight.md)에 따로 정리한다. Terraform wave 설계와 Docker image 준비는 이 문서와 함께 본다.

### Staging App Phase Prework

`Build Staging Images` workflow는 두 용도로 사용한다.

- PR 단계: Spring API/worker Dockerfile이 실제로 빌드되는지 확인
- manual 단계: 승인 후 staging ACR에 image를 push하고, 결과 image ref를 `STAGING_SPRING_API_IMAGE`, `STAGING_WORKER_IMAGE`로 갱신할 준비

`Deploy Staging Spring API` workflow는 이미 `api_app_ready`로 Spring API Container App이 생성된 이후의 코드 변경 배포 경로다. `dev` merge 또는 manual dispatch에서 Spring API image를 staging ACR에 push하고, 기존 `ca-onmu-staging-krc-001-api`의 image만 새 revision으로 바꾼다. 배포 뒤 `/healthz`, `/readyz`, no-token `/api/v1/users/me=401` smoke가 모두 통과하면 `azure-staging-apply` environment variable `STAGING_SPRING_API_IMAGE`를 같은 image ref로 갱신해 후속 Terraform app wave가 이전 image로 되돌리지 않게 한다.

이 workflow가 새로 만들지 않는 것:

- PostgreSQL, Redis, Blob, Key Vault, ACA Environment 같은 인프라 리소스
- Key Vault secret value
- DB migration 전용 job
- worker Container App rollout
- DNS/custom domain/provider console 변경

현재 app rollout은 별도 orchestration workflow보다 `terraform-staging.yml`의 split wave를 우선 사용한다.

- `postgres_ready`
- `api_app_ready`
- `worker_app_ready`
- `place_reason_worker_ready`

이 순서를 쓰는 이유는 PostgreSQL, Spring API, worker를 각각 독립 approval과 smoke로 끊기 위해서다. `db_and_app_ready`는 호환용 alias로만 유지한다.

`place_reason_worker_ready`는 기존 API/worker Container App에 장소 추천 설명 worker wiring을 반영하는 patch wave다. API에는 ACA internal worker URL과 internal callback secretRef를, worker에는 Spring callback base URL, internal secretRef, Azure OpenAI place-reason secretRef, worker_ai DB secretRef를 연결한다. OOTD `azure_ml` provider 전환은 포함하지 않으며 `worker_ai_ready`와 분리한다. 이미 적용된 `ai_foundation` 리소스는 delete로 계획되지 않도록 keepalive 입력으로 유지하되, 이 wave에서 새 AI foundation resource create는 허용하지 않는다.

### Staging DB/App Ready

`wave=postgres_ready`, `wave=api_app_ready`, `wave=worker_app_ready`는 PostgreSQL Flexible Server와 Spring API/worker Container App을 순차적으로 만들기 위한 split wave다. 아래 protected 값이 준비되고 사용자가 별도 승인할 때만 plan/apply한다.

- `STAGING_POSTGRES_ADMINISTRATOR_PASSWORD`
- `STAGING_SPRING_API_IMAGE`
- `STAGING_WORKER_IMAGE`

PostgreSQL admin password는 Terraform state에 sensitive value로 기록될 수 있다. 이 방식을 채택하기 전 사용자는 state 보관 리스크와 secret rotation 절차를 명시적으로 승인해야 한다. Spring API/worker app은 Key Vault reference만 사용하며 secret value는 Terraform code, plan 공유본, PR, workflow log에 출력하지 않는다.

`postgres_ready`, `api_app_ready`, `worker_app_ready`도 신규 PostgreSQL/Container App resource id가 plan 시점에 unknown이므로 diagnostic setting을 동시에 만들지 않는다. App/DB diagnostic setting은 app resource 생성 이후 별도 diagnostics wave로 분리한다.

staging에서 PostgreSQL public access를 유지하는 동안 `postgres_ready`는 ACA environment static IP용 firewall rule create를 함께 포함할 수 있다. 이 rule이 없으면 이후 `api_app_ready`에서 Spring/Flyway가 DB connection timeout으로 기동 실패할 수 있다.

만약 `api_app_ready`가 먼저 부분 적용되어 Spring API Container App resource가 state에 생긴 뒤라면 `postgres_firewall_ready`를 별도로 사용한다. 이 remediation wave는 현재 Spring image ref를 유지한 채 PostgreSQL firewall rule만 추가하는 용도다.

현재 app phase의 운영 gate는 다음을 추가로 요구한다.

- runtime managed identity에 staging ACR scope `AcrPull`
- runtime managed identity에 재사용 Key Vault scope `Key Vault Secrets User`
- runtime managed identity에 Blob storage account scope `Storage Blob Data Contributor`
- presigned URL 유지를 위해 Blob storage account scope `Storage Blob Delegator`
- GitHub OIDC identity에 staging ACR `AcrPush`, Spring API Container App image update 권한, resource group read 권한
- Spring API plain env `OBJECT_STORAGE_PROVIDER=azure_blob`와 Blob endpoint/container secret reference 확인
- OAuth redirect/callback env가 ACA plain value가 아니라 재사용 Key Vault secretRef인지 확인
  - `KAKAO_OAUTH_REDIRECT_URI` -> `staging-kakao-oauth-redirect-uri`
  - `KAKAO_OAUTH_MOBILE_CALLBACK_URI` -> `staging-kakao-oauth-mobile-callback-uri`
  - `NAVER_OAUTH_REDIRECT_URI` -> `staging-naver-oauth-redirect-uri`
  - `NAVER_OAUTH_MOBILE_CALLBACK_URI` -> `staging-naver-oauth-mobile-callback-uri`
- `managed_redis_ready` apply와 `staging-redis-url` 수동 갱신이 끝났는지 확인
- Managed Redis 전환 후 `/readyz` 최종 200을 다시 확인

`db_and_app_ready`는 기존 호환용 alias로 유지하지만, 실제 운영 기준은 split wave다. 어느 경로를 쓰더라도 staging 성공 판정은 Terraform apply 성공이 아니다. Clean DB + Flyway full migration, 실제 OAuth 로그인 기반 `/users/me`, `/healthz`, `/readyz`, Blob origin과 후속 edge/tile, Place/Search/Route, Notification/Event, Observability smoke까지 통과해야 한다.

### Staging Front Door Tile Edge

`wave=frontdoor_tile_edge`는 Blob origin 이후 tile/static edge delivery를 Azure Front Door Standard로 구성하는 선택지다. 기본료가 발생하므로 `apply_wave=true` 실행 전 별도 비용 승인을 받아야 한다. 이 wave는 Managed Redis 이전 단계로 두고, Redis resource나 Redis diagnostic target을 함께 켜지 않는다.

`frontdoor_tile_edge`에서 켜는 Terraform module은 다음이다.

- `front_door`: Azure Front Door Standard profile, endpoint, Blob origin group/origin/route.
- `storage`: Blob origin을 참조한다. `core_foundation` apply 후에는 기존 state를 유지해야 하며 recreate하면 안 된다.

`frontdoor_tile_edge`에서 명시적으로 제외한다.

- Azure CDN Standard Microsoft classic 신규 생성
- Custom domain 연결
- TLS certificate/custom domain validation
- Front Door diagnostic settings
- DNS 변경
- production 적용

Plan summary가 Front Door Standard profile/endpoint/origin group/origin/route 외의 예상 밖 create/update/delete를 포함하면 apply하지 않고 중단한다. `frontdoor_tile_edge`는 foundation diagnostic setting을 no-op로 유지해야 하며 delete가 나오면 apply하지 않는다. staging 기준 Front Door route는 Blob account root가 아니라 `tiles` container를 `cdn_frontdoor_origin_path=/tiles`로 prefix해야 한다. Front Door가 아직 없는 환경이면 profile/endpoint/origin group/origin/route create만 허용하고, 이미 적용된 staging라면 `azurerm_cdn_frontdoor_route` update 1건만 허용한다. 현재 staging처럼 postgres, managed redis, Spring API, worker가 이미 state에 들어간 뒤에는 `frontdoor_tile_edge`, `frontdoor_origin_access`, `frontdoor_diagnostics` wave도 이 리소스들을 keepalive 입력으로 유지해야 하며 delete가 나오면 apply하지 않는다. Front Door diagnostic setting은 resource id가 remote state에 안정화된 뒤 별도 diagnostics wave에서 붙인다. Front Door 적용 후에는 `tiles` container 안에 `manifest.json`, `styles/onmu-light.json`, `pmtiles/korea-dev.pmtiles`가 실제로 업로드되어 있는지 먼저 확인하고, 그 다음 PMTiles Range 206, `Accept-Ranges`, `Content-Range`, `Access-Control-Allow-Origin`, `Access-Control-Expose-Headers`, cache-control, rollback 기준을 별도 smoke로 확인한다.

### Staging Front Door Origin Access

`wave=frontdoor_origin_access`는 이미 적용된 staging Front Door가 Blob origin에 익명으로 접근하고 browser tile smoke까지 통과할 수 있게 storage access boundary를 보정하는 patch wave다. 이 wave는 새 Front Door를 만들지 않고 기존 storage account와 `tiles` container만 수정한다. Managed Redis가 아직 없는 단계에서도 plan/apply가 성립하도록 Redis resource와 Redis diagnostic target은 함께 켜지 않는다.

기대 변경은 다음 중 필요한 범위로 제한한다.

- `azurerm_storage_account` update 1: nested public item 허용 또는 tile/static CORS rule 보정
- 선택적 `azurerm_storage_container` update 1: `tiles` container access를 `blob`으로 전환

기존 Front Door, foundation 리소스, diagnostic setting은 모두 no-op여야 한다. `media` container는 계속 private로 유지한다. Public tile/static은 credential 없이 읽는 자산이므로 Blob origin CORS는 `Access-Control-Allow-Origin: *`를 기본값으로 유지한다. 이유는 Front Door가 Blob origin의 CORS 응답 헤더를 object 단위로 캐시할 수 있어 origin allow-list를 그대로 쓰면 다른 caller origin에 잘못된 ACAO가 재사용될 수 있기 때문이다. release/pre-prod smoke는 local Flutter web origin(`localhost`/`127.0.0.1` 5173~5175)과 `staging-api.onmu.cloud` 요청을 기준으로 본다. `dev-api.onmu.cloud`와 `int-api.onmu.cloud`는 legacy/dev opt-in 경로를 명시 점검할 때만 추가 확인한다. exposed headers에는 `Accept-Ranges`, `Content-Length`, `Content-Range`, `Content-Type`, `ETag`, `Last-Modified`, `Cache-Control`을 유지한다. 예상 밖 create/delete나 다른 update가 보이면 apply하지 않는다.

### Staging Front Door Diagnostics

`wave=frontdoor_diagnostics`는 `frontdoor_tile_edge` apply가 성공하고, 필요 시 `frontdoor_origin_access` patch까지 끝난 뒤에 실행한다. 이 wave는 지원되는 Front Door scope의 diagnostic setting만 Log Analytics로 연결한다. 현재 staging 기준으로는 Front Door profile scope만 대상이다. 이 시점에도 Redis가 아직 없으면 Redis diagnostic target은 포함하지 않는다.

`microsoft.cdn/profiles/afdendpoints`는 diagnostic settings를 지원하지 않으므로 endpoint를 target에 포함하지 않는다. `frontdoor_diagnostics` plan summary에는 `azurerm_monitor_diagnostic_setting` create와 기존 resource no-op만 허용한다. Front Door profile/endpoint/origin group/origin/route create가 다시 잡히면 Front Door edge가 아직 적용되지 않았거나 state가 맞지 않는 상태이므로 apply하지 않는다.

## 3. PR 단계

PR에서 수행한다.

- `terraform fmt -check`
- `terraform validate`
- static policy check 후보
- Spring targeted tests
- Flutter analyze/test
- Docker image build
- docs link/secret scan
- Markdown UTF-8/encoding smoke 후보
- 문서 링크 존재 여부 후보

PR 단계에서는 수행하지 않는다.

- `terraform apply`
- production secret 변경
- DNS 변경
- DB destructive migration
- provider console 변경

## 4. Staging deploy 단계

1. 최신 base branch 확인
2. container image build
3. ACR push
4. Terraform plan review
5. protected environment approval
6. Terraform apply
7. infra readiness gate
8. DB migration job 실행
9. Spring rollout
10. Worker rollout
11. smoke checklist 실행
12. deploy summary 작성

Deploy summary에는 commit, image tag, environment, endpoint status, count, Azure resource name 같은 안전한 메타데이터만 포함한다.

## 5. Orchestration race guard

GitHub Actions는 Terraform이 만든 리소스가 실제로 준비되기 전에 Flyway나 app rollout이 먼저 접근하는 race condition을 막아야 한다.

권장 job 순서:

```text
terraform_plan
  -> protected_environment_approval
  -> terraform_apply
  -> infra_readiness_gate
  -> flyway_migration
  -> app_rollout
  -> smoke
```

`infra_readiness_gate`는 secret 값을 출력하지 않고 다음 상태만 확인한다.

- Terraform apply job이 성공했고 output artifact가 현재 commit/environment와 일치한다.
- PostgreSQL Flexible Server endpoint, database, extension 후보가 활성 상태다.
- migration job이 사용할 `DATABASE_URL` 또는 secret reference가 존재한다.
- Key Vault RBAC/secret reference 전파가 완료되어 runtime identity가 필요한 secret을 읽을 수 있다.
- Container Apps 또는 AKS runtime identity와 env binding 후보가 배포 대상 revision에 연결되어 있다.
- public traffic 전환 전 internal `/healthz` 또는 container readiness probe가 통과할 수 있는 네트워크 경로가 있다.

Flyway 실행 방식은 environment별로 하나만 선택한다.

- staging/production 권장: dedicated migration job을 먼저 실행하고, 성공 뒤 Spring rollout을 진행한다.
- 단순 dev/staging rehearsal 후보: Spring startup Flyway를 사용할 수 있지만 이 경우 별도 migration job을 동시에 실행하지 않는다.

두 방식이 동시에 같은 database를 찌르지 않도록 workflow `needs`와 environment lock을 둔다. migration이 실패하면 app rollout과 traffic cutover는 실행하지 않는다.

## 6. Production deploy 단계

Production은 staging smoke가 통과한 artifact/image를 승격한다.

- 새 image를 재빌드하지 않고 staging에서 검증한 digest를 우선 사용한다.
- production Key Vault secret 존재 여부와 managed identity 접근만 확인한다.
- migration은 dry-run/plan 성격의 사전 점검을 먼저 한다.
- traffic 전환 전 shadow smoke를 수행한다.
- cutover window와 rollback 담당자를 확정한다.

## 7. Migration job 기준

Spring DB schema는 Flyway가 관리한다.

- migration job은 Spring app image 또는 dedicated job image로 실행한다.
- migration logs에는 SQL parameter 값, 사용자 데이터, secret 값을 출력하지 않는다.
- migration version, status, duration, error type만 보고한다.
- 실패 시 app rollout 전에 중단한다.

## 8. Smoke job 기준

Smoke job은 [Azure smoke checklist](./azure-smoke-checklist.md)를 따른다.

Token이 필요한 API는 짧은 수명의 JWT를 job 내부에서만 생성하거나 approved secret reference를 사용한다. Authorization header와 token 값은 출력하지 않는다.

빌드 성공, container image push 성공, Terraform apply 성공은 각각 deploy 성공의 일부일 뿐이다. 최종 deploy 성공은 Spring startup, `/readyz`, public smoke, domain smoke까지 통과했을 때만 인정한다.

## 9. Documentation quality gate

운영 문서는 배포 절차의 일부이므로 PR 단계에서 다음을 후보로 검증한다.

- `docs/**/*.md`가 UTF-8로 저장되어 있는지 확인
- PowerShell과 zsh에서 한글이 깨지지 않는지 spot check
- GitHub 웹 렌더링에서 표/링크가 깨지지 않는지 확인
- 상대 링크가 존재하는지 확인
- secret/token/raw body 예시가 실제 값처럼 보이지 않는지 scan
- 문서에 쓰인 env var name이 `azure-secret-inventory.md`와 충돌하지 않는지 확인

## 10. 실패 분류

| 실패 유형 | 예시 | 우선 조치 |
| --- | --- | --- |
| Terraform | provider auth, quota, resource conflict | apply 중단, plan 수정 |
| Runtime | container crash, readiness fail | logs/health/readiness 확인 |
| Migration | Flyway fail, extension missing | DB 변경 중단, forward fix 판단 |
| Network/Edge | 502/530/1033, DNS, WAF | local/container health와 edge 분리 |
| App contract | API status/body schema mismatch | app PR 또는 rollback |
| Provider | OAuth/place/route external fail | provider console/secret/runtime 분리 |
