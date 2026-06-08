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

secret, OAuth client secret, DB 비밀번호, Cloudflare token, Azure credential은 코드와 문서에 평문으로 두지 않습니다. 공유 Windows 서버에서는 Azure Key Vault 또는 로컬 환경변수에서 주입합니다.

## Flyway

Spring Boot Flyway가 core schema를 소유합니다.

- `V1__core_schema_scaffold.sql`: core table 초안
- `V2__dev_seed_data.sql`: contract smoke용 synthetic seed와 `public_id` 보강

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
- `GET /api/v1/groups/{groupId}/summary`
- `GET /api/v1/groups/{groupId}/plans`
- `POST /api/v1/groups/{groupId}/plans`
- `GET /api/v1/groups/{groupId}/plans/{planId}`
- `POST /api/v1/place-search`
- `GET /api/v1/groups/{groupId}/votes`
- `POST /api/v1/groups/{groupId}/votes`
- `GET /api/v1/groups/{groupId}/votes/{voteId}`
- `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates`
- `POST /api/v1/groups/{groupId}/plans/{planId}/place-candidates`
- `POST /api/v1/groups/{groupId}/plans/{planId}/schedule-places`
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
- `vote.created`
- `place_candidate.created`
- `settlement.created`
- `notification.requested`

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
- place search는 외부 API key 없이 neutral mock 결과를 반환합니다.
- 기록 API와 실제 Naver OAuth token exchange는 다음 API 구현 PR 범위입니다.
- request log는 Node stub의 `logs/api-access.log`와 동등한 운영 관측성으로 후속 정리합니다.
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
curl.exe -X POST http://localhost:8080/api/v1/place-search -H "Content-Type: application/json" --data-binary '{ "query": "카페", "groupId": "1", "planId": "101" }'
curl.exe -X POST http://localhost:8080/api/v1/groups/1/votes -H "Content-Type: application/json" --data-binary '{ "voteType": "PLACE", "targetType": "PLAN", "targetId": "101", "title": "장소 투표", "options": ["A", "B"] }'
curl http://localhost:8080/api/v1/groups/1/plans/101/place-candidates
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/place-candidates -H "Content-Type: application/json" --data-binary '{ "name": "새 후보", "category": "카페", "address": "서울" }'
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/schedule-places -H "Content-Type: application/json" --data-binary '{ "candidateId": "201", "name": "온무식당" }'
curl http://localhost:8080/api/v1/groups/1/plans/101/settlement-draft
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/settlements/preview -H "Content-Type: application/json" --data-binary '{}'
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/settlements -H "Content-Type: application/json" --data-binary '{}'
```
