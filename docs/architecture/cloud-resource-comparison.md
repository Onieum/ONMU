# ONMU Cloud Resource Comparison

이 문서는 `current-to-target-architecture-practice-guide`의 권장 영역이 현재 아키텍처 문서에 반영되었는지 점검하고, ONMU 로드맵을 기준으로 Azure 리소스 선정이 적절한지 확인하기 위한 비교표다. 추가로 같은 요구를 GCP/AWS로 옮길 때 대응되는 managed resource를 함께 정리한다.

비용은 2026년 6월 기준 공개 free credit와 일반적인 MVP 저트래픽 가정을 바탕으로 한 rough planning range다. 실제 견적은 배포 region, HA, traffic, storage, log retention, egress, provider 호출량에 따라 달라지므로 각 클라우드 pricing calculator로 다시 산정해야 한다.

## 1. 권장 영역 반영 점검

| 가이드 권장 영역 | 현재 반영 문서 | 반영 상태 | 팀원에게 요구할 보완 |
| --- | --- | --- | --- |
| Auth / Session / OAuth | [Auth/User/Profile](./auth-user-profile-architecture.md), [API Contract Map](./api-contract-map.md), [Azure secret 인벤토리](../operations/azure-secret-inventory.md) | 반영 | Provider console별 redirect/package/SHA-1 검증 결과를 운영 smoke에 계속 누적 |
| User / Profile / Character / Friends | [User/Profile/Character/Friends](./user-profile-character-friends-architecture.md) | 반영 | profile encoding/mojibake scan 기준을 Azure smoke와 연결 |
| Groups / Plans / Members | [Home/Plans/Vote](./home-plans-vote-architecture.md), [API Contract Map](./api-contract-map.md) | 부분 반영 | 전용 `groups-plans-members-architecture.md`가 필요하면 분리. 현재는 Home/Plans/Vote 안에 포함됨 |
| Place / Search / Route / Map | [Place/Search/Route/Map](./place-search-route-map-architecture.md) | 반영 | Kakao Local 권한/심사 상태와 route provider production 기준은 별도 운영 결정 필요 |
| Vote / Decision | [Home/Plans/Vote](./home-plans-vote-architecture.md), [API Contract Map](./api-contract-map.md) | 부분 반영 | 전용 `vote-decision-architecture.md`가 필요하면 분리. 현재는 Home/Plans/Vote 안에 포함됨 |
| Settlement | [Settlement](./settlement-architecture.md) | 반영 | 실제 runtime notification row/outbox 연결 smoke를 Azure staging에서 재확인 |
| Records / Memories / Media / OOTD | [Records/Memories/Media/OOTD](./records-memories-media-ootd-architecture.md) | 반영 | Blob lifecycle, signed URL expiry, thumbnail/AI worker job 기준 확정 |
| Notification / Push / Devices | [Notification/Push/Devices](./notification-push-devices-architecture.md) | 반영 | FCM/APNs provider credential과 dev-safe delivery를 production smoke에서 분리 |
| Realtime / ChatActivity | [ChatActivity](./chat-activity-architecture.md) | 반영 | Spring SSE 유지 단계와 Realtime Gateway 전환 시점을 roadmap에 맞춰 결정 |
| Worker / AI / Outbox | [Backend stack](./backend-stack-options.md), [Current Architecture](./current-architecture-diagram.md), 각 도메인 문서의 Worker/Outbox 섹션 | 부분 반영 | 전용 `worker-ai-outbox-architecture.md`가 있으면 Terraform queue/worker/AI Search/OpenAI 경계를 더 명확히 할 수 있음 |
| Runtime / Infra / Observability | [Current Architecture](./current-architecture-diagram.md), [Terraform Resource Ownership](./terraform-resource-ownership.md), [Azure runtime contract](../operations/azure-runtime-contract.md), [Azure CI/CD runbook](../operations/azure-ci-cd-runbook.md) | 반영 | 실제 Terraform skeleton 작성 시 `.azure/infrastructure-plan.json`과 `infra/terraform`으로 확정 |

판정:

- 가이드 권장 11개 영역은 모두 현재 문서 체계에 매핑되어 있다.
- 다만 `Groups / Plans / Members`, `Vote / Decision`, `Worker / AI / Outbox`는 독립 문서가 아니라 기존 통합 문서 또는 여러 문서에 걸쳐 있다.
- 팀원에게 요구할 수 있는 보완은 "문서 누락"보다는 "전용 세부 문서로 분리할지 결정"이다.

