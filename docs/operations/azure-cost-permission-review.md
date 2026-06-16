# Azure staging cost and permission review

이 문서는 ONMU Azure staging 적용 전에 비용 산출과 권한 경계를 점검하기 위한 checklist다. 금액은 Azure Pricing Calculator로 확정하고, 이 문서에는 rough risk와 산출 항목만 남긴다.

## 1. 공식 가격/크레딧 확인 기준

- Azure 무료 계정은 신규 고객에게 제한된 기간의 크레딧과 일부 무료 서비스를 제공한다. 실제 적용 여부와 만료일은 계정 상태에서 확인한다.
- Microsoft Learn의 무료 계정 안내에 따르면 무료 크레딧은 정해진 기간 동안만 사용할 수 있고, 이후에는 종량제 전환 여부에 따라 과금이 달라진다.
- Container Apps consumption은 월별 무료 할당량이 있으나, API min replica를 1로 두면 idle 사용량이 계속 발생한다.
- Event Hubs Standard는 throughput/capacity 단위와 retention/consumer group 설계가 비용에 영향을 준다.
- 최종 비용은 Azure Pricing Calculator 산출물로 승인한다.
- ONMU staging/bootstrap 비용 gate는 월별 목표가 아니라 `3dt-final-team1` 기준 2026-06-26까지 총 1,000,000원 상한이다.
- Azure Budget 리소스 생성은 이번 문서/PR 범위가 아니며 별도 승인 전까지 Terraform으로 만들지 않는다.

참고:

- [Azure 무료 계정](https://azure.microsoft.com/pricing/purchase-options/azure-account)
- [Azure 무료 계정 과금 방지](https://learn.microsoft.com/azure/cost-management-billing/manage/avoid-charges-free-account)
- [Azure Container Apps 가격](https://azure.microsoft.com/pricing/details/container-apps/)
- [Azure Event Hubs 가격](https://azure.microsoft.com/pricing/details/event-hubs/)
- [Azure Event Hubs scalability](https://learn.microsoft.com/azure/event-hubs/event-hubs-scalability)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)

## 2. 2026-06-26 budget gate

| 항목 | 기준 |
| --- | --- |
| Scope | `3dt-final-team1` resource group |
| 비용 상한 | 2026-06-26까지 총 1,000,000원 |
| 권장 alert | 50%, 75%, 90%, 100% |
| apply 전 비용 보고 | 현재 누적 / 예상 증가분 / 상한 대비 잔여율 |
| Budget 리소스 생성 | 별도 승인 전까지 제외 |

- ACR, ACA, PostgreSQL, Azure Managed Redis 후보, CDN/Front Door, Event Hubs는 skeleton/plan-only 이후 별도 apply 승인 전에 budget impact를 확인한다.
- WAF/APIM/Front Door Premium/Private Endpoint/AKS는 2026-06-26 전 staging 1차 범위에서 제외한다.
- 비용 산출은 resource/action summary 중심으로 공유하고 subscription id, principal id, raw plan output은 공유하지 않는다.
- Wave 1은 ACR Basic, Log Analytics, Application Insights만 대상으로 한다. Cost Management 조회 권한이 아직 없으면 apply 전 보고는 `현재 누적 확인 불가 / 예상 증가분 low-medium / 사용자 승인 필요` 형식으로 제한한다.

## 3. Pricing Calculator 입력 항목

| 리소스 | 필요한 입력 |
| --- | --- |
| Container Apps | region, replica 수, vCPU, memory, 요청량, active/idle 시간 |
| PostgreSQL Flexible Server | region, SKU `B_Standard_B1ms`, storage, backup retention, public/private network |
| Azure Managed Redis 후보 | region, SKU/tier, 운영 시간 |
| Blob Storage | redundancy, capacity, read/write/list transaction, lifecycle policy |
| Azure CDN | profile SKU, egress GB, request count, purge 빈도 |
| Key Vault | operation count, private endpoint 여부 |
| Log Analytics | GB/day ingestion, retention days |
| Application Insights | sampling, ingestion, retention |
| Event Hubs | Standard capacity/throughput, partition count, retention, consumer group 수 |
| ACR | 신규 생성 여부, SKU, storage/pull 빈도 |

## 4. 무료 크레딧 방어 가능성

| 구간 | 방어 가능성 | 이유 |
| --- | --- | --- |
| 낮은 트래픽의 ACA consumption | 높음 | 월별 무료 할당량과 작은 workload가 맞으면 초기 비용이 낮다 |
| 작은 Blob capacity와 낮은 transaction | 높음 | tile rehearsal object가 작고 egress가 낮으면 비용 변동이 작다 |
| Key Vault operation | 높음 | staging smoke 수준의 secret reference 호출은 일반적으로 작다 |
| PostgreSQL Flexible Server | 중간 | DB는 상시 기동 리소스라 크레딧 소모가 지속된다 |
| Azure Managed Redis 후보 | 중간 | cache는 상시 기동 리소스라 idle 비용이 남는다. Azure Cache for Redis classic 신규 생성 차단으로 별도 비용 산출 필요 |
| Event Hubs Standard | 중간-낮음 | throughput/capacity 단위가 시간 기준으로 비용을 만든다 |
| CDN tile egress/request | 낮음-중간 | Android 지도 smoke와 PMTiles egress가 늘면 빠르게 비용 변수가 된다 |
| Log Analytics/App Insights | 낮음-중간 | raw body 없이도 ingestion volume이 커질 수 있다 |

무료 크레딧은 staging rehearsal를 지연시키는 예산 완충재일 뿐, production 운영비 대체 기준이 아니다.

## 5. Rough range 판단

정확한 금액 대신 다음 risk range로 선검토한다.

| 비용 risk | 포함 항목 | 대응 |
| --- | --- | --- |
| Low | Key Vault operation, 작은 Blob, 낮은 ACA request | 기본값 유지 |
| Medium | PostgreSQL B1ms, Azure Managed Redis 후보, ACR Basic | 운영 시간과 SKU 재검토 |
| Medium-High | Event Hubs Standard, CDN egress, Log Analytics ingestion | retention, sampling, TU/capacity, tile egress 제한 |
| High | private endpoint/VNet, WAF/APIM/Front Door Premium, AKS, production HA | production hardening PR로 분리 |

## 6. 권한 경계 checklist

| 대상 | 권한 기준 |
| --- | --- |
| Key Vault | runtime managed identity에 필요한 secret read 권한만 부여 |
| Container Apps | image pull 권한, Key Vault reference 권한, Log Analytics 연결 권한 |
| PostgreSQL | app runtime 연결 권한과 migration job 권한 분리 검토 |
| Redis | connection secret reference만 사용, value 출력 금지 |
| Blob Storage | tile upload/read, private media 접근, checkpoint storage 권한 분리 |
| CDN | endpoint read와 purge/invalidation 권한을 운영자/CI gate로 제한 |
| Event Hubs | producer, consumer, owner 권한 분리 |
| Log Analytics/App Insights | write/config 권한과 query/read 권한 분리 |
| Terraform backend | state storage account/container/RBAC를 앱 리소스와 분리 |
| GitHub Actions | `plan`과 `apply`를 protected environment와 manual approval로 분리 |

## 7. 승인 전 금지

- Azure 리소스 실제 생성
- Terraform state backend bootstrap
- `terraform apply`
- DNS 변경
- DB migration 실행
- Key Vault secret value 작성
- raw plan에 secret/provider token/user data 출력
