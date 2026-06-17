# Azure ACA 앱 배포 사전 점검

이 문서는 ONMU staging에서 Spring API와 worker를 Azure Container Apps에 올리기 전에 막히기 쉬운 조건을 한곳에 모은다. 목적은 `postgres_ready -> api_app_ready -> worker_app_ready` wave를 실행하기 전에 사람과 CI가 같은 체크리스트를 보게 만드는 것이다.

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

### 3.3 image 준비

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

Spring `/readyz`는 현재 Redis를 필수 의존성으로 본다. staging Terraform은 Azure Cache for Redis classic 신규 생성을 더 이상 전제로 둘 수 없으므로, Azure Managed Redis 설계가 닫히기 전에는 Spring app revision readiness가 실패할 수 있다.

즉, `api_app_ready`는 Container App resource를 만들 준비 단계로는 유효하지만, 최종 `/readyz=200` 승격 기준은 Redis 방향이 확정된 뒤에 다시 확인해야 한다.

### 4.2 object storage adapter

현재 Spring `MediaService`와 `/readyz` object storage check는 MinIO-compatible endpoint를 기준으로 구현되어 있다.

- `MediaService`는 MinIO client와 access key/secret path를 사용한다.
- `ReadinessProbeService`는 `{endpoint}/minio/health/live`를 호출한다.

따라서 true Azure Blob runtime으로 바로 전환하면 media upload/read와 `/readyz`가 그대로 통과하지 않을 수 있다. app phase 전에는 아래 둘 중 하나를 명시적으로 선택해야 한다.

1. Spring object storage adapter를 Azure Blob 기준으로 전환
2. staging에서만 MinIO-compatible 경로를 유지하고 ACA app rollout smoke를 먼저 통과

이 결정 없이 `api_app_ready`를 apply하면 app resource는 생겨도 runtime readiness는 막힐 수 있다.

## 5. 권장 실행 순서

### 5.1 PostgreSQL

- `Terraform Staging`에서 `wave=postgres_ready`, `apply_wave=false`로 plan 확인
- create가 PostgreSQL server/database/extension만인지 확인
- 승인 후 apply

### 5.2 Spring API

- `Build Staging Images`로 Spring image build, 필요 시 push
- `STAGING_SPRING_API_IMAGE` 갱신
- runtime identity의 `AcrPull`, `Key Vault Secrets User` 확인
- object storage/Redis 병목 상태를 확인한 뒤 `wave=api_app_ready`

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
