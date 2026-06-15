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
| Secret | Key Vault, access policy/RBAC, managed identity | secret 값은 별도 주입 |
| Observability | Log Analytics, Application Insights, diagnostic settings | alert는 단계적 추가 |

## 3. Terraform이 소유하지 않는 것

| 항목 | 소유자 | 이유 |
| --- | --- | --- |
| DB table/index/column | Flyway/Alembic | 앱 버전과 migration 순서가 필요 |
| seed/test 데이터 | Spring script 또는 운영 runbook | 환경별 데이터 정책이 다름 |
| 실제 secret value | Key Vault 운영 절차 | 문서/코드 유출 방지 |
| OAuth provider console 설정 | 권한 보유자 | provider UI 승인/심사 필요 |
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
| PMTiles object 교체 | 불필요 | 불필요 | object upload/rollback |
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

## 6. PR 분리 기준

- Terraform skeleton PR: 리소스 정의와 variable/output만 포함한다.
- Runtime config PR: Spring/FastAPI env binding, health/readiness, secret name mapping만 포함한다.
- Data migration PR: Flyway/Alembic/schema 또는 migration job만 포함한다.
- Mobile PR: API base URL, 공개 OAuth define, platform 설정만 포함한다.
- Operations PR: runbook, smoke, rollback, checklist만 포함한다.
