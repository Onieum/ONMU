# Windows integration-staging 운영 가이드

이 문서는 ONMU 초기 단계에서 Windows 서버 안에 `dev`와 분리된 `integration-staging` 환경을 구축하고 검증하는 기준이다. 로컬 전용 초안 `onmu-windows-dev-integration-staging-rationale.md`의 결정 내용을 실행 가능한 repo 기준으로 옮긴 문서이며, secret 값은 다루지 않는다.

## 환경 역할

| 환경 | 위치 | 용도 |
| --- | --- | --- |
| dev | Windows | 개발 중인 API와 Flutter 연결을 빠르게 확인하는 공용 개발 환경 |
| integration-staging | Windows | 팀 내부 통합 smoke와 API mode 검증을 dev 재배포와 분리해 확인하는 환경 |
| prod | 없음 | 초기 Windows 단계에서는 만들지 않는다 |

prod Azure 리소스와 prod domain `api.onmu.cloud`는 이 문서 범위가 아니다.

## 분리 기준

| 항목 | dev | integration-staging |
| --- | --- | --- |
| API domain | `dev-api.onmu.cloud` | `int-api.onmu.cloud` |
| DB Access TCP domain | `db-dev.onmu.cloud` | `db-int.onmu.cloud` |
| Cloudflare tunnel | `onmu-dev-api` | `onmu-int-api` |
| Spring env | `local` 또는 dev 기준 | `integration` |
| API port | `8080` | `18080` |
| PostgreSQL host port | `15432` | `16432` |
| PostgreSQL database | `onmu` | `onmu_integration` |
| PostgreSQL user | `onmu` | `onmu_int` |
| Redis host port | `6379` | `6380` |
| MinIO API/console port | `9000` / `9001` | `9100` / `9101` |
| MinIO bucket | dev bucket | `onmu-integration` |
| 로그 | `logs/` | `logs/integration/` |
| Key Vault secret prefix | `dev-` | `int-` |

## Key Vault secret 이름

값은 Azure Key Vault에만 저장하고, 문서/PR/로그/채팅에 출력하지 않는다.

초기 integration-staging에서 사용하는 최소 secret 이름:

| Secret name | 런타임 env |
| --- | --- |
| `int-api-access-token` | `ONMU_API_ACCESS_TOKEN` |
| `int-api-refresh-token` | `ONMU_API_REFRESH_TOKEN` |
| `int-cors-origins` | `ONMU_CORS_ORIGINS` |
| `int-database-url` | `DATABASE_URL` |
| `int-postgres-password` | `POSTGRES_PASSWORD` |
| `int-redis-url` | `REDIS_URL` |
| `int-object-storage-endpoint` | `OBJECT_STORAGE_ENDPOINT` |
| `int-object-storage-bucket` | `OBJECT_STORAGE_BUCKET` |
| `int-minio-root-user` | `MINIO_ROOT_USER` |
| `int-minio-root-password` | `MINIO_ROOT_PASSWORD` |

dev token 값은 integration token으로 재사용하지 않는다. 같은 환경변수 이름으로 주입하더라도 secret name과 값은 `int-*` 기준으로 분리한다.

## 실행

integration 의존성 compose config 확인:

```powershell
npm run compose:config:integration:windows
```

Key Vault에서 `int-*` secret을 읽어 integration PostgreSQL, Redis, MinIO를 시작:

```powershell
npm run compose:up:integration:windows
npm run compose:ps:integration:windows
```

Spring integration runtime 배포:

```powershell
npm run api:integration:deploy
```

public DNS route가 아직 준비되지 않은 상태에서 local process만 검증할 때:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\deploy-integration-backend.ps1 -SkipPublicSmoke
```

Cloudflare named tunnel 실행:

```powershell
npm run tunnel:cloudflare:integration
```

DB Access TCP는 Cloudflare Zero Trust Access application과 팀 MFA policy가 active인 것을 확인한 뒤에만 실행한다.

```powershell
$env:CLOUDFLARE_ACCESS_TCP_POLICY_ACTIVE="true"
npm run tunnel:cloudflare:integration:access-tcp
```

## Smoke

dev 회귀 확인:

```powershell
curl.exe -i https://dev-api.onmu.cloud/healthz?client=integration-rollout-dev
curl.exe -i https://dev-api.onmu.cloud/readyz?client=integration-rollout-dev
```

integration 확인:

```powershell
curl.exe -i https://int-api.onmu.cloud/healthz?client=integration-rollout
curl.exe -i https://int-api.onmu.cloud/readyz?client=integration-rollout
curl.exe -i https://int-api.onmu.cloud/api/v1/home/summary?client=integration-rollout
```

보호 API는 token 없이 401이 정상이다. bearer token smoke는 `int-api-access-token` 값을 현재 프로세스 환경변수에만 넣고 실행한다. 값은 출력하지 않는다.

```powershell
curl.exe -i `
  -H "Authorization: Bearer $env:ONMU_API_ACCESS_TOKEN" `
  "https://int-api.onmu.cloud/api/v1/home/summary?client=integration-rollout"
```

CORS preflight:

```powershell
curl.exe -i -X OPTIONS `
  "https://int-api.onmu.cloud/api/v1/auth/session?client=integration-rollout" `
  -H "Origin: http://localhost:5173" `
  -H "Access-Control-Request-Method: DELETE" `
  -H "Access-Control-Request-Headers: authorization,content-type"
```

DB migration과 seed count:

```powershell
docker exec onmu-int-postgres psql -U onmu_int -d onmu_integration -c "select installed_rank, version, description, success from flyway_schema_history order by installed_rank;"
docker exec onmu-int-postgres psql -U onmu_int -d onmu_integration -c "select 'users' as table_name, count(*) from users union all select 'groups', count(*) from groups union all select 'plans', count(*) from plans;"
```

access log:

```powershell
Get-Content logs\integration\api-access.log -Tail 20
```

## Rollback

integration 실패 시 dev는 건드리지 않고 integration process와 route만 정리한다.

```powershell
$pidPath = "logs\integration\integration-backend-api.pid"
if (Test-Path $pidPath) {
  Stop-Process -Id ([int](Get-Content $pidPath -Raw)) -Force
}
npm run compose:down:integration:windows
```

Cloudflare tunnel은 실행 중인 `onmu-int-api` 프로세스만 중지한다. `onmu-dev-api`, `dev-api.onmu.cloud`, `db-dev.onmu.cloud`, `api.onmu.cloud`는 변경하지 않는다.

rollback 뒤에는 dev smoke를 다시 확인한다.

```powershell
curl.exe -i https://dev-api.onmu.cloud/healthz?client=integration-rollback-dev
curl.exe -i https://dev-api.onmu.cloud/readyz?client=integration-rollback-dev
```
