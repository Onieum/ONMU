# On-prem backup backend runbook

이 문서는 Mac 또는 Windows 장비를 ONMU 백업 백엔드 서버 후보로 준비하고, 필요 시 Azure staging primary를 수동 대체 운영 경로로 전환할 때의 공통 절차를 정리한다.

현재 팀의 primary 서비스와 acceptance 기준은 Azure staging이다. On-prem backup backend는 자동 failover 대상이 아니며, Azure staging 장애 분석, 수동 fallback, 개발/검증 분리, 복구 리허설, 단기 대체 운영을 위한 보조 경로다.

## 1. 운영 경계

| 항목 | 기준 |
| --- | --- |
| Primary API | `https://staging-api.onmu.cloud` Azure Container Apps |
| Backup 후보 | Mac 또는 Windows 장비의 Spring Boot Main API |
| 실행 단계 | Phase A local-only 준비 -> Phase B 데이터/미디어 rehearsal -> Phase C 공개 route cutover |
| 기본 공개 범위 | Phase A는 local-only, Phase B는 팀 내부 smoke, Phase C에서만 공개 route 전환 |
| 자동 전환 | 하지 않음 |
| DNS/provider console 변경 | Phase C cutover checklist에서만 실행 |
| DB/Media 복제 | Phase B migration checklist에서만 실행 |

Phase A 준비 중에는 Azure staging DNS, Container Apps, Key Vault secret value, OAuth provider console, Cloudflare tunnel route를 변경하지 않는다. Phase B/C로 넘어갈 때는 이 문서의 migration/cutover checklist를 그대로 이어서 실행하고, status/path/count와 rollback point만 기록한다.

## 2. 문서 읽는 순서

1. 현재 운영 기준: [staging cutover status](./staging-cutover-status.md)
2. Azure primary 운영: [Azure staging 배포/운영 runbook](./azure-staging-deploy-runbook.md)
3. 환경별 차이: [Azure 환경 매트릭스](./azure-environment-matrix.md)
4. 데이터 이전 세부 기준: [Azure 데이터 이전 runbook](./azure-data-migration-runbook.md)
5. Windows legacy 상세: [Windows 노트북 백엔드 서버 세팅 가이드](./windows-backend-server.md)

이 문서는 Mac/Windows 공통 진입점이다. Windows 전용 legacy tunnel, PowerShell helper, Docker Desktop 세부 운영은 Windows 문서를 참고한다.

## 3. 공통 원칙

- `dev`와 `main`에 직접 push하지 않는다.
- 백업 서버는 최신 `origin/dev` 기준으로만 준비한다.
- 작업 전 `git status --short --branch`로 unrelated dirty/untracked change를 확인한다.
- secret 값은 장비 간 복사하지 않는다. 필요한 값은 env var 이름과 Key Vault secret name으로만 추적한다.
- `.env`, dart-define, raw log, DB dump, object dump는 git ignored 경로 또는 repo 밖에 둔다.
- 사용자 실제 이름, 이메일, 사진, 위치, 정산 내역, OAuth `code`/`state`/idToken, bearer token, DB password는 문서와 로그 요약에 남기지 않는다.
- destructive command는 해당 phase의 go/no-go 체크포인트와 rollback point를 기록하기 전에는 실행하지 않는다.

## 4. 복사 대상과 비대상

| 구분 | 복사 가능 | 기본 비대상 |
| --- | --- | --- |
| 코드 | repo clone 또는 기존 worktree 최신화 절차 | dev/main 직접 push |
| 설정 | `.env.example` 기반 local ignored env 파일 | 운영 secret value 평문 복사 |
| DB | schema 준비 절차와 Phase B logical dump/restore 절차 | Phase B 체크포인트 없는 staging raw data dump/restore |
| Redis | 재생성 가능한 cache로 취급 | 영속 backup/restore |
| Object storage | object prefix/count/checksum 리허설과 Phase B copy 절차 | 사용자 media raw URL/파일명 공유 |
| Tile asset | manifest/style/PMTiles count/status 검증 | current object 체크포인트 없는 overwrite |

