# Spring Boot Main API

`services/api-spring`은 ONMU의 확정 Main API입니다. Flutter 앱이 직접 호출하는 공개 `/api/v1` 계약은 이 서비스가 구현하고, FastAPI Worker는 모바일 앱에 직접 노출하지 않는 내부 AI/Data worker로 둡니다.

현재 브랜치에서는 Spring Boot 앱을 실제 실행 가능한 상태로 시작합니다. 아직 제품 기능 전체를 구현한 것은 아니며, Windows backend-host의 `spring` runtime smoke와 Flutter mock-to-API 전환을 위한 최소 core API부터 제공합니다.

## 기술 선택

- Spring Boot 3.5.x
- Java 21 target
- Maven wrapper
- Spring Web, Validation, Security, Actuator
- Spring Data JPA
- PostgreSQL driver
- Flyway
- Test

Maven을 선택한 이유는 이 저장소의 Spring 앱이 아직 작고, `pom.xml` 한 파일에서 의존성/Java target/plugin을 읽기 쉬우며, 로컬 PC에 Maven/Gradle이 없어도 wrapper로 같은 명령을 재현하기 쉽기 때문입니다.

## 실행

로컬 의존성 실행:

```powershell
cd C:\dev\ONMU
npm run host:windows
```

Spring Boot 실행:

```powershell
cd C:\dev\ONMU\services\api-spring
.\mvnw.cmd spring-boot:run
```

빌드와 테스트:

```powershell
cd C:\dev\ONMU\services\api-spring
.\mvnw.cmd test
.\mvnw.cmd -DskipTests package
```

## 환경 변수

기본값은 Windows dev backend-host와 맞춰져 있습니다.

