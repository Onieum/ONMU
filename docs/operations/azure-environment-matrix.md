# Azure 환경 매트릭스

이 문서는 ONMU의 local, Windows dev, integration-staging, Azure staging, Azure production 환경을 같은 축으로 비교한다. 값이 secret인 항목은 env var name 또는 Key Vault secret name만 적는다.

## 1. 환경 표

| 항목 | Local | Windows dev | Integration staging | Azure staging | Azure production |
| --- | --- | --- | --- | --- | --- |
| 목적 | 개인 개발 | legacy/dev opt-in, shutdown 전 비교 | dev와 분리된 연동 검증 | 팀 기본 pre-prod 기준 | 실제 서비스 |
| API host | `127.0.0.1:8080` | `https://dev-api.onmu.cloud` | `https://int-api.onmu.cloud` | `https://staging-api.onmu.cloud` | `https://api.onmu.cloud` 후보 |
| Compute | Spring local process | Windows stable worktree Spring | Windows 분리 process | Azure Container Apps 우선 | AKS 또는 Container Apps |
| DB | Docker Postgres/PostGIS | Docker Postgres/PostGIS | 분리 DB 또는 schema | Azure Database for PostgreSQL Flexible Server | Azure Database for PostgreSQL Flexible Server |
| Redis | Docker Redis | Docker Redis | 분리 Redis DB 또는 instance | Azure Managed Redis | Azure Managed Redis |
| Object storage | MinIO | MinIO | 분리 MinIO bucket | Azure Blob Storage native adapter | Azure Blob Storage + Front Door |
| Tile | local/MinIO/gateway | legacy tile gateway 후보 | 별도 manifest 후보 | Blob Storage + Azure Front Door Standard | Blob + Front Door |
| Secret source | local env | Azure Key Vault import | Azure Key Vault import | Key Vault + Managed Identity | Key Vault + Managed Identity |
| Runtime env | shell/process env | PowerShell process env | PowerShell process env | container app env/secret ref | workload identity/secret ref |
| CI/CD | 수동 | GitHub Actions + Windows runner | GitHub Actions + Windows runner | GitHub Actions protected env | GitHub Actions protected env |
| Observability | console/log file | log file + smoke | log file + smoke | App Insights + Log Analytics | App Insights + alerts |
| OOTD AI generation | mock provider | mock provider | mock 또는 Azure ML 후보 | Worker + Azure ML + Vision 후보, 기본 mock | production 승인 후 상업 가능 모델 또는 승인된 endpoint |

### 1.1 On-prem backup backend 후보

On-prem backup backend는 위 표의 Local/Windows dev와 다르게 팀 공용 fallback 후보를 준비하는 절차다. Mac 또는 Windows 장비를 사용할 수 있지만, Azure staging primary를 대체하거나 자동 전환하지 않는다.

| 항목 | On-prem backup 기준 |
| --- | --- |
| 목적 | Azure staging 장애 분석, 수동 fallback 준비, 복구 리허설 |
| API host | 기본 local-only `127.0.0.1:8080`, 공개 전환은 별도 승인 |
| Compute | Mac 또는 Windows Spring Boot Main API |
| DB | 기본 local/승인된 restored copy, staging raw DB 직접 복제 금지 |
| Secret source | env var name과 Key Vault secret name만 문서화, 값 복사 금지 |
| CI/CD | 자동 deploy 없음. 수동 준비와 smoke 기록 |
| 세부 runbook | [On-prem backup backend runbook](./onprem-backup-backend-runbook.md) |

## 2. Secret prefix 기준

| 환경 | Key Vault secret prefix 후보 | 비고 |
| --- | --- | --- |
| Windows dev | `dev-*` | legacy/dev opt-in 기준. release/pre-prod smoke gate가 아님 |
| Integration staging | `int-*` | dev와 token/DB를 분리 |
| Azure staging | `staging-*` | Terraform 전환 rehearsal 기준 |
| Azure production | `prod-*` | production cutover 전 별도 승인 |

Key Vault 이름과 권한 모델은 Terraform skeleton 단계에서 확정한다. 이 문서에는 secret 값이 아니라 secret name 후보만 남긴다.

## 3. OAuth redirect/callback 기준

| Provider | Local | Windows dev | Azure staging | Production 후보 | 모바일 callback |
| --- | --- | --- | --- | --- | --- |
| Kakao | `http://localhost:8080/api/v1/auth/oauth/kakao/callback` 또는 provider console에 등록된 local callback | `https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback` | `https://staging-api.onmu.cloud/api/v1/auth/oauth/kakao/callback` | `https://api.onmu.cloud/api/v1/auth/oauth/kakao/callback` | `io.onieum.onmu://oauth/kakao/callback` |
| Naver | `http://localhost:8080/api/v1/auth/oauth/naver/callback` | `https://dev-api.onmu.cloud/api/v1/auth/oauth/naver/callback` | `https://staging-api.onmu.cloud/api/v1/auth/oauth/naver/callback` | `https://api.onmu.cloud/api/v1/auth/oauth/naver/callback` | `io.onieum.onmu://oauth/naver/callback` |
| Google | local public client id + Spring `POST /api/v1/auth/oauth/google` | dev public client id/server client id | staging public client id/server client id 후보 | production public client id/server client id 후보 | Android package/SHA-1, iOS `GOOGLE_IOS_REVERSED_CLIENT_ID` URL scheme |