데이터 복제가 필요하면 이 문서의 Phase B 절차와 [Azure 데이터 이전 runbook](./azure-data-migration-runbook.md)을 함께 사용한다. 이 PR에서는 백업 후보 준비에서 실제 대체 운영/마이그레이션까지 한 runbook 안에서 이어지도록 다룬다.

## 5. 공통 준비 절차

### 5.1 Repo 준비

새 장비:

```bash
git clone <ONMU_REPO_URL> ONMU
cd ONMU
git fetch origin --prune --force
git switch dev
git pull --ff-only origin dev
git status --short --branch
```

기존 worktree:

```bash
cd <ONMU_REPO>
git status --short --branch
git fetch origin --prune --force
git switch dev
git pull --ff-only origin dev
git status --short --branch
```

작업 중인 브랜치나 detached HEAD에서 공용 백업 서버를 준비해야 하면, 먼저 별도 worktree 또는 clean clone을 사용한다. 기존 사용자 변경을 되돌리지 않는다.

### 5.2 필수 도구

| 도구 | macOS | Windows |
| --- | --- | --- |
| Java | Homebrew OpenJDK 21 | Temurin 또는 Microsoft Build of OpenJDK 21 |
| Shell | `zsh` | PowerShell 7 권장 |
| Docker | Docker Desktop 또는 Colima | Docker Desktop + WSL2 |
| GitHub CLI | `gh` | `gh` |
| Azure CLI | `az` | `az` |
| Optional tunnel | `cloudflared` | `cloudflared` |

설치 확인 예시:

```bash
java -version
docker version
gh --version
az version
```

Windows:

```powershell
java -version
docker version
gh --version
az version
```

## 6. Local env와 secret reference

백업 서버는 env var name을 Spring runtime에 주입한다. secret 값은 Key Vault나 실행자가 관리하는 local ignored env 파일에서만 읽는다.

현재 staging runtime secret source는 재사용 Key Vault `onmu-dev-kv-27db5e`의 `staging-*` secret name이다. 이 이름은 secret 값이 아니라 운영 참조명이다.

Local-only 백업 후보 준비에서 즉시 필요한 값은 DB 연결 정보, Redis URL, local object storage endpoint/bucket, `ONMU_ACCESS_TOKEN_SECRET` 정도다. OAuth redirect/callback, provider secret, place-search/route API key는 OAuth 또는 provider smoke가 포함되는 Phase B/C에서만 참조한다. `staging-*` secret value는 실행자가 fallback rehearsal 또는 cutover phase를 시작한다고 기록했을 때만 읽는다.

| Env var | Key Vault secret name 후보 | 대상 |
| --- | --- | --- |
| `DATABASE_URL` 또는 `SPRING_DATASOURCE_URL` | `staging-database-url` | Spring datasource |
| `POSTGRES_PASSWORD` 또는 `SPRING_DATASOURCE_PASSWORD` | `staging-postgres-password` | Spring datasource |
| `ONMU_ACCESS_TOKEN_SECRET` | `staging-access-token-secret` | Spring JWT |
| `REDIS_URL` 또는 `SPRING_DATA_REDIS_URL` | `staging-redis-url` | Redis |
| `KAKAO_REST_API_KEY` | `staging-kakao-rest-api-key` | OAuth/place public client |
| `KAKAO_CLIENT_SECRET` | `staging-kakao-client-secret` | Spring OAuth secret |
| `KAKAO_OAUTH_REDIRECT_URI` | `staging-kakao-oauth-redirect-uri` | Spring callback |
| `KAKAO_OAUTH_MOBILE_CALLBACK_URI` | `staging-kakao-oauth-mobile-callback-uri` | Mobile deep link callback |
| `NAVER_OAUTH_CLIENT_ID` | `staging-naver-oauth-client-id` | OAuth public client |
| `NAVER_OAUTH_CLIENT_SECRET` | `staging-naver-oauth-client-secret` | Spring OAuth secret |
| `NAVER_OAUTH_REDIRECT_URI` | `staging-naver-oauth-redirect-uri` | Spring callback |
| `NAVER_OAUTH_MOBILE_CALLBACK_URI` | `staging-naver-oauth-mobile-callback-uri` | Mobile deep link callback |
| `GOOGLE_OAUTH_CLIENT_ID` | `staging-google-oauth-client-id` | Spring audience |
| `GOOGLE_SERVER_CLIENT_ID` | `staging-google-server-client-id` | Spring/Flutter Google server client |
| `NAVER_SEARCH_CLIENT_ID` | `staging-naver-search-client-id` | Place search |
| `NAVER_SEARCH_CLIENT_SECRET` | `staging-naver-search-client-secret` | Place search |
| `OPENROUTESERVICE_API_KEY` | `staging-openrouteservice-api-key` | Route provider |
| `OBJECT_STORAGE_ENDPOINT` | `staging-blob-endpoint` | Object storage. local-only 준비에서는 local MinIO endpoint를 사용하고, `staging-blob-*` secret name은 Phase B/C에서만 참조한다. |
| `OBJECT_STORAGE_BUCKET` | `staging-blob-container` | Object storage. local-only 준비에서는 local MinIO bucket을 사용하고, `staging-blob-*` secret name은 Phase B/C에서만 참조한다. |