| 변수 | 기본값 | 설명 |
| --- | --- | --- |
| `SERVER_ADDRESS` | `API_HOST` 또는 `127.0.0.1` | Spring 서버 bind 주소 |
| `SERVER_PORT` | `API_PORT` 또는 `8080` | Spring 서버 포트 |
| `POSTGRES_HOST_PORT` | `15432` | 로컬 Docker PostgreSQL host port |
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://localhost:${POSTGRES_HOST_PORT}/onmu` | Spring JDBC URL |
| `SPRING_DATASOURCE_USERNAME` | `onmu` | DB 사용자 |
| `SPRING_DATASOURCE_PASSWORD` | `POSTGRES_PASSWORD` 또는 dev 기본값 | DB 비밀번호 |
| `REDIS_URL` | 없음 | Redis readiness 우선 연결 문자열 |
| `REDIS_HOST` / `REDIS_PORT` | `localhost` / `6379` | `REDIS_URL`이 없을 때 Redis TCP check 대상 |
| `OBJECT_STORAGE_ENDPOINT` | 없음 | MinIO readiness 우선 endpoint |
| `MINIO_ENDPOINT` | `http://localhost:9000` | `OBJECT_STORAGE_ENDPOINT`가 없을 때 MinIO health check endpoint |
| `ONMU_ENV` | `local` | health 응답 환경 표시 |
| `ONMU_ACCESS_LOG_PATH` | `logs/api-access.log` | Spring request-level access log JSONL 파일 경로 |
| `ONMU_ACCESS_TOKEN_SECRET` | 로컬 dev 기본값 | HS256 access JWT 서명 secret. 공유 dev/integration은 Key Vault의 `dev-access-token-secret` 또는 `int-access-token-secret`에서 주입 |
| `ONMU_API_ACCESS_TOKEN` | 없음 | legacy 정적 token 이름. 현재 Spring 인증 필터는 이 값을 access token으로 검증하지 않음 |
| `ONMU_API_REFRESH_TOKEN` | 없음 | legacy refresh smoke token 이름. refresh token 저장/회전 구현 검증 외에는 Flutter 실행 token으로 쓰지 않음 |
| `ONMU_CORS_ORIGINS` | 없음 | dev/integration 공통 CORS origin 목록. `ONMU_DEV_CORS_ORIGINS`은 dev fallback |
| `ONMU_OAUTH_KAKAO_USER_INFO_URL` | `https://kapi.kakao.com/v2/user/me` | Kakao provider access token 검증용 user info endpoint override |
| `ONMU_OAUTH_NAVER_USER_INFO_URL` | `https://openapi.naver.com/v1/nid/me` | Naver provider access token 검증용 user info endpoint override |
| `KAKAO_REST_API_KEY` | 없음 | Kakao authorization code token exchange에 필요한 OAuth client id이자 Kakao Local Keyword Search 서버 전용 REST API key. Flutter에 전달하지 않음 |
| `KAKAO_CLIENT_SECRET` | 없음 | Kakao authorization code token exchange에 필요한 서버 전용 OAuth secret. Key Vault secret name은 `dev-kakao-client-secret` 또는 `int-kakao-client-secret`이며 Flutter에 넣지 않음 |
| `KAKAO_OAUTH_REDIRECT_URI` | `https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback` | Kakao token exchange에 사용하는 redirect URI |
| `KAKAO_OAUTH_TOKEN_URL` | `https://kauth.kakao.com/oauth/token` | Kakao authorization code token endpoint override |
| `KAKAO_OAUTH_MOBILE_CALLBACK_URI` | `io.onieum.onmu://oauth/kakao/callback` | Spring callback이 Flutter 앱으로 code/state를 넘길 때 사용하는 mobile deep link |
| `NAVER_OAUTH_CLIENT_ID` | 없음 | Naver authorization code token exchange에 필요한 서버 전용 OAuth client id |
| `NAVER_OAUTH_CLIENT_SECRET` | 없음 | Naver authorization code token exchange에 필요한 서버 전용 OAuth client secret. Flutter에 넣지 않음 |
| `NAVER_OAUTH_TOKEN_URL` | `https://nid.naver.com/oauth2.0/token` | Naver authorization code token endpoint override |
| `NAVER_OAUTH_MOBILE_CALLBACK_URI` | `io.onieum.onmu://oauth/naver/callback` | Spring callback이 Flutter 앱으로 code/state를 넘길 때 사용하는 mobile deep link |
| `NAVER_SEARCH_CLIENT_ID` | 없음 | Naver Local Search 서버 전용 client id. Flutter에 전달하지 않음 |
| `NAVER_SEARCH_CLIENT_SECRET` | 없음 | Naver Local Search 서버 전용 client secret. Flutter에 전달하지 않음 |
| `OPENROUTESERVICE_API_KEY` | 없음 | OpenRouteService route recommendation 서버 전용 API key. Flutter에 전달하지 않음 |

secret, OAuth client secret, DB 비밀번호, Cloudflare token, Azure credential은 코드와 문서에 평문으로 두지 않습니다. 공유 Windows 서버에서는 Azure Key Vault 또는 로컬 환경변수에서 주입합니다.

## Flyway

Spring Boot Flyway가 core schema를 소유합니다.

- `V1__core_schema_scaffold.sql`: core table 초안
- `V2__dev_seed_data.sql`: contract smoke용 synthetic seed와 `public_id` 보강
- `V3__vertical_slice_contract_tables.sql`: Spring 세로 흐름 smoke용 장소/투표 contract seed
- `V4__core_schema_data_dictionary.sql`: 데이터사전 기반 core app schema 확장
- `V5__core_seed_data_dictionary.sql`: 데이터사전 검증용 synthetic seed
- `V6__align_friend_settings_data_dictionary.sql`: canonical friendship와 사용자별 친구 설정 정합성 보정
- `V7__add_external_place_links.sql`: 장소 외부 링크 canonical 원장과 `external_places.link_summary` 표시 캐시 추가
- `V8__screen_aligned_dev_seed.sql`: Flutter mock 화면과 맞춘 synthetic seed와 정산 item/target/transfer seed 보강
- `V8__add_place_candidate_hearts.sql`: 장소 후보별 사용자 하트 저장소와 중복 방지 제약 추가
- `V9__screen_aligned_dev_seed.sql`: Flutter 화면 정합 smoke용 synthetic seed 보강
- `V10__auth_user_profile_infra.sql`: 인증/프로필 구현에 필요한 사용자 프로필, 인증 identity, refresh token 보강

