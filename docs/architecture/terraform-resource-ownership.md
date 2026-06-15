# Terraform 리소스 소유권

이 문서는 Azure 전환 시 Terraform이 소유할 것과 애플리케이션/runtime이 소유할 것을 구분한다. 목적은 인프라 변경, DB schema 변경, 앱 기능 변경이 한 PR에 섞이지 않게 하는 것이다.

## 1. 소유권 원칙

- Terraform은 Azure 리소스, 네트워크, 권한, 진단 설정을 소유한다.
- Spring Flyway는 Main API DB schema를 소유한다.
- FastAPI Worker 전용 schema가 생기면 Alembic이 해당 schema를 소유한다.
- GitHub Actions는 build/deploy/migration/smoke orchestration을 소유한다.
- 사람이 provider console, DNS cutover, production approval 같은 외부 승인 작업을 소유한다.
- 실제 secret value는 Terraform 코드, PR 본문, 문서, 로그에 남기지 않는다.

## 2. Terraform 소유 리소스

| 영역 | Terraform 소유 후보 | 비고 |
| --- | --- | --- |
| Resource group | environment별 resource group | tag/owner/cost center 포함 |
| Networking | VNet, subnet, private endpoint, DNS zone 후보 | ACA/AKS 선택에 따라 조정 |
| Edge | Front Door, Application Gateway WAF 후보 | production cutover 전 별도 승인 |
| API boundary | API Management 후보 | staging에서는 최소화 가능 |
| Compute | Container Apps Environment, AKS, app/container resources | staging은 ACA 우선 |
| Registry | Azure Container Registry | GitHub Actions push 대상 |
| Database | PostgreSQL Flexible Server, database, extension 설정 | 테이블 schema는 Flyway |
| Cache | Azure Cache for Redis | persistence 원장 아님 |
| Storage | Blob account/container, lifecycle policy | media/tile asset 저장 |
| Messaging | Service Bus namespace/queue/topic, Event Hubs 후보 | outbox consumer 대상 |
| Secret | Key Vault, access policy/RBAC, managed identity, Container Apps secret reference | secret 값은 별도 주입 |
| Observability | Log Analytics, Application Insights, diagnostic settings | alert는 단계적 추가 |

## 3. Terraform이 소유하지 않는 것

| 항목 | 소유자 | 이유 |
| --- | --- | --- |
| DB table/index/column | Flyway/Alembic | 앱 버전과 migration 순서가 필요 |
| seed/test 데이터 | Spring script 또는 운영 runbook | 환경별 데이터 정책이 다름 |
| 실제 secret value | Key Vault 운영 절차 | 문서/코드 유출 방지 |
| OAuth provider console 설정 | 권한 보유자 | provider UI 승인/심사 필요 |
| records/OOTD media object 내용 | Spring runtime / media runbook | upload, object key, orphan cleanup은 배포/사용자 데이터 흐름과 연결됨 |
| tile manifest/style/PMTiles object 내용 | Tile runtime runbook | object version, manifest pointer, rollback은 배포 시점 판단이 필요 |
| DNS traffic cutover | 운영 승인자 | rollback window와 smoke 필요 |
| Flutter 앱 store 설정 | 모바일 release owner | 플랫폼별 signing/provisioning 필요 |
| business logic | 앱 코드 PR | infra PR과 기능 PR 분리 |

## 4. 경계별 변경 예시

| 변경 | Terraform PR | App PR | Runbook/수동 |
| --- | --- | --- | --- |
| Azure Redis instance 추가 | 필요 | Redis URL config 대응만 | secret/connection smoke |
| `users` 컬럼 추가 | 불필요 | Flyway migration 필요 | backup/smoke |
| Kakao client secret 교체 | 불필요 | 불필요 | Key Vault secret 갱신, runtime restart |
| API Management route 추가 | 필요 | endpoint가 없다면 필요 | smoke |
| records media upload provider 전환 | storage/identity/env가 없으면 필요 | MediaService/provider binding 필요 | upload/read/delete smoke, orphan cleanup |
| PMTiles object 교체 | container/edge가 없으면 필요 | 불필요 | versioned object upload, manifest pointer 전환, cache invalidation/rollback |
| Service Bus queue 추가 | 필요 | consumer/publisher 필요 | dead-letter/monitoring smoke |

