# Spring Runtime 전환 운영 워크플로우

## 문서 목적

이 문서는 Windows dev backend의 public endpoint인 `https://dev-api.onmu.cloud`를 Spring Boot Main API 기준으로 운영하기 위한 팀 작업 흐름을 설명한다.

이 문서는 실행 프롬프트가 아니다. Windows 서버에서 실제 전환을 수행할 Codex에게 보낼 프롬프트는 채팅 메시지로만 전달하고, 이 문서는 팀원이 나중에 다시 읽어도 전환 배경, 용어, 검증 순서, 장애 대응 기준을 이해할 수 있는 운영 가이드로 유지한다.

ONMU의 백엔드 개발은 이제 본격적으로 시작되는 단계다. 그래서 이 문서는 이미 모든 기술 스택에 익숙한 사람만을 위한 체크리스트가 아니라, 처음 Spring, Windows self-hosted runner, Cloudflare Tunnel, Key Vault, GitHub Actions, Flutter API mode를 함께 다루는 팀원도 따라올 수 있게 작성한다.

## 이 문서를 읽는 방법

한 번에 모든 내용을 외울 필요는 없다. 먼저 아래 세 가지 흐름만 잡으면 된다.

| 먼저 이해할 것 | 의미 |
| --- | --- |
| Endpoint와 runtime은 다르다 | `dev-api.onmu.cloud`라는 주소는 유지하고, 그 뒤에서 응답하는 프로그램을 `node-stub`에서 `spring`으로 바꾸는 작업이다. |
| Spring 전환은 기능 전환이면서 운영 전환이다 | 단순히 Spring 서버를 띄우는 것이 아니라 인증, CORS, secret, 로그, rollback, 팀 공지를 함께 맞추는 작업이다. |
| 401은 항상 장애가 아니다 | Spring 보호 API는 bearer token 없이 호출하면 401이 정상이다. 기존 plain curl 테스트와 기준이 달라진다. |

이 문서의 큰 흐름은 다음과 같다.

```text
배경 이해
  -> 현재 구조와 목표 구조 구분
  -> 전환 전에 통과해야 할 게이트 확인
  -> Windows 서버에서 Spring runtime 전환
  -> public endpoint smoke
  -> Flutter/API 팀 작업 방식 변경
  -> CD 기본 runtime 전환
  -> 장애 시 rollback
```

---

# 가이드 인덱스

| 순서 | 문서 | 이 문서에서 쓰는 이유 |
| --- | --- | --- |
| 1 | [Agent Rules](../../AGENTS.md) | dev API/dev DB secret 사용, PR, 검증 원칙의 최상위 기준이다. |
| 2 | [GitHub 작업 흐름](../development/git-workflow.md) | dev/main 직접 push 금지, Jira branch, PR, CI, review 기준을 확인한다. |
| 3 | [Windows 백엔드 서버](./windows-backend-server.md) | `dev-api.onmu.cloud`, Cloudflare Tunnel, Windows host, 배포 스크립트의 기준 문서다. |
| 4 | [현재 아키텍처 다이어그램](../architecture/current-architecture-diagram.md) | 모바일, public API, Windows backend, worker, storage의 연결 관계를 본다. |
| 5 | [API Contract Map](../architecture/api-contract-map.md) | Spring이 구현해야 할 canonical `/api/v1` route 기준이다. |
| 6 | [Mock to API Migration](../development/mock-to-api-migration.md) | Flutter가 mock repository에서 API repository로 넘어가는 기준이다. |
| 7 | [Spring Boot Main API](../../services/api-spring/README.md) | Spring runtime의 endpoint, smoke, local 실행, scaffold 범위를 확인한다. |
| 8 | [Node Smoke/Contract Stub](../../services/api/README.md) | 기존 public 안정 endpoint와 rollback runtime의 역할을 이해한다. |
| 9 | [Outbox Contract](../../services/api-spring/OUTBOX_CONTRACT.md) | Spring과 worker 사이 event boundary를 확인한다. |

---

# 핵심 용어

## Public endpoint

`https://dev-api.onmu.cloud`처럼 팀원이 브라우저, curl, Flutter 앱에서 호출하는 공개 주소다.

중요한 점은 endpoint가 바뀌는 것이 아니라는 점이다. 이번 전환의 목표는 팀 공용 주소를 그대로 유지하고, 그 뒤에서 요청을 처리하는 backend runtime만 바꾸는 것이다.

```text
전환 전:
dev-api.onmu.cloud -> Cloudflare Tunnel -> localhost:8080 -> node-stub

전환 후:
dev-api.onmu.cloud -> Cloudflare Tunnel -> localhost:8080 -> Spring Boot
```

## Runtime

같은 포트와 같은 public endpoint 뒤에서 실제로 실행되는 서버 프로그램이다.

| Runtime | 역할 |
| --- | --- |
| `node-stub` | 기존 smoke/contract 확인용 Node API. 팀 공용 안정 endpoint 역할을 했다. |
| `spring` | 앞으로의 Main API runtime. 인증, CORS, DB, canonical `/api/v1` 구현의 기준이 된다. |

전환 이후에도 `node-stub`을 삭제하지 않는다. 장애가 생겼을 때 빠르게 되돌릴 수 있는 rollback runtime으로 남긴다.

## Cloudflare Tunnel

Windows 서버의 `localhost:8080`을 외부 HTTPS 주소인 `dev-api.onmu.cloud`로 연결해주는 통로다.

Cloudflare Tunnel은 public API만 노출해야 한다. PostgreSQL, Redis, MinIO 같은 내부 의존성 포트는 외부에 열지 않는다.

## Health와 readiness

둘은 비슷해 보이지만 의미가 다르다.

| Endpoint | 의미 |
| --- | --- |
| `/healthz` | 서버 프로세스가 살아 있고 HTTP 응답을 할 수 있는지 확인한다. |
| `/readyz` | 서버가 실제 요청을 받을 준비가 됐는지 확인한다. PostgreSQL, Redis, MinIO 같은 의존성 상태까지 본다. |

