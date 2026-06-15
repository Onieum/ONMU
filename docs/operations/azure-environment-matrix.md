# Azure 환경 매트릭스

이 문서는 ONMU의 local, Windows dev, integration-staging, Azure staging, Azure production 환경을 같은 축으로 비교한다. 값이 secret인 항목은 env var name 또는 Key Vault secret name만 적는다.

## 1. 환경 표

| 항목 | Local | Windows dev | Integration staging | Azure staging | Azure production |
| --- | --- | --- | --- | --- | --- |
| 목적 | 개인 개발 | 팀 공유 dev API | dev와 분리된 연동 검증 | Terraform 1차 목표 | 실제 서비스 |
| API host | `127.0.0.1:8080` | `https://dev-api.onmu.cloud` | `https://int-api.onmu.cloud` | `https://staging-api.onmu.cloud` 후보 | `https://api.onmu.cloud` 후보 |
| Compute | Spring local process | Windows stable worktree Spring | Windows 분리 process | Azure Container Apps 우선 | AKS 또는 Container Apps |
| DB | Docker Postgres/PostGIS | Docker Postgres/PostGIS | 분리 DB 또는 schema | Azure Database for PostgreSQL Flexible Server | Azure Database for PostgreSQL Flexible Server |
| Redis | Docker Redis | Docker Redis | 분리 Redis DB 또는 instance | Azure Cache for Redis | Azure Cache for Redis |
| Object storage | MinIO | MinIO | 분리 MinIO bucket | Azure Blob Storage | Azure Blob Storage + CDN/Front Door |
| Tile | local/MinIO/gateway | `https://tiles.onmu.cloud` | 별도 manifest 후보 | Blob/CDN 후보 | Blob/CDN/Front Door |
| Secret source | local env | Azure Key Vault import | Azure Key Vault import | Key Vault + Managed Identity | Key Vault + Managed Identity |
| Runtime env | shell/process env | PowerShell process env | PowerShell process env | container app env/secret ref | workload identity/secret ref |
| CI/CD | 수동 | GitHub Actions + Windows runner | GitHub Actions + Windows runner | GitHub Actions protected env | GitHub Actions protected env |
| Observability | console/log file | log file + smoke | log file + smoke | App Insights + Log Analytics | App Insights + alerts |

## 2. Secret prefix 기준

| 환경 | Key Vault secret prefix 후보 | 비고 |
| --- | --- | --- |
| Windows dev | `dev-*` | 현재 팀 공유 dev 기준 |
| Integration staging | `int-*` | dev와 token/DB를 분리 |
| Azure staging | `staging-*` | Terraform 전환 rehearsal 기준 |
| Azure production | `prod-*` | production cutover 전 별도 승인 |

Key Vault 이름과 권한 모델은 Terraform skeleton 단계에서 확정한다. 이 문서에는 secret 값이 아니라 secret name 후보만 남긴다.

## 3. OAuth redirect/callback 기준

| Provider | Windows dev | Azure staging 후보 | Production 후보 | 모바일 callback |
| --- | --- | --- | --- | --- |
| Kakao | `https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback` | `https://staging-api.onmu.cloud/api/v1/auth/oauth/kakao/callback` | `https://api.onmu.cloud/api/v1/auth/oauth/kakao/callback` | `io.onieum.onmu://oauth/kakao/callback` |
| Naver | Spring API callback 사용 시 dev host 기준 | staging host 기준 | production host 기준 | `io.onieum.onmu://oauth/naver/callback` |
| Google | 모바일은 idToken을 Spring에 전달 | staging client/server id 분리 후보 | production client/server id 분리 | platform client id 설정 |

Provider console 변경은 사용자 또는 권한 보유자가 직접 확인하고, 변경 전후에는 actual key/code/state/token 값을 출력하지 않는다.

## 4. CORS와 앱 base URL

| 환경 | API base URL | CORS origin 기준 |
| --- | --- | --- |
| Local Flutter web | local API 또는 dev API | `localhost`/`127.0.0.1` 개발 포트 |
| Android/iOS dev build | `https://dev-api.onmu.cloud` | 모바일 앱은 CORS 대상이 아님 |
| Azure staging build | `https://staging-api.onmu.cloud` 후보 | staging web origin 후보 |
| Production build | `https://api.onmu.cloud` 후보 | production web origin 후보 |

Flutter에는 공개 client id와 redirect URI만 넣는다. OAuth client secret, DB password, JWT signing secret은 Flutter에 넣지 않는다.

## 5. Smoke 기준 요약

각 환경은 최소 다음 smoke를 통과해야 한다.

- `GET /healthz` 200
- `GET /readyz` 200
- no-token `GET /api/v1/users/me` 401
- authenticated `GET /api/v1/users/me` 200
- tile manifest/style/PMTiles Range 200/206
- Naver place-search는 status/result_count/provider_counts/source_counts/coordinate_count만 보고
- chat/notification/push-token은 raw body/token 없이 status/count 중심 보고