`public_id`는 Flutter API 전환 검증 ID인 `groupId=1`, `planId=101`, `voteId=501`을 유지하기 위한 외부 contract ID입니다. 내부 PK는 UUID를 사용합니다.

FastAPI Worker Alembic은 `worker_ai` schema만 소유합니다. FastAPI Worker는 core domain table을 직접 수정하지 않습니다.

## 구현된 Endpoint

Health:

- `GET /healthz`
- `GET /readyz`

`/readyz`는 PostgreSQL, Redis, MinIO를 모두 필수 의존성으로 확인합니다. Redis는 TCP socket으로, MinIO는 `{endpoint}/minio/health/live` HTTP 요청으로 검사합니다. 하나라도 실패하면 HTTP 503을 반환하고, 응답에는 dependency별 `ok`, `required`, `detail` 또는 `error`만 포함합니다.

Core API:

- `GET /api/v1/home/summary`
- `GET /api/v1/users/me`
- `GET /api/v1/groups`
- `POST /api/v1/groups`
- `GET /api/v1/groups/{groupId}`
- `PATCH /api/v1/groups/{groupId}`
- `GET /api/v1/groups/{groupId}/members`
- `DELETE /api/v1/groups/{groupId}/members/me`
- `GET /api/v1/groups/{groupId}/summary`
- `GET /api/v1/groups/{groupId}/plans`
- `POST /api/v1/groups/{groupId}/plans`
- `GET /api/v1/groups/{groupId}/plans/{planId}`
- `PATCH /api/v1/groups/{groupId}/plans/{planId}`
- `GET /api/v1/groups/{groupId}/plans/{planId}/participants`
- `PUT /api/v1/groups/{groupId}/plans/{planId}/participants/me`
- `PATCH /api/v1/groups/{groupId}/plans/{planId}/participants/me`
- `POST /api/v1/place-search`
- `GET /api/v1/groups/{groupId}/votes`
- `POST /api/v1/groups/{groupId}/votes`
- `GET /api/v1/groups/{groupId}/votes/{voteId}`
- `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates`
- `POST /api/v1/groups/{groupId}/plans/{planId}/place-candidates`
- `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}`
- `PUT /api/v1/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}/heart`
- `POST /api/v1/groups/{groupId}/plans/{planId}/schedule-places`
- `GET /api/v1/groups/{groupId}/plans/{planId}/schedule-places`
- `GET /api/v1/groups/{groupId}/chat/messages`
- `POST /api/v1/groups/{groupId}/chat/messages`
- `PUT /api/v1/groups/{groupId}/chat/read-state`
- `GET /api/v1/groups/{groupId}/chat/events`
- `GET /api/v1/groups/{groupId}/plans/{planId}/settlement-draft`
- `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft`
- `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft/items/{itemId}/targets`
- `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/preview`
- `POST /api/v1/groups/{groupId}/plans/{planId}/settlements`
- `GET /api/v1/groups/{groupId}/plans/{planId}/settlements`
- `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}`
- `GET /api/v1/notifications`

Auth scaffold:

- `POST /api/v1/auth/oauth/{provider}`
- `GET /api/v1/auth/oauth/naver/callback`
- `GET /api/v1/auth/oauth/kakao/callback`
- `GET /api/v1/auth/session`
- `POST /api/v1/auth/refresh`
- `DELETE /api/v1/auth/session`

`POST /api/v1/auth/oauth/kakao`는 Flutter가 전달한 Kakao `providerAccessToken` 또는 `authorizationCode`를 Spring에서 검증한 뒤 ONMU access JWT와 refresh token을 발급합니다. `authorizationCode` 경로는 Spring이 서버 환경변수의 `KAKAO_REST_API_KEY`, 선택적 `KAKAO_CLIENT_SECRET`, `KAKAO_OAUTH_REDIRECT_URI`로 Kakao token endpoint를 호출해 provider access token을 받은 뒤 Kakao user info API(`GET https://kapi.kakao.com/v2/user/me`)로 검증합니다. provider access token은 ONMU API의 `Authorization` bearer token으로 쓰지 않습니다.