`/healthz`가 성공해도 `/readyz`가 실패하면 앱 기능은 제대로 동작하지 않을 수 있다. Spring 전환 후에는 둘을 모두 확인해야 한다.

## Protected API

Spring 전환 후 `/api/v1/**`의 많은 API는 보호 API가 된다. 보호 API는 bearer token 없이는 401을 반환한다.

이것은 장애가 아니라 인증이 적용됐다는 신호다. 전환 전 팀원이 plain curl로 바로 확인하던 방식은 더 이상 모든 API에 적용되지 않는다.

```text
token 없음:
GET /api/v1/home/summary -> 401

token 있음:
GET /api/v1/home/summary -> 200
```

## CORS

브라우저 또는 Flutter web 환경에서 다른 origin의 API를 호출할 때 허용 여부를 결정하는 정책이다.

개발 중에는 `*` wildcard로 열어두고 싶어질 수 있지만, 공용 dev backend가 Spring으로 바뀌는 순간에는 팀 테스트 기준이 된다. 그래서 허용 origin을 명시하고, `ONMU_DEV_CORS_ORIGINS` 같은 환경변수로 관리해야 한다.

## Key Vault와 secret

Token, OAuth secret, DB password 같은 값은 코드나 문서에 들어가면 안 된다. 필요한 값의 이름은 문서에 남길 수 있지만, 실제 값은 Azure Key Vault, GitHub Secrets, Windows process env, 로컬 `.env` 중 안전한 곳에만 둔다.

이 문서에서도 secret 값은 쓰지 않는다.

## Self-hosted runner

GitHub Actions가 Windows 서버에서 직접 배포 스크립트를 실행할 수 있게 연결된 runner다.

이 runner는 팀 공용 backend를 실제로 바꿀 수 있으므로 PR 코드에서 무분별하게 실행하면 안 된다. 전환 작업은 승인, 게이트 확인, 수동 smoke 후에 진행한다.

---

# 현재 구조와 목표 구조

## 현재 구조

현재 구조는 public endpoint 안정성을 위해 `node-stub`을 기본 runtime으로 두고, Spring은 수동 smoke 가능한 runtime으로 준비한 상태에서 출발한다.

```text
Flutter app
  -> https://dev-api.onmu.cloud
  -> Cloudflare Tunnel
  -> Windows server localhost:8080
  -> node-stub
```

이 구조의 장점은 단순하다. 팀원이 `healthz`, `readyz`, contract smoke를 쉽게 확인할 수 있고, 인증이 아직 강하게 걸리지 않은 상태에서 API 연결 흐름을 볼 수 있다.

단점도 있다. 실제 production 방향의 Main API는 Spring이므로, 계속 `node-stub`만 기준으로 개발하면 Flutter repository, API contract, DB schema, 인증 정책이 실제 구현과 어긋날 수 있다.

## 목표 구조

목표 구조는 public endpoint 뒤의 기본 runtime을 Spring Boot로 전환하는 것이다.

```text
Flutter app
  -> https://dev-api.onmu.cloud
  -> Cloudflare Tunnel
  -> Windows server localhost:8080
  -> Spring Boot Main API
  -> PostgreSQL / Redis / MinIO
```

전환 후 팀 기준은 다음처럼 바뀐다.

| 항목 | 전환 전 | 전환 후 |
| --- | --- | --- |
| public endpoint | `dev-api.onmu.cloud` | 그대로 유지 |
| 기본 runtime | `node-stub` | `spring` |
| Node stub 역할 | 공용 기준 endpoint | rollback 및 compatibility reference |
| 보호 API | 일부 contract smoke 중심 | `/api/v1/**` bearer token 기준 |
| Flutter API mode | mock/API 전환 준비 | Spring API 기준 smoke |
| DB 기준 | stub data 중심 | Spring Flyway/PostgreSQL 기준 |
| 운영 로그 | Node access log 중심 | Spring access log 또는 관측 도구 기준 |

---

# 전환 원칙

## 1. 주소는 유지하고 기준 runtime만 바꾼다

팀원이 사용하는 주소는 `https://dev-api.onmu.cloud` 그대로다. 앱 설정과 문서 링크가 모두 이 주소를 기준으로 되어 있기 때문이다.

바꾸는 것은 주소가 아니라 `localhost:8080`에서 실행되는 프로그램이다. 이 구분이 중요하다. 주소를 바꾸면 Flutter, 문서, smoke, 팀 공지가 모두 흔들리지만, runtime만 바꾸면 같은 주소에서 실제 API 구현 기준만 Spring으로 옮길 수 있다.

## 2. Spring이 뜬 것과 Spring을 기본으로 삼는 것은 다르다

Spring을 로컬이나 Windows 서버에서 한 번 실행하는 것은 기술 검증이다. public dev backend의 기본 runtime으로 삼는 것은 팀 운영 결정이다.

기본 runtime 전환은 다음 영향을 만든다.

- 팀원이 plain curl로 호출하던 보호 API가 401을 반환할 수 있다.
- Flutter API mode는 dev token을 필요로 한다.
- CORS 허용 origin이 틀리면 브라우저 기반 테스트가 실패한다.
- Spring 로그와 Node 로그의 위치가 달라진다.
- DB readiness 실패가 public API 장애처럼 보일 수 있다.

그래서 Spring 전환은 단순 실행 성공이 아니라 운영 게이트 통과로 판단한다.

## 3. 안전한 전환은 rollback을 포함한다

전환 작업은 성공 명령만 아는 것으로 충분하지 않다. 실패했을 때 되돌리는 명령, 되돌린 뒤 확인할 smoke, 팀에 알릴 문구까지 있어야 한다.

