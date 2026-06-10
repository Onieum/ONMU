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
| `ONMU_API_ACCESS_TOKEN` | 없음 | dev/integration 공통 보호 API smoke token. `ONMU_DEV_ACCESS_TOKEN`은 dev fallback |
| `ONMU_API_REFRESH_TOKEN` | 없음 | dev/integration 공통 refresh smoke token. `ONMU_DEV_REFRESH_TOKEN`은 dev fallback |
| `ONMU_CORS_ORIGINS` | 없음 | dev/integration 공통 CORS origin 목록. `ONMU_DEV_CORS_ORIGINS`은 dev fallback |

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
- `V8__add_place_candidate_hearts.sql`: 장소 후보별 사용자 하트 저장소와 중복 방지 제약 추가

`public_id`는 Flutter/Node stub의 검증 ID인 `groupId=1`, `planId=101`, `voteId=501`을 유지하기 위한 외부 contract ID입니다. 내부 PK는 UUID를 사용합니다.

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
- `GET /api/v1/groups/{groupId}/plans/{planId}/settlement-draft`
- `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft`
- `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/preview`
- `POST /api/v1/groups/{groupId}/plans/{planId}/settlements`
- `GET /api/v1/groups/{groupId}/plans/{planId}/settlements`

Auth scaffold:

- `POST /api/v1/auth/oauth/{provider}`
- `GET /api/v1/auth/session`
- `POST /api/v1/auth/refresh`
- `DELETE /api/v1/auth/session`

Spring Boot는 canonical route를 우선 구현합니다. `POST /api/v1/groups/{groupId}/plans/{planId}/votes`와 `GET /api/v1/place-search?query=...`는 Node stub의 dev compatibility route이며, 이 Spring scaffold에는 추가하지 않았습니다.

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

아직 queue publisher/consumer가 없으므로 status는 `no_consumer`로 저장합니다. 다음 단계에서 Spring Boot publisher와 FastAPI Worker consumer를 연결합니다.

## Flutter API Mode

Flutter 앱은 기본적으로 mock repository를 사용합니다. Spring Main API를 직접 호출하려면 실행 시 Dart define으로 API mode를 켭니다.

```powershell
cd C:\dev\ONMU\apps\mobile-flutter
flutter run `
  --dart-define=ONMU_DATA_SOURCE=api `
  --dart-define=ONMU_API_BASE_URL=http://127.0.0.1:8080
```

Cloudflare Tunnel을 통할 때는 base URL을 `https://dev-api.onmu.cloud`로 바꿉니다. Android emulator에서 Windows host Spring API를 직접 볼 때는 환경에 따라 `10.0.2.2:8080` 같은 emulator host alias가 필요할 수 있습니다.

현재 API repository 전환 대상은 Home summary, Group list/detail, Plan list/detail, Vote create/detail, Place candidates, Settlement summary입니다. members/messages/memories처럼 아직 Spring endpoint가 없는 화면 보조 데이터는 API mode에서도 중립 placeholder를 반환합니다.

## 아직 Dev/Mock인 부분

- Naver OAuth token exchange는 controller/service 경계만 둔 scaffold입니다.
- Spring scaffold는 `/api/v1/** permitAll`, wildcard CORS, `authenticated: true` session scaffold를 제거하고 dev token 기반 보호 정책을 적용합니다. public dev 기본 runtime 전환 전에는 Naver OAuth 실제 token exchange, refresh token 저장/회전을 별도 PR에서 보강합니다.
- place search는 외부 API key 없이 neutral mock 결과를 반환합니다. 요청은 `query`, `groupId`, `planId`와 optional `lat`, `lng`, `radius`, `category`를 받을 수 있고, 응답 결과는 dev mock `source`, 합성 좌표, `heartCount`, `myHearted`를 포함합니다.
- 장소 후보 하트는 dev currentUser 기준으로 `PUT /api/v1/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}/heart`에서 설정합니다. body의 `hearted`가 `true` 또는 생략이면 내 하트를 켜고, `false`면 끕니다. 같은 후보에 같은 사용자가 중복 하트를 만들 수 없도록 DB unique 제약을 둡니다.
- 장소 후보 기반 투표는 `POST /api/v1/groups/{groupId}/votes`에서 `targetType=PLAN`, `targetId=<planId>`, `voteType=PLACE`, `placeCandidateIds`를 받습니다. 기존 `options` 문자열 방식은 계속 허용하며, 후보 option 응답에는 `candidateId`, `candidateName`, `address`, `heartCount`, `responseCount`, `countLabel`, `progress`를 포함합니다.
- 기록 API와 실제 Naver OAuth token exchange는 다음 API 구현 PR 범위입니다.
- request log는 Node stub과 같은 `logs/api-access.log` JSONL 파일에 기록합니다. 기록 필드는 `method`, `path`, `status`, `duration_ms`, `dev_client`, `origin`, `request_id`, `runtime` 중심이며 Authorization, bearer token, refresh token, request body, 개인정보는 남기지 않습니다.
- Mockito는 future JDK의 dynamic agent 제한을 피하기 위해 Maven Surefire에서 `mockito-core`를 javaagent로 지정합니다.