`POST /api/v1/auth/oauth/naver`는 Flutter가 전달한 Naver `providerAccessToken` 또는 `authorizationCode`를 Spring에서 검증한 뒤 ONMU access JWT와 refresh token을 발급합니다. `authorizationCode` 경로는 Spring이 서버 환경변수의 `NAVER_OAUTH_CLIENT_ID`, `NAVER_OAUTH_CLIENT_SECRET`으로 Naver token endpoint를 호출해 provider access token을 받은 뒤 Naver user info API(`GET https://openapi.naver.com/v1/nid/me`)로 검증합니다. Naver `response.id`를 provider subject로 사용하고, `response.name`, `response.email`, `response.profile_image`는 있으면 프로필 입력값으로 매핑합니다. provider access token은 ONMU API의 `Authorization` bearer token으로 쓰지 않습니다.

Kakao authorization code token exchange는 provider-neutral exchange seam을 사용합니다. Flutter는 `KAKAO_REST_API_KEY` 또는 `KAKAO_OAUTH_CLIENT_ID`를 공개 OAuth client id로만 사용하고, `KAKAO_CLIENT_SECRET`은 Spring 서버 환경변수 또는 Key Vault secret 역할로만 관리하며 Flutter bundle이나 dart-define에 넣지 않습니다.

Kakao redirect URI 후보:

- `http://localhost:8080/api/v1/auth/oauth/kakao/callback`
- `https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback`
- prod later: `https://api.onmu.cloud/api/v1/auth/oauth/kakao/callback`

Naver authorization code token exchange도 같은 exchange seam을 사용합니다. 서버 전용 설정은 `NAVER_OAUTH_CLIENT_ID`, `NAVER_OAUTH_CLIENT_SECRET`을 사용합니다. `GET /api/v1/auth/oauth/naver/callback`은 Naver callback에서 받은 `code`, `state`, `error`를 `NAVER_OAUTH_MOBILE_CALLBACK_URI` deep link로 넘기며, token 발급은 Flutter가 다시 호출하는 `POST /api/v1/auth/oauth/naver`에서 수행합니다.

Naver redirect URI 후보:

- `http://localhost:8080/api/v1/auth/oauth/naver/callback`
- `https://dev-api.onmu.cloud/api/v1/auth/oauth/naver/callback`
- `https://int-api.onmu.cloud/api/v1/auth/oauth/naver/callback`
- future prod: `https://api.onmu.cloud/api/v1/auth/oauth/naver/callback`

Spring Boot는 canonical route를 우선 구현합니다. `POST /api/v1/groups/{groupId}/plans/{planId}/votes`와 `GET /api/v1/place-search?query=...` 같은 과거 compatibility route는 이 Spring scaffold에 추가하지 않았습니다.

## Outbox

`outbox_events` table을 유지하고, 현재는 다음 이벤트를 같은 DB transaction 안에서 기록합니다.

- `plan.created`
- `plan.updated`
- `plan.participant_updated`
- `vote.created`
- `place_candidate.created`
- `place_candidate.heart_updated`
- `schedule_place.created`
- `settlement.created`
- `notification.requested`
- `group.created`
- `group.updated`
- `group.member_left`
- `chat.message`

`chat.message`는 SCRUM-50의 in-process SSE fan-out과 SCRUM-51의 이미지 첨부 metadata를 함께 담아 future Realtime Gateway, Notification Worker, Media Worker hook 용도로 기록합니다.
아직 queue publisher/consumer가 없으므로 status는 `no_consumer`로 저장합니다. 다음 단계에서 Spring Boot publisher와 FastAPI Worker consumer를 연결합니다.

## Flutter API Mode

Flutter 앱은 기본적으로 Windows dev Spring API(`https://dev-api.onmu.cloud`)를 호출합니다. 보호 API 화면을 검증하려면 실행 전 Key Vault의 signing secret으로 짧은 수명의 access JWT를 발급한 dart-define 파일을 만듭니다.

