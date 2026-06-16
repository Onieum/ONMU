# Azure staging plan

이 문서는 ONMU Azure staging 전환을 위한 plan-only 실행 기준이다. 실제 Azure 리소스 생성, `terraform apply`, DNS 변경, DB migration, Key Vault secret value 작성은 별도 승인 전까지 수행하지 않는다.

## 1. 확정 기준

| 항목 | 선택 |
| --- | --- |
| Azure region | `koreacentral` |
| Runtime platform | Azure Container Apps |
| Terraform state backend | Azure Storage blob backend |
| Tile/static public delivery | Blob Storage origin + Azure Front Door Standard. `tiles`는 public blob origin, `media`는 private 유지 |
| Event/analytics fan-out | Event Hubs Standard |
| PostgreSQL Flexible Server | Burstable `B_Standard_B1ms` |
| Redis | Azure Managed Redis 후보로 재검토 |
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
| Redis | deferred | Azure Managed Redis 후보와 secret reference |
| Blob Storage | public `tiles` container, private `media` container, checkpoint container | account, container, lifecycle/versioning 후보, RBAC. Front Door가 `tiles` origin을 읽고 private media는 계속 비공개 유지 |
| Edge/CDN | Azure Front Door Standard 후보 | Terraform `frontdoor_tile_edge` wave에서 disabled-by-default로 준비. custom domain/TLS는 별도 단계 |
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
| `redis` | disabled | disabled | disabled | Azure Cache for Redis 신규 생성 차단으로 분리. Azure Managed Redis 재설계 전 apply 금지 |
| `storage` | disabled | enabled | enabled | public `tiles`, private `media` container 분리 |
| `cdn` | disabled | disabled | disabled | Azure CDN classic 신규 생성 경로는 사용하지 않음 |
| `front_door` | disabled | disabled | optional wave | Azure Front Door Standard. 기본료 발생으로 apply 전 별도 승인 필요 |
| `eventhubs` | disabled | enabled | enabled | Standard, `worker`/`analytics` consumer group |
| `container_apps_environment` | disabled | enabled | enabled | ACA Environment까지만 foundation에서 생성 |
| `container_apps` | disabled | disabled | enabled | Spring API/worker app은 image/secret/Flyway 준비 후 별도 승인 |
| `diagnostics` | disabled | disabled | disabled | 리소스 생성 wave와 분리. `core_diagnostics`, `frontdoor_diagnostics`에서 별도 연결 |
| `rbac_assignments` | disabled | disabled | disabled | Key Vault runtime role assignment는 `key_vault_rbac`에서 별도 승인 |

`core_foundation`은 Blob Storage origin, Event Hubs, Key Vault, user-assigned managed identity, ACA Environment까지만 만든다. Spring API Container App, worker Container App, PostgreSQL Flexible Server, Redis, CDN/edge 리소스, Key Vault role assignment, diagnostic setting은 생성하지 않는다. Diagnostic setting은 신규 resource id가 remote state에 기록된 뒤 `core_diagnostics` wave에서 별도 plan/apply한다. Key Vault runtime secret read 권한은 `key_vault_rbac` wave에서 `User Access Administrator` 또는 `Role Based Access Control Administrator` 권한 승인 후 연결한다.

Azure Cache for Redis는 신규 생성이 차단될 수 있으므로 staging Redis는 Azure Managed Redis 지원 리소스와 Terraform provider 지원을 별도 PR에서 재검토한다.

`db_and_app_ready`는 PostgreSQL과 ACA app을 만들 수 있는 선택지지만, protected `STAGING_POSTGRES_ADMINISTRATOR_PASSWORD`, `STAGING_SPRING_API_IMAGE`, `STAGING_WORKER_IMAGE`가 준비되고 별도 승인되기 전에는 실행하지 않는다. PostgreSQL admin password는 Terraform state에 sensitive value로 남을 수 있으므로, 이 방식을 채택하려면 사용자가 명시 승인해야 한다. DB/App diagnostic setting도 app resource 생성 이후 별도 diagnostics wave로 분리한다.

## 4. Blob + Front Door 운영 경계

- Blob Storage는 tile/static/media object의 origin이자 source of truth다.
- `core_foundation`은 storage account를 만들고 `tiles` container에 public blob access를 허용한다. `media` container는 private로 유지한다.
- Edge/CDN은 public tile/static delivery 계층이지만 `core_foundation`에서는 만들지 않는다. `frontdoor_tile_edge` wave에서 Azure Front Door Standard profile, endpoint, Blob origin group/origin/route를 준비한다. Front Door Standard는 기본료가 발생하므로 apply 전 별도 비용 승인 gate를 둔다. `frontdoor_diagnostics`는 이후 지원되는 Front Door scope만 대상으로 하며 현재 staging 기준으로는 profile scope만 diagnostic setting을 붙인다.
- 기존 staging state가 private `tiles`로 남아 있으면 `frontdoor_origin_access` patch wave로 storage account와 `tiles` access boundary만 보정한다.
- Custom domain/TLS는 이번 Front Door skeleton에서 즉시 연결하지 않고 후속 단계로 둔다.
- Tile manifest, style JSON, PMTiles는 후속 edge 계층이 확정되면 public edge delivery 대상으로 둘 수 있다.
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
| 3 | Staging core foundation | Blob Storage origin, Event Hubs, Key Vault, managed identity, ACA Environment | Redis, PostgreSQL, ACA app, CDN/edge, diagnostics, RBAC role assignment, secret value |
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
