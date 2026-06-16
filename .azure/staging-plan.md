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
| Resource group | `onmu-stg-*` resource group | resource group, tag |
| Identity | user-assigned managed identity | Container Apps, Key Vault, Storage, Event Hubs 접근 role assignment |
| Key Vault | RBAC 기반 vault | vault, RBAC, secret reference name. secret value는 제외 |
| Runtime | Container Apps Environment, Spring API Container App, optional worker | app, revision, ingress, scale, env var name, secret reference |
| Registry | Azure Container Registry Basic 또는 기존 registry 연동 | ACR를 만들 경우 registry와 pull 권한 |
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
    network/
    edge/
```

State backend는 Azure Storage blob backend로 고정하되, backend bootstrap 리소스 생성은 별도 PR과 승인으로 분리한다. State key는 다음 형식을 목표로 한다.

| 환경 | State key 후보 |
| --- | --- |
| staging | `onmu/staging/terraform.tfstate` |
| prod | `onmu/prod/terraform.tfstate` |

Backend bootstrap 세부 기준은 [Azure Terraform state backend bootstrap](../docs/operations/azure-terraform-state-backend.md)과 `infra/terraform/bootstrap/state-backend` root module을 따른다.

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
- Connection string 원문은 Terraform code/state/plan/PR/log에 기록하지 않는다.

## 6. 비용/권한 리뷰 gate

비용과 권한은 [Azure staging cost and permission review](../docs/operations/azure-cost-permission-review.md)를 기준으로 별도 승인한다.

- Azure Pricing Calculator 산출물은 apply 전 승인 자료로 남긴다.
- Container Apps, PostgreSQL, Redis, Blob, CDN, Event Hubs, Key Vault, Log Analytics, Application Insights 비용 항목을 모두 포함한다.
- Key Vault, Container Apps, PostgreSQL, Redis, Blob, CDN, Event Hubs, Log Analytics 권한 경계를 리소스별로 분리한다.
- 무료 크레딧으로 방어 가능한 구간과 상시 비용/egress/ingestion 위험 구간을 분리한다.

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
| 2 | State backend bootstrap | `대한상공회의소 Data School` subscription의 `3dt-final-team1` resource group 기준 storage/container/RBAC plan, backend config 예시 | 앱 리소스 |
| 3 | Staging resource skeleton 확장 | ACA/Postgres/Redis/Blob/CDN/Event Hubs/observability module 보완 | secret value |
| 4 | Staging apply gate | GitHub protected environment, manual approval, plan artifact | 자동 production apply |
| 5 | Runtime config | Key Vault reference, app setting name, startup/readiness smoke | secret 값 출력 |
| 6 | Data rehearsal | clean DB Flyway, Blob copy rehearsal, tile CDN smoke | dev snapshot restore 무승인 실행 |
| 7 | Event Hubs integration | producer/consumer contract, checkpoint, replay smoke | command queue 대체 |

## 10. 남은 결정사항

- Azure subscription과 resource naming suffix
- Terraform backend bootstrap 리소스 이름과 RBAC 주체
- ACR 신규 생성 또는 기존 registry 연동
- Container Apps CPU/memory 초기값
- PostgreSQL storage/backup retention
- Blob lifecycle/versioning policy
- CDN custom domain과 TLS 적용 window
- Event Hubs event name, payload version, consumer group 수
- Log Analytics retention과 App Insights sampling
- Pricing Calculator 산출 담당자와 승인 기준