## 2. 로드맵 기준 Azure 리소스 선정 점검

| Roadmap 단계 | ONMU 요구 | Azure 선정 | 상태 | 비고 |
| --- | --- | --- | --- | --- |
| Phase 0: 문서화/계획 | current-to-target, ownership, smoke, rollback | `.azure/deployment-plan.md`, 운영 문서 세트 | 반영 | 실제 리소스 생성 없음 |
| Phase 1: Azure staging MVP | Spring Main API, DB, Redis, object storage, secret, logs | Container Apps, PostgreSQL Flexible Server + PostGIS, Azure Cache for Redis, Blob Storage, Key Vault, Log Analytics/App Insights | 적합 | AKS보다 ACA가 초기 운영 부담이 낮음 |
| Phase 1: tile 안정화 | manifest/style/PMTiles Range/CORS | Blob Storage + CDN/Front Door 후보 | 적합 | public tile gateway를 Blob/CDN으로 이전 가능. 단, 최종 hosting, cache invalidation, rollback 방식은 Terraform 적용 전 결정 |
| Phase 1: place/route provider | Naver/Kakao/OpenRouteService secret, short TTL cache | Key Vault, Managed Identity, Azure Cache for Redis | 적합 | Flutter가 provider API 직접 호출하지 않음 |
| Phase 2: chat/notification 안정화 | SSE, outbox, delivery record, push token | Spring SSE 유지 + Service Bus 후보 + App Insights | 적합 | Realtime Gateway는 후속 |
| Phase 2: worker 분리 | AI/Data Worker, notification worker, async jobs | Container Apps Worker 또는 Container Apps Jobs, Service Bus | 적합 | worker schema는 Alembic 후보 |
| Phase 3: 추천/AI | Azure OpenAI, RAG/search, explanation worker | Azure OpenAI, Azure AI Search 후보 | 적합 | MVP는 rule-based explanation 먼저 |
| Phase 3: analytics/reporting | outbox/event fan-out, lakehouse | Event Hubs, Databricks/Lakehouse 후보 | 후속 | MVP 필수 리소스 아님 |
| Phase 4: production hardening | WAF, APIM, private network, HA, alerts | Front Door/App Gateway WAF, API Management, Private Endpoint/VNet, Azure Monitor alerts | 후속 | staging에서 비용을 보고 단계 도입 |

판정:

- Azure 기준 리소스는 현재 로드맵과 대체로 맞게 선정되어 있다.
- 초기 staging은 AKS보다 Container Apps가 더 현실적이다.
- Production/portfolio 목표에는 AKS, APIM, WAF, private networking을 남겨 두는 구성이 적절하다.
- 지금 당장 확정해야 할 것은 "ACA staging first"와 "AKS production target 후보"의 우선순위이지, AKS를 처음부터 강제하는 것이 아니다.

### Place/Search/Route/Map 확정 전 체크

Place/Search/Route/Map 영역은 기준선 문서와 smoke checklist에는 반영되어 있지만, Terraform으로 리소스를 생성하기 전 다음 항목을 운영 결정으로 닫아야 한다.

| 항목 | 결정 필요 내용 | Terraform 반영 위치 |
| --- | --- | --- |
| Tile hosting | Blob Storage + CDN, Front Door, gateway fallback 중 staging/prod traffic 경로 선택 | storage/edge module, endpoint output |
| Tile rollback | versioned manifest/style/PMTiles object, current pointer 전환, purge/invalidation 권한 | storage lifecycle, edge purge 권한 |
| Provider production | Kakao Local 심사/권한, Naver/Kakao quota, route provider quota/약관 | Key Vault secret name, runtime env binding |
| Provider retention | raw provider body 장기 저장 금지, 최소 snapshot field와 TTL/삭제 기준 | 앱/Flyway/운영 정책. Terraform 소유 아님 |
| PostGIS query | geometry/geography column, GiST/SP-GiST index, radius/nearby query | DB extension은 Terraform 후보, table/index는 Flyway |
| Android map regression | MapLibre/PMTiles emulator matrix, 담당자, artifact 기준 | CI/CD smoke job 후보 |
| 비용 산정 | staging/prod별 Blob egress, edge, PostgreSQL/PostGIS, Redis, provider 호출량 | pricing calculator 산출물. Terraform 코드가 아님 |