Windows PowerShell:

```powershell
cd C:\dev\ONMU
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\new-flutter-access-jwt.ps1 -Environment dev -VaultName $env:AZURE_KEY_VAULT_NAME

cd apps\mobile-flutter
flutter run `
  --dart-define-from-file=.dart_tool\onmu-dev-api.defines.json
```

macOS:

```bash
cd <ONMU repo>
./scripts/macos/new-flutter-access-jwt.sh \
  --environment dev \
  --vault-name "$AZURE_KEY_VAULT_NAME"

./scripts/macos/run-flutter-dev-api.sh
```

`scripts/windows/new-flutter-access-jwt.ps1`와 `scripts/macos/new-flutter-access-jwt.sh`는 Key Vault의 `dev-access-token-secret`으로 짧은 수명의 HS256 JWT를 발급하고, token 값을 출력하지 않은 채 `.dart_tool/onmu-dev-api.defines.json`에만 저장합니다. Flutter API client는 `ONMU_API_ACCESS_JWT`를 우선 읽으며, fallback 호환용 `ONMU_DEV_ACCESS_TOKEN`도 같은 JWT로 채웁니다. 이 파일은 git에서 무시됩니다.

macOS 편의 실행 스크립트는 Flutter web을 `127.0.0.1:5173`에서 띄웁니다. dev Spring CORS는 이 origin을 명시적으로 허용해야 하며 wildcard로 넓히지 않습니다.

로컬 Spring API를 직접 볼 때는 base URL을 명시합니다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\new-flutter-access-jwt.ps1 `
  -Environment dev `
  -ApiBaseUrl http://127.0.0.1:8080 `
  -VaultName $env:AZURE_KEY_VAULT_NAME
```

```bash
./scripts/macos/new-flutter-access-jwt.sh \
  --environment dev \
  --api-base-url http://127.0.0.1:8080 \
  --vault-name "$AZURE_KEY_VAULT_NAME"
```

Cloudflare Tunnel을 통할 때 기본 base URL은 `https://dev-api.onmu.cloud`입니다. Android emulator에서 Windows host Spring API를 직접 볼 때는 환경에 따라 `10.0.2.2:8080` 같은 emulator host alias가 필요할 수 있습니다.

현재 API repository 전환 대상은 Home summary, Group list/detail, Plan list/detail, Vote create/detail, Place candidates, Chat messages, Settlement draft/preview/create/result입니다. memories처럼 아직 Spring endpoint가 없는 화면 보조 데이터는 API mode에서도 중립 placeholder를 반환합니다.

## 아직 Dev/Mock인 부분

