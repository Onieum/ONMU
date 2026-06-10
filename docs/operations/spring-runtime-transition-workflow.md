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

Spring access token은 정적 문자열이 아니라 `ONMU_ACCESS_TOKEN_SECRET`으로 서명한 HS256 JWT다. Flutter API mode 실행용 token은 Key Vault의 `dev-access-token-secret` 또는 `int-access-token-secret` 값을 직접 앱에 넣지 않고, 로컬에서 짧은 수명의 JWT로 발급해 git ignored dart-define 파일로 전달한다.

이 dev/integration JWT 생성 스크립트는 로컬 smoke와 Flutter API mode 검증용이다. MVP/dev 단계에서는 현재 `sub=<users.public_id>` 흐름을 유지하며, CDC/Databricks/analytics 기준을 이유로 dev 인증 흐름을 바꾸지 않는다.

Azure/Terraform 기반 prod 전환 시에는 Flutter가 OAuth login을 시작하고, Spring Boot가 provider token/code를 검증한 뒤 access JWT와 refresh token을 발급한다. Flutter는 발급받은 token을 secure storage에 저장한다. 운영 클라이언트에는 JWT signing secret을 넣지 않고, signing secret과 token TTL은 Terraform/Key Vault/env 기준으로 관리한다.

dev Flutter 실행:

Windows PowerShell:

```powershell
cd C:\dev\ONMU
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\new-flutter-access-jwt.ps1 `
  -Environment dev `
  -VaultName $env:AZURE_KEY_VAULT_NAME

cd apps\mobile-flutter
flutter run --dart-define-from-file=.dart_tool\onmu-dev-api.defines.json
```

macOS:

```bash
cd <ONMU repo>
./scripts/macos/new-flutter-access-jwt.sh \
  --environment dev \
  --vault-name "$AZURE_KEY_VAULT_NAME"

./scripts/macos/run-flutter-dev-api.sh
```

macOS Flutter web 검증은 `http://127.0.0.1:5173` 기준으로 실행한다. 이 origin은 dev Spring CORS 허용 목록에 포함되어 있어야 하며, 임의 wildcard로 넓히지 않는다. `ONMU_ACCESS_TOKEN_SECRET`이 이미 로컬 환경변수에 있으면 macOS JWT 스크립트는 Key Vault를 호출하지 않고 해당 값으로 짧은 수명의 JWT만 발급한다.

Mac에서 dev API 연결이 의심될 때는 browser-like User-Agent와 IPv4/HTTP1.1 조건으로 public endpoint를 먼저 확인한다.

```bash
curl -4 --http1.1 --connect-timeout 5 --max-time 12 \
  -A 'Mozilla/5.0 ONMU smoke' \
  https://dev-api.onmu.cloud/healthz
curl -4 --http1.1 --connect-timeout 5 --max-time 12 \
  -A 'Mozilla/5.0 ONMU smoke' \
  https://dev-api.onmu.cloud/readyz
```

## 인증과 CORS

- `/api/v1/**` 보호 API는 bearer token을 요구한다.
- 일반 연결 확인에는 signing secret으로 발급한 access JWT만 사용한다.
- 정적 `dev-api-access-token`, `int-api-access-token` 값은 현재 Spring JWT 인증 필터의 access token으로 쓰지 않는다.
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
