# Azure CI/CD runbook

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
| `deploy-staging.yml` | manual + approval | staging image build/push, apply, migration, smoke |
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

staging backend smoke는 Azure AD auth로 `3dt-final-team1` / `onmutfstatekrc001` / `tfstate` / `onmu/staging/terraform.tfstate`를 초기화한다. GitHub Actions workload identity에는 tfstate storage account scope의 `Storage Blob Data Contributor`와 resource group scope의 `Reader`가 필요하다.

Terraform staging provider는 `subscription_id` variable을 사용하므로, protected Wave plan/apply job은 `AZURE_SUBSCRIPTION_ID`와 `AZURE_TENANT_ID`를 값 출력 없이 `TF_VAR_subscription_id`, `TF_VAR_tenant_id`로 전달한다. `AZURE_*` 실제 값은 workflow log, PR, 문서에 출력하지 않는다.

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
- `key_vault`: Key Vault, user-assigned managed identity, Key Vault Secrets User role assignment.
- `redis`: Azure Cache for Redis Basic C0.
- `storage`: Blob Storage account, public tile/static container, private media container.
- `eventhubs`: Event Hubs Standard namespace, `notification-requested`, `worker-jobs`, consumer groups `worker`, `analytics`.
- `container_apps_environment`: ACA Environment만 생성.
- `diagnostics`: foundation 리소스 diagnostic setting을 Log Analytics로 연결.

`core_foundation`에서 명시적으로 제외한다.

- PostgreSQL Flexible Server
- Spring API Container App
- Worker Container App
- CDN/edge resource. Terraform foundation은 Blob origin까지만 만든다. Azure CDN classic 직접 생성 가능성 또는 Front Door Standard 전환은 후속 PR에서 결정한다.
- Key Vault secret value 작성
- DNS/custom domain 변경
- DB migration 실행

Plan summary가 Redis, Storage, Event Hubs, Key Vault, managed identity, ACA Environment, diagnostic settings 외의 create/update/delete를 포함하면 apply하지 않고 중단한다. Key Vault role assignment 생성 중 RBAC 권한이 부족하면 `User Access Administrator` 또는 `Role Based Access Control Administrator` 부여 여부를 별도 승인으로 분리한다.

### Staging DB/App Ready

`wave=db_and_app_ready`는 PostgreSQL Flexible Server와 Spring API/worker Container App을 만들 수 있는 선택지지만, 기본 실행 대상이 아니다. 아래 protected 값이 준비되고 사용자가 별도 승인할 때만 plan/apply한다.

- `STAGING_POSTGRES_ADMINISTRATOR_PASSWORD`
- `STAGING_SPRING_API_IMAGE`
- `STAGING_WORKER_IMAGE`

PostgreSQL admin password는 Terraform state에 sensitive value로 기록될 수 있다. 이 방식을 채택하기 전 사용자는 state 보관 리스크와 secret rotation 절차를 명시적으로 승인해야 한다. Spring API/worker app은 Key Vault reference만 사용하며 secret value는 Terraform code, plan 공유본, PR, workflow log에 출력하지 않는다.

`db_and_app_ready` 이후에도 staging 성공 판정은 Terraform apply 성공이 아니다. Clean DB + Flyway full migration, 실제 OAuth 로그인 기반 `/users/me`, `/healthz`, `/readyz`, Blob origin과 후속 edge/tile, Place/Search/Route, Notification/Event, Observability smoke까지 통과해야 한다.

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
