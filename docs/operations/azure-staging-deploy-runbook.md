# Azure staging 배포/운영 runbook

이 문서는 ONMU의 현재 표준 배포/운영 경로를 설명한다. 지금 팀의 기본선은 Azure staging이며, 이 환경을 일정상 pre-prod 기준점처럼 사용한다. 기존 production 로드맵은 유지하며, 이 문서는 현재 운영 현실만 정리한다.

## 1. 현재 표준 기준

| 항목 | 현재 기준 |
| --- | --- |
| resource group | `3dt-final-team1` |
| region | `koreacentral` |
| API public host | `https://staging-api.onmu.cloud` |
| API ACA | `ca-onmu-staging-krc-001-api` |
| worker ACA | `ca-onmu-staging-krc-001-worker` |
| ACA environment | `cae-onmu-staging-krc-001` |
| ACR | `acronmustagingkrc001` |
| PostgreSQL | `psql-onmu-staging-krc-001` |
| Managed Redis | `redis-onmu-staging-krc-001` |
| Blob Storage | `stonmustagingkrc001` |
| Front Door profile | `afd-onmu-staging-krc-001` |
| Front Door endpoint | `fde-onmustagingkrc001` |
| runtime managed identity | `id-onmu-staging-krc-001-runtime` |
| runtime secret source | 재사용 Key Vault `onmu-dev-kv-27db5e` |

추가 메모:

- `kvonmustagingkrc001` 리소스는 존재하지만 현재 runtime 표준 secret source는 아니다.
- 팀 기본 Flutter 동선은 staging이며, Windows dev backend는 표준 staging 경로가 아니라 dev/rollback/legacy 경계다.

## 2. 이 문서를 읽는 사람의 첫 분기

| 내가 하려는 일 | 먼저 할 일 |
| --- | --- |
| Flutter 앱 실행/재빌드 | [Flutter staging 실행 runbook](./flutter-staging-runbook.md) |
| 실제 OAuth/login smoke | [OAuth 모바일 smoke 검증 워크플로](./oauth-mobile-smoke.md) |
| staging backend 배포/재시작/secret refresh | 이 문서 |
| 최종 acceptance 판정 | [Azure staging smoke checklist](./azure-staging-smoke-checklist.md) |
| legacy Windows dev backend 확인 | [Windows 노트북 백엔드 서버 세팅 가이드](./windows-backend-server.md) |

추가로 같이 볼 문서:

- app phase 직전 조건을 다시 확인할 때: [Azure ACA 앱 배포 사전 점검](./azure-aca-app-preflight.md)
- 환경별 callback, define, host 차이를 비교할 때: [Azure 환경 매트릭스](./azure-environment-matrix.md)
- cutover/rollback 판단이 필요한 경우: [Azure cutover/rollback runbook](./azure-cutover-rollback.md)

## 3. 배포 전에 확인할 것

### 3.1 GitHub 기준

- 최신 `origin/dev` 기준인지 확인
- `Build Staging Images` workflow가 active인지 확인
- `Deploy Staging Spring API` workflow가 active인지 확인
- `Terraform Staging` workflow가 active인지 확인
- `azure-staging-apply` GitHub Environment가 유지되는지 확인
  - required reviewers
  - `dev` branch/ref 제한

### 3.2 GitHub Environment 이름 기준

`azure-staging-apply`에 아래 이름이 있어야 한다.

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `STAGING_POSTGRES_ADMINISTRATOR_PASSWORD`
- `STAGING_SPRING_API_IMAGE`
- `STAGING_WORKER_IMAGE`

아래 이름은 기본값이 workflow에 있지만, resource name이 바뀐 경우 GitHub Environment variable로 덮어쓴다.

- `STAGING_RESOURCE_GROUP`
- `STAGING_ACR_NAME`
- `STAGING_API_CONTAINER_APP_NAME`
- `STAGING_API_BASE_URL`

실제 값은 문서, PR, 로그에 출력하지 않는다.

### 3.3 수동 운영 gate

아래는 workflow만으로 닫히지 않는다.

- Key Vault secret 값 반영
- provider console 변경
- DNS/custom domain 변경
- runtime identity RBAC 추가
- image ref 승인

## 4. 현재 표준 운영 경로

### 4.1 코드/이미지 변경 배포

Spring API 코드만 바뀐 일반 배포는 `Deploy Staging Spring API` workflow를 표준으로 쓴다.

1. PR이 `dev`에 merge됨
2. workflow가 Spring API image를 build
3. staging ACR에 image push
4. 기존 Spring API Container App image update
5. latest revision ready 확인
6. `/healthz`, `/readyz`, no-token `/api/v1/users/me=401` smoke
7. 통과한 image ref를 `STAGING_SPRING_API_IMAGE`에 기록