## 5. Terraform module 후보

초기 skeleton은 다음 module 경계를 우선 검토한다.

```text
infra/terraform/
  environments/
    staging/
    prod/
  modules/
    naming/
    resource-group/
    network/
    key-vault/
    container-apps/
    postgres/
    redis/
    storage/
    messaging/
    observability/
    edge/
```

module 이름은 실제 리소스 생성 전 ADR 또는 PR 설명에서 확정한다.

## 6. Terraform state/backend 기준

Terraform skeleton을 실제 `plan/apply` 대상으로 만들기 전에 state/backend를 먼저 결정한다.

| 항목 | 후보 | 기본 방향 |
| --- | --- | --- |
| state backend | Azure Storage Account blob backend | Azure 기준으로 고정. local state는 개인 실험 외 금지 |
| state lock | Azure Blob lease | GitHub Actions와 로컬 apply가 동시에 실행되지 않도록 사용 |
| 환경 분리 | `infra/terraform/environments/staging`, `infra/terraform/environments/prod` 폴더 분리 | 초기에는 Terraform workspace보다 폴더 분리를 우선 |
| state key | environment별 고정 key | 예: `onmu-staging.tfstate`, `onmu-prod.tfstate` 후보 |
| backend 리소스 소유 | bootstrap runbook 또는 별도 승인된 bootstrap PR | 앱 리소스 PR과 섞지 않음 |
| naming convention | app/env/region/component suffix | skeleton PR에서 확정 |
| required tags | `app`, `env`, `owner`, `cost_center`, `managed_by`, `data_classification` 후보 | cost 추적과 삭제 방지 기준 |

backend storage account, container, lock 권한을 만들기 전에는 production `terraform apply`를 실행하지 않는다. backend 설정과 state 접근 권한은 secret value 없이 resource id, role assignment presence, environment name 중심으로 검토한다.

## 7. Container Apps secret reference 기준

Azure Container Apps를 staging 1차 runtime으로 쓸 때는 container env var에 secret 값을 직접 넣지 않고 Key Vault secret reference를 우선 사용한다.

Terraform skeleton은 다음 의존성을 명시해야 한다.

1. User-assigned managed identity를 만든다.
2. Key Vault에 해당 identity의 secret read 권한을 부여한다. 기본 후보 역할은 `Key Vault Secrets User`다.
3. Container Apps secret은 secret value가 아니라 Key Vault secret URI와 identity reference를 사용한다.
4. Container env var는 Container Apps secret name만 참조한다.
5. Container App 또는 revision 배포는 Key Vault role assignment 이후 실행되도록 `depends_on`을 둔다.

이 순서가 없으면 Terraform apply는 성공해도 container가 startup 시점에 secret을 읽지 못해 crash loop에 들어갈 수 있다. secret value는 Terraform variable, state, plan artifact, GitHub Actions log에 남기지 않는다. plan/review에는 secret name, Key Vault URI path, identity resource id, role assignment 존재 여부만 남긴다.

## 8. PR 분리 기준

- Terraform skeleton PR: 리소스 정의와 variable/output만 포함한다.
- Runtime config PR: Spring/FastAPI env binding, health/readiness, secret name mapping만 포함한다.
- Data migration PR: Flyway/Alembic/schema 또는 migration job만 포함한다.
- Mobile PR: API base URL, 공개 OAuth define, platform 설정만 포함한다.
- Operations PR: runbook, smoke, rollback, checklist만 포함한다.
