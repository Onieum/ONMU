# Azure staging plan

이 문서는 ONMU Azure staging 전환을 위한 plan-only 실행 기준이다. 실제 Azure 리소스 생성, `terraform apply`, DNS 변경, DB migration, Key Vault secret value 작성은 별도 승인 전까지 수행하지 않는다.

## 1. 확정 기준

| 항목 | 선택 |
| --- | --- |
| Azure region | `koreacentral` |
| Runtime platform | Azure Container Apps |
| Terraform state backend | Azure Storage blob backend |
| Tile/static public delivery | Blob Storage + Azure CDN Standard Microsoft |
| Event/analytics fan-out | Event Hubs Standard |
| PostgreSQL Flexible Server | Burstable `B_Standard_B1ms` |
| Redis | Basic C0 |
| Container Apps scale | Spring API min 1, worker min 0 |
| Networking | Public ingress + Key Vault reference |
| Secret management | Key Vault RBAC + managed identity |
| DB migration strategy | Clean DB full Flyway migration |
| Domain target | `staging-api.onmu.cloud` |

Spring Main API는 인증, 권한, 트랜잭션, Flyway 원장 역할을 유지한다. DB schema는 Terraform이 아니라 Flyway가 소유한다. Terraform은 Azure resource, identity, RBAC, diagnostic setting, app setting reference를 소유한다.

## 2. Staging 리소스 계획

| 영역 | Staging 후보 | Terraform 소유 경계 |
| --- | --- | --- |
| Resource group | 기존 `3dt-final-team1` resource group | Terraform은 기본적으로 생성하지 않고 기존 RG를 참조한다. 전용 RG는 구독 정책이 허용될 때 후속 후보 |
| Identity | user-assigned managed identity | Container Apps, Key Vault, Storage, Event Hubs 접근 role assignment |
| Key Vault | RBAC 기반 vault | vault, RBAC, secret reference name. secret value는 제외 |
| Runtime | Container Apps Environment, Spring API Container App, optional worker | app, revision, ingress, scale, env var name, secret reference |
| Registry | Azure Container Registry Basic 신규 생성 | registry와 pull 권한 |
| PostgreSQL | Flexible Server `B_Standard_B1ms`, database, PostGIS 전제 | server/database/extension allow path. schema DDL은 제외 |
| Redis | Basic C0 | cache instance와 secret reference |
| Blob Storage | public tile/static container, private media container, checkpoint container | account, container, lifecycle/versioning 후보, RBAC |
| CDN | Azure CDN Standard Microsoft profile/endpoint | profile, endpoint, origin, cache rule 후보 |
| Event Hubs | Standard namespace, event hubs, consumer groups | namespace, hub, consumer group, RBAC |
| Observability | Log Analytics, Application Insights, diagnostic settings | workspace, app insights, diagnostics, retention 후보 |
| Cost guard | budget/cost alert 후보 | 후속 승인 전까지 문서 후보 |

## 3. Terraform 구조 제안

현재 skeleton은 `infra/terraform/environments/staging`과 `infra/terraform/environments/prod`를 분리한다. Staging plan은 다음 module 경계를 유지한다.

```text
infra/terraform/
  environments/
    staging/
    prod/
  modules/
    naming/
    resource-group/
    observability/
    key-vault/
    container-registry/
    postgres/
    redis/
    storage/
    cdn/
    eventhubs/
    container-apps/
    diagnostic-settings/
    network/
    edge/
```

State backend는 Azure Storage blob backend로 고정하되, backend bootstrap 리소스 생성은 별도 PR과 승인으로 분리한다. State key는 다음 형식을 목표로 한다.

| 환경 | State key 후보 |
| --- | --- |
| staging | `onmu/staging/terraform.tfstate` |
| prod | `onmu/prod/terraform.tfstate` |

Backend bootstrap 세부 기준은 [Azure Terraform state backend bootstrap](../docs/operations/azure-terraform-state-backend.md)과 `infra/terraform/bootstrap/state-backend` root module을 따른다. 첫 bootstrap은 remote backend가 없으므로 local state와 `terraform init -backend=false`로 진행하며, 실제 apply 승인 전에는 승인된 운영자 또는 GitHub Actions principal object id와 실행 주체의 storage data-plane 권한을 확인한다.