Provider console 변경은 사용자 또는 권한 보유자가 직접 확인하고, 변경 전후에는 actual key/code/state/token 값을 출력하지 않는다.

OAuth smoke는 provider callback과 mobile deep link를 분리해 판정한다. Kakao/Naver browser flow는 Spring callback에 `code`/`state`가 도달한 뒤 모바일 custom scheme으로 앱 복귀가 이어져야 로그인 완료다. Flutter web callback path와 모바일 custom scheme은 같은 성공 기준으로 보지 않는다.

Azure staging/prod runtime에서는 위 redirect/callback URI 값도 Container App plain env가 아니라 Key Vault secretRef로 주입한다. Staging secret name은 `staging-kakao-oauth-redirect-uri`, `staging-kakao-oauth-mobile-callback-uri`, `staging-naver-oauth-redirect-uri`, `staging-naver-oauth-mobile-callback-uri`를 사용한다. 값 자체가 공개 URI라도 배포 경계는 secretRef로 통일한다.

## 4. CORS와 앱 base URL

| 환경 | API base URL | CORS origin 기준 | 비고 |
| --- | --- | --- | --- |
| Local Flutter web | local API 또는 dev API | `http://localhost:<port>`, `http://127.0.0.1:<port>`. 현재 Vite/Flutter web smoke 기준 `http://127.0.0.1:5173`, `http://localhost:5173` 포함 | local-only |
| Legacy Windows dev web smoke | `https://dev-api.onmu.cloud` | dev Flutter web origin 후보 또는 local web origin | 명시 opt-in한 legacy 점검 전용 |
| Legacy Android/iOS dev build | `https://dev-api.onmu.cloud` | 모바일 앱은 CORS 대상이 아님 | 명시 opt-in한 dev define에서만 사용 |
| Azure staging web build | `https://staging-api.onmu.cloud` | staging web origin 후보 | DNS/provider console 변경은 별도 승인 후 수행 |
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
| Azure staging 기본 앱 | define 없음 또는 `.dart_tool/onmu-staging-api.defines.json` | staging API base URL, 필요 시 짧은 수명 staging JWT 후보 | JWT signing secret, OAuth client secret |
| Azure staging OAuth smoke | `.dart_tool/onmu-staging-oauth.defines.json` | staging API base URL, staging public OAuth config | access token, refresh token, DB password |
| local/dev API mode | `.dart_tool/onmu-dev-api.defines.json` | `ONMU_API_BASE_URL`, 짧은 수명 dev JWT 후보 | JWT signing secret, OAuth client secret |
| dev OAuth smoke | `.dart_tool/onmu-dev-oauth.defines.json` | provider public client id, redirect URI, Google public client ids | access token, refresh token, DB password |
| production release | release pipeline managed define 후보 | production API base URL, production public OAuth config | secret 값, debug/dev token |

iOS는 `ios/Flutter/GoogleOAuth.generated.xcconfig`가 `GOOGLE_IOS_REVERSED_CLIENT_ID`를 제공해야 Google 앱 복귀가 가능하다. Android는 manifest intent filter와 package/SHA-1 provider console 설정을 환경별로 확인한다.

현재 팀 표준 모바일 재빌드 기본값은 Azure staging이다. Windows dev/local 연결은 명시적으로 dev define 또는 local base URL을 넣었을 때만 사용한다.

## 6. Smoke 기준 요약

Release/pre-prod acceptance는 Azure staging 기준으로만 본다. Local/Windows dev/integration은 해당 환경을 명시 opt-in했을 때의 보조 smoke다. Azure staging은 최소 다음 smoke를 통과해야 한다.

- `GET /healthz` 200
- `GET /readyz` 200
- no-token `GET /api/v1/users/me` 401
- authenticated `GET /api/v1/users/me` 200
- tile manifest/style/PMTiles Range 200/206
- Naver place-search는 status/result_count/provider_counts/source_counts/coordinate_count만 보고
- chat/notification/push-token은 raw body/token 없이 status/count 중심 보고

OOTD AI generation은 Azure staging에서도 단계적으로 판정한다.

- mock provider smoke: Flutter 생성 요청, Spring job 생성, worker 상태 전이, completed result 표시
- media smoke: 업로드 응답의 `storageKey`와 `publicUrl` 보존, worker가 private object key 기준으로 입력 이미지를 참조할 수 있는지 확인
- Azure ML smoke: Key Vault secret 존재 여부, worker secretRef resolve, Azure ML endpoint 호출 성공/실패 상태 전이
- Vision smoke: OOTD 사진에서 의상 descriptor JSON을 생성하되, 원본 이미지나 사용자 개인정보 값을 로그에 출력하지 않음
- result smoke: 생성 결과 이미지는 Blob generated path에 저장하고 Flutter는 Spring API가 반환한 결과 URL만 사용