- Naver는 provider access token user info 검증과 authorization code token exchange를 지원합니다. Flutter에는 `NAVER_OAUTH_CLIENT_SECRET`을 넣지 않고 Spring 서버 env로만 주입합니다.
- Kakao는 provider access token user info 검증과 authorization code token exchange를 지원합니다. Flutter에는 `KAKAO_CLIENT_SECRET`을 넣지 않고 Spring 서버 env로만 주입합니다.
- `devVerifiedSubject`는 `onmu.auth.dev-oauth-enabled=true` 또는 `ONMU_DEV_OAUTH_ENABLED=true`일 때만 NAVER dev identity로 취급합니다. provider token 또는 authorization code가 있으면 dev subject fallback을 사용하지 않습니다.
- Spring scaffold는 `/api/v1/** permitAll`, wildcard CORS, `authenticated: true` session scaffold를 제거하고 dev token 기반 보호 정책을 적용합니다. refresh token 저장/회전은 AuthService의 기존 경로를 유지합니다.
- place search는 Spring Boot가 Naver Local Search를 1차 provider로 호출하고 Kakao Keyword Search를 보강/fallback provider로 호출합니다. Flutter 앱은 Naver/Kakao를 직접 호출하지 않습니다. 외부 credential이 없으면 local/test 개발성을 위해 deterministic dev mock 결과를 반환합니다. 요청은 `query`, `groupId`, `planId`와 optional `lat`, `lng`, `radius`, `category`, `providers`, `compare`를 받을 수 있고, 응답 결과는 기존 필드에 더해 `provider`, `providerPlaceId`, `roadAddress`, `sourceUrl`, `fetchedAt`을 포함할 수 있습니다. Naver Local Search의 `mapx`, `mapy`는 WGS84 좌표로 신뢰하지 않으므로 이번 PR에서는 nullable 좌표로 둡니다.
- route recommendation은 `POST /api/v1/routes/recommend`에서 `groupId`, `planId`, `travelMode`(`car`, `walk`, `bike`)를 받습니다. `OPENROUTESERVICE_API_KEY`가 있으면 OpenRouteService를 호출하고, 없거나 후보 좌표가 부족하면 Flutter route UI가 렌더링 가능한 deterministic `dev-mock` geometry를 반환합니다.
- 장소 후보 하트는 dev currentUser 기준으로 `PUT /api/v1/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}/heart`에서 설정합니다. body의 `hearted`가 `true` 또는 생략이면 내 하트를 켜고, `false`면 끕니다. 같은 후보에 같은 사용자가 중복 하트를 만들 수 없도록 DB unique 제약을 둡니다.
- 장소 후보 기반 투표는 `POST /api/v1/groups/{groupId}/votes`에서 `targetType=PLAN`, `targetId=<planId>`, `voteType=PLACE`, `placeCandidateIds`를 받습니다. 기존 `options` 문자열 방식은 계속 허용하며, 후보 option 응답에는 `candidateId`, `candidateName`, `address`, `heartCount`, `responseCount`, `countLabel`, `progress`를 포함합니다.
- 기록 API 구현은 다음 API 구현 PR 범위입니다.
- request log는 `logs/api-access.log` JSONL 파일에 기록합니다. 기록 필드는 `method`, `path`, `status`, `duration_ms`, `dev_client`, `origin`, `request_id`, `runtime` 중심이며 Authorization, bearer token, refresh token, request body, 개인정보는 남기지 않습니다.
- Mockito는 future JDK의 dynamic agent 제한을 피하기 위해 Maven Surefire에서 `mockito-core`를 javaagent로 지정합니다.

## Smoke

### Fresh DB 기준 smoke

최종 smoke 검증은 기존 Docker volume이 아니라 fresh DB 기준으로 수행합니다. 이전 smoke에서 생성된 vote/outbox row가 남아 있으면 `group summary`나 outbox 검증에 섞여 실제 contract 오류를 가릴 수 있습니다.

공용 Windows dev runtime이나 팀원이 사용하는 compose volume은 삭제하지 않습니다. `docker compose down -v`는 smoke 전용 compose project 또는 smoke 전용 volume에서만 사용하고, 일반 검증에서는 별도 임시 컨테이너/포트(예: PostgreSQL `16543`, Redis `16379`, MinIO `19000`, Spring `18080`)로 격리합니다.

Windows dev backend CD의 runtime은 Spring Boot Main API입니다. `dev` 브랜치 merge 후 GitHub Actions가 `scripts\windows\deploy-dev-backend.ps1 -Runtime spring` 흐름으로 재배포합니다.

