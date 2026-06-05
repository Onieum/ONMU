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

Maven을 선택한 이유는 이 저장소의 Spring 앱이 아직 작고, `pom.xml` 한 파일에서 의존성/Java target/plugin을 읽기 쉬우며, 이 Windows PC에 Maven/Gradle이 설치되어 있지 않아 wrapper 기반 재현성이 중요하기 때문입니다.

## 실행

로컬 의존성 실행:

```powershell
cd C:\Users\EL035\dataschool\ONMU
npm run host:windows
```

Spring Boot 실행:

```powershell
cd C:\Users\EL035\dataschool\ONMU\services\api-spring
.\mvnw.cmd spring-boot:run
```

빌드와 테스트:

```powershell
cd C:\Users\EL035\dataschool\ONMU\services\api-spring
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

Auth scaffold:

- `POST /api/v1/auth/oauth/{provider}`

Spring Boot는 canonical route를 우선 구현합니다. `POST /api/v1/groups/{groupId}/plans/{planId}/votes`와 `GET /api/v1/place-search?query=...`는 Node stub의 dev compatibility route이며, 이 Spring scaffold에는 추가하지 않았습니다.

## Outbox

`outbox_events` table을 유지하고, 현재는 다음 이벤트를 같은 DB transaction 안에서 기록합니다.

- `plan.created`
- `vote.created`

아직 queue publisher/consumer가 없으므로 status는 `no_consumer`로 저장합니다. 다음 단계에서 Spring Boot publisher와 FastAPI Worker consumer를 연결합니다.

## 아직 Dev/Mock인 부분

- Naver OAuth token exchange는 controller/service 경계만 둔 scaffold입니다.
- place search는 외부 API key 없이 neutral mock 결과를 반환합니다.
- 정산, 기록, 장소 후보 영구 CRUD는 다음 API 구현 PR 범위입니다.
- request log는 Node stub의 `logs/api-access.log`와 동등한 운영 관측성으로 후속 정리합니다.

## Smoke

```powershell
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
curl http://localhost:8080/api/v1/home/summary
curl http://localhost:8080/api/v1/groups
curl.exe -X POST http://localhost:8080/api/v1/groups -H "Content-Type: application/json" --data-binary '{ "name": "새 모임" }'
curl http://localhost:8080/api/v1/groups/1/plans
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans -H "Content-Type: application/json" --data-binary '{ "title": "새 약속" }'
curl.exe -X POST http://localhost:8080/api/v1/place-search -H "Content-Type: application/json" --data-binary '{ "query": "카페", "groupId": "1", "planId": "101" }'
curl.exe -X POST http://localhost:8080/api/v1/groups/1/votes -H "Content-Type: application/json" --data-binary '{ "voteType": "PLACE", "targetType": "PLAN", "targetId": "101", "title": "장소 투표", "options": ["A", "B"] }'
```