## Smoke

### Fresh DB 기준 smoke

최종 smoke 검증은 기존 Docker volume이 아니라 fresh DB 기준으로 수행합니다. 이전 smoke에서 생성된 vote/outbox row가 남아 있으면 `group summary`나 outbox 검증에 섞여 실제 contract 오류를 가릴 수 있습니다.

공용 Windows dev runtime이나 팀원이 사용하는 compose volume은 삭제하지 않습니다. `docker compose down -v`는 smoke 전용 compose project 또는 smoke 전용 volume에서만 사용하고, 일반 검증에서는 별도 임시 컨테이너/포트(예: PostgreSQL `16543`, Redis `16379`, MinIO `19000`, Spring `18080`)로 격리합니다.

Windows dev backend CD의 기본 runtime은 아직 `node-stub`입니다. Spring Boot Main API는 `scripts\windows\deploy-dev-backend.ps1 -Runtime spring`으로 수동 선택하는 옵션 runtime이며, dev merge와 팀 합의 전까지 기본값으로 전환하지 않습니다.

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
curl http://localhost:8080/api/v1/groups/1/plans/101/settlement-draft
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/settlements/preview -H "Content-Type: application/json" --data-binary '{ "items": [{ "title": "Coffee", "amount": 12000, "payerName": "Jimin", "targetNames": ["Jimin", "Minsu"] }] }'
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/settlements -H "Content-Type: application/json" --data-binary '{ "items": [{ "title": "Coffee", "amount": 12000, "payerName": "Jimin", "targetNames": ["Jimin", "Minsu"] }] }'
```

`POST /settlements/preview`, `POST /settlements`는 `items`가 비어 있으면 `400 missing_settlement_items`를 반환합니다. 기본 draft preview는 `GET /settlement-draft`로 확인합니다.

## Dev Token 인증과 CORS 기준

Spring Boot Main API는 scaffold 단계에서도 `/api/v1/**`를 공개 `permitAll`로 두지 않습니다. 공개 dev backend 기본 runtime은 아직 `node-stub`이며, Spring은 수동 smoke용 옵션 runtime입니다. Spring runtime을 켤 때 보호된 `/api/v1/**` 요청은 다음 헤더가 필요합니다.

```powershell
$env:ONMU_API_ACCESS_TOKEN="<local-smoke-token>"
$headers = @{ Authorization = "Bearer $env:ONMU_API_ACCESS_TOKEN" }
Invoke-RestMethod http://127.0.0.1:8080/api/v1/home/summary -Headers $headers
```

토큰 값은 코드, 문서, 로그에 평문으로 남기지 않습니다. 공유 Windows backend-host에서는 Key Vault 또는 로컬 프로세스 환경변수로만 주입합니다.

인증 scaffold 동작:

- `GET /api/v1/auth/session`: 토큰이 없으면 `authenticated: false`, 유효한 dev token이면 `authenticated: true`를 반환합니다.
- `DELETE /api/v1/auth/session`: 유효한 bearer token이 있어야 호출할 수 있습니다.
- `POST /api/v1/auth/refresh`: `ONMU_API_REFRESH_TOKEN`과 요청 body의 `refreshToken`이 일치할 때만 access token 응답을 반환합니다. dev 환경에서는 기존 `ONMU_DEV_REFRESH_TOKEN`도 fallback으로 지원합니다.
- `POST /api/v1/auth/oauth/{provider}`: Naver OAuth 실제 token exchange 전까지 public scaffold로 유지합니다.

CORS는 wildcard를 쓰지 않고 명시된 origin만 허용합니다. 기본 허용 origin은 로컬 Flutter/web dev와 `https://dev-api.onmu.cloud`이며, 필요하면 쉼표로 구분해 확장합니다.

```powershell
$env:ONMU_CORS_ORIGINS="http://localhost:5173,http://127.0.0.1:5173,https://dev-api.onmu.cloud"
```

Spring을 public dev 기본 runtime으로 전환하기 전에는 OAuth 실제 연동, refresh token 저장/회전, CORS origin 확정을 별도 PR에서 다시 검증합니다. Access log는 Spring runtime에서도 `logs/api-access.log`에 남기므로 `?client=` 또는 `X-Onmu-Dev-Client`로 팀원별 smoke 요청을 추적할 수 있습니다.
