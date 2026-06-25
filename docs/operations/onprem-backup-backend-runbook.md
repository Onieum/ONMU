# On-prem backup backend runbook

이 문서는 Mac 또는 Windows 장비를 ONMU 백업 백엔드 서버 후보로 준비할 때의 공통 절차를 정리한다.

현재 팀의 primary 서비스와 acceptance 기준은 Azure staging이다. On-prem backup backend는 자동 failover 대상이 아니며, Azure staging 장애 분석, 수동 fallback 준비, 개발/검증 분리, 복구 리허설을 위한 보조 경로다.

## 1. 운영 경계

| 항목 | 기준 |
| --- | --- |
| Primary API | `https://staging-api.onmu.cloud` Azure Container Apps |
| Backup 후보 | Mac 또는 Windows 장비의 Spring Boot Main API |
| 기본 공개 범위 | local-only 또는 팀 내부 승인 범위 |
| 자동 전환 | 하지 않음 |
| DNS/provider console 변경 | 별도 승인 전 금지 |
| DB/Media 복제 | 별도 승인 전 금지 |

On-prem backup backend 준비 중에는 Azure staging DNS, Container Apps, Key Vault secret value, OAuth provider console, Cloudflare tunnel route를 변경하지 않는다.

## 2. 문서 읽는 순서

1. 현재 운영 기준: [staging cutover status](./staging-cutover-status.md)
2. Azure primary 운영: [Azure staging 배포/운영 runbook](./azure-staging-deploy-runbook.md)
3. 환경별 차이: [Azure 환경 매트릭스](./azure-environment-matrix.md)
4. 데이터 이전 승인 경계: [Azure 데이터 이전 runbook](./azure-data-migration-runbook.md)
5. Windows legacy 상세: [Windows 노트북 백엔드 서버 세팅 가이드](./windows-backend-server.md)

이 문서는 Mac/Windows 공통 진입점이다. Windows 전용 legacy tunnel, PowerShell helper, Docker Desktop 세부 운영은 Windows 문서를 참고한다.

## 3. 공통 원칙

- `dev`와 `main`에 직접 push하지 않는다.
- 백업 서버는 최신 `origin/dev` 기준으로만 준비한다.
- 작업 전 `git status --short --branch`로 unrelated dirty/untracked change를 확인한다.
- secret 값은 장비 간 복사하지 않는다. 필요한 값은 env var 이름과 Key Vault secret name으로만 추적한다.
- `.env`, dart-define, raw log, DB dump, object dump는 git ignored 경로 또는 repo 밖에 둔다.
- 사용자 실제 이름, 이메일, 사진, 위치, 정산 내역, OAuth `code`/`state`/idToken, bearer token, DB password는 문서와 로그 요약에 남기지 않는다.
- destructive command는 별도 승인 없이 실행하지 않는다.

## 4. 복사 대상과 비대상

| 구분 | 복사 가능 | 기본 비대상 |
| --- | --- | --- |
| 코드 | repo clone 또는 기존 worktree 최신화 절차 | dev/main 직접 push |
| 설정 | `.env.example` 기반 local ignored env 파일 | 운영 secret value 평문 복사 |
| DB | schema 준비 절차와 승인된 logical dump 절차 링크 | 승인 없는 staging raw data dump/restore |
| Redis | 재생성 가능한 cache로 취급 | 영속 backup/restore |
| Object storage | 승인된 object prefix/count/checksum 리허설 | 사용자 media raw URL/파일명 공유 |
| Tile asset | manifest/style/PMTiles count/status 검증 | current object 승인 없는 overwrite |

데이터 복제가 필요하면 이 문서에서 직접 진행하지 않고 [Azure 데이터 이전 runbook](./azure-data-migration-runbook.md)의 승인 절차를 따른다.

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

백업 서버는 env var name을 Spring runtime에 주입한다. secret 값은 Key Vault나 운영자가 승인한 local ignored env 파일에서만 읽는다.

현재 staging runtime secret source는 재사용 Key Vault `onmu-dev-kv-27db5e`의 `staging-*` secret name이다. 이 이름은 secret 값이 아니라 운영 참조명이다.

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
| `OBJECT_STORAGE_ENDPOINT` | `staging-blob-endpoint` | Object storage |
| `OBJECT_STORAGE_BUCKET` | `staging-blob-container` | Object storage |

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

### 7.2 실행 형태

Mac 백업 서버는 local-only로 먼저 준비한다.

```bash
cd <ONMU_REPO>/services/api-spring
./mvnw -DskipTests clean package
java -jar target/onmu-api-spring-*.jar
```

실제 운영 secret을 넣어 실행해야 하는 경우에는 별도 승인된 local ignored env 파일에서 현재 shell로만 주입한다. `.env`나 shell history에 secret value가 남지 않도록 한다.

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

승인된 Windows 백업 서버에서 local Spring만 확인할 때는 공개 Cloudflare tunnel을 새로 열지 않는다. `dev-api.onmu.cloud`, `db-dev.onmu.cloud` 같은 legacy route는 별도 승인 전 사용하지 않는다.

로그 후보:

| 로그 | 기준 |
| --- | --- |
| deploy log | `logs\deploy-dev-backend.log` |
| Spring stdout | `logs\dev-backend-api.out.log` |
| Spring stderr | `logs\dev-backend-api.err.log` |
| access log | `logs\api-access.log` |

## 9. Smoke 명령 예시

아래 명령은 문서화된 예시다. 이 문서 작성 작업에서는 실행하지 않는다.

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

보호 API, OAuth, media, place-search, chat smoke는 별도 승인된 검증 작업으로 분리한다.

## 10. 공개 전환 금지 기준

다음 작업은 이 runbook의 기본 준비 절차에 포함하지 않는다.

- `staging-api.onmu.cloud` DNS 변경
- Azure Container Apps revision 변경
- Key Vault secret value 변경
- OAuth provider console 변경
- Cloudflare tunnel route 추가
- DB dump/restore
- Blob object overwrite
- Terraform apply
- GitHub environment secret/variable 변경

실제 fallback 전환이 필요하면 운영자가 Azure staging 상태, backup backend 상태, 데이터 신선도, OAuth callback host, DNS TTL, rollback 경로를 별도 체크리스트로 승인한다.

## 11. 정리와 폐기

백업 서버 준비가 끝나면 아래만 기록한다.

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

장비를 폐기하거나 역할에서 내릴 때는 local ignored env 파일, dump 파일, temporary log, generated dart-define, build artifact의 보존/삭제 여부를 운영자가 확인한다. 삭제 명령은 별도 승인 후 수행한다.
