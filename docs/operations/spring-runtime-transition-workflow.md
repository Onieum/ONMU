# Spring runtime 운영 워크플로

이 문서는 Windows `dev`와 `integration-staging` backend-host에서 Spring Boot Main API를 운영하는 기준이다. 현재 ONMU Windows backend 배포 runtime은 Spring으로 고정한다.

## 운영 결정

| 항목 | 결정 |
| --- | --- |
| public dev endpoint | `dev-api.onmu.cloud` |
| integration-staging endpoint | `int-api.onmu.cloud` |
| dev runtime | `services/api-spring` Spring Boot Main API |
| integration runtime | `services/api-spring` Spring Boot Main API |
| dev 자동 배포 | `dev` 브랜치 push 후 GitHub Actions self-hosted Windows runner가 Spring 배포 |
| integration 배포 | `workflow_dispatch`에서 `environment=integration`을 선택할 때만 수동 배포 |
| prod | 초기 Windows 단계에서는 없음 |

`api.onmu.cloud`와 prod Azure 리소스는 이 문서 범위가 아니다.

## 배포 흐름

### dev 자동 배포

PR이 `dev`에 merge되면 `.github/workflows/deploy-dev-backend.yml`이 실행된다. workflow는 Windows self-hosted runner에서 `ONMU_BACKEND_RUNTIME=spring`을 명시하고 `scripts/windows/deploy-dev-backend.ps1`을 실행한다.

확인 명령:

```powershell
gh run list --workflow "Deploy Windows backend" --branch dev --event push -L 3
gh run view <run-id> --log | Select-String -Pattern "Selected deploy environment: dev","Selected backend runtime: spring"
```

### integration-staging 수동 배포

integration-staging은 merge만으로 자동 배포하지 않는다. 권한 있는 사용자가 GitHub Actions에서 수동 실행한다.

```powershell
gh workflow run deploy-dev-backend.yml --ref dev -f environment=integration -f dry_run=false
gh run list --workflow "Deploy Windows backend" --branch dev --event workflow_dispatch -L 3
gh run view <run-id> --log | Select-String -Pattern "Selected deploy environment: integration","Selected backend runtime: spring"
```

dry-run 검증:

```powershell
gh workflow run deploy-dev-backend.yml --ref dev -f environment=integration -f dry_run=true
```

## 로컬 검증

dev:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\deploy-dev-backend.ps1 -DryRun -SkipPublicSmoke
curl.exe -i https://dev-api.onmu.cloud/healthz?client=spring-dev-smoke
curl.exe -i https://dev-api.onmu.cloud/readyz?client=spring-dev-smoke
```

integration-staging:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\deploy-integration-backend.ps1 -DryRun -SkipPublicSmoke
curl.exe -i https://int-api.onmu.cloud/healthz?client=spring-int-smoke
curl.exe -i https://int-api.onmu.cloud/readyz?client=spring-int-smoke
curl.exe -i https://int-api.onmu.cloud/api/v1/home/summary?client=spring-int-no-token
```

보호 API는 token 없이 `401`이 정상이다. bearer token smoke는 Key Vault에서 읽은 값을 현재 프로세스 환경변수에만 넣고 실행하며, 값은 출력하지 않는다.

## 인증과 CORS

- `/api/v1/**` 보호 API는 bearer token을 요구한다.
- 일반 연결 확인에는 access token만 사용한다.
- refresh token, OAuth secret, DB password, Cloudflare token 값은 문서, 로그, PR 본문, 채팅에 출력하지 않는다.
- CORS origin은 `ONMU_CORS_ORIGINS` 또는 dev fallback `ONMU_DEV_CORS_ORIGINS`로 명시한다.
- wildcard origin/header를 운영 기준으로 쓰지 않는다.

## 로그

| 환경 | 로그 |
| --- | --- |
| dev | `logs/api-access.log`, `logs/deploy-dev-backend.log`, `logs/dev-backend-api.out.log`, `logs/dev-backend-api.err.log` |
| integration-staging | `logs/integration/api-access.log`, `logs/integration/deploy-integration-backend.log`, `logs/integration/integration-backend-api.out.log`, `logs/integration/integration-backend-api.err.log` |

access log는 `method`, `path`, `status`, `duration_ms`, `dev_client`, `origin`, `request_id`, `runtime` 중심으로 확인한다. Authorization header, bearer token, refresh token, request body, 실제 개인정보는 기록하지 않는다.

## Rollback

dev 배포 실패 시에는 GitHub Actions log와 Windows 로그를 확인하고, 직전 정상 commit으로 revert PR을 만든 뒤 `dev`에 merge한다. dev/main에 직접 push하지 않는다.

integration-staging 실패 시에는 dev를 건드리지 않고 integration process와 의존성만 정리한다.

```powershell
npm run api:integration:stop
npm run compose:down:integration:windows
```

rollback 뒤에는 dev endpoint가 살아 있는지 확인한다.

```powershell
curl.exe -i https://dev-api.onmu.cloud/healthz?client=spring-rollback-dev
curl.exe -i https://dev-api.onmu.cloud/readyz?client=spring-rollback-dev
```
