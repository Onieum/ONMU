# Azure ACA 앱 배포 사전 점검

이 문서는 ONMU staging에서 Spring API와 worker를 Azure Container Apps에 올리기 전에 막히기 쉬운 조건을 한곳에 모은다. 목적은 `postgres_ready -> api_app_ready -> worker_app_ready` wave를 실행하기 전에 사람과 CI가 같은 체크리스트를 보게 만드는 것이다.

이 문서는 app phase 직전 전용 점검표다. 팀 표준 staging 실행/운영 순서는 먼저 [Flutter staging 실행 runbook](./flutter-staging-runbook.md), [Azure staging 배포/운영 runbook](./azure-staging-deploy-runbook.md), [staging cutover status](./staging-cutover-status.md)를 본다.

## 1. 현재 기준

- 대상 resource group: `3dt-final-team1`
- region: `koreacentral`
- staging state key: `onmu/staging/terraform.tfstate`
- ACR: `acronmustagingkrc001`
- ACA app 배포는 아직 `Terraform Staging` workflow의 split wave를 사용한다.
- image build/push는 `Build Staging Images` workflow로 분리한다.

## 2. wave 순서

1. `postgres_ready`
2. `api_app_ready`
3. `worker_app_ready`

`db_and_app_ready`는 호환용 alias로만 유지한다. 실제 운영 순서는 split wave를 기준으로 본다.

## 3. 필수 사전 조건

### 3.1 GitHub Environment

`azure-staging-apply`에 아래 항목이 있어야 한다.

- required reviewers
- `dev` branch/ref 제한
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `STAGING_POSTGRES_ADMINISTRATOR_PASSWORD`
- `STAGING_SPRING_API_IMAGE`
- `STAGING_WORKER_IMAGE`

실제 값은 문서, PR, 로그에 출력하지 않는다.

### 3.2 runtime managed identity 권한

Spring/worker ACA revision이 정상 기동되려면 runtime managed identity에 아래 권한이 필요하다.

- staging ACR scope: `AcrPull`
- 재사용 Key Vault scope: `Key Vault Secrets User`

현재 Terraform wave는 role assignment를 자동으로 만들지 않는 경로를 기본값으로 둔다. 속도 우선 기준에서는 운영자가 수동으로 role을 부여하고, Terraform은 secret reference와 identity wiring만 유지한다.

### 3.3 runtime env secretRef 경계

Staging ACA의 Spring runtime env는 public URI 계열을 포함해 Key Vault secretRef를 기본값으로 둔다. 따라서 OAuth callback 관련 env도 plain env가 아니라 재사용 Key Vault secret name을 통해 연결한다.

필수 OAuth secretRef:

- `KAKAO_OAUTH_REDIRECT_URI` -> `staging-kakao-oauth-redirect-uri`
- `KAKAO_OAUTH_MOBILE_CALLBACK_URI` -> `staging-kakao-oauth-mobile-callback-uri`
- `NAVER_OAUTH_REDIRECT_URI` -> `staging-naver-oauth-redirect-uri`
- `NAVER_OAUTH_MOBILE_CALLBACK_URI` -> `staging-naver-oauth-mobile-callback-uri`

이 값들이 누락되면 Spring fallback callback host가 dev 계열로 돌아가 provider token exchange가 실패할 수 있다. `api_app_ready` 또는 revision restart 전에는 ACA env name이 위 secretRef를 보고 있는지만 확인하고, secret value는 출력하지 않는다.

### 3.4 image 준비

`Build Staging Images` workflow 또는 로컬 Docker build로 아래 이미지를 미리 검증한다.

- Spring API image
- worker image

image ref는 `azure-staging-apply` environment variable에 등록한 뒤 `api_app_ready` 또는 `worker_app_ready`를 실행한다.

예를 들어 workflow가 push한 ref를 운영자가 확인한 뒤 GitHub variable을 갱신한다.

```powershell
gh variable set STAGING_SPRING_API_IMAGE --env azure-staging-apply --body "<staging-spring-image-ref>"
gh variable set STAGING_WORKER_IMAGE --env azure-staging-apply --body "<staging-worker-image-ref>"
```

