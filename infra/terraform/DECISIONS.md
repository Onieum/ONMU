# Terraform 결정 항목

이 문서는 Terraform skeleton 이후 사람이 확정한 선택지와 남은 승인 gate를 정리한다. 확정 결정은 Azure staging 1차 skeleton 기준이다. `environments/prod`는 production hardening 후보를 담은 placeholder이며, 별도 production approval 전에는 apply 대상이 아니다. 실제 `terraform apply`, DNS 변경, DB migration, secret value 작성은 별도 승인 뒤에만 한다.

## 확정 결정 요약

| 번호 | 항목 | 확정 선택 |
| --- | --- | --- |
| 1 | Azure region | `koreacentral` |
| 2 | Runtime platform | Azure Container Apps |
| 3 | Terraform state backend | Azure Storage blob backend |
| 4 | Blob + edge tile/static serving | Public `tiles` Blob origin + private `media` + Azure Front Door Standard |
| 5 | Event Hubs topology | Event Hubs Standard |
| 6 | PostgreSQL Flexible Server | Burstable `B_Standard_B1ms` |
| 7 | Redis | Azure Managed Redis 후보로 재설계. core foundation에서는 제외 |
| 8 | Container Apps scale | API min 1, worker min 0 |
| 9 | Networking | Public ingress + Key Vault reference |
| 10 | Secret management | Key Vault RBAC + managed identity |
| 11 | DB migration strategy | Clean DB full Flyway migration |
| 12 | Domain and DNS | `staging-api.onmu.cloud` |
| 13 | Terraform backend resource group | 기존 `3dt-final-team1` 재사용 |
| 14 | Terraform backend Storage Account 후보 | `onmutfstatekrc001`부터 suffix 증가 |
| 15 | ACR | 신규 ACR 생성 |
| 16 | Staging budget gate | 2026-06-26까지 총 1,000,000원 상한 |

## 1. Azure region

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| `koreacentral` | 국내 사용자 latency와 데이터 위치 설명이 가장 쉽다 | 일부 SKU/quota가 부족할 수 있다 | 1순위 |
| `eastasia` | Azure 리소스 가용성이 넓고 fallback region으로 쓰기 쉽다 | 한국 사용자 latency가 다소 늘 수 있다 | 2순위 |
| `japaneast` | 동아시아 latency가 안정적이고 SKU 가용성이 좋은 편이다 | 한국 데이터 위치 설명이 약해진다 | quota 부족 시 후보 |

확정: `koreacentral`을 기본 region으로 둔다. `terraform plan` 또는 quota 검증에서 막히면 별도 승인으로 `eastasia` fallback을 검토한다.

## 2. Runtime platform

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| Azure Container Apps | 초기 운영이 단순하고 scale rule, secret reference, ingress가 편하다 | 복잡한 service mesh나 Kubernetes ecosystem은 제한적이다 | staging 1차 |
| AKS | production portfolio와 확장성이 좋다 | 초기 운영, 비용, 보안 설정 부담이 크다 | production 후보 |
| App Service | 단순한 Web API에는 쉽다 | Worker, event consumer, container multi-service 운영이 애매하다 | 비추천 |

확정: staging은 Container Apps로 시작한다. AKS는 production hardening 또는 portfolio 목표에서 다시 평가한다.

## 3. Terraform state backend

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| Azure Storage blob backend | Azure 표준이고 blob lease lock을 쓸 수 있다 | bootstrap 리소스가 별도 필요하다 | 기본 |
| Terraform Cloud | locking과 collaboration이 편하다 | 외부 SaaS 운영 경계가 추가된다 | 팀 합의 시 후보 |
| local state | 빠르다 | 팀 작업과 CI/CD에 부적합하다 | 개인 실험 외 금지 |

확정: Terraform state는 Azure Storage blob backend를 목표로 한다. 기존 resource group `3dt-final-team1` 안에 `onmutfstatekrc001`부터 suffix 순서로 storage account 후보를 확인하고, 앱 리소스 skeleton PR과 섞지 않는다. state key는 `onmu/staging/terraform.tfstate`, `onmu/prod/terraform.tfstate` 형식으로 분리한다.