`environments/staging`은 feature flag로 wave별 리소스를 켠다. 현재 Wave 1 apply는 완료됐고, 다음 PR은 `core_foundation`과 `db_and_app_ready` wave를 한 workflow에서 선택할 수 있게 한다. 기준은 기존 resource group `3dt-final-team1`, region `koreacentral`, 2026-06-26까지 총 1,000,000원 상한이다.

| Module | Wave 1 `acr_observability` | `core_foundation` | `db_and_app_ready` | 비고 |
| --- | --- | --- | --- | --- |
| `observability` | enabled | enabled | enabled | Log Analytics 30일 retention, workspace-based Application Insights |
| `container_registry` | enabled | enabled | enabled | ACR Basic, admin user disabled |
| `key_vault` | disabled | enabled | enabled | Vault/RBAC/reference만 Terraform 소유, secret value 작성 제외 |
| `postgres` | disabled | disabled | enabled | protected secret과 clean DB/Flyway 승인 전 apply 금지 |
| `redis` | disabled | enabled | enabled | Basic C0, source of truth 아님 |
| `storage` | disabled | enabled | enabled | public tiles/static, private media container 분리 |
| `cdn` | disabled | enabled | enabled | Azure CDN Standard Microsoft, Blob origin |
| `eventhubs` | disabled | enabled | enabled | Standard, `worker`/`analytics` consumer group |
| `container_apps_environment` | disabled | enabled | enabled | ACA Environment까지만 foundation에서 생성 |
| `container_apps` | disabled | disabled | enabled | Spring API/worker app은 image/secret/Flyway 준비 후 별도 승인 |
| `diagnostics` | disabled | enabled | enabled | 생성 리소스 diagnostic setting을 Log Analytics로 연결 |

`core_foundation`은 Redis, Blob/CDN, Event Hubs, Key Vault, user-assigned managed identity, ACA Environment, diagnostic settings까지만 만든다. Spring API Container App, worker Container App, PostgreSQL Flexible Server는 생성하지 않는다.

`db_and_app_ready`는 PostgreSQL과 ACA app을 만들 수 있는 선택지지만, protected `STAGING_POSTGRES_ADMINISTRATOR_PASSWORD`, `STAGING_SPRING_API_IMAGE`, `STAGING_WORKER_IMAGE`가 준비되고 별도 승인되기 전에는 실행하지 않는다. PostgreSQL admin password는 Terraform state에 sensitive value로 남을 수 있으므로, 이 방식을 채택하려면 사용자가 명시 승인해야 한다.

## 4. Blob + CDN 운영 경계

- Blob Storage는 tile/static/media object의 origin이자 source of truth다.
- Azure CDN은 public tile/static edge delivery 계층이다.
- Tile manifest, style JSON, PMTiles는 public CDN 대상으로 둘 수 있다.
- PMTiles는 versioned object path와 manifest pointer rollback을 우선한다.
- Manifest/style은 rollback을 해치지 않는 짧은 cache policy를 둔다.
- Private user media는 public CDN cache 대상이 아니다.
- 공개 가능한 media와 private media는 container, path, cache-control, access policy로 분리한다.
- Signed access 또는 private delivery 정책이 확정되기 전까지 private media는 public delivery로 보지 않는다.

## 5. Event Hubs 운영 경계

- Event Hubs는 analytics/event stream fan-out 용도다.
- Command queue, transactional outbox 원장, retry/dead-letter 중심 작업과 혼동하지 않는다.
- Spring/PostgreSQL outbox는 transactional source of truth로 유지한다.
- Event Hubs producer/consumer 구현과 payload contract는 별도 PR에서 다룬다.
- Staging skeleton은 namespace, event hub, consumer group, RBAC interface까지만 연다.
- 초기 consumer group은 `worker`, `analytics` 2개로 분리한다.
- replay/ops 전용 consumer group은 운영 도구와 replay smoke가 생긴 뒤 추가 검토한다.
- Connection string 원문은 Terraform code/state/plan/PR/log에 기록하지 않는다.

## 6. 비용/권한 리뷰 gate

비용과 권한은 [Azure staging cost and permission review](../docs/operations/azure-cost-permission-review.md)를 기준으로 별도 승인한다. 예산 기준은 월별 목표가 아니라 `3dt-final-team1` 기준 2026-06-26까지 총 1,000,000원 상한이다.