### Records/Media/OOTD 확정 전 체크

Records/Media/OOTD 영역은 Blob Storage 리소스만으로 완성되지 않는다. Terraform 적용 전 Spring upload boundary, DB metadata, Flutter state 갱신 기준을 함께 닫는다.

| 항목 | 결정 필요 내용 | Terraform 반영 위치 |
| --- | --- | --- |
| Media upload boundary | Flutter 직접 Blob/MinIO write 금지, Spring multipart/proxy 또는 Spring-issued presigned flow 중 선택 | Container Apps env, storage identity, CORS 최소화 |
| Storage provider | local/dev MinIO compatibility, Azure staging/prod Blob Storage target | storage module, managed identity/RBAC |
| Media metadata | `record_media` object key, content type, size, sort order, comment, target `media[]` contract | DB schema는 Flyway, Terraform 소유 아님 |
| Upload limits | max count, MIME/extension, per-file/body size, client compression, error code | Container Apps ingress/body limit, Spring env |
| OOTD display | DAILY/OOTD same-day coexistence, OOTD 없는 날짜 character 미표시 | Flutter/API smoke. Terraform 소유 아님 |
| Diary reproducibility | `layoutType`, decoration seed 또는 selected asset key 저장 | 앱/Flyway 계약. Terraform 소유 아님 |

### Edge/API Gateway 확정 전 체크

| 항목 | staging 1차 | production 후보 |
| --- | --- | --- |
| Ingress | Container Apps ingress + Spring CORS | Front Door/WAF 또는 API Management |
| CORS | 환경별 allowlist, credential 최소화 | web origin 고정, preflight cache policy |
| OAuth callback | Spring public route 직접 도달 | custom domain/edge route smoke 후 cutover |
| Rate limit | 앱 내부 또는 edge 없이 시작 가능 | APIM/WAF policy 후보 |
| WAF | 기본 미적용 | production traffic 전 별도 비용/운영 승인 |

MVP staging은 Container Apps ingress를 기본값으로 둔다. Front Door/WAF/APIM은 production hardening 후보이며, 도입 전에는 OAuth callback, mobile deep link, CORS preflight, `/readyz`, domain smoke가 edge 뒤에서 모두 통과해야 한다.

## 3. Cloud resource 대응표

| ONMU 요구 | Azure | GCP | AWS | Azure 선정 판단 |
| --- | --- | --- | --- | --- |
| Container app runtime | Azure Container Apps | Cloud Run | App Runner 또는 ECS Fargate | staging 1차로 ACA 적합 |
| Kubernetes target | Azure Kubernetes Service | Google Kubernetes Engine | Elastic Kubernetes Service | production/portfolio 후보 |
| Container registry | Azure Container Registry | Artifact Registry | Elastic Container Registry | 필수 |
| Managed PostgreSQL + PostGIS | Azure Database for PostgreSQL Flexible Server | Cloud SQL for PostgreSQL | Amazon RDS for PostgreSQL | 필수 |
| Redis cache | Azure Cache for Redis | Memorystore for Redis | ElastiCache for Redis | 필수, source of truth 아님 |
| Object storage/media/tile | Azure Blob Storage | Cloud Storage | Amazon S3 | 필수 |
| CDN/edge for static/tile | Azure Front Door 또는 Azure CDN | Cloud CDN | CloudFront | tile/production 단계 |
| WAF/edge security | Front Door WAF 또는 Application Gateway WAF | Cloud Armor | AWS WAF + CloudFront/ALB | production 단계 |
| API gateway/policy | Azure API Management | API Gateway 또는 Apigee | Amazon API Gateway | staging에서는 optional |
| Secret management | Key Vault + Managed Identity | Secret Manager + Cloud KMS + Service Account | Secrets Manager/Parameter Store + KMS + IAM Role | 필수 |
| Queue/outbox bridge | Service Bus | Pub/Sub | SQS/SNS/EventBridge | notification/worker 단계 |
| Event streaming/analytics | Event Hubs | Pub/Sub 또는 Dataflow | Kinesis | analytics 후속 |
| App logs/metrics/tracing | Application Insights + Log Analytics | Cloud Logging/Monitoring/Trace | CloudWatch + X-Ray | 필수 |
| AI LLM | Azure OpenAI | Vertex AI/Gemini | Amazon Bedrock | 후속 |
| Search/RAG | Azure AI Search | Vertex AI Search 또는 AlloyDB/Cloud SQL + vector | OpenSearch Service 또는 Kendra | 후속 |
| Data lake/reporting | Azure Databricks 또는 Fabric/Lakehouse | BigQuery/Dataproc/Dataflow | Redshift/Glue/Athena/EMR | 후속 |
| CI/CD identity | GitHub OIDC + Azure federated credential | Workload Identity Federation | IAM OIDC provider | 필수 |
| Background jobs | Container Apps Jobs | Cloud Run Jobs | ECS scheduled task 또는 Lambda | worker/maintenance 후보 |
| Private networking | VNet, Private Endpoint | VPC, Private Service Connect | VPC, PrivateLink | production hardening |
| DNS | Azure DNS 또는 외부 DNS | Cloud DNS | Route 53 | cutover 단계 |

