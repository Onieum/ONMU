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

| Provider | Local | Windows dev | Azure staging 후보 | Production 후보 | 모바일 callback |
| --- | --- | --- | --- | --- | --- |
| Kakao | `http://localhost:8080/api/v1/auth/oauth/kakao/callback` 또는 provider console에 등록된 local callback | `https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback` | `https://staging-api.onmu.cloud/api/v1/auth/oauth/kakao/callback` | `https://api.onmu.cloud/api/v1/auth/oauth/kakao/callback` | `io.onieum.onmu://oauth/kakao/callback` |
| Naver | `http://localhost:8080/api/v1/auth/oauth/naver/callback` | `https://dev-api.onmu.cloud/api/v1/auth/oauth/naver/callback` | `https://staging-api.onmu.cloud/api/v1/auth/oauth/naver/callback` | `https://api.onmu.cloud/api/v1/auth/oauth/naver/callback` | `io.onieum.onmu://oauth/naver/callback` |
| Google | local public client id + Spring `POST /api/v1/auth/oauth/google` | dev public client id/server client id | staging public client id/server client id 후보 | production public client id/server client id 후보 | Android package/SHA-1, iOS `GOOGLE_IOS_REVERSED_CLIENT_ID` URL scheme |

Provider console 변경은 사용자 또는 권한 보유자가 직접 확인하고, 변경 전후에는 actual key/code/state/token 값을 출력하지 않는다.

OAuth smoke는 provider callback과 mobile deep link를 분리해 판정한다. Kakao/Naver browser flow는 Spring callback에 `code`/`state`가 도달한 뒤 모바일 custom scheme으로 앱 복귀가 이어져야 로그인 완료다. Flutter web callback path와 모바일 custom scheme은 같은 성공 기준으로 보지 않는다.

## 4. CORS와 앱 base URL

| 환경 | API base URL | CORS origin 기준 | 비고 |
| --- | --- | --- | --- |
| Local Flutter web | local API 또는 dev API | `http://localhost:<port>`, `http://127.0.0.1:<port>`. 현재 Vite/Flutter web smoke 기준 `http://127.0.0.1:5173`, `http://localhost:5173` 포함 | local-only |
| Windows dev web smoke | `https://dev-api.onmu.cloud` | dev Flutter web origin 후보 또는 local web origin | dev API host 자체를 browser origin으로 허용할지 여부는 별도 판단 |
| Android/iOS dev build | `https://dev-api.onmu.cloud` | 모바일 앱은 CORS 대상이 아님 | deep link/URL scheme 별도 |
| Azure staging web build | `https://staging-api.onmu.cloud` 후보 | staging web origin 후보 | Terraform 전 확정 필요 |
| Production web build | `https://api.onmu.cloud` 후보 | production web origin 후보 | production approval 필요 |

Flutter에는 공개 client id와 redirect URI, `ONMU_API_BASE_URL` 같은 공개 runtime define만 넣는다. OAuth client secret, DB password, JWT signing secret, object storage credential은 Flutter에 넣지 않는다.

CORS 기본 정책 후보:

- 허용 method: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`
- 허용 header: `Authorization`, `Content-Type`, `Accept`, `X-Requested-With`, 필요한 client metadata header
- credential 허용 여부: bearer token 기반 API는 기본적으로 cookie credential에 의존하지 않는다. cookie/session을 도입하기 전까지 `Access-Control-Allow-Credentials`는 최소화한다.
- preflight cache: staging에서 짧게 시작하고 production에서 안정화 후 늘린다.
- 보고 기준: origin/method/status/count만 기록하고 `Authorization` header와 body는 출력하지 않는다.

Edge/API gateway 단계:

| 단계 | 후보 | 판단 |
| --- | --- | --- |
| Azure staging 1차 | Container Apps ingress + Spring CORS + Key Vault secret reference | MVP 기본값 |
| Production 후보 | Front Door/WAF 또는 API Management | rate limit, WAF, custom domain, OAuth callback 안정화 후 선택 |
| 후속 hardening | Private Endpoint/VNet, APIM policy, WAF managed rules | 비용/운영 복잡도 승인 후 적용 |

## 5. Mobile build define 기준

| 환경 | Flutter define 파일 후보 | 포함 가능 | 금지 |
| --- | --- | --- | --- |
| local/dev API mode | `.dart_tool/onmu-dev-api.defines.json` | `ONMU_API_BASE_URL`, 짧은 수명 dev JWT 후보 | JWT signing secret, OAuth client secret |
| dev OAuth smoke | `.dart_tool/onmu-dev-oauth.defines.json` | provider public client id, redirect URI, Google public client ids | access token, refresh token, DB password |
| Azure staging | `.dart_tool/onmu-staging-oauth.defines.json` 후보 | staging API base URL, staging public OAuth config | secret 값 |
| production release | release pipeline managed define 후보 | production API base URL, production public OAuth config | secret 값, debug/dev token |

iOS는 `ios/Flutter/GoogleOAuth.generated.xcconfig`가 `GOOGLE_IOS_REVERSED_CLIENT_ID`를 제공해야 Google 앱 복귀가 가능하다. Android는 manifest intent filter와 package/SHA-1 provider console 설정을 환경별로 확인한다.

## 6. Smoke 기준 요약

각 환경은 최소 다음 smoke를 통과해야 한다.

- `GET /healthz` 200
- `GET /readyz` 200
- no-token `GET /api/v1/users/me` 401
- authenticated `GET /api/v1/users/me` 200
- tile manifest/style/PMTiles Range 200/206
- Naver place-search는 status/result_count/provider_counts/source_counts/coordinate_count만 보고
- chat/notification/push-token은 raw body/token 없이 status/count 중심 보고
