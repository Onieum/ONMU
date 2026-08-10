# staging cutover status

이 문서는 현재 ONMU가 어떤 환경을 사실상 배포 기준점으로 쓰는지, 그리고 팀원이 무엇을 직접 해도 되는지 빠르게 보여주기 위한 운영 경계 문서다.

## 0. 운영 이중 경로 (중요)

ONMU는 환경을 두 경로로 분리해 관리한다.

- **정식 운영 target (검증된 관리형):** `infra/terraform/`의 Azure 관리형 아키텍처(Container Apps, ACR, Front Door, Managed Redis, Event Hubs, Blob). 정식 운영 전환 시 이 경로로 이전한다. 현재는 skeleton/검증 상태로 apply 대기다.
- **현재 임시 운영 런타임:** 개발 단계 비용($0/월, 무료 한도) 때문에 정식 운영 전까지 Azure VM + Docker Compose(`infra/compose/docker-compose.prod-vm.yml`) + Cloudflare Tunnel + Cloudflare R2 + Azure PostgreSQL Flexible(관리형 DB 잔류) 조합을 쓴다. `dev` 머지 시 `deploy-staging-vm.yml`이 VM에 자동 배포한다.

이 문서의 "현재 표준"은 **임시 운영 런타임** 기준이고, "정식 운영 target" 열은 관리형 아키텍처 기준이다.

## 1. 현재 운영 판단

- 현재 일정에서는 **임시 운영 런타임(Azure VM + Cloudflare)** 을 pre-prod 기본선으로 사용한다. 비용이 주된 이유다.
- 이 판단은 정식 운영 target(관리형) 로드맵을 삭제하거나 대체하지 않는다.
- 정식 운영 target 구조와 cutover discipline은 [ONMU 릴리스 아키텍처](../architecture/release-architecture.md)와 `infra/terraform/`에 그대로 유지한다.

> **진행 중(2026-08): 무료 우선 티어 전환.** free trial 크레딧 소진에 대비해 임시 운영 런타임 자체를 12개월 무료 한도 내로 맞춘다 — VM 은 `B2ats_v2`(750h/월 무료) 복귀, PostgreSQL Flexible(유료)은 VM 컨테이너로 이관, ACR 은 Standard(무료), 빌드는 VM → CI/ACR 로 이전. 절차는 [무료 우선 티어 전환 런북](./free-tier-migration-runbook.md) 참조. PostgreSQL Flexible 이 관리형 DB 기준에서 빠지는 것이 이 전환의 핵심이다.

## 2. 지금 팀이 기준으로 삼는 경로

| 구분 | 현재 임시 운영 (실제 런타임) | 정식 운영 target (관리형, 전환 시) |
| --- | --- | --- |
| 모바일 앱 기본 재빌드 | staging host 기본값 | 동일 |
| public API smoke | `https://dev-api.onmu.cloud` (Cloudflare Tunnel) | `https://staging-api.onmu.cloud` (관리형 전환 후 기본) |
| tile manifest | `https://tiles.onmu.cloud/manifest.json` (Cloudflare R2) | Front Door custom domain cutover 후 `tiles.onmu.cloud`를 Front Door origin 기준으로 승격 |
| runtime secret source | VM 내 `.env.production` + GitHub Secrets | `onmu-dev-kv-27db5e` Key Vault secretRef |
| backend compute | Azure VM(`onmu-staging-vm`) + Docker Compose | Azure Container Apps |
| 백업/rollback compute | (임시 운영 자체가 비상용 성격) Mac/Windows on-prem은 Phase A–E 수동 fallback 후보 | 관리형 target 전환 전까지는 임시 VM 경로가 사실상 rollback 기준 |

임시 운영(VM)에서는 OAuth redirect/callback runtime env가 ACA plain env가 아니라 VM의 `.env.production`에서 주입된다. 관리형 target에서는 `onmu-dev-kv-27db5e` Key Vault secretRef 기준으로 본다. 대상은 `KAKAO_OAUTH_REDIRECT_URI`, `KAKAO_OAUTH_MOBILE_CALLBACK_URI`, `NAVER_OAUTH_REDIRECT_URI`, `NAVER_OAUTH_MOBILE_CALLBACK_URI`다.