```powershell
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
curl http://localhost:8080/api/v1/home/summary
curl http://localhost:8080/api/v1/groups
curl http://localhost:8080/api/v1/groups/1/summary
curl -i http://localhost:8080/api/v1/groups/not-found/summary
curl http://localhost:8080/api/v1/groups/1/plans/101
curl -i http://localhost:8080/api/v1/groups/1/plans/not-found
curl http://localhost:8080/api/v1/groups/1/votes/501
curl -i http://localhost:8080/api/v1/groups/1/votes/not-found
curl.exe -X POST http://localhost:8080/api/v1/groups -H "Content-Type: application/json" --data-binary '{ "name": "새 모임" }'
curl http://localhost:8080/api/v1/groups/1/plans
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans -H "Content-Type: application/json" --data-binary '{ "title": "새 약속" }'
curl.exe -X POST http://localhost:8080/api/v1/place-search -H "Content-Type: application/json" --data-binary '{ "query": "카페", "groupId": "1", "planId": "101", "lat": 37.5665, "lng": 126.9780, "radius": 1000, "category": "cafe" }'
curl.exe -X POST http://localhost:8080/api/v1/groups/1/votes -H "Content-Type: application/json" --data-binary '{ "voteType": "PLACE", "targetType": "PLAN", "targetId": "101", "title": "장소 투표", "options": ["A", "B"] }'
curl.exe -X POST http://localhost:8080/api/v1/groups/1/votes -H "Content-Type: application/json" --data-binary '{ "voteType": "PLACE", "targetType": "PLAN", "targetId": "101", "title": "후보 기반 장소 투표", "placeCandidateIds": ["201", "202"] }'
curl http://localhost:8080/api/v1/groups/1/plans/101/place-candidates
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/place-candidates -H "Content-Type: application/json" --data-binary '{ "name": "새 후보", "category": "카페", "address": "서울" }'
curl http://localhost:8080/api/v1/groups/1/plans/101/place-candidates/201
curl.exe -X PUT http://localhost:8080/api/v1/groups/1/plans/101/place-candidates/201/heart -H "Content-Type: application/json" --data-binary '{ "hearted": true }'
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/schedule-places -H "Content-Type: application/json" --data-binary '{ "candidateId": "201", "name": "온무식당" }'
curl http://localhost:8080/api/v1/groups/1/chat/messages
curl "http://localhost:8080/api/v1/groups/1/chat/messages?limit=20"
curl.exe -X POST http://localhost:8080/api/v1/groups/1/chat/messages -H "Content-Type: application/json" --data-binary '{ "message": "채팅 API smoke" }'
curl.exe -X PUT http://localhost:8080/api/v1/groups/1/chat/read-state -H "Content-Type: application/json" --data-binary '{ "lastReadMessageId": "메시지 UUID" }'
curl http://localhost:8080/api/v1/groups/1/plans/101/settlement-draft
curl.exe -X PATCH http://localhost:8080/api/v1/groups/1/plans/103/settlement-draft/items/401/targets -H "Content-Type: application/json" --data-binary '{ "targetUserIds": ["user-jimin", "user-minsu"], "targetNames": ["지민", "민수"] }'
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/settlements/preview -H "Content-Type: application/json" --data-binary '{ "items": [{ "title": "커피", "amountWon": 12000, "payerUserId": "user-jimin", "payerName": "지민", "targetUserIds": ["user-jimin", "user-minsu"], "targetNames": ["지민", "민수"] }] }'
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/settlements -H "Content-Type: application/json" --data-binary '{ "items": [{ "title": "커피", "amountWon": 12000, "payerUserId": "user-jimin", "payerName": "지민", "targetUserIds": ["user-jimin", "user-minsu"], "targetNames": ["지민", "민수"] }] }'
curl http://localhost:8080/api/v1/groups/1/plans/101/settlements
curl http://localhost:8080/api/v1/groups/1/plans/103/settlements/301
```

`POST /settlements/preview`, `POST /settlements`는 `items`가 비어 있으면 `400 missing_settlement_items`를 반환합니다. 기본 draft preview는 `GET /settlement-draft`로 확인합니다.
정산 draft/result 응답은 `settlement_items`, `settlement_item_targets`, `settlement_transfers`를 우선 읽고, JSON `payload`는 payer user id 같은 계산 보조 필드와 이전 Flutter mock contract 호환 용도로 유지합니다. 요청은 `payerUserId`, `targetUserIds`를 우선 사용하며, `payerName`, `targetNames`는 dev seed 호환 fallback입니다. 이름 fallback이 중복 이름을 만나면 `400 ambiguous_settlement_member_name`을 반환합니다.

`GET /settlement-draft`가 저장되지 않은 synthetic draft를 반환할 때는 `persisted=false`, `targetPatchAvailable=false`입니다. 항목별 target PATCH는 `PATCH /settlement-draft`로 저장된 draft/item을 만든 뒤에만 사용합니다.