- Azure Pricing Calculator 산출물은 apply 전 승인 자료로 남긴다.
- apply 전 비용 보고 형식은 현재 누적 / 예상 증가분 / 상한 대비 잔여율로 고정한다.
- Budget alert는 50%, 75%, 90%, 100%를 권장하되, Budget 리소스 생성은 별도 승인 전까지 수행하지 않는다.
- Container Apps, PostgreSQL, Redis, Blob, CDN, Event Hubs, Key Vault, Log Analytics, Application Insights 비용 항목을 모두 포함한다.
- Key Vault, Container Apps, PostgreSQL, Redis, Blob, CDN, Event Hubs, Log Analytics 권한 경계를 리소스별로 분리한다.
- 무료 크레딧으로 방어 가능한 구간과 상시 비용/egress/ingestion 위험 구간을 분리한다.
- ACR, ACA, PostgreSQL, Redis, CDN, Event Hubs는 skeleton/plan-only 이후 별도 apply 승인 전에 budget impact를 확인한다.
- WAF/APIM/Front Door Premium/Private Endpoint/AKS는 2026-06-26 전 staging 1차 범위에서 제외한다.

## 7. CI/CD plan-only gate

PR 단계에서는 다음만 허용한다.

- `terraform fmt -recursive`
- `terraform init -backend=false`
- `terraform validate`
- mock 또는 placeholder variable 기반 plan 가능성 확인
- JSON/schema parse와 secret pattern scan

다음 작업은 protected environment와 수동 승인 이후에만 허용한다.

- Terraform backend bootstrap
- `terraform apply`
- Azure 리소스 실제 생성
- DNS/custom domain 변경
- DB migration job 실행
- Key Vault secret value 작성
- production traffic 전환

Migration job과 app rollout은 별도 단계로 나눈다. Terraform apply 성공은 배포 성공이 아니며 Spring startup, `/readyz`, public/domain smoke, observability smoke까지 통과해야 한다.

## 8. 성공 기준

Staging은 Terraform apply 성공만으로 성공 처리하지 않는다. 최소 성공 기준은 다음을 모두 포함한다.

- `terraform fmt`, `terraform init -backend=false`, `terraform validate` 통과
- Spring container startup 통과
- `/healthz` 200
- `/readyz` 200
- no-token `/api/v1/users/me` 401
- dependency readiness: PostgreSQL, Redis, Key Vault reference
- Blob/CDN edge smoke
- Tile manifest/style/PMTiles Range/CORS smoke
- Place/Search/Route provider smoke
- Observability smoke
- secret/token/raw body가 plan, log, PR, telemetry에 남지 않는지 확인

## 9. 구현 PR 분리 제안

| 순서 | PR 범위 | 포함 | 제외 |
| --- | --- | --- | --- |
| 1 | Staging plan 구체화 | plan 문서, smoke checklist, data rehearsal, cost/permission checklist | Azure apply |
| 2 | State backend bootstrap | `대한상공회의소 Data School` subscription의 `3dt-final-team1` resource group 기준 storage/container/RBAC plan, backend config 예시, optional delete lock, read-only preflight, RBAC 전파 지연 시 2-phase fallback | 앱 리소스 |
| 3 | Staging core foundation | Redis, Blob/CDN, Event Hubs, Key Vault, managed identity, ACA Environment, diagnostics | PostgreSQL, ACA app, secret value |
| 4 | DB/App readiness | PostgreSQL skeleton, Spring API/worker app wiring, image/secret gate | DB migration 실행, DNS/custom domain |
| 5 | Runtime config | Key Vault reference, app setting name, startup/readiness smoke | secret 값 출력 |
| 6 | Data rehearsal | clean DB Flyway, Blob copy rehearsal, tile CDN smoke | dev snapshot restore 무승인 실행 |
| 7 | Event Hubs integration | producer/consumer contract, checkpoint, replay smoke | command queue 대체 |

## 10. 남은 결정사항

- Azure subscription과 resource naming suffix
- Terraform backend bootstrap 리소스 이름, 승인된 RBAC 주체, 실행 주체 data-plane 권한
- `onmutfstatekrc001`부터 시작하는 Storage Account 후보 availability
- ACR 신규 생성 세부 SKU와 image retention
- Container Apps CPU/memory 초기값
- PostgreSQL storage/backup retention
- Blob lifecycle/versioning policy
- CDN custom domain과 TLS 적용 window
- Event Hubs event name, payload version, `worker`/`analytics` consumer group checkpoint storage
- Log Analytics 30일 retention, App Insights sampling, daily cap 값
- Pricing Calculator 산출 담당자와 승인 기준