ONMU에서는 `node-stub`을 rollback runtime으로 남긴다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\deploy-dev-backend.ps1 -Runtime node-stub -Client codex-spring-rollback
```

## 4. Secret은 값이 아니라 이름으로만 공유한다

팀원이 어떤 환경변수가 필요한지 알아야 하므로 변수 이름은 문서화한다. 하지만 실제 값은 절대 문서, PR, 로그, 채팅에 남기지 않는다.

좋은 보고:

```text
ONMU_DEV_ACCESS_TOKEN 주입 확인
ONMU_DEV_REFRESH_TOKEN 주입 확인
ONMU_DEV_CORS_ORIGINS 주입 확인
```

나쁜 보고:

```text
ONMU_DEV_ACCESS_TOKEN=실제값...
```

---

# 전환 전 게이트

Spring runtime 전환 전에 아래 게이트를 통과해야 한다.

## Git 게이트

| 확인 | 이유 |
| --- | --- |
| 최신 `dev` 기준인지 확인 | 이미 merge된 수정사항을 놓치면 서버 상태와 문서가 어긋난다. |
| PR #69 또는 동등한 auth/CORS hardening merge 확인 | hardening 없는 Spring을 public 기본 runtime으로 두면 팀 테스트 기준이 잘못 굳을 수 있다. |
| CI 성공 확인 | Flutter/API 계약 변경이 기본 검증을 통과했는지 본다. |
| review 상태 확인 | 공용 dev backend 영향이 있으므로 승인 없는 기본 전환을 피한다. |

확인 명령 예시:

```powershell
git fetch origin --prune
git switch dev
git pull --ff-only origin dev
gh pr view 69 --json state,mergeStateStatus,reviewDecision,statusCheckRollup
git log --oneline -5
```

## Spring hardening 게이트

아래 항목은 public Spring runtime 전에 최소 기준으로 본다.

| 항목 | 기대 |
| --- | --- |
| 보호 API | `/api/v1/**`는 bearer token 없이는 401 |
| session | anonymous와 authenticated 상태를 구분 |
| refresh | dev refresh token 검증 후 access token 응답 |
| CORS | wildcard 대신 허용 origin 기반 |
| token 로그 | Authorization header 원문 노출 금지 |

이 기준이 없는 상태에서 public runtime을 Spring으로 바꾸면, 팀원들이 인증 scaffold를 production 기준처럼 받아들이거나 반대로 정상 401을 장애로 오해할 수 있다.

## 환경변수 게이트

필수 이름:

| 변수 | 목적 |
| --- | --- |
| `ONMU_DEV_ACCESS_TOKEN` | protected API smoke, Flutter API mode |
| `ONMU_DEV_REFRESH_TOKEN` | refresh smoke |
| `ONMU_DEV_CORS_ORIGINS` | Spring CORS 허용 origin |
| `DATABASE_URL` 또는 `SPRING_DATASOURCE_*` | PostgreSQL 연결 |
| `REDIS_URL` 또는 `REDIS_HOST`/`REDIS_PORT` | Redis readiness |
| `OBJECT_STORAGE_ENDPOINT` 또는 `MINIO_ENDPOINT` | MinIO readiness |

확인할 때는 값이 아니라 존재 여부와 주입 경로만 기록한다.

## 로그 게이트

Node stub은 `logs/api-access.log`에서 `client=` 추적이 가능했다. Spring 전환 후에도 운영자가 "누가 어떤 요청을 보냈고, 어떤 응답이 났는지"를 확인할 수 있어야 한다.

최소 기준:

| 로그 요소 | 이유 |
| --- | --- |
| request id | 하나의 요청을 여러 로그에서 추적한다. |
| method/path | 어떤 API가 호출됐는지 본다. |
| status | 200, 401, 500 같은 결과를 본다. |
| latency | 느린 요청을 찾는다. |
| client | 팀 smoke, Flutter, Codex 작업을 구분한다. |

Spring access log parity가 아직 완성되지 않았다면, 전환 자체를 막을지 또는 임시 관측 방식을 승인할지 결정해야 한다.

---

# 리소스별 작업 흐름

## 1. GitHub / PR 작업 흐름

ONMU의 backend 전환은 운영 작업이지만, 코드 변경은 반드시 GitHub workflow를 따른다.

```text
Jira issue 확인
  -> branch 생성
  -> 작은 단위 수정
  -> 테스트
  -> PR
  -> CI
  -> review
  -> dev merge
```

운영 기준:

- `dev`와 `main`에 직접 push하지 않는다.
- 코드 변경이 필요하면 Jira 키 기반 브랜치로 작업한다.
- PR 제목과 본문에는 변경 범위, 검증 결과, 남은 위험을 적는다.
- secret 값은 PR 본문과 로그에 남기지 않는다.
- self-hosted Windows runner에서 실제 public backend를 바꾸는 workflow는 승인 없이 실행하지 않는다.

처음 백엔드 작업을 시작하는 팀원에게 중요한 점은 "코드가 돌아간다"와 "공용 서버에 반영한다"가 다르다는 것이다. 로컬 검증, PR 검증, 공용 dev backend 전환은 서로 다른 단계로 기록해야 한다.

## 2. Windows Server / Runner 작업 흐름

Windows 서버는 현재 팀의 공용 backend 개발 서버다. 이 서버에서 `localhost:8080`에 떠 있는 runtime이 public endpoint의 실제 응답을 만든다.

```text
Windows 서버 접속
  -> 저장소 최신화
  -> Docker Desktop 확인
  -> 의존성 container 확인
  -> 배포 스크립트 dry-run
  -> Spring runtime 배포
  -> public smoke
```

확인 명령 예시:

```powershell
docker compose -f infra\compose\docker-compose.yml ps
Get-Content logs\deploy-dev-backend.log -Tail 80
Get-Content logs\dev-backend-api.out.log -Tail 80
Get-Content logs\dev-backend-api.err.log -Tail 80
netstat -ano | findstr :8080
```

운영자가 봐야 할 것:

| 확인 | 왜 보는가 |
| --- | --- |
| Docker Desktop | PostgreSQL, Redis, MinIO가 container로 떠 있을 수 있다. |
| port 8080 owner | Node와 Spring이 같은 port를 두고 충돌하지 않는지 본다. |
| deploy log | 배포 스크립트가 어떤 runtime을 선택했는지 본다. |
| stdout/stderr | Spring boot 실패, DB 연결 실패, CORS 설정 오류를 본다. |
| tunnel 상태 | public endpoint가 Windows 서버로 연결되는지 본다. |

## 3. Key Vault / Secret 작업 흐름

Secret 관리는 초반부터 습관을 만들어야 한다. 개발 편의를 위해 token 값을 문서에 붙여넣으면 나중에 삭제하기 어렵고, 팀원이 같은 패턴을 따라 하게 된다.

```text
필요한 변수 이름 확인
  -> Key Vault/GitHub Secrets/Windows env 중 주입 위치 확인
  -> 값은 출력하지 않고 존재 여부만 확인
  -> 배포 프로세스가 변수를 읽는지 확인
  -> smoke에서 token 동작 확인
```

좋은 점검 방식:

- "어떤 변수 이름이 필요한지" 문서화한다.
- "어디에서 주입되는지" 기록한다.
- "값이 로그에 찍히지 않는지" 확인한다.
- 누락된 값은 변수 이름만 보고한다.

금지:

- `.env` 커밋
- PR 본문에 token 값 작성
- PowerShell 출력에 token 원문 노출
- 스크린샷에 secret 포함
- smoke 실패 로그에 Authorization header 원문 남김

## 4. Spring Runtime 배포 작업 흐름

전환은 dry-run을 먼저 수행한 뒤 실제 배포로 넘어간다.

```text
node-stub dry-run
  -> spring dry-run
  -> Spring 수동 배포
  -> local smoke
  -> public smoke
  -> 팀 공지
```

명령 예시:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\deploy-dev-backend.ps1 -DryRun -Runtime node-stub
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\deploy-dev-backend.ps1 -DryRun -Runtime spring
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\deploy-dev-backend.ps1 -Runtime spring -Client codex-spring-cutover
```

dry-run에서 확인할 것:

| 확인 | 이유 |
| --- | --- |
| 선택 runtime | 스크립트가 의도한 runtime을 잡는지 확인한다. |
| port cleanup | 기존 process를 안전하게 정리할 수 있는지 본다. |
| env 주입 | Spring 실행에 필요한 변수 이름이 들어오는지 본다. |
| token redaction | Authorization 값이 `<redacted>`처럼 숨겨지는지 본다. |

실제 배포에서 주의할 것:

- 기존 팀 dev DB volume을 삭제하지 않는다.
- 실패했을 때 공용 endpoint를 죽은 상태로 방치하지 않는다.
- Spring이 반복 종료되면 바로 rollback 기준을 검토한다.
- 성공 여부는 local process가 아니라 public endpoint smoke로 판단한다.

## 5. Public Smoke 작업 흐름

public smoke는 팀원이 실제로 쓰는 주소에서 확인한다.

```text
health
  -> readiness
  -> auth negative
  -> auth positive
  -> core route
  -> mutation route
  -> CORS preflight
  -> log evidence
```

검증 표:

| 요청 | 인증 | 기대 |
| --- | --- | --- |
| `GET /healthz` | 없음 | 200 |
| `GET /readyz` | 없음 | 200, PostgreSQL/Redis/MinIO ok |
| `GET /api/v1/auth/session` | 없음 | 200, `authenticated=false` |
| `GET /api/v1/auth/session` | Bearer | 200, `authenticated=true` |
| `GET /api/v1/home/summary` | 없음 | 401 |
| `GET /api/v1/home/summary` | Bearer | 200 |
| `GET /api/v1/groups` | Bearer | 200 |
| `POST /api/v1/place-search` | Bearer | 200 |
| `POST /api/v1/groups/{groupId}/votes` | Bearer | 200 또는 201 |
| `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/preview` | Bearer | 200 |
| `OPTIONS /api/v1/auth/session` | Origin + method preflight | 200 |

처음 보는 팀원을 위한 해석:

- `/healthz` 실패는 서버 process 또는 HTTP routing 문제일 가능성이 높다.
- `/readyz` 실패는 DB/Redis/MinIO 연결 문제일 가능성이 높다.
- 보호 API가 token 없이 401이면 정상이다.
- 보호 API가 token 있어도 401이면 token 주입, header 형식, 서버 설정을 본다.
- CORS preflight 실패는 앱이 서버에 도달하기 전 브라우저 정책에서 막힌 것일 수 있다.

주의할 route:

- `POST /api/v1/place-search`가 canonical route다.
- `GET /api/v1/place-search?query=...`는 Node compatibility route였으므로 Spring 기준 API로 삼지 않는다.
- `POST /api/v1/groups/{groupId}/votes`가 canonical vote 생성 route다.
- `POST /api/v1/groups/{groupId}/plans/{planId}/votes`는 기존 화면 전환 검증용 compatibility route로만 본다.

## 6. Flutter API Mode 작업 흐름

Spring 전환 후 Flutter 팀은 mock repository와 API repository의 차이를 더 명확히 봐야 한다.

```text
mock mode
  -> API mode 환경변수 주입
  -> dev token 주입
  -> protected API smoke
  -> Flutter 화면 단위 확인
```

실행 예:

```powershell
flutter run `
  --dart-define=ONMU_DATA_SOURCE=api `
  --dart-define=ONMU_API_BASE_URL=https://dev-api.onmu.cloud `
  --dart-define=ONMU_DEV_ACCESS_TOKEN=<값은 안전한 방식으로 주입>
```

팀 안내 기준:

| 상황 | 설명 |
| --- | --- |
| mock mode | 로컬 화면/상태 전환을 빠르게 볼 때 사용한다. |
| API mode | Spring public dev backend와 실제 계약을 맞출 때 사용한다. |
| token 없음 | protected API 401이 정상이다. |
| token 있음 | Spring 구현된 canonical API는 200/201을 기대한다. |
| 아직 Spring에 없는 보조 데이터 | Flutter repository placeholder 또는 mock fallback 여부를 명확히 표시한다. |

중요한 점은 Flutter가 이미 모든 화면을 미리 구현해 둔 것처럼, DB와 API도 최종 구조를 염두에 두고 가야 한다는 것이다. 다만 public dev backend에서 실제로 열어둔 route와 아직 scaffold인 route는 문서로 구분해야 한다.

## 7. Access Log / Observability 작업 흐름

전환 후 장애 대응은 로그에서 시작한다.

```text
요청 실패 확인
  -> request id 확인
  -> access log 확인
  -> stdout/stderr 확인
  -> dependency readiness 확인
  -> GitHub Actions run 확인
```

필수 증적:

| 증적 | 위치 |
| --- | --- |
| 배포 로그 | `logs\deploy-dev-backend.log` |
| Spring stdout | `logs\dev-backend-api.out.log` |
| Spring stderr | `logs\dev-backend-api.err.log` |
| 요청 추적 | Spring access log 또는 Application Insights/Log Analytics |
| GitHub Actions | `Deploy Windows dev backend` workflow run |

좋은 로그는 "서버가 죽었나?"라는 질문에 빠르게 답하게 해준다.

예를 들어 protected API가 401을 반환했을 때, 로그에서 아래를 구분할 수 있어야 한다.

| 가능성 | 로그에서 볼 것 |
| --- | --- |
| token 없음 | Authorization header 미존재, 401 |
| token 잘못됨 | bearer 형식 또는 검증 실패, 401 |
| CORS 문제 | preflight 요청, origin, method |
| DB 문제 | `/readyz` dependency 실패, datasource error |
| API 구현 문제 | 특정 controller/service exception |

## 8. CD 기본 Runtime 전환 작업 흐름

Spring 수동 전환이 성공했다고 해서 GitHub Actions의 기본 runtime까지 자동으로 바뀐 것은 아니다.

두 단계를 분리해서 생각한다.

| 단계 | 의미 |
| --- | --- |
| 수동 전환 | Windows 서버에서 지금 당장 `spring` runtime을 띄운다. |
| CD 기본 전환 | 이후 `dev` push 또는 workflow 실행 시 기본 runtime도 `spring`이 되게 한다. |

권장 순서:

```text
Spring 수동 전환 안정화
  -> workflow_dispatch runtime=spring 통과
  -> 팀 승인
  -> deploy-dev-backend.yml 기본 runtime 변경 PR
  -> CI 통과
  -> review
  -> merge to dev
  -> push-trigger CD smoke
```

왜 분리하는가:

- 수동 전환은 빠르게 rollback할 수 있다.
- CD 기본값 변경은 앞으로의 모든 dev 배포에 영향을 준다.
- self-hosted runner가 공용 서버를 재배포하므로 실수의 영향이 크다.
- 팀원이 언제부터 Spring을 기준으로 봐야 하는지 명확히 공지할 수 있다.

## 9. Rollback 작업 흐름

rollback은 실패를 인정하는 절차가 아니라 공용 개발 환경을 지키는 절차다.

```text
장애 감지
  -> 영향 범위 판단
  -> Spring 로그 보존
  -> node-stub rollback
  -> public smoke
  -> 팀 공지
  -> 원인 PR/이슈 작성
```

롤백 명령:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\deploy-dev-backend.ps1 -Runtime node-stub -Client codex-spring-rollback
```

롤백 기준:

| 기준 | 설명 |
| --- | --- |
| `/healthz` 실패 | 서버 process 또는 routing 문제다. |
| `/readyz` 실패 | DB/Redis/MinIO 의존성 문제일 수 있다. |
| Spring 반복 종료 | runtime 안정성이 없다. |
| token 기준 불일치 | 보호 API가 인증 정책대로 동작하지 않는다. |
| CORS 전면 실패 | Flutter/web 테스트가 막힌다. |
| 팀 테스트 전면 차단 | 원인 분석보다 공용 환경 복구가 먼저다. |

롤백 후 반드시 할 일:

- `dev-api.onmu.cloud`가 다시 응답하는지 확인한다.
- rollback runtime이 `node-stub`인지 확인한다.
- Spring 실패 로그를 삭제하지 않는다.
- 팀에 "임시 rollback 완료, 원인 분석 중"이라고 공유한다.
- 같은 방식으로 즉시 재전환하지 말고 원인과 수정 PR을 남긴다.

---

# 전환 완료 후 팀 표준 흐름

Windows Codex가 Spring runtime 전환을 완료했다는 가정에서, 이후 팀의 기본 작업 방식은 아래처럼 정리한다.

## 팀원 연결/테스트 Quickstart

이 절은 팀원이 오늘 바로 public Spring dev backend에 붙어서 화면과 API를 확인할 때 쓰는 짧은 실행 가이드다. 세부 배포나 rollback은 위 운영 절차를 따르고, 여기서는 "내 PC에서 어떻게 연결하고, 무엇을 확인하고, 어떤 방식으로 작업을 이어갈지"에 집중한다.

현재 팀 기준은 다음처럼 이해한다.

| 항목 | 기준 |
| --- | --- |
| API base URL | `https://dev-api.onmu.cloud` |
| public runtime | Windows 서버에서 수동 전환된 Spring Boot Main API |
| CD 기본 runtime | 별도 PR과 팀 합의 전까지 `node-stub`일 수 있다. 수동 Spring 전환과 CD 기본값은 분리해서 본다. |
| 보호 API | `/api/v1/**`는 bearer token 없으면 401이 정상이다. |
| secret 사용 | [AGENTS.md](../../AGENTS.md)의 dev API/dev DB 연결 보안 원칙을 따른다. |
| DB 직접 접속 | 필요한 팀원만 Cloudflare Access TCP와 개인 DB 계정으로 접속한다. |

이 절은 팀원이 복사해서 실행할 수 있는 연결 절차를 다룬다. 권한 부여 범위, refresh token 공유 금지, Cloudflare API token 금지 같은 전역 보안 원칙은 [AGENTS.md](../../AGENTS.md)를 기준으로 한다.

| 용도 | 필요한 secret |
| --- | --- |
| 개인 DB 접속 | 본인 계정의 `dev-db-<계정>-password` |
| API 연결 smoke | `dev-api-access-token` |

개인별 DB password secret 이름은 아래 기준을 따른다.

| 사용자 | Secret name |
| --- | --- |
| `3dt001` | `dev-db-3dt001-password` |
| `3dt005` | `dev-db-3dt005-password` |
| `3dt016` | `dev-db-3dt016-password` |
| `3dt028` | `dev-db-3dt028-password` |

팀원이 먼저 확인할 것은 API가 살아 있는지와 인증 기준이 바뀌었다는 점이다.

```bash
curl -i https://dev-api.onmu.cloud/healthz
curl -i https://dev-api.onmu.cloud/readyz
curl -i https://dev-api.onmu.cloud/api/v1/home/summary
```

기대 해석:

| 요청 | 기대 | 해석 |
| --- | --- | --- |
| `/healthz` | 200 | Spring process가 HTTP 요청을 받는다. |
| `/readyz` | 200 | PostgreSQL, Redis, MinIO가 준비됐다. |
| token 없는 `/api/v1/home/summary` | 401 | 보호 API 인증이 적용된 정상 동작이다. |

token이 있는 smoke는 Key Vault에서 access token을 읽어 환경변수로만 사용한다. 아래 예시는 값을 출력하지 않는다.

macOS/Linux:

```bash
export ONMU_API_BASE_URL="https://dev-api.onmu.cloud"
export ONMU_DEV_ACCESS_TOKEN="$(az keyvault secret show --vault-name onmu-dev-kv-27db5e --name dev-api-access-token --query value -o tsv)"

curl -i \
  -H "Authorization: Bearer ${ONMU_DEV_ACCESS_TOKEN}" \
  "${ONMU_API_BASE_URL}/api/v1/home/summary?client=<본인-이름>-api-smoke"
```

Windows PowerShell:

```powershell
$env:ONMU_API_BASE_URL="https://dev-api.onmu.cloud"
$env:ONMU_DEV_ACCESS_TOKEN = az keyvault secret show --vault-name onmu-dev-kv-27db5e --name dev-api-access-token --query value -o tsv

curl.exe -i `
  -H "Authorization: Bearer $env:ONMU_DEV_ACCESS_TOKEN" `
  "$env:ONMU_API_BASE_URL/api/v1/home/summary?client=<본인-이름>-api-smoke"
```

Flutter 앱은 mock mode와 API mode를 분리해서 실행한다. mock mode는 화면 흐름을 빠르게 볼 때 쓰고, API mode는 Spring public dev backend와 실제 contract를 맞출 때 쓴다.

API mode를 실행할 때는 `apps/mobile-flutter/.env` 파일을 사용한다. 이 파일은 gitignore 대상이어야 하며, PR에 올리지 않는다.

```env
ONMU_DATA_SOURCE=api
ONMU_API_BASE_URL=https://dev-api.onmu.cloud
ONMU_DEV_ACCESS_TOKEN=<Key Vault에서 읽은 dev-api-access-token 값>
```

실행:

```bash
cd apps/mobile-flutter
flutter pub get
flutter run -d chrome --dart-define-from-file=.env
```

기기나 에뮬레이터에서 실행할 때는 `-d chrome` 대신 본인의 device id를 사용한다. API mode에서 우선 확인할 화면은 홈, 모임 목록, 약속 상세, 장소 후보/검색, 투표 생성, 정산 preview다. 화면이 깨졌을 때는 아래 순서로 본다.

| 증상 | 먼저 확인할 것 |
| --- | --- |
| 401 | token 주입 여부, `Bearer ` prefix, protected API 여부 |
| 404 | Spring에 해당 canonical route가 구현됐는지, mock-only route를 호출 중인지 |
| CORS 실패 | 실행 origin이 `ONMU_DEV_CORS_ORIGINS`에 포함됐는지 |
| 빈 화면 | Flutter repository가 mock fallback을 쓰는지, API 응답 shape가 mock과 다른지 |
| `/readyz` 실패 | 앱 문제가 아니라 DB/Redis/MinIO readiness 문제일 수 있다. |

DB 직접 접속은 API 테스트와 별도다. Flutter 화면 확인만 하는 팀원은 DB 접속이 필요하지 않다. DB schema, seed, SELECT smoke, repository 구현을 확인해야 하는 팀원만 개인 계정으로 접속한다.

DB 접속 전 서버 쪽 조건:

| 조건 | 확인 |
| --- | --- |
| Access TCP DNS | `db-dev.onmu.cloud`가 NXDOMAIN이 아니어야 한다. |
| Cloudflare Access policy | 팀 계정/MFA 정책이 active 상태여야 한다. |
| Windows tunnel | `db-dev.onmu.cloud -> localhost:15432` ingress가 실행 중이어야 한다. |
| DB 계정 | 개인 계정은 read-only, full-dev 계정은 DDL/DML 가능 계정으로 분리한다. |

먼저 Azure 로그인 상태를 확인한다.

```bash
az account show
```

로그인이 안 되어 있으면 `az login`으로 로그인한다.

DB password는 Key Vault에서 본인 secret만 읽어 환경변수로 사용한다. 아래 예시는 `3dt005` 기준이다. 본인 계정에 맞게 username과 secret name을 바꾼다.

macOS/Linux:

```bash
export AZURE_KEY_VAULT_NAME="onmu-dev-kv-27db5e"
export PGPASSWORD="$(az keyvault secret show --vault-name "$AZURE_KEY_VAULT_NAME" --name dev-db-3dt005-password --query value -o tsv)"
```

Windows PowerShell:

```powershell
$env:AZURE_KEY_VAULT_NAME="onmu-dev-kv-27db5e"
$env:PGPASSWORD = az keyvault secret show --vault-name $env:AZURE_KEY_VAULT_NAME --name dev-db-3dt005-password --query value -o tsv
```

`echo $PGPASSWORD`처럼 값을 출력하는 명령은 실행하지 않는다. 터미널 로그나 스크린샷에도 secret 값이 남지 않게 한다.

Mac에서 `dig`나 `nslookup`은 성공하지만 `cloudflared`가 `lookup db-dev.onmu.cloud: no such host`를 내면 macOS system resolver 지연 또는 DNS negative cache일 수 있다. Access TCP 실행 전에 아래 명령으로 system resolver를 확인한다.

```bash
dscacheutil -q host -a name db-dev.onmu.cloud
python3 - <<'PY'
import socket
print(socket.getaddrinfo("db-dev.onmu.cloud", 443))
PY
```

실패하면 DNS cache를 정리하고 잠시 기다린 뒤 다시 확인한다.

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

팀원 PC에서 Access TCP를 연다. 로컬에 이미 PostgreSQL이 `15432`를 쓰고 있으면 `15433` 같은 다른 포트를 쓰고, DB client port도 같은 값으로 맞춘다.

```powershell
cloudflared access tcp --hostname db-dev.onmu.cloud --url localhost:15432
```

DB client 설정:

| 항목 | 값 |
| --- | --- |
| Host | `localhost` |
| Port | `15432` 또는 본인이 연 local listener port |
| Database | `onmu` |
| Username | 본인 계정 또는 승인된 팀 full-dev 계정 |
| Password | Key Vault에서 읽어 `PGPASSWORD`에 저장한 본인 DB password |

`db-dev.onmu.cloud`가 DNS에서 `NXDOMAIN`으로 나오면 개인 계정 문제가 아니다. 이때는 Windows backend 담당자에게 Access TCP DNS route와 policy 활성화를 먼저 요청한다.

개인 read-only 계정은 SELECT 성공과 DDL/DML 차단을 함께 확인한다. 아래 예시는 `3dt005` 기준이다.

```bash
psql -h localhost -p 15432 -U 3dt005 -d onmu -c "select current_user, count(*) from users group by current_user;"
```

기대 결과:

- `current_user`가 본인 계정으로 나온다.
- `users` count 조회가 성공한다.

개인 계정에서 `create table`, `insert`, `update`, `delete`, `drop`이 가능하면 권한 설정이 잘못된 것이다. 실험이 필요하면 transaction 안에서 시도하고, 실패 메시지만 공유한다. 실제 데이터 변경을 남기지 않는다.

DDL 차단 확인:

```bash
psql -h localhost -p 15432 -U 3dt005 -d onmu -v ON_ERROR_STOP=1 -c "begin; create table public.__onmu_3dt005_should_fail(id int); rollback;"
```

DML 차단 확인:

```bash
psql -h localhost -p 15432 -U 3dt005 -d onmu -v ON_ERROR_STOP=1 -c "begin; insert into users (id, public_id, display_name, status, created_at, updated_at) values (gen_random_uuid(), 'readonly_should_fail', 'readonly_should_fail', 'active', now(), now()); rollback;"
```

`permission denied` 또는 `read-only transaction` 관련 에러가 나면 정상이다. 명령 exit code가 실패로 나오는 것도 정상이다. 성공하면 권한이 과하게 열린 것이므로 바로 공유한다.

팀 full-dev 계정은 migration 담당자나 DB 작업 담당자가 제한적으로 사용한다. 개인 작업 브랜치에서 schema 변경이 필요하면 이미 적용된 Flyway migration을 수정하지 말고 새 version migration으로 추가한다.

검증이 끝나면 환경변수를 정리한다.

macOS/Linux:

```bash
unset PGPASSWORD
unset ONMU_DEV_ACCESS_TOKEN
```

Windows PowerShell:

```powershell
Remove-Item Env:\PGPASSWORD
Remove-Item Env:\ONMU_DEV_ACCESS_TOKEN
```

작업을 시작할 때는 항상 최신 `dev`에서 브랜치를 만든다.

```bash
git fetch origin --prune
git switch dev
git pull --ff-only origin dev
git switch -c <type>/SCRUM-<번호>-<short-description>
```

작업 기준:

| 작업 | 기준 |
| --- | --- |
| Flutter 화면 작업 | mock mode로 빠르게 UI를 확인한 뒤 API mode로 Spring contract를 확인한다. |
| Spring API 작업 | API Contract Map, data dictionary, Flyway 상태를 먼저 확인한다. |
| DB schema 작업 | 이미 적용된 V1~Vn migration은 수정하지 않고 새 Vn+1 migration을 만든다. |
| 운영 스크립트 작업 | dry-run을 먼저 실행하고, public runtime 변경은 승인 후 진행한다. |
| 문서 작업 | 변경된 route, env, smoke, rollback 기준을 함께 갱신한다. |

테스트 결과를 공유할 때는 아래 형식으로 남긴다. token, DB password, 실제 secret은 포함하지 않는다.

```text
[ONMU Spring dev 연결 테스트]
- 이름/계정:
- 날짜:
- 실행 환경: macOS/Windows, Flutter device 또는 curl/DB client
- API base URL: https://dev-api.onmu.cloud
- client marker: <본인-이름>-api-smoke
- /healthz:
- /readyz:
- protected API no token:
- protected API bearer:
- Flutter 확인 화면:
- Azure login 상태:
- Key Vault password 읽기 성공 여부:
- DNS resolve 결과:
- Access TCP tunnel 결과:
- DB SELECT smoke: 필요 시만 작성
- CREATE TABLE 차단 결과: 필요 시만 작성
- INSERT 차단 결과: 필요 시만 작성
- API 연결 결과: 해당자만 작성
- secret 미출력 확인:
- 실패/이상 증상:
- 첨부: screenshot 또는 로그 일부. secret 제외.
```

팀에서 이슈를 나눌 때는 "내 앱이 안 됨"보다 "어떤 route, 어떤 status, 어떤 mode, 어떤 client marker"인지 적는다. 그래야 backend 로그, Flutter repository, DB readiness 중 어디를 봐야 하는지 빠르게 갈라낼 수 있다.

## 백엔드 개발자

```text
API Contract Map 확인
  -> Spring controller/service/repository 구현
  -> Flyway schema 또는 seed 필요 여부 확인
  -> 단위/통합 테스트
  -> local smoke
  -> PR
  -> public dev smoke
```

백엔드 개발자는 `node-stub`을 기준 구현으로 보지 않는다. `node-stub`은 rollback과 compatibility 확인용이고, 새 기능의 기준은 Spring Boot Main API다.

## Flutter 개발자

```text
mock mode로 화면 흐름 확인
  -> API mode로 Spring contract 확인
  -> token 없는 실패와 token 있는 성공 구분
  -> repository placeholder 여부 기록
  -> API gap을 issue/PR로 연결
```

Flutter 개발자는 401을 먼저 장애로 보지 말고, "이 route가 protected API인가?", "token이 주입됐는가?", "Spring에 route가 구현됐는가?"를 순서대로 본다.

## 운영 담당자

```text
public smoke 확인
  -> deploy log 확인
  -> access log 확인
  -> readiness dependency 확인
  -> rollback 필요 여부 판단
  -> 팀 공지
```

운영 담당자는 성공/실패를 말할 때 "내 PC에서는 됨"이 아니라 public endpoint, 로그, GitHub run, smoke 결과로 말한다.

## 문서 담당자

```text
API route 변경
  -> API Contract Map 갱신
  -> Spring README smoke 갱신
  -> Flutter migration 문서 갱신
  -> data dictionary 영향 확인
  -> 팀 공지 링크 정리
```

문서 담당자는 구현과 문서를 나중에 맞추는 사람이 아니라, 팀이 같은 기준으로 개발하게 만드는 사람이다.

---

# 자주 생기는 오해

## "dev-api.onmu.cloud가 그대로면 아무것도 안 바뀐 것 아닌가?"

아니다. 주소는 같아도 뒤의 runtime이 바뀌면 인증, route 구현, DB 연결, 로그, 오류 응답이 모두 달라질 수 있다.

## "401이 나오면 서버가 죽은 것 아닌가?"

보호 API에서 token 없이 401이 나오면 정상이다. `/healthz`, `/readyz`, token 있는 protected API까지 같이 봐야 한다.

## "Spring이 local에서 뜨면 public 전환도 끝난 것 아닌가?"

아니다. public endpoint는 Cloudflare Tunnel, Windows port, env 주입, DB readiness, CORS, 로그, 팀 공지까지 통과해야 한다.

## "Node stub은 이제 삭제해도 되나?"

아직은 삭제하지 않는다. 전환 초기에는 rollback runtime이 필요하다. 삭제는 Spring 운영이 충분히 안정화되고 팀이 합의한 뒤 별도 PR로 진행한다.

## "CD 기본 runtime도 바로 Spring으로 바꾸면 되나?"

수동 전환 안정화와 CD 기본값 변경은 분리한다. CD 기본값 변경은 이후 모든 `dev` 배포에 영향을 주므로 별도 PR, CI, review, 공지가 필요하다.

---

# 완료 보고 템플릿

전환 완료 보고는 아래 형식으로 남긴다. 값은 채우되 secret은 절대 쓰지 않는다.

```markdown
## Spring Runtime 전환 완료 보고

### 1. Git 기준
- Branch:
- Commit:
- PR #69 또는 동등 hardening merge 확인:
- 추가 PR:
- CI 상태:

### 2. Runtime 기준
- Public endpoint:
- 전환 전 runtime:
- 전환 후 runtime:
- rollback runtime:
- Cloudflare Tunnel:

### 3. 환경/Secret
- 확인된 변수 이름:
- 값 출력 여부: 출력하지 않음
- 주입 방식:
- 누락 변수:

### 4. 배포
- dry-run node-stub:
- dry-run spring:
- 실제 배포 명령:
- PID/port owner:
- 배포 로그:

### 5. Public Smoke
| 항목 | 결과 | 메모 |
| --- | --- | --- |
| /healthz |  |  |
| /readyz |  |  |
| auth/session anonymous |  |  |
| auth/session bearer |  |  |
| protected API no token 401 |  |  |
| protected API bearer 200/201 |  |  |
| CORS preflight |  |  |

### 6. 로그 증적
- deploy log:
- stdout:
- stderr:
- access log 또는 observability:
- GitHub Actions run:

### 7. Flutter/팀 공지
- API mode 안내:
- Key Vault secret 사용 방식:
- plain curl 401 정상 안내:
- node-stub rollback 가능 안내:

### 8. Rollback
- rollback 명령:
- rollback smoke:
- rollback 필요 여부:

### 9. 남은 리스크
- OAuth scaffold:
- access log parity:
- DB migration/seed:
- 아직 Spring에 없는 API:
- 다음 PR:
```

---

# 다음 개선 과제

Spring runtime 전환은 끝이 아니라 시작이다. public dev backend가 Spring 기준이 되면 아래 작업을 순차적으로 진행한다.

| 과제 | 이유 |
| --- | --- |
| 실제 Naver OAuth 구현 | dev token scaffold에서 실제 로그인/refresh token 저장/회전으로 넘어간다. |
| Spring access log parity 강화 | Node stub 수준의 client 추적을 Spring에서도 안정적으로 제공한다. |
| DB schema와 data dictionary 연결 | API 구현이 임시 seed가 아니라 최종 도메인 schema를 바라보게 한다. |
| Flutter API repository gap 정리 | mock으로 남아 있는 화면 데이터를 Spring route와 연결한다. |
| worker outbox 연동 | AI worker, notification worker, media worker로 넘길 event boundary를 구현한다. |
| observability 도입 | request, error, latency, dependency 상태를 장기적으로 추적한다. |
| rollback drill | 실제 장애 전에도 rollback 명령과 smoke를 연습한다. |