현재 DB 컬럼명은 `amount_cents`지만 정산 API의 `amountWon`/호환 `amount` 값은 KRW 원 단위 integer입니다. `mySummaryLabel`과 `memberResults[].isMe`는 실제 사용자 인증 주입 전까지 dev seed의 첫 사용자 기준으로 계산되는 dev-only 한계가 있습니다.

## 인증과 CORS 기준

Spring Boot Main API는 scaffold 단계에서도 `/api/v1/**`를 공개 `permitAll`로 두지 않습니다. 보호된 `/api/v1/**` 요청은 다음 헤더가 필요합니다.

```powershell
cd C:\dev\ONMU
$env:ONMU_ACCESS_TOKEN_SECRET="<local-only-signing-secret>"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\new-flutter-access-jwt.ps1 -ApiBaseUrl http://127.0.0.1:8080

$defines = Get-Content apps\mobile-flutter\.dart_tool\onmu-dev-api.defines.json -Raw | ConvertFrom-Json
$headers = @{ Authorization = "Bearer $($defines.ONMU_API_ACCESS_JWT)" }
Invoke-RestMethod http://127.0.0.1:8080/api/v1/home/summary -Headers $headers
```

토큰 값은 코드, 문서, 로그에 평문으로 남기지 않습니다. 공유 Windows backend-host에서는 Key Vault의 signing secret으로 JWT를 발급해 현재 로컬 프로세스 또는 git ignored dart-define 파일에서만 사용합니다.

인증 동작:

- 보호된 `/api/v1/**` endpoint는 유효한 `Authorization: Bearer <accessToken>`이 없으면 HTTP 401과 `{ "ok": false, "error": "authentication_required" }`를 반환합니다.
- Spring access token은 `iss=onmu-api`, `aud=onmu-mobile`, `typ=access`, `sub=<users.public_id>` claim을 가진 HS256 JWT입니다. 정적 `dev-api-access-token` 값은 현재 Spring 인증 필터에서 유효한 access token이 아닙니다.
- `GET /api/v1/auth/session`, `GET /api/v1/users/me`, `GET /api/v1/home/summary`는 보호된 endpoint입니다. 토큰이 유효하면 현재 인증 사용자 기준으로 session/user/viewer 정보를 반환합니다.
- `POST /api/v1/auth/refresh`는 공개 endpoint입니다. 요청 body의 `refreshToken`이 저장된 활성 refresh token과 일치할 때만 기존 token family 안에서 refresh token을 회전하고 새 access token/refresh token을 반환합니다. 이미 회전된 token 재사용이 감지되면 같은 token family를 폐기합니다.
- `POST /api/v1/auth/logout`과 contract route인 `DELETE /api/v1/auth/session`은 refresh-token 기반 공개/idempotent logout입니다. body에 `refreshToken`이 있으면 해당 token을 폐기하고, 없거나 이미 폐기된 경우에도 인증되지 않은 세션 상태를 반환합니다.
- `POST /api/v1/auth/oauth/{provider}`는 공개 endpoint지만, client가 보낸 provider subject를 신뢰하지 않습니다. Naver/Kakao provider access token은 Spring provider verifier가 user info API로 검증합니다. `devVerifiedSubject`는 `onmu.auth.dev-oauth-enabled=true` 또는 `ONMU_DEV_OAUTH_ENABLED=true`일 때만 로컬/dev scaffold로 취급하는 명시적 dev boundary입니다.

CORS는 wildcard를 쓰지 않고 명시된 origin만 허용합니다. 기본 허용 origin은 로컬 Flutter/web dev와 `https://dev-api.onmu.cloud`이며, 필요하면 쉼표로 구분해 확장합니다.

```powershell
$env:ONMU_CORS_ORIGINS="http://localhost:5173,http://127.0.0.1:5173,https://dev-api.onmu.cloud"
```

OAuth 실제 연동, refresh token 저장/회전, CORS origin 확정은 별도 PR에서 다시 검증합니다. Access log는 Spring runtime에서도 `logs/api-access.log`에 남기므로 `?client=` 또는 `X-Onmu-Dev-Client`로 팀원별 smoke 요청을 추적할 수 있습니다.