## 3. 팀원이 가장 먼저 읽을 순서

임시 운영 런타임(현재 실제 배포 경로):

1. [VM 하이브리드 호스팅 마이그레이션 runbook](./vm-hosting-migration-runbook.md) — 현재 임시 운영 런타임(VM + Cloudflare) 세팅/배포 기준
2. [Flutter staging 실행 runbook](./flutter-staging-runbook.md)
3. [OAuth 모바일 smoke 검증 워크플로](./oauth-mobile-smoke.md)
4. [On-prem backup backend runbook](./onprem-backup-backend-runbook.md) - Mac/Windows 백업 서버 후보 준비부터 대체 운영까지
5. [Windows 노트북 백엔드 서버 세팅 가이드](./windows-backend-server.md) - Windows legacy 세부 절차나 rollback 비교가 필요할 때만

정식 운영 target(관리형) 전환 시:

6. [Azure staging 배포/운영 runbook](./azure-staging-deploy-runbook.md)
7. [Azure staging smoke checklist](./azure-staging-smoke-checklist.md)
8. [On-prem full migration runbook](./onprem-full-migration-runbook.md) - 임시 VM 경로를 완전히 내리고 관리형 target을 새 source of truth로 승격할 때

추가 참고:

- app phase 직전 세부 gate: [Azure ACA 앱 배포 사전 점검](./azure-aca-app-preflight.md)
- environment별 host/callback/define 비교: [Azure 환경 매트릭스](./azure-environment-matrix.md)
- cutover/rollback 단계: [Azure cutover/rollback runbook](./azure-cutover-rollback.md)

## 4. 누가 무엇을 직접 해도 되는가

| 작업 | 일반 구현자 | 리뷰어/승인자 | 운영자 |
| --- | --- | --- | --- |
| Flutter staging 기본 실행 | 가능 | 가능 | 가능 |
| staging OAuth smoke | 가능 | 가능 | 가능 |
| PR/push/CI 확인 | 가능 | 가능 | 가능 |
| `Build Staging Images` 실행 | 가능 | 가능 | 가능 |
| `Deploy Staging VM` 실행/확인 | 가능 | 가능 | 가능 |
| `Terraform Staging` plan-only | 가능 | 가능 | 가능 |
| `Terraform Staging` apply | 아니오, approval 필요 | approval 후 가능 | 가능 |
| `Legacy Windows backend deploy` 실행 | 아니오, 기본 사용 안 함 | rollback/dev 분리 때만 승인 | 가능 |
| Key Vault secret 값 쓰기 | 아니오 | 아니오 | 가능 |
| revision restart | 제한적, 운영 합의 필요 | 승인 후 가능 | 가능 |
| DNS/custom domain/provider console 변경 | 아니오 | 아니오 | 가능 |
| RBAC role assignment | 아니오 | 승인 후 가능 | 가능 |

## 5. protected workflow와 수동 운영 gate

### 5.1 workflow_dispatch로 가능한 것

- `Build Staging Images`
- `Deploy Staging VM` (임시 운영 런타임, `dev` push 시 자동 실행)
- `Terraform Staging`
  - `backend_smoke`
  - `wave` plan/apply
- `Legacy Windows backend deploy`
  - legacy Windows dev/integration runtime만 수동 배포
  - staging acceptance 또는 release/pre-prod gate로 사용하지 않음

### 5.2 protected approval이 필요한 것

- `azure-staging-apply` 환경을 사용하는 Terraform apply
- staging 인프라/앱 리소스 mutation

### 5.3 수동 운영이 필요한 것

- Key Vault secret value 반영
- provider console 설정
- DNS/custom domain 변경
- runtime identity RBAC 보강
- tile object 업로드

## 6. 관리형 target Terraform wave 상태

아래 표는 **정식 운영 target(관리형)의 skeleton/검증 상태**다. 현재 임시 운영은 이 표와 무관하게 VM 경로(`vm-hosting-migration-runbook.md`)로 돈다. 관리형 target은 apply 승인 전까지 plan-only/검증 상태로 본다.