값 존재 여부를 확인할 때는 secret value를 출력하지 않고 presence, length, status만 기록한다.

## 7. macOS 백업 서버 후보

### 7.1 준비

권장 shell은 `zsh`다. Java 21은 Homebrew 경로를 명시한다.

```bash
export JAVA_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
java -version
```

Docker Desktop 또는 Colima가 실행 중인지 확인한다.

```bash
docker ps
```

Local dependency compose 파일은 repo 루트가 아니라 `infra/compose/docker-compose.yml`에 있다. Spring datasource 기본값은 `POSTGRES_HOST_PORT=15432` 축을 사용하므로, Mac local-only 준비에서는 compose와 Spring 실행 전에 같은 값을 명시한다.

```bash
cd <ONMU_REPO>
export POSTGRES_HOST_PORT=15432
docker compose -f infra/compose/docker-compose.yml up -d postgres redis minio
```

### 7.2 실행 형태

Mac 백업 서버는 local-only로 먼저 준비한다.

```bash
cd <ONMU_REPO>/services/api-spring
./mvnw -DskipTests clean package
java -jar target/onmu-api-spring-*.jar
```

Local-only 단계에서는 `ONMU_ACCESS_TOKEN_SECRET`을 staging secret에서 읽지 않고 local-only 값이나 local 개발 기본값을 사용한다. staging signing secret을 Mac 장비로 가져오는 일은 Phase B/C에서만 진행한다.

실제 운영 secret을 넣어 실행해야 하는 경우에는 local ignored env 파일에서 현재 shell로만 주입한다. `.env`나 shell history에 secret value가 남지 않도록 한다.

로그 후보:

| 로그 | 기준 |
| --- | --- |
| process stdout/stderr | 현재 terminal 또는 운영자가 지정한 local log |
| access log | `logs/api-access.log` 후보 |
| deploy note | repo 밖 또는 ignored `tmp/` 후보 |

## 8. Windows 백업 서버 후보

### 8.1 준비

PowerShell 7을 권장한다. Java 21과 Docker Desktop/WSL2가 준비되어 있어야 한다.

```powershell
java -version
docker ps
```

Windows 기존 상세 절차는 [Windows 노트북 백엔드 서버 세팅 가이드](./windows-backend-server.md)를 참고한다. 이 문서에서는 Windows도 Azure primary의 대체 후보일 뿐이며, staging acceptance 기준으로 승격하지 않는다.

### 8.2 실행 형태