## 4. 생태계별 장단점

| 생태계 | 장점 | 단점 | ONMU 관점 |
| --- | --- | --- | --- |
| Azure | Key Vault, Managed Identity, App Insights, Azure OpenAI, ACA/AKS 전환 경로가 ONMU 목표와 잘 맞음. Windows dev/PowerShell/Key Vault 운영 경험을 그대로 확장하기 쉬움 | APIM/WAF/Private Endpoint까지 한 번에 켜면 비용과 운영 복잡도가 빠르게 증가. 일부 리소스 SKU 선택이 초보자에게 어렵다 | 현재 문서/secret/runtime 흐름과 가장 자연스럽다. staging은 ACA 중심으로 가볍게 시작하는 것이 좋음 |
| GCP | Cloud Run과 Cloud SQL 조합이 단순하고 개발자 경험이 좋음. Pub/Sub, Cloud Logging, BigQuery가 자연스럽게 연결됨 | Microsoft/Windows/Key Vault 중심 운영과는 도구 전환 비용이 있음. Vertex/Cloud IAM 권한 모델을 새로 학습해야 함 | container-first staging에는 매력적이지만, 현재 ONMU의 Azure Key Vault/Windows 운영 축과는 별도 전환 비용이 큼 |
| AWS | 서비스 선택지가 가장 넓고 production 패턴 자료가 많음. RDS/S3/CloudFront/ECS/Fargate 조합이 안정적 | 같은 요구를 여러 서비스 조합으로 풀 수 있어 초기에 결정 피로가 큼. IAM, VPC, 비용 관리가 복잡해지기 쉽다 | 대규모 production에는 강하지만, 팀의 현재 Azure 전환 목표와 문서 자산을 다시 짜야 함 |

## 5. 예상 운영 비용 범위

아래 범위는 Korea/East Asia 계열 region, 낮은 트래픽, 1개 staging environment, managed PostgreSQL/Redis 24시간 운영, 작은 로그 보존을 가정한 planning range다. 실제 비용은 공식 pricing calculator로 다시 계산한다.

| 시나리오 | Azure 예상 월비용 | GCP 예상 월비용 | AWS 예상 월비용 | 주요 비용 원인 |
| --- | ---: | ---: | ---: | --- |
| 문서/plan only | 0 USD | 0 USD | 0 USD | 리소스 생성 없음 |
| 최소 staging | 80-250 USD | 70-230 USD | 80-260 USD | managed Postgres, Redis, logs, storage |
| MVP staging + queue + worker | 150-450 USD | 130-400 USD | 150-480 USD | worker 상시/예약 실행, queue, log 증가 |
| Production MVP without full enterprise edge | 300-900 USD | 280-850 USD | 320-950 USD | HA DB, cache, monitoring, egress, object traffic |
| Production with WAF/APIM/private networking | 700-2,000+ USD | 650-1,800+ USD | 750-2,200+ USD | WAF/API gateway/private endpoint/NAT/log retention |
| AI/RAG 실험 포함 | 위 비용 + 사용량 기반 | 위 비용 + 사용량 기반 | 위 비용 + 사용량 기반 | LLM token, embedding, search index, vector storage |

비용 방어 우선순위:

