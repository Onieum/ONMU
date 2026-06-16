# Azure staging WAF review

이 문서는 ONMU Azure Terraform skeleton을 만들기 전에 확인한 Well-Architected Framework 기준과 승인 게이트를 정리한다. 실제 Azure 리소스 생성, DNS 변경, DB migration, Key Vault secret value 작성은 별도 승인 전까지 보류한다.

## 결정된 기준

- Azure region: `koreacentral`
- Runtime platform: Azure Container Apps
- Object/tile/media origin: Azure Blob Storage
- Public tile/static delivery: Blob Storage + Azure CDN Standard Microsoft
- Event/analytics fan-out: Azure Event Hubs Standard
- PostgreSQL Flexible Server: Burstable `B_Standard_B1ms`
- Redis: Azure Managed Redis 후보로 재검토
- Domain target: `staging-api.onmu.cloud`
- Spring Main API: 인증, 권한, 트랜잭션, Flyway 원장
- DB schema: Terraform이 아니라 Flyway 소유
- Secret value: Terraform code, state, plan, PR, log에 기록하지 않음

## WAF 요약

### Reliability

- Container Apps는 staging 1차 runtime으로 적합하지만, 배포 성공은 build가 아니라 Spring startup, readiness, domain smoke 통과로 판단한다.
- PostgreSQL Flexible Server는 backup/restore, PostGIS extension, migration order를 별도 smoke gate에 포함한다.
- Redis는 source of truth가 아니며 place-search/route/provider response TTL cache로만 사용한다.
- PMTiles는 versioned object path와 manifest pointer rollback을 기본으로 둔다.
- CDN 경유 Range 206, CORS, Expose-Headers가 깨지면 Android MapLibre blank/fallback 문제가 재발할 수 있으므로 edge smoke를 필수로 둔다.
- Event Hubs는 analytics/event stream fan-out 용도이며 command queue나 transactional outbox 원장과 혼동하지 않는다.

### Security

- Container Apps는 managed identity와 Key Vault reference를 우선하며 secret value를 직접 코드에 넣지 않는다.
- Key Vault는 RBAC, soft delete, purge protection 기준을 plan에 포함한다.
- Blob은 private tile/static container와 private user media container를 분리한다. Public tile/static delivery는 Front Door route/cache policy에서 처리한다.
- Private user media는 public CDN cache 대상이 아니다.
- Event Hubs producer/consumer 권한은 분리하고 connection string 원문은 Key Vault reference로만 다룬다.
- Terraform state와 plan에는 secret name, Key Vault URI/reference, role assignment presence만 남긴다.

### Cost Optimization

- Staging은 Container Apps consumption, PostgreSQL burstable SKU로 시작한다. Redis는 Azure Cache for Redis 신규 생성 차단에 따라 Azure Managed Redis 후보를 별도 gate에서 재검토한다.
- PostgreSQL HA, Redis Standard, private networking, WAF/APIM은 production hardening 후보로 분리한다.
- CDN egress/request, Blob transaction, Log Analytics ingestion/retention, Event Hubs throughput/retention이 주요 비용 변수다.
- Event Hubs auto-inflate는 staging 기본값에서 끄고 비용 산출 후 조정한다.

### Operational Excellence

- Plan-only CI는 `terraform fmt`, `terraform init -backend=false`, `terraform validate`까지 허용한다.
- `terraform apply`, DNS 변경, DB destructive migration, Key Vault secret value write는 사용자 승인 전 금지한다.
- Migration job과 app rollout은 분리한다.
- Terraform apply 성공만으로 deploy 성공 판정하지 않는다.
- 모든 리소스에는 `app`, `env`, `owner`, `cost_center`, `managed_by`, `data_classification` tag 후보를 적용한다.

### Performance Efficiency

- PMTiles는 CDN edge에서 Range 206이 필수다.
- Manifest/style cache-control은 rollback 가능성을 해치지 않아야 한다.
- Redis는 TTL cache로만 쓰고 원장 데이터는 PostgreSQL에 둔다.
- PostGIS extension만 Terraform 후보이며 geometry/geography column, index, query는 Flyway와 API 설계가 소유한다.
- Event Hubs partition, throughput, consumer group은 analytics/event fan-out 기준으로 산정한다.

## Preliminary resource list

- Environment별 Resource Group
- User-assigned Managed Identity
- Key Vault
- Container Apps Environment
- Spring Main API Container App
- Optional Worker Container App
- Azure Container Registry 또는 기존 registry 연동
- PostgreSQL Flexible Server, database, PostGIS extension allow-list
- Azure Managed Redis 후보
- Blob Storage account와 private tile/static container, private media container
- Azure CDN profile/endpoint for Blob origin
- Event Hubs namespace와 `notification-requested`, `worker-jobs` event hub
- Log Analytics workspace
- Application Insights
- Diagnostic settings 후보
- Budget/cost alert 후보

## 확정 결정과 후속 gate

세부 선택지는 `infra/terraform/DECISIONS.md`를 기준으로 한다.

Staging 실행 계획은 `.azure/staging-plan.md`, `docs/operations/azure-staging-smoke-checklist.md`, `docs/operations/azure-staging-data-rehearsal.md`, `docs/operations/azure-cost-permission-review.md`에 분리해 기록한다. 이 문서들은 plan-only 산출물이며 실제 Azure 리소스 생성이나 `terraform apply`를 수행하지 않는다.

- CDN 제품은 staging 1차에서 Azure CDN Standard Microsoft로 확정한다. Front Door는 production hardening 후보로 둔다.
- Staging network는 public endpoint + Key Vault reference로 시작한다. Private endpoint/VNet은 비용 산출 후 결정한다.
- Region은 `koreacentral`로 확정한다. quota/SKU 문제가 있으면 별도 승인으로 `eastasia` fallback을 검토한다.
- PostgreSQL은 `B_Standard_B1ms`로 시작한다. Redis는 Azure Managed Redis 후보를 별도 gate에서 결정한다.
- Event Hubs는 Standard, partition 2, retention 1일로 시작한다.
- Terraform state backend는 Azure Storage Blob backend로 확정하지만 bootstrap 생성은 별도 승인 후 진행한다.
- Staging domain 목표는 `staging-api.onmu.cloud`로 확정하지만 DNS/provider console 변경은 별도 승인 후 수행한다.
- Pricing Calculator 산출물은 PR 후속 운영 산출물로 분리한다.