image ref 자체는 secret은 아니지만, 로그/채팅에는 필요 이상으로 오래된 ref와 섞이지 않게 현재 적용 대상만 관리한다.

## 4. 현재 남아 있는 병목

### 4.1 Redis

Spring `/readyz`는 현재 Redis를 필수 의존성으로 본다. staging Terraform은 Azure Managed Redis 전용 wave로 Redis를 분리한다.

사전 조건은 다음과 같다.

- tile/static edge를 사용하는 staging이면 `frontdoor_origin_access`와 `frontdoor_diagnostics`까지 먼저 정리
- `managed_redis_ready` apply 완료
- 필요 시 `managed_redis_diagnostics` apply 완료
- 운영자가 Azure Managed Redis access 정보로 재사용 runtime Key Vault의 기존 `staging-redis-url` 값을 수동 갱신
- `REDIS_URL`, `SPRING_DATA_REDIS_URL`는 계속 같은 secret name을 참조

즉, `api_app_ready`는 Container App resource를 만들 준비 단계로는 유효하지만, 최종 `/readyz=200` 승격 기준은 Managed Redis와 재사용 Key Vault secret 동기화가 끝난 뒤에 다시 확인해야 한다. 기존 staging 전용 Key Vault cleanup은 별도 승인 작업으로 남긴다.

### 4.2 object storage

Spring은 object storage provider abstraction을 사용한다. local/dev 기본값은 `OBJECT_STORAGE_PROVIDER=minio`이고, staging/prod는 `OBJECT_STORAGE_PROVIDER=azure_blob`로 Blob Storage SDK와 runtime managed identity를 사용한다.

App phase 전에는 아래 운영 gate를 확인한다.

- `OBJECT_STORAGE_ENDPOINT`, `OBJECT_STORAGE_BUCKET` secret reference가 재사용 runtime Key Vault에 존재
- Spring API Container App plain env에 `OBJECT_STORAGE_PROVIDER=azure_blob`
- runtime managed identity에 Blob storage account scope `Storage Blob Data Contributor`
- `/api/v1/uploads/presigned-url` 유지 기준으로 runtime managed identity에 `Storage Blob Delegator`

Terraform은 Blob secret value를 쓰지 않는다. secret value와 RBAC는 운영자가 승인된 경로로 수동 반영하고, 보고에는 secret name과 role/status만 남긴다.

## 5. 권장 실행 순서

### 5.1 PostgreSQL

- `Terraform Staging`에서 `wave=postgres_ready`, `apply_wave=false`로 plan 확인
- create가 PostgreSQL server/database/extension과 ACA environment static IP용 firewall rule 범위만인지 확인
- 승인 후 apply

staging은 PostgreSQL public access를 쓰는 동안 ACA environment static IP를 firewall rule로 허용해야 한다. firewall rule이 없으면 `api_app_ready` apply가 성공해도 Spring/Flyway가 DB connection timeout으로 startup 실패할 수 있다.

이미 `api_app_ready`가 부분 적용되어 Spring API Container App resource가 state에 들어간 뒤라면 `postgres_ready` 대신 `postgres_firewall_ready`를 사용한다. 이 wave는 현재 `STAGING_SPRING_API_IMAGE`를 유지한 채 firewall rule만 추가하도록 설계한다.

### 5.2 Spring API

- `Build Staging Images`로 Spring image build, 필요 시 push
- `STAGING_SPRING_API_IMAGE` 갱신
- runtime identity의 `AcrPull`, `Key Vault Secrets User` 확인
- Blob object storage RBAC와 Redis secret sync까지 끝낸 뒤 `wave=api_app_ready`

### 5.3 worker

- `Build Staging Images`로 worker image build, 필요 시 push
- `STAGING_WORKER_IMAGE` 갱신
- `wave=worker_app_ready`

## 6. smoke 기준

`api_app_ready` 또는 `worker_app_ready` 이후에는 최소한 아래를 다시 본다.

- container revision ready 여부
- `/healthz` 200
- `/readyz` 200 또는 실패 dependency 분류
- Key Vault secret reference resolved count
- image pull failure 없음
- raw secret, token, body 미출력

최종 승격 기준은 `docs/operations/azure-staging-smoke-checklist.md`를 따른다.