이 경로는 이미 생성된 Spring API Container App의 image rollout만 담당한다. 신규 ACA 생성, PostgreSQL/Redis/Blob/Key Vault wiring 변경, worker rollout, DB migration이 필요하면 아래 Terraform split wave를 사용한다.

초기 app 생성 또는 인프라 변경 배포:

1. 최신 `origin/dev` 머지 확인
2. `Build Staging Images` 실행
3. `STAGING_SPRING_API_IMAGE`, `STAGING_WORKER_IMAGE` 갱신
4. 필요하면 `Terraform Staging`의 split wave 실행
   - `postgres_ready`
   - `api_app_ready`
   - `worker_app_ready`
5. smoke 실행

원칙:

- DB, API, worker를 한 wave로 합치지 않는다.
- plan summary가 범위를 벗어나면 apply하지 않는다.
- runtime smoke 없이 성공 판정을 내리지 않는다.

### 4.2 secret 값만 바뀐 경우

예: `staging-openrouteservice-api-key`, `staging-redis-url`, provider secret, CORS secret

1. 재사용 Key Vault `onmu-dev-kv-27db5e`에 대상 secret 값을 반영
2. 영향받는 Container App만 최소 범위로 restart
3. smoke 재실행

예시 흐름:

```powershell
az keyvault secret set `
  --vault-name onmu-dev-kv-27db5e `
  --name <secret-name> `
  --value <operator-provided-value>
```

```powershell
az containerapp revision list `
  --resource-group 3dt-final-team1 `
  --name ca-onmu-staging-krc-001-api `
  --query "[?properties.active].name" -o tsv
```

```powershell
az containerapp revision restart `
  --resource-group 3dt-final-team1 `
  --name ca-onmu-staging-krc-001-api `
  --revision <active-revision-name>