| Wave | 관리형 target 상태 | 메모 |
| --- | --- | --- |
| `backend_smoke` | 검증 완료 | staging remote backend 기준점 |
| `acr_observability` | 검증 완료 | ACR, Log Analytics, App Insights 생성됨 |
| `core_foundation` | 검증 완료 | storage, Event Hubs, identity, Key Vault, ACA environment 생성됨 |
| `core_diagnostics` | 검증 완료 | foundation diagnostic setting 연결됨 |
| `frontdoor_tile_edge` | 검증 완료 | Front Door profile/endpoint/origin/route 기준 존재 |
| `frontdoor_origin_access` | 검증 완료 | `tiles` public access와 CORS 보정 반영됨 |
| `frontdoor_diagnostics` | 검증 완료 | Front Door profile diagnostic setting 존재 |
| `managed_redis_ready` | 검증 완료 | staging Managed Redis 리소스 존재 (임시 운영은 컨테이너 Redis 사용) |
| `managed_redis_diagnostics` | 검증 완료 | Managed Redis diagnostic setting 존재 |
| `postgres_ready` | 검증 완료 | PostgreSQL Flexible Server 존재 (임시 운영도 이 관리형 DB를 그대로 사용) |
| `postgres_firewall_ready` | 검증 완료 | app phase용 firewall 보정 경로 반영됨 |
| `api_app_ready` | 검증 완료 | staging API Container App 존재 |
| `worker_app_ready` | 검증 완료 | staging worker Container App 존재 |
| `key_vault_rbac` | 수동 운영 기준 | 재사용 Key Vault 기준으로 운영 경계 유지 |

## 7. 남겨둔 운영 경계

- 임시 운영(VM)에서는 runtime secret source가 VM 내 `.env.production` + GitHub Secrets 다. `onmu-dev-kv-27db5e`는 정식 운영 target(관리형)의 runtime 표준 secret source로 본다.
- `kvonmustagingkrc001`는 존재하지만 현재 앱 runtime의 기본 secret source로 보지 않는다.
- Windows dev backend는 임시 운영 표준 경로가 아니다. GitHub Actions도 자동 deploy를 하지 않고 수동 legacy workflow로만 남긴다.
- Mac/Windows on-prem backup backend는 [공통 runbook](./onprem-backup-backend-runbook.md)의 Phase A/B/C/D/E를 기준으로 준비, 데이터 rehearsal, route cutover, 지도 tile/provider 분리, Key Vault down preseed까지 이어간다. 자동 failover는 아니며 rollback point를 기록한 수동 fallback으로만 본다.
- 임시 운영(VM)에서 정식 운영 target(관리형)으로 전환하려면 [On-prem full migration runbook](./onprem-full-migration-runbook.md)을 별도 go/no-go 기준으로 따른다. 정식 운영 전환은 단순 route rollback이 아니라 VM→관리형 방향의 이전이다.
- Azure 전체 장애를 가정하는 fallback은 API/DB/media만으로 완료되지 않는다. 지도 화면은 `ONMU_TILE_MANIFEST_URL`이 backup tile route를 보도록 재빌드 또는 route 전환되어야 하며, Naver/Kakao/OpenRouteService 같은 외부 provider secret과 Spring runtime secret은 Azure/Key Vault 장애 전에 backup 장비에 사전 적재되어 있어야 한다.
- Windows backend workflow, Cloudflare tunnel, `dev-api.onmu.cloud` 문서는 임시 운영 기간 동안 유지하고 정식 운영 전환 PR에서 정비한다.
- production 전용 environment, stronger rollback discipline, private networking hardening은 정식 운영 target(관리형) 로드맵에서 후속으로 합류한다.

## 8. 지금부터의 기준

- 팀원이 무옵션으로 앱을 다시 빌드하면 임시 운영 staging을 봐야 한다.
- staging acceptance와 cutover 판단은 임시 운영(VM + Cloudflare) 기준 smoke로 본다.
- Spring API 코드 변경은 `dev` merge 후 `Deploy Staging VM` workflow(`deploy-staging-vm.yml`)의 컨테이너 빌드/rollout과 `/readyz` smoke 결과를 본다.
- dev/local은 문제 분리나 rollback 비교처럼 명시 목적이 있을 때만 사용한다.