## 4. Blob + edge tile/static serving

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| Public `tiles` Blob origin + Azure Front Door Standard | 현재 Azure API 정책에서 지원되는 edge 경로이며 PMTiles Range/CORS를 Front Door에서 검증할 수 있다 | Front Door 기본료와 request/egress 비용이 생긴다 | staging 1차 |
| Blob direct serving | 가장 단순하다 | edge cache, custom domain, purge 전략이 약하다 | 임시 smoke만 |
| Azure CDN Standard Microsoft classic | 과거 비용은 낮았지만 신규 생성이 막힐 수 있다 | 현재 staging 신규 생성 경로로 부적합하다 | 제외 |

확정: staging skeleton은 Blob origin + Azure Front Door Standard로 둔다. Storage account는 nested public item 허용을 켜고 `tiles` container만 public blob access를 허용하며 `media` container는 private로 유지한다. manifest는 짧은 TTL, PMTiles는 versioned path + 긴 TTL을 기본으로 잡고 rollback은 manifest pointer 복구를 우선한다.

## 5. Event Hubs topology

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| Event Hubs Standard | consumer group, retention, throughput 확장이 staging rehearsal에 충분하다 | Basic보다 비용이 높다 | 기본 |
| Event Hubs Basic | 저렴하다 | consumer/replay 확장 검증이 제한적이다 | 비용 극단 절감 시 |
| Service Bus | command queue와 retry/dead-letter에 단순하다 | 사용자 결정인 Event Hubs 기준과 다르다 | 이번 skeleton 제외 |

확정: Event Hubs Standard, partition `2`, retention `1`일로 시작한다. 초기 consumer group은 `worker`, `analytics`를 분리하고, checkpoint는 Blob container를 사용한다. replay/ops consumer group은 운영 도구가 생긴 뒤 추가 검토한다.

## 6. PostgreSQL Flexible Server

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| Burstable `B_Standard_B1ms` | staging 비용이 낮다 | sustained workload에는 약하다 | staging 1차 |
| Burstable `B_Standard_B2s` | 약간 더 안정적이다 | 비용 증가 | smoke가 느리면 승격 |
| General Purpose | production 안정성이 좋다 | MVP staging에는 비용 부담 | production 후보 |

확정: staging은 `B_Standard_B1ms` + PostGIS 허용으로 시작한다. schema/table/index는 Terraform이 아니라 Flyway가 소유한다.

## 7. Redis

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| Azure Managed Redis 후보 | Azure Cache for Redis classic 신규 생성 차단 이후 권장 경로 | provider/resource/SKU와 비용 재검토 필요 | 후속 PR |
| Redis 미사용 | 비용이 없다 | place-search/route cache와 readiness 계약 검증이 약해진다 | core foundation 임시 기본 |
| Azure Cache for Redis classic Basic C0 | 과거 skeleton 기준 비용이 낮았다 | 신규 생성이 차단될 수 있다 | 비추천 |

확정: Redis는 source of truth로 쓰지 않는다. Azure Cache for Redis classic 신규 생성 차단이 확인되어, core foundation에서는 Redis를 제외하고 Azure Managed Redis 후보를 별도 PR에서 결정한다.

## 8. Container Apps scale

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| API min 1, worker min 0 | API cold start를 줄이고 worker 비용을 아낀다 | API idle 비용이 조금 든다 | staging 1차 |
| API min 0, worker min 0 | 비용 최소 | 로그인/smoke 첫 응답이 느릴 수 있다 | 비용 압박 시 |
| API min 2 이상 | 가용성 검증에 좋다 | SSE/event fan-out 검증이 선행돼야 한다 | production rehearsal |

확정: Spring API는 min 1, Worker/Event consumer는 비활성 또는 min 0으로 둔다.

## 9. Networking

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| Public ingress + Key Vault reference | staging을 빠르게 만들 수 있다 | private endpoint/WAF가 아직 없다 | staging 1차 |
| VNet + private endpoint | 보안 경계가 강하다 | 설계와 비용이 증가한다 | production hardening |
| APIM/WAF 선도입 | 정책 관리가 좋다 | MVP staging에는 과하다 | 후속 |

확정: staging은 public ingress로 시작하되 CORS, auth, Key Vault reference, smoke를 필수 gate로 둔다. Private networking은 비용 산출 뒤 도입한다.

