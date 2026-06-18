# staging cutover status

이 문서는 현재 ONMU가 어떤 환경을 사실상 배포 기준점으로 쓰는지, 그리고 팀원이 무엇을 직접 해도 되는지 빠르게 보여주기 위한 운영 경계 문서다.

## 1. 현재 운영 판단

- 현재 일정에서는 Azure staging을 pre-prod 기본선으로 사용한다.
- 이 판단은 기존 production 로드맵을 삭제하거나 대체하지 않는다.
- 기존 production 목표 구조와 cutover discipline은 [ONMU 릴리스 아키텍처](../architecture/release-architecture.md)에 그대로 유지한다.

## 2. 지금 팀이 기준으로 삼는 경로

| 구분 | 현재 표준 | 비표준 또는 legacy |
| --- | --- | --- |
| 모바일 앱 기본 재빌드 | staging host 기본값 | dev/local은 명시 opt-in |
| public API smoke | `https://staging-api.onmu.cloud` | `https://dev-api.onmu.cloud`는 legacy/dev opt-in 전용이며 acceptance gate가 아님 |
| tile manifest | Azure Front Door default endpoint 또는 `https://tiles.onmu.cloud/manifest.json` | `tiles.onmu.cloud`는 Azure Front Door custom domain으로 정리한다. Windows local gateway는 dev 전용 |
| runtime secret source | `onmu-dev-kv-27db5e` | `kvonmustagingkrc001`는 현재 표준 runtime source 아님 |
| 표준 backend compute | Azure Container Apps | Windows Spring runtime은 legacy/dev/rollback |

OAuth redirect/callback runtime env도 ACA plain env가 아니라 `onmu-dev-kv-27db5e`의 staging Key Vault secretRef를 기준으로 본다. 대상은 `KAKAO_OAUTH_REDIRECT_URI`, `KAKAO_OAUTH_MOBILE_CALLBACK_URI`, `NAVER_OAUTH_REDIRECT_URI`, `NAVER_OAUTH_MOBILE_CALLBACK_URI`다.

## 3. 팀원이 가장 먼저 읽을 순서

1. [Flutter staging 실행 runbook](./flutter-staging-runbook.md)
2. [Azure staging 배포/운영 runbook](./azure-staging-deploy-runbook.md)
3. [Azure staging smoke checklist](./azure-staging-smoke-checklist.md)
4. [OAuth 모바일 smoke 검증 워크플로](./oauth-mobile-smoke.md)
5. [Windows 노트북 백엔드 서버 세팅 가이드](./windows-backend-server.md) - dev/rollback이 필요할 때만

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

## 6. 현재 Terraform wave 상태

아래 표는 현재 dev와 Azure 리소스 상태 기준의 운영 상태다.

| Wave | 현재 상태 | 메모 |
| --- | --- | --- |
| `backend_smoke` | 완료 | staging remote backend 기준점 |
| `acr_observability` | 완료 | ACR, Log Analytics, App Insights 생성됨 |
| `core_foundation` | 완료 | storage, Event Hubs, identity, Key Vault, ACA environment 생성됨 |
| `core_diagnostics` | 완료 | foundation diagnostic setting 연결됨 |
| `frontdoor_tile_edge` | 완료 | Front Door profile/endpoint/origin/route 기준 존재 |
| `frontdoor_origin_access` | 완료 | `tiles` public access와 CORS 보정 반영됨 |
| `frontdoor_diagnostics` | 완료 | Front Door profile diagnostic setting 존재 |
| `managed_redis_ready` | 완료 | staging Managed Redis 리소스 존재 |
| `managed_redis_diagnostics` | 완료 | Managed Redis diagnostic setting 존재 |
| `postgres_ready` | 완료 | PostgreSQL Flexible Server 존재 |
| `postgres_firewall_ready` | 완료 | app phase용 firewall 보정 경로 반영됨 |
| `api_app_ready` | 완료 | staging API Container App 존재 |
| `worker_app_ready` | 완료 | staging worker Container App 존재 |
| `key_vault_rbac` | 수동 운영 기준 | 재사용 Key Vault 기준으로 운영 경계 유지 |

## 7. 남겨둔 운영 경계

- `onmu-dev-kv-27db5e`가 현재 runtime 표준 secret source다.
- `kvonmustagingkrc001`는 존재하지만 현재 앱 runtime의 기본 secret source로 보지 않는다.
- Windows dev backend는 staging 표준 경로가 아니다. GitHub Actions도 자동 deploy를 하지 않고 수동 legacy workflow로만 남긴다.
- 2026-06-26 이후 Windows backend workflow, Cloudflare tunnel, `dev-api.onmu.cloud` 문서의 유지/삭제를 별도 PR로 판단한다.
- production 전용 environment, stronger rollback discipline, private networking hardening은 기존 production 로드맵에서 후속으로 다시 합류한다.

## 8. 지금부터의 기준

- 팀원이 무옵션으로 앱을 다시 빌드하면 staging을 봐야 한다.
- staging acceptance와 cutover 판단은 Azure 기준 smoke로 본다.
- dev/local은 문제 분리나 rollback 비교처럼 명시 목적이 있을 때만 사용한다.