기존 helper를 쓸 수 있지만, 공개 legacy endpoint를 건드리기 전에는 dry-run 또는 local-only 실행으로 제한한다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\deploy-dev-backend.ps1 -DryRun -Runtime spring
```

Windows 백업 서버에서 local Spring만 확인할 때는 공개 Cloudflare tunnel을 새로 열지 않는다. `dev-api.onmu.cloud`, `db-dev.onmu.cloud` 같은 legacy route는 Phase C route cutover 대상이 아닌 한 사용하지 않는다.

로그 후보:

| 로그 | 기준 |
| --- | --- |
| deploy log | `logs\deploy-dev-backend.log` |
| Spring stdout | `logs\dev-backend-api.out.log` |
| Spring stderr | `logs\dev-backend-api.err.log` |
| access log | `logs\api-access.log` |

## 9. Smoke 명령 예시

아래 명령은 Phase A local-only 준비에서 실행하는 최소 smoke 예시다. Phase B/C로 넘어가기 전에 이 결과를 status/path/count 중심으로 기록한다.

```bash
curl -i http://127.0.0.1:8080/healthz
curl -i http://127.0.0.1:8080/readyz
curl -i http://127.0.0.1:8080/api/v1/users/me
```

성공 기준:

| Endpoint | 기대 |
| --- | --- |
| `/healthz` | `200` |
| `/readyz` | `200` |
| `/api/v1/users/me` no-token | `401` |

보호 API, OAuth, media, place-search, chat smoke는 Phase B/C 검증 작업으로 이어서 실행한다.

## 10. End-to-end 실행 단계

백업 서버 준비가 끝나면 별도 문서나 별도 PR로 미루지 않고 아래 phase를 순서대로 이어간다. 단, 각 phase는 이전 phase의 status/path/count와 rollback point가 기록되어야 시작한다.

| Phase | 목표 | 실행 범위 | 완료 기준 |
| --- | --- | --- | --- |
| A. Local-only 준비 | Mac/Windows 장비가 Spring API를 실행할 수 있는지 확인 | repo sync, Java/Docker, local Postgres/Redis/MinIO, Spring package/run | `/healthz` 200, `/readyz` 200, no-token `/api/v1/users/me` 401 |
| B. 데이터/미디어 rehearsal | backup backend가 staging-compatible data를 읽을 수 있는지 확인 | DB logical dump/restore, object prefix copy, staging-compatible env 주입, 내부 smoke | row count/table presence, object prefix/count/checksum, authenticated smoke, OAuth/provider smoke |
| C. 공개 route cutover | `staging-api` 대체 경로로 단기 운영 | backup API 공개 route, DNS/tunnel/provider callback 정렬, smoke, 모니터링 | route smoke 통과, mobile smoke 통과, rollback point 보존 |

Phase C는 자동 failover가 아니다. 실행자가 route를 전환하고, 실패 시 route를 Azure staging으로 되돌리는 수동 절차다.

## 11. 데이터/미디어 migration checklist

Phase B에서는 단일 writer 원칙을 먼저 정한다. source Azure staging과 backup backend가 동시에 쓰기를 받으면 데이터가 갈라지므로, cutover window 동안 source write를 멈추거나 backup route로만 쓰기가 들어가게 한다.

### 11.1 DB logical dump/restore

아래 명령은 runbook 예시다. connection string value는 화면, 로그, 문서, PR 본문에 출력하지 않는다. `SOURCE_DATABASE_URL`, `TARGET_DATABASE_URL`은 현재 shell 또는 local ignored env 파일에서만 주입한다.

```bash
RUN_DIR="<ignored-local-run-dir>/onprem-cutover-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN_DIR"
test -n "${SOURCE_DATABASE_URL:-}" && echo "SOURCE_DATABASE_URL present"
test -n "${TARGET_DATABASE_URL:-}" && echo "TARGET_DATABASE_URL present"
pg_dump --format=custom --no-owner --no-privileges --file "$RUN_DIR/onmu.dump" "$SOURCE_DATABASE_URL"
pg_restore --clean --if-exists --no-owner --no-privileges --dbname "$TARGET_DATABASE_URL" "$RUN_DIR/onmu.dump"
```

기록할 값:

- dump 시작/종료 시각
- target migration version
- 핵심 table 존재 여부
- 핵심 table row count
- 실패 시 error type

기록하지 않을 값:

- connection string value
- row value
- 사용자 이름/이메일/위치/사진 URL
- OAuth/token/raw request body

### 11.2 Redis와 cache

Redis는 원장 저장소가 아니므로 기본적으로 복제하지 않는다. backup backend 기동 후 place-search cache, session-like cache, rate-limit state는 자연 재생성한다. Redis key/value를 dump해서 문서나 로그에 남기지 않는다.

### 11.3 Object storage와 media

media는 object key prefix, count, size/checksum/status 중심으로 복제한다. 사용자 media raw URL과 파일명은 보고하지 않는다. local-only Phase A는 MinIO local endpoint를 사용하고, Phase B/C에서만 staging Blob/MinIO source와 target을 연결한다.

기록할 값:

- source prefix count
- target prefix count
- sample object size/checksum/status
- API read smoke status

기록하지 않을 값:

- raw object URL
- credential
- 사용자 사진 파일명

### 11.4 Backup Spring runtime 연결

DB/Redis/Object storage 연결이 끝나면 backup Spring API를 staging-compatible env로 실행한다. env var 이름과 Key Vault secret name만 기록하고 값은 기록하지 않는다.

```bash
java -jar target/onmu-api-spring-*.jar
```

내부 smoke:

- `GET /healthz` -> 200
- `GET /readyz` -> 200
- no-token `GET /api/v1/users/me` -> 401
- authenticated `GET /api/v1/users/me` -> 200, field presence만 확인
- OAuth callback path status
- media read API status/count
- place-search provider/source/coordinate count
- chat messages/read-state/SSE status
- notification list/unread/preferences status/count

## 12. Public route cutover checklist

Phase C에서는 backup backend를 공개 route에 연결한다. 권장 순서는 `backup-api.onmu.cloud` 같은 임시 route로 먼저 smoke한 뒤, 같은 결과가 확인되면 `staging-api.onmu.cloud`를 backup backend로 전환하는 것이다. 모바일 앱이 이미 `staging-api.onmu.cloud`를 바라보고 있다면, 최종 cutover는 앱 재빌드보다 route 전환으로 처리하는 편이 빠르다.

Cutover 전 확인:

- Azure staging의 현재 ACA revision, image tag, health status
- backup backend commit hash와 Spring runtime status
- source/target DB dump 시각과 row count
- object prefix/count/checksum
- OAuth callback host가 기존 host와 같은지 여부
- rollback route 대상

Route 전환 방식 후보:

| 방식 | 기준 |
| --- | --- |
| Cloudflare tunnel route | Mac/Windows 장비를 짧게 공개 대체해야 할 때 |
| DNS/CNAME switch | 고정 백업 endpoint가 준비되어 있고 TTL/rollback을 관리할 수 있을 때 |
| Reverse proxy | 같은 네트워크 안의 별도 gateway가 있고 TLS/health check를 관리할 수 있을 때 |

OAuth provider callback host가 바뀌면 provider console과 관련 Key Vault secret name의 값이 같은 phase 안에서 정렬되어야 한다. callback host를 바꾸지 않고 `staging-api.onmu.cloud` route만 backup backend로 이동하면 provider console 변경 없이 smoke할 수 있다.

Cutover 직후 smoke:

- public `GET /healthz` -> 200
- public `GET /readyz` -> 200
- no-token public `GET /api/v1/users/me` -> 401
- authenticated mobile smoke
- OAuth mobile smoke
- chat send/read smoke
- media upload/read smoke
- place-search smoke
- notification unread/list smoke

Rollback:

1. route를 Azure staging primary로 되돌린다.
2. backup backend를 read-only 또는 stopped 상태로 전환한다.
3. cutover 이후 backup backend에서만 발생한 write가 있으면 reverse migration 또는 forward fix 범위를 count/status 중심으로 기록한다.
4. 사용자 raw row, token, media URL은 rollback 보고에 남기지 않는다.

## 13. 정리와 폐기

각 phase가 끝나면 아래만 기록한다.

- OS와 장비 역할
- repo commit hash
- Spring runtime 시작 여부
- smoke status/path/count
- 사용한 env var name
- 참고한 Key Vault secret name

아래는 기록하지 않는다.

- secret value
- DB connection string value
- bearer token
- OAuth code/state/idToken
- 사용자 raw row
- 사용자 media URL

장비를 폐기하거나 역할에서 내릴 때는 local ignored env 파일, dump 파일, temporary log, generated dart-define, build artifact의 보존/삭제 여부를 확인한다. 삭제 명령은 폐기 체크포인트와 보존 대상 목록을 기록한 뒤 수행한다.