## 10. Secret management

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| Key Vault RBAC + managed identity | Container Apps secret reference와 잘 맞고 value가 Terraform에 들어가지 않는다 | role assignment 순서가 중요하다 | 기본 |
| Key Vault access policy | 단순한 구형 모델 | RBAC 표준과 섞이면 혼란스럽다 | 비추천 |
| Terraform `azurerm_key_vault_secret`로 value 생성 | 자동화가 쉽다 | secret value가 state에 들어갈 수 있다 | 금지 |

확정: Terraform은 vault, identity, RBAC, secret reference만 만들고 secret value는 운영 절차로 주입한다.

## 11. DB migration strategy

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| Clean DB full Flyway migration | Azure staging 첫 검증이 가장 명확하다 | dev 데이터 기반 검증은 따로 필요하다 | staging 1차 |
| dev snapshot dump/restore rehearsal | 실제 데이터 이슈를 찾기 좋다 | PII/raw value 보호와 백업 승인이 필요하다 | 2단계 |
| 기존 migration 수정/repair | 빠르게 보일 수 있다 | checksum mismatch와 팀 DB 파손 위험 | 금지 |

확정: 첫 staging은 clean DB full migration으로 시작하고, 이후 승인된 dev snapshot rehearsal을 별도로 수행한다.

## 12. Domain and DNS

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| ACA 기본 FQDN으로 smoke | DNS 변경 없이 빠르게 검증한다 | 실제 domain/callback 검증은 불완전하다 | staging 초기 |
| `staging-api.onmu.cloud` | OAuth/callback smoke가 현실적이다 | DNS와 provider console 변경 승인이 필요하다 | staging smoke 이후 |
| `api.onmu.cloud` | production 최종 경로다 | cutover 리스크가 크다 | production gate |

확정: staging domain 목표는 `staging-api.onmu.cloud`다. 단, DNS/provider console 변경과 custom domain 연결은 별도 승인 window에서 수행한다.

## 13. Terraform backend resource group

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| 기존 `3dt-final-team1` 재사용 | 구독 RG 생성 제한을 피하고 즉시 bootstrap 준비가 가능하다 | tfstate 전용 lifecycle 격리는 약하다 | 확정 |
| tfstate 전용 RG 생성 | 삭제 방지와 RBAC 경계가 가장 명확하다 | 현재 구독 정책과 충돌할 수 있다 | 이번 범위 제외 |

확정: Terraform state backend는 기존 `3dt-final-team1` resource group을 사용한다. tfstate 전용 RG는 만들지 않는다.

## 14. Terraform backend Storage Account 후보

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| `onmutfstatekrc001` | ONMU prefix와 region 약어를 포함한다 | 전역 유일성 확인이 필요하다 | 1순위 |
| `onmutfstatekrc002` / `003` | suffix 증가로 충돌을 피한다 | 실제 이름이 후보별로 달라질 수 있다 | fallback |

확정: apply 전 read-only preflight로 `onmutfstatekrc001`, `onmutfstatekrc002`, `onmutfstatekrc003` 순서로 availability를 확인한다.

## 15. ACR

| 선택지 | 장점 | 단점 | 추천 |
| --- | --- | --- | --- |
| 신규 ACR Basic | staging image push/pull 경계가 Azure 안에 닫힌다 | ACR 비용과 image retention 관리가 필요하다 | 확정 |
| 기존 registry 연동 | 빠르게 시작할 수 있다 | 현재 기존 ACR이 없고 권한 경계가 애매하다 | 제외 |

확정: 기존 ACR이 없으므로 staging skeleton은 신규 ACR 생성을 기준으로 한다. 실제 생성은 별도 apply 승인 전 budget impact를 확인한다.

## 16. Staging budget gate

| 항목 | 확정 기준 |
| --- | --- |
| Scope | `3dt-final-team1` resource group |
| 상한 | 2026-06-26까지 총 1,000,000원 |
| Alert | 50%, 75%, 90%, 100% |
| apply 전 보고 | 현재 누적 / 예상 증가분 / 상한 대비 잔여율 |

확정: Budget 리소스 생성은 이번 Terraform PR 범위가 아니다. ACR, ACA, PostgreSQL, Redis, CDN, Event Hubs는 plan-only 이후 별도 apply 승인 전에 budget impact를 확인한다. WAF/APIM/Front Door Premium/Private Endpoint/AKS는 2026-06-26 전 staging 1차 범위에서 제외한다.