```

원칙:

- secret 값 변경 직후 전체 Terraform wave를 다시 돌리지 않는다.
- secret 값은 Key Vault에만 쓰고, 문서/PR/log에는 secret name만 남긴다.

### 4.2.1 ACA runtime env와 Key Vault secretRef 기준

Staging Container App의 runtime env는 기본적으로 Key Vault secretRef로 맞춘다. OAuth redirect URI와 mobile callback URI처럼 값 자체가 공개 URI인 항목도 예외로 두지 않는다. 이유는 재배포나 Terraform wave 이후 plain env와 secret env가 섞여 빠지는 일을 막기 위해서다.

대표 OAuth env와 Key Vault secret name:

| Env var | Key Vault secret name |
| --- | --- |
| `KAKAO_OAUTH_REDIRECT_URI` | `staging-kakao-oauth-redirect-uri` |
| `KAKAO_OAUTH_MOBILE_CALLBACK_URI` | `staging-kakao-oauth-mobile-callback-uri` |
| `NAVER_OAUTH_REDIRECT_URI` | `staging-naver-oauth-redirect-uri` |
| `NAVER_OAUTH_MOBILE_CALLBACK_URI` | `staging-naver-oauth-mobile-callback-uri` |

운영자가 위 값을 수정할 때는 Key Vault secret value만 갱신하고, ACA env는 해당 secret name을 `secretref`로 계속 바라봐야 한다. ACA revision env에 redirect URI가 plain value로 직접 들어가 있으면 임시 hotfix 상태로 보고 Terraform/ACA secretRef 경계에 맞춰 되돌린다.

### 4.3 Terraform 인프라 patch

Terraform으로 다루는 변경이면 `Terraform Staging` workflow를 사용한다.

기본 순서:

1. `apply_wave=false`로 plan-only
2. plan summary 검토
3. `azure-staging-apply` approval
4. `apply_wave=true`
5. wave 범위에 맞는 smoke

현재 기준으로 자주 쓰는 wave:

- `frontdoor_tile_edge`
- `frontdoor_origin_access`
- `frontdoor_diagnostics`
- `managed_redis_ready`
- `managed_redis_diagnostics`
- `postgres_ready`
- `api_app_ready`
- `worker_app_ready`

### 4.4 key vault secret refresh 이후 smoke

secret refresh 뒤에는 최소한 아래 순서로 다시 본다.

1. `GET /healthz`
2. `GET /readyz`
3. no-token `GET /api/v1/users/me`
4. secret 영향 기능 smoke
   - route secret이면 route smoke
   - Redis secret이면 readiness/Redis smoke
   - object storage secret이면 media smoke
   - OAuth/public define 변경이면 actual OAuth smoke

## 5. 보호 장치와 사람 손이 필요한 경계

| 작업 | workflow_dispatch 가능 | protected approval 필요 | 수동 운영 필요 |
| --- | --- | --- | --- |
| image build | 예 | 아니오 또는 repo 정책에 따름 | 아니오 |
| Spring API image rollout | 예, `dev` push도 가능 | `azure-staging-apply` 환경 정책에 따름 | 실패 시 원인 분리 |
| Terraform plan | 예 | 예 | 아니오 |
| Terraform apply | 예 | 예 | 아니오 |
| Key Vault secret 값 쓰기 | 아니오 | 아니오 | 예 |
| runtime revision restart | 부분적으로 가능하지만 현재는 수동 우선 | 환경에 따라 다름 | 예 |
| provider console 변경 | 아니오 | 아니오 | 예 |
| DNS/custom domain 변경 | 아니오 | 아니오 | 예 |
| RBAC role assignment | 경우에 따라 Terraform 가능하지만 현재는 수동 gate 우선 | 예 | 예 |

## 5.1 운영자가 직접 만지는 대표 항목

| 항목 | 표준 대상 | 기본 원칙 |
| --- | --- | --- |
| GitHub image ref | `STAGING_SPRING_API_IMAGE`, `STAGING_WORKER_IMAGE` | Spring API는 deploy workflow가 smoke 통과 image로 갱신하고, worker와 초기 app wave는 운영자가 현재 image만 반영 |
| runtime secret value | 재사용 Key Vault `onmu-dev-kv-27db5e` | secret value는 Key Vault에만 쓰고 문서/PR/log에는 secret name만 남김 |
| OAuth/provider console | Kakao, Naver, Google, 외부 provider console | callback host와 공개 client 설정만 확인하고 secret 값은 출력하지 않음 |
| custom domain/DNS | `staging-api.onmu.cloud`, `tiles.onmu.cloud` | smoke 전후 host 분리, 승인 없는 즉시 변경 금지 |
| tile object | `stonmustagingkrc001` `tiles` container | `manifest.json`, style, PMTiles 같은 서비스 필수 object만 운영 반영 |

주의:

- mock data, demo-only seed, 불필요한 sample media는 운영 기본선에 넣지 않는다.
- 필수 asset이 아니라면 앱 동작에 필요한 최소 object만 유지한다.
- 수동 운영 조치 뒤에는 해당 기능 smoke만 최소 범위로 다시 돌린다.

## 6. retry / restart / rollback 기준

### restart가 맞는 경우

- Key Vault secret 값만 바뀌었고 image나 Terraform 리소스는 그대로일 때
- active revision이 이전 값 캐시를 들고 있을 때
- `/healthz`는 200인데 특정 provider/secret wiring만 갱신이 안 됐을 때

### retry가 맞는 경우

- 같은 commit, 같은 image, 같은 secret 값으로 일시적 플랫폼 오류가 났을 때
- protected environment 승인 누락, Azure transient error처럼 원인이 분명할 때

### rollback이 맞는 경우

- 신규 image 반영 뒤 `/readyz`가 지속 실패할 때
- actual OAuth, media, route 같은 핵심 acceptance가 회귀할 때
- plan summary와 다른 리소스 mutation이 실제로 발생했을 때

원칙:

- 원인 분리 없이 전체 wave를 다시 돌리지 않는다.
- image 문제인지, secret wiring 문제인지, Terraform drift 문제인지 먼저 나눈다.

## 7. smoke 기준

이 문서는 smoke 세부 절차를 반복하지 않는다. 최종 판정은 [Azure staging smoke checklist](./azure-staging-smoke-checklist.md)를 따른다.

최소 기준만 요약하면 다음과 같다.

- `staging-api.onmu.cloud` 기준 `/healthz` 200
- `staging-api.onmu.cloud` 기준 `/readyz` 200
- no-token `/api/v1/users/me` 401
- actual OAuth `/api/v1/users/me` 200
- route provider가 `dev-mock`이 아님
- media upload/public read/presigned-url 통과
- tile/front door smoke 통과
- App Insights / Log Analytics count 정상

## 8. legacy 경계

Windows dev backend는 아직 완전히 폐기하지 않는다. 다만 현재 팀의 표준 배포/검증 기준은 Azure staging이다.

Windows 경로를 쓰는 경우:

- dev 전용 회귀 분리
- local Spring provider 문제 분리
- rollback 비교
- Cloudflare 기반 legacy dev smoke. 단, `Legacy Windows backend deploy` workflow는 자동 실행되지 않으며 수동 `workflow_dispatch`로만 사용한다.

그 외 일반 배포, 팀 모바일 재빌드, staging acceptance는 Azure 기준으로 본다.