1. staging은 Container Apps/Cloud Run/App Runner처럼 scale-to-zero 또는 낮은 idle 비용의 runtime을 선택한다.
2. Redis managed SKU는 꼭 필요한 TTL cache만 쓰고, source of truth로 쓰지 않는다.
3. WAF/APIM/private networking은 production cutover 직전까지 optional로 둔다.
4. Log retention과 sampling을 제한한다.
5. AI/RAG는 rule-based MVP 이후 별도 budget gate로 연다.

Azure 비용 guardrail 후보:

| 항목 | staging 기본 | production 전 확인 |
| --- | --- | --- |
| SKU | 최소 HA/replica, scale-to-zero 가능 runtime 우선 | HA/zone redundancy는 비용 승인 후 |
| Budget alert | resource group 또는 subscription budget alert 후보 | monthly budget, forecast alert, owner 지정 |
| Auto-shutdown | dev/test성 worker/job은 예약 실행 또는 scale-to-zero | production 상시 runtime만 예외 |
| Log retention | 짧은 retention으로 시작 | incident/SLO 요구에 맞춰 연장 |
| Blob lifecycle | old media/tile version lifecycle 후보 | legal/product retention 결정 후 적용 |
| AI/LLM | 기본 disabled 또는 quota 제한 | 별도 budget gate |

비용 산출물에는 SKU, count, region, 월 예상 범위, 주요 비용 원인만 남긴다. billing account 식별자나 결제 정보는 문서/PR에 남기지 않는다.

## 6. 무료 크레딧 방어 가능성

공식 무료 계정/크레딧 기준:

- Azure: 신규 free account는 30일 동안 사용할 수 있는 200 USD credit과 일부 free services를 제공한다.
- GCP: 신규 고객은 90일 동안 사용할 수 있는 300 USD free credit을 제공한다.
- AWS: 신규 AWS Free Tier account는 즉시 100 USD, 추가 활동으로 최대 100 USD를 더해 총 최대 200 USD credit을 6개월 동안 사용할 수 있다.

| 생태계 | 무료 크레딧으로 방어 가능한 범위 | 주의점 |
| --- | --- | --- |
| Azure | 최소 staging 1개월 전후 방어 가능. ACA scale-to-zero, 작은 DB, Redis 최소 SKU면 문서/초기 smoke에는 충분 | 30일 제한이 짧다. PostgreSQL/Redis/WAF/APIM을 켜면 빠르게 소진 |
| GCP | 최소 staging 1-2개월 방어 가능. Cloud Run + Cloud SQL 소형 구성으로 실험 여유가 가장 큼 | 90일 이후 managed DB/Redis 비용이 바로 드러남 |
| AWS | 최소 staging 1개월 전후 방어 가능. Free Tier/credit 조합을 잘 쓰면 실험은 가능 | RDS/ElastiCache/NAT/WAF 조합은 크레딧을 빠르게 소모 |

무료 크레딧은 "production 운영비 절감"이 아니라 "staging rehearsal 비용 완충"으로만 본다. ONMU의 실제 production 비용은 DB/Redis/object/log/edge/AI 사용량을 기준으로 별도 FinOps 계산이 필요하다.

## 7. 최종 권고

1. ONMU는 Azure 기준으로 계속 가는 것이 가장 자연스럽다.
2. 첫 Azure PR은 Terraform skeleton과 `.azure/infrastructure-plan.json`까지로 제한한다.
3. Staging runtime은 Container Apps를 1차 목표로 둔다.
4. AKS, APIM, WAF, private networking은 production hardening 단계로 미룬다.
5. 팀원에게는 `Groups / Plans / Members`, `Vote / Decision`, `Worker / AI / Outbox`를 전용 문서로 분리할지 결정해 달라고 요구하면 된다.
6. 비용 견적은 이 문서의 범위를 시작점으로 삼고, 실제 Azure/GCP/AWS calculator export를 PR 또는 운영 이슈에 첨부한다.

## 8. 공식 참고 링크

- [Microsoft Azure pricing calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [Microsoft Azure free account](https://azure.microsoft.com/en-us/pricing/purchase-options/azure-account)
- [Google Cloud pricing calculator](https://cloud.google.com/products/calculator)
- [Google Cloud Free Program](https://cloud.google.com/free)
- [AWS Pricing Calculator](https://calculator.aws/)
- [AWS Free Tier](https://aws.amazon.com/free/)
