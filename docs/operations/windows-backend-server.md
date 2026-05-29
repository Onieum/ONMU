# Windows 노트북 백엔드 서버 세팅 가이드

이 문서는 Windows 노트북을 팀 개발용 백엔드 서버로 사용할 때 필요한 세팅과 운영 기준입니다. OBS와 캡처보드는 화면 공유와 모니터링 용도이고, 백엔드 서비스 자체는 Windows, Docker Desktop, WSL2, 방화벽, 네트워크 설정으로 운영합니다.

## 운영 목표

목표:

- 팀원이 각자 다른 PC나 모바일 기기에서 같은 백엔드에 접속할 수 있게 합니다.
- 로컬 개발 환경과 나중의 Azure/AKS 환경이 크게 다르지 않게 Docker 기반으로 맞춥니다.
- 외부 API 키, DB, Redis, Object Storage 같은 민감한 리소스를 직접 인터넷에 열지 않습니다.
- 초기에는 Windows 노트북을 임시 dev 서버로 쓰고, 배포 준비가 되면 Azure Container Apps 또는 AKS staging으로 옮깁니다.
- `onmu.cloud` 루트 도메인은 제품/비즈니스 소개 페이지용으로 남기고, 로컬 백엔드는 `dev-api.onmu.cloud` 같은 개발용 서브도메인으로만 노출합니다.
- 팀원 DB 점검이 필요할 때는 DB 포트를 직접 열지 않고 `db-dev.onmu.cloud` Cloudflare Access TCP 앱을 통해 인증된 사용자만 접속하게 합니다.

권장 구조:

```text
Team devices
  -> https://dev-api.onmu.cloud
     또는 http://<windows-lan-ip>:8080
  -> ONMU API / local gateway
  -> Docker Desktop / WSL2
     -> PostgreSQL + PostGIS
     -> Redis
     -> MinIO
     -> optional Redpanda
     -> optional OpenSearch
```

현재 아키텍처 반영 기준:

| 영역 | Windows dev 서버 기준 |
| --- | --- |
| Main API | 현재는 `services/api/server.mjs` smoke API가 `/healthz`, `/readyz`를 제공하고, 이후 Spring Boot Main API도 같은 포트와 헬스 체크 계약을 유지합니다. |
| Realtime Gateway | 1차 구현 전까지 별도 실행하지 않습니다. 구현 후에는 API 뒤에 두거나 개발용 포트를 별도로 정합니다. |
| AI/Data Worker | 1차 Windows helper의 기본 실행 대상이 아닙니다. 추천/기록 worker가 생기면 Docker image 또는 별도 프로세스로 추가합니다. |
| PostgreSQL/PostGIS | 약속, 장소, 기록, 정산, 공개 범위의 원본 저장소입니다. Windows 호스트에서는 `localhost:15432`를 사용합니다. |
| Redis | Naver Place API 캐시, 실시간 presence, WebSocket fan-out, rate limit 보조에만 사용합니다. 원본 저장소로 쓰지 않습니다. |
| MinIO | Azure Blob Storage 대체 로컬 오브젝트 스토리지입니다. 사진, 공유 카드, 기록 이미지 개발 테스트에 사용합니다. |
| Redpanda | Azure Service Bus/Event Hubs 또는 Kafka 호환 이벤트 흐름을 실험할 때만 켭니다. 기본 실행 대상이 아닙니다. |
| OpenSearch | 초기 검색은 PostgreSQL Search를 우선합니다. 검색/RAG 실험이 필요할 때만 켭니다. |
| Airflow | MVP Windows dev 서버 기본 구성에는 포함하지 않습니다. 추천 평가, 통계 리포트, 데이터셋 생성 같은 배치 파이프라인이 커질 때 별도 도입을 검토합니다. |
| Cloudflare Tunnel | 외부 팀 테스트를 위한 개발용 API 터널입니다. 운영 배포 경계나 제품 소개 페이지 호스팅과 분리합니다. |

나중에 외부 네트워크 접속이 필요해지면 다음 중 하나를 사용합니다.

- Tailscale 같은 VPN
- Cloudflare Tunnel 또는 ngrok 같은 터널
- 공유기 port forwarding + HTTPS reverse proxy

인터넷에 직접 여는 방식은 마지막 선택지입니다. 열어야 한다면 API reverse proxy만 열고, DB/Redis/MinIO 관리 포트는 열지 않습니다.

## Windows Codex 작업 지시문

Windows 쪽 Codex에게는 아래 순서대로 요청하면 됩니다.

```text
ONMU 저장소를 Windows 개발 서버로 세팅해줘.
PowerShell 기준으로 Git, GitHub CLI, Docker Desktop, WSL2, Node.js LTS, Azure CLI를 확인하고 없으면 설치해줘.
저장소를 clone한 뒤 npm install, npm run compose:config:windows, npm run host:windows를 실행해줘.
기본 구성은 PostgreSQL/PostGIS, Redis, MinIO만 올려줘.
이벤트/검색 실험이 필요할 때만 -IncludeEvents, -IncludeSearch 옵션으로 Redpanda/OpenSearch를 켜줘.
API가 LAN 테스트에 필요할 때만 0.0.0.0:8080으로 열고, Windows Defender Firewall에서 8080만 인바운드 허용해줘.
PostgreSQL 5432, Redis 6379, MinIO 9000/9001은 외부 네트워크에 열지 말고 로컬 또는 Docker network 내부에서만 쓰게 해줘.
외부 네트워크 테스트는 dev-api.onmu.cloud Cloudflare Tunnel을 우선 사용하고, onmu.cloud 루트는 소개 페이지용으로 남겨줘.
DB 직접 점검이 필요하면 db-dev.onmu.cloud Cloudflare Access TCP를 쓰고, 팀 계정 MFA와 개인별 DB 계정을 먼저 확인해줘.
마지막에 같은 LAN의 다른 PC에서 접속할 수 있는 주소와 점검 명령을 정리해줘.
```

## 1. 기본 소프트웨어 설치

관리자 PowerShell에서 실행합니다.

```powershell
winget install Git.Git
winget install GitHub.cli
winget install OpenJS.NodeJS.LTS
winget install Docker.DockerDesktop
winget install Microsoft.AzureCLI
winget install Microsoft.VisualStudioCode
```

Flutter 앱 빌드까지 Windows에서 확인할 예정이면 추가합니다.

```powershell
winget install Google.Flutter
```

WSL2가 없다면 설치합니다.

```powershell
wsl --install
wsl --update
```

설치 후 Windows를 재부팅하고 Docker Desktop을 한 번 실행합니다. Docker Desktop 설정에서 WSL integration이 켜져 있는지 확인합니다.

## 2. 계정 로그인

PowerShell:

```powershell
gh auth login
az login
```

Git 사용자 정보:

```powershell
git config --global user.name "your-name"
git config --global user.email "your-email@example.com"
```

## 3. 저장소 준비

권장 위치는 공백이 적은 경로입니다.

```powershell
mkdir C:\dev
cd C:\dev
gh repo clone Onieum/ONMU
cd ONMU
npm install
copy .env.example .env
```

`.env`는 커밋하지 않습니다. 개인 로컬 테스트는 `.env.example`의 임시값을 복사해 쓸 수 있지만, 공유 Windows dev 서버의 DB 비밀번호, 외부 API key, Cloudflare API token은 Azure Key Vault에서 읽습니다.

Docker Compose 설정 확인:

```powershell
docker compose -f infra/compose/docker-compose.yml config
```

이미 로컬 PostgreSQL이 `5432`를 쓰는 Windows 개발 서버에서는 Windows helper를 사용합니다.

```powershell
npm run compose:config:windows
```

현재 Compose 의존성 포트는 `127.0.0.1`에만 바인딩합니다. Windows 서버에서 직접 띄운 API는 `localhost:5432`, `localhost:6379`, `localhost:9000`으로 의존성에 접근할 수 있지만, 다른 팀원 PC에서는 이 포트에 직접 접근할 수 없어야 합니다.

이 저장소의 Windows helper는 이 PC의 기존 PostgreSQL과 충돌하지 않도록 `POSTGRES_HOST_PORT=15432`를 설정해 Docker PostgreSQL을 `localhost:15432`에 바인딩합니다. 공유 dev 서버에서는 `DATABASE_URL`과 `POSTGRES_PASSWORD`를 Key Vault에서 로드합니다.

기본 의존성 실행:

```powershell
docker compose -f infra/compose/docker-compose.yml up -d postgres redis minio
docker compose -f infra/compose/docker-compose.yml ps
```

Windows helper를 쓰는 경우:

```powershell
npm run host:windows
npm run compose:ps:windows
```

공유 Windows dev 서버에서 Key Vault 값을 로드해 의존성을 시작하는 경우:

```powershell
npm run host:windows:keyvault
npm run api:dev:keyvault
```

이벤트나 검색 기능을 함께 테스트할 때만 선택적으로 실행합니다. 현재 ONMU의 기본 MVP 흐름은 PostgreSQL/PostGIS, Redis, MinIO만으로 충분합니다.

```powershell
npm run host:windows:events
npm run host:windows:search
npm run host:windows:full
```

Windows helper를 쓰지 않을 때는 Compose profile을 직접 지정합니다.

```powershell
docker compose -f infra/compose/docker-compose.yml --profile events up -d postgres redis minio redpanda
docker compose -f infra/compose/docker-compose.yml --profile search up -d postgres redis minio opensearch
```

## 4. API 서버 바인딩 규칙

팀원이 다른 장치에서 접속하려면 API 서버가 `localhost`가 아니라 `0.0.0.0`에 바인딩되어야 합니다.

단, 기본값은 안전하게 `127.0.0.1`입니다. 같은 LAN에서 직접 테스트할 때만 `0.0.0.0`과 Windows 방화벽 규칙을 사용하고, 외부 네트워크 테스트는 Cloudflare Tunnel을 우선 사용합니다.

권장 환경 변수:

```powershell
$env:HOST="0.0.0.0"
$env:PORT="8080"
```

API 서비스가 생긴 뒤 실행 예시는 서비스별 README에 맞춥니다.

```powershell
# 예시입니다. 실제 명령은 services/api 구현 후 갱신합니다.
npm run dev --workspace services/api
```

현재 저장소의 smoke test API는 아래처럼 실행합니다.

```powershell
npm run api:dev
```

이 smoke API는 현재 Windows dev 서버 연결 검증용입니다. 이후 Spring Boot Main API로 바뀌더라도 다음 계약은 유지합니다.

| 계약 | 이유 |
| --- | --- |
| `GET /healthz` | 프로세스가 살아 있고 HTTP 요청을 받을 수 있는지 확인 |
| `GET /readyz` | PostgreSQL, Redis, MinIO 등 로컬 의존성 연결 확인 |
| 기본 포트 `8080` | Cloudflare Tunnel, LAN 테스트, 모바일 앱 dev base URL을 고정하기 위함 |
| DB/Redis/MinIO 로컬 바인딩 | 데이터 계층을 인터넷과 LAN에 직접 노출하지 않기 위함 |

LAN으로 직접 열어야 할 때만 API host를 바꿉니다.

```powershell
$env:API_HOST="0.0.0.0"
$env:HOST="0.0.0.0"
npm run api:dev
```

헬스 체크 엔드포인트가 생기면 Windows 로컬에서 확인합니다.

```powershell
curl http://localhost:8080/healthz
```

다른 PC나 휴대폰에서는 아래처럼 확인합니다.

```powershell
curl http://<windows-lan-ip>:8080/healthz
```

## 5. Windows IP 고정

현재 IP 확인:

```powershell
ipconfig
```

확인할 항목:

- Wi-Fi 또는 Ethernet 어댑터의 IPv4 주소
- 예: `192.168.0.23`

팀원이 같은 공유기나 같은 네트워크에 있다면 접속 주소는 다음과 같습니다.

```text
http://192.168.0.23:8080
```

서버 역할로 계속 쓸 PC라면 공유기에서 DHCP reservation을 설정해 IP가 바뀌지 않게 합니다. 공유기 설정이 어렵다면 Windows 네트워크 설정에서 수동 IP를 지정할 수 있지만, 충돌 위험이 있으므로 공유기 예약이 더 안전합니다.

## 6. Windows Defender Firewall

API 포트만 인바운드 허용합니다.

관리자 PowerShell:

```powershell
New-NetFirewallRule `
  -DisplayName "ONMU API 8080" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 8080 `
  -Action Allow
```

확인:

```powershell
Get-NetFirewallRule -DisplayName "ONMU*"
```

포트를 닫아야 할 때:

```powershell
Remove-NetFirewallRule -DisplayName "ONMU API 8080"
```

주의:

- PostgreSQL `5432`는 외부에 열지 않습니다.
- Redis `6379`는 외부에 열지 않습니다.
- MinIO API `9000`과 Console `9001`은 외부에 열지 않습니다.
- Redpanda `9092`, OpenSearch `9200`도 외부에 열지 않습니다.
- 외부 접속이 필요하면 API gateway나 reverse proxy 포트만 열고 HTTPS를 붙입니다.

## 7. 같은 LAN에서 접속 테스트

Windows 서버에서 포트가 열렸는지 확인:

```powershell
netstat -ano | findstr :8080
```

다른 Windows PC에서 확인:

```powershell
Test-NetConnection -ComputerName <windows-lan-ip> -Port 8080
curl http://<windows-lan-ip>:8080/healthz
```

Mac 또는 Linux에서 확인:

```bash
nc -vz <windows-lan-ip> 8080
curl http://<windows-lan-ip>:8080/healthz
```

휴대폰에서 확인:

- 같은 Wi-Fi에 연결합니다.
- 브라우저에서 `http://<windows-lan-ip>:8080/healthz`를 엽니다.

## 8. 외부 네트워크 접속 기준

팀원이 같은 LAN 밖에 있다면 바로 공유기 port forwarding을 열기보다 VPN이나 터널을 먼저 사용합니다.

ONMU의 현재 Windows dev 서버는 Cloudflare를 기본 선택지로 둡니다. 이유는 다음과 같습니다.

- 공유기 port forwarding 없이 outbound 연결만으로 외부 접속을 열 수 있습니다.
- Windows Defender Firewall에서 8080 inbound를 열지 않아도 됩니다.
- PostgreSQL, Redis, MinIO 포트는 계속 `127.0.0.1`에만 둘 수 있습니다.
- `onmu.cloud` DNS, 나중의 제품 소개 페이지, dev API tunnel을 한 Cloudflare 계정에서 관리할 수 있습니다.
- 루트 도메인은 제품과 비즈니스 소개 페이지에 남기고, 로컬 백엔드는 개발용 서브도메인으로 분리할 수 있습니다.

도메인 역할:

| 도메인 | 용도 |
| --- | --- |
| `onmu.cloud` | 제품/비즈니스 소개 페이지. Cloudflare Pages, Vercel, Azure Web App 중 나중에 선택합니다. |
| `www.onmu.cloud` | `onmu.cloud`와 같은 소개 페이지 또는 redirect. |
| `dev-api.onmu.cloud` | Windows 로컬 백엔드 dev tunnel. |
| `db-dev.onmu.cloud` | Cloudflare Access TCP로 보호되는 개발 DB 점검용 hostname. |
| `api.onmu.cloud` | 나중의 staging/prod API용으로 예약합니다. |

권장 순서:

1. 같은 조직 안의 장기 개발망은 Tailscale 같은 VPN을 검토합니다.
2. 현재 Windows dev 서버와 짧은 팀 테스트는 Cloudflare Tunnel을 사용합니다.
3. 장기 운영은 Azure staging 환경으로 옮깁니다.
4. 공유기 port forwarding은 HTTPS reverse proxy와 인증을 준비한 뒤 마지막 선택지로만 사용합니다.

외부 공개 시 금지:

- DB 포트 공개
- Redis 포트 공개
- MinIO console 공개
- `.env`나 API 키를 화면 공유 또는 Notion/Jira에 노출
- 기본 비밀번호를 그대로 사용

### Gabia와 Cloudflare 네임서버

`onmu.cloud`는 Gabia에서 구매했고, Gabia 도메인 관리에서 Cloudflare가 발급한 nameserver 2개로 교체했습니다. 2026-05-27 작업에서는 Cloudflare zone이 약 5분 만에 `Active`가 되었지만, DNS 변경은 등록기관/상위 DNS 캐시 상태에 따라 더 오래 걸릴 수 있습니다. 따라서 실제 운영 절차에서는 빠르게 끝날 수 있되, 외부 팀 일정에는 여유를 둡니다.

Gabia 쪽에서는 DNS 레코드를 직접 만들지 않고 nameserver만 Cloudflare로 넘깁니다. 이후 `dev-api`, `www`, `api` 같은 레코드는 Cloudflare에서 관리합니다.

### Cloudflare Tunnel

현재 dev API tunnel:

```text
dev-api.onmu.cloud -> onmu-dev-api tunnel -> http://localhost:8080
```

처음 만드는 명령:

```powershell
cloudflared tunnel create onmu-dev-api
cloudflared tunnel route dns onmu-dev-api dev-api.onmu.cloud
```

실행:

```powershell
npm run tunnel:cloudflare
```

확인:

```powershell
curl https://dev-api.onmu.cloud/healthz
curl https://dev-api.onmu.cloud/readyz
npm run tunnel:cloudflare:info
```

Cloudflare Tunnel은 `dev-api.onmu.cloud`에서 API/gateway만 프록시합니다. PostgreSQL, Redis, MinIO, Redpanda, OpenSearch 관리 포트는 Cloudflare나 LAN에 직접 열지 않습니다. Realtime Gateway가 WebSocket을 쓰게 되면 같은 API 경계 아래로 붙이거나, 필요할 때만 `dev-realtime.onmu.cloud` 같은 별도 개발용 호스트를 추가합니다.

기본 실행은 API 전용 config를 사용합니다.

```powershell
npm run tunnel:cloudflare
```

DB 점검용 Access TCP까지 함께 켤 때만 별도 config를 사용합니다. 이 모드는 Cloudflare Zero Trust의 Access application과 팀 정책이 active인 것을 확인한 뒤 실행합니다. 스크립트도 실수 실행을 막기 위해 `CLOUDFLARE_ACCESS_TCP_POLICY_ACTIVE=true`가 없으면 중단됩니다.

```powershell
$env:CLOUDFLARE_ACCESS_TCP_POLICY_ACTIVE="true"
npm run tunnel:cloudflare:access-tcp
```

2026-05-27 초기 세팅 검증:

- `onmu-dev-api` named tunnel 생성
- `dev-api.onmu.cloud` DNS route 생성
- `cloudflared` 2026.5.1로 실행
- `https://dev-api.onmu.cloud/healthz`가 `200 OK`
- `https://dev-api.onmu.cloud/readyz`가 PostgreSQL `localhost:15432`, Redis `localhost:6379`, MinIO `localhost:9000` 모두 `ok`
- quick tunnel은 정리하고 named tunnel connector 1개만 유지

Cloudflare quick tunnel을 쓸 때도 저장소의 전용 config를 사용합니다. 이 PC에 이미 `~/.cloudflared/config.yml`이 있으면 기존 ingress 규칙이 섞여서 새 URL이 404를 반환할 수 있기 때문입니다.

```powershell
npm run tunnel:cloudflare:quick
```

`cloudflared tunnel route dns`에서 `Authentication error`가 나면 현재 `~/.cloudflared/cert.pem`이 새 zone 권한을 갖고 있지 않은 상태입니다. 기존 인증서는 백업해 두고 `cloudflared login`을 다시 실행한 뒤 `onmu.cloud`를 선택해서 승인합니다.

### Cloudflare Access TCP로 개발 DB 접속

DB를 클라우드처럼 팀원이 점검해야 할 때도 PostgreSQL 포트를 인터넷에 직접 열지 않습니다. ONMU 개발 서버의 권장 구조는 다음과 같습니다.

```text
Team member PC
  -> cloudflared access tcp
  -> localhost:15433
  -> Cloudflare Access policy + MFA
  -> db-dev.onmu.cloud
  -> onmu-dev-api tunnel
  -> Windows server localhost:15432
  -> PostgreSQL/PostGIS
```

서버 쪽 Cloudflare ingress는 API와 DB를 분리합니다.

| Hostname | Origin | 실행 모드 |
| --- | --- | --- |
| `dev-api.onmu.cloud` | `http://localhost:8080` | 기본 API tunnel |
| `db-dev.onmu.cloud` | `tcp://localhost:15432` | Access TCP policy 확인 후에만 실행 |

Cloudflare Zero Trust에서 먼저 설정해야 하는 항목:

1. Access application을 추가하고 hostname을 `db-dev.onmu.cloud`로 지정합니다.
2. 허용 정책은 팀 이메일 또는 팀 IdP 그룹만 포함합니다.
3. MFA를 필수로 적용하고 세션 만료 시간을 짧게 둡니다.
4. Access authentication logs에서 누가 언제 접속했는지 확인할 수 있게 합니다.
5. DNS route는 `db-dev.onmu.cloud`가 `onmu-dev-api` tunnel을 보도록 만듭니다.

위 정책이 active가 되기 전에는 `db-dev.onmu.cloud` DNS route를 만들거나 `npm run tunnel:cloudflare:access-tcp`를 공유하지 않습니다. 정책 없이 TCP ingress를 먼저 켜면 편의성보다 노출 위험이 커집니다.

정책 활성화 후 Windows 서버에서 실행:

```powershell
cloudflared tunnel route dns onmu-dev-api db-dev.onmu.cloud
$env:CLOUDFLARE_ACCESS_TCP_POLICY_ACTIVE="true"
npm run tunnel:cloudflare:access-tcp
```

팀원 PC에서 실행:

```powershell
winget install Cloudflare.cloudflared
npm run db:access:cloudflare
```

저장소를 받지 않은 팀원은 같은 명령을 직접 실행할 수 있습니다.

```powershell
cloudflared access tcp --hostname db-dev.onmu.cloud --url localhost:15433
```

DB 클라이언트 설정:

| 항목 | 값 |
| --- | --- |
| Host | `localhost` |
| Port | `15433` |
| Database | `onmu` |
| User | 개인별 개발 DB 계정 |
| SSL | 로컬 cloudflared listener에는 불필요. 필요 시 DB 정책에 맞춰 조정 |

보안 기준:

- PostgreSQL host port `15432`는 Windows 서버의 `127.0.0.1`에만 둡니다.
- Redis `6379`, MinIO `9000/9001`은 Access TCP로도 바로 열지 않습니다. 필요하면 별도 이슈에서 사용자, 권한, 감사로그를 먼저 설계합니다.
- 공용 `onmu` 계정은 smoke test와 초기 개발용으로만 쓰고, 팀원에게는 개인별 DB 계정과 최소 권한을 부여합니다.
- DDL 권한은 기본적으로 제한하고, migration 담당자 또는 CI 계정만 부여합니다.
- `0.0.0.0/0` 허용, 공유 비밀번호, 장기 세션, MFA 미적용 정책은 사용하지 않습니다.
- Access 로그와 DB 로그를 함께 봐서 사용자 접속과 실제 DB 작업을 대조할 수 있게 합니다.
- `dev-api.onmu.cloud`, `db-dev.onmu.cloud` 같은 hostname은 비밀값으로 간주하지 않습니다. 대신 Cloudflare Access, RBAC, 방화벽, 로그로 접근을 통제합니다.
- DB 비밀번호, Cloudflare API token, Naver/Kakao/Google API key, JWT signing secret은 Azure Key Vault에 저장합니다.

참고:

- Cloudflare Arbitrary TCP with Access: <https://developers.cloudflare.com/cloudflare-one/access-controls/applications/non-http/cloudflared-authentication/arbitrary-tcp/>
- Cloudflare Tunnel ingress rules: <https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/configure-tunnels/local-management/ingress/>
- Cloudflare self-hosted Access applications: <https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted-public-app/>

## 9. Docker Compose 운영

상태 확인:

```powershell
docker compose -f infra/compose/docker-compose.yml ps
docker ps
```

로그 확인:

```powershell
docker compose -f infra/compose/docker-compose.yml logs -f postgres
docker compose -f infra/compose/docker-compose.yml logs -f redis
docker compose -f infra/compose/docker-compose.yml logs -f minio
```

재시작:

```powershell
docker compose -f infra/compose/docker-compose.yml restart
```

중지:

```powershell
docker compose -f infra/compose/docker-compose.yml down
```

볼륨까지 삭제하는 명령은 데이터가 사라집니다. 필요할 때만 사용합니다.

```powershell
docker compose -f infra/compose/docker-compose.yml down -v
```

## 10. 전원과 OBS 운영

서버 PC는 화면 공유용 PC와 동시에 쓰더라도 전원 관리가 중요합니다.

Windows 설정:

- 전원 연결 상태에서 절전 모드를 끕니다.
- 디스플레이 꺼짐은 가능하지만 절전은 피합니다.
- Windows Update 자동 재시작 시간을 데모 시간과 겹치지 않게 설정합니다.
- Docker Desktop이 로그인 후 자동 실행되는지 확인합니다.

OBS와 캡처보드:

- OBS는 팀원이 서버 상태를 볼 수 있게 하는 보조 수단입니다.
- OBS가 꺼져도 백엔드 서비스는 계속 떠 있어야 합니다.
- 화면 공유 중 `.env`, 토큰, 관리자 콘솔 비밀번호가 보이지 않게 합니다.

## 11. 환경 변수와 시크릿

로컬 템플릿:

```powershell
copy .env.example .env
```

운영 규칙:

- `.env`는 커밋하지 않습니다.
- 공유 dev 서버와 Azure 배포의 실제 비밀값은 팀 Azure 구독의 dev Key Vault에 저장합니다. 실제 vault 이름과 리소스 그룹은 공개 문서나 PR 본문에 남기지 않습니다.
- 실제 외부 API 키는 팀 채팅이나 Notion에 쓰지 않습니다.
- GitHub Actions에는 GitHub Secrets를 사용합니다.
- Azure 배포에서는 Managed Identity와 Key Vault reference를 사용합니다.
- Key Vault 접근은 RBAC 최소 권한으로 부여합니다. 운영 앱에는 `Key Vault Secrets User`, secret 관리 담당자에게만 `Key Vault Secrets Officer`를 부여합니다.
- 감사 로그는 팀 Azure 구독의 Log Analytics workspace로 보냅니다.
- 비밀번호와 API key는 주기적으로 로테이션하고, 로테이션한 값은 PR/문서/터미널 로그에 출력하지 않습니다.
- 키가 화면에 노출되었으면 즉시 폐기하고 재발급합니다.

현재 dev Key Vault 식별자는 팀 내부 채널에서만 공유합니다. 공개 저장소에는 아래 환경변수 이름만 남깁니다.

| 환경변수 | 용도 |
| --- | --- |
| `AZURE_RESOURCE_GROUP` | Key Vault가 있는 리소스 그룹 |
| `AZURE_KEY_VAULT_NAME` | dev Key Vault 이름 |
| `AZURE_LOG_ANALYTICS_WORKSPACE` | Key Vault 감사 로그 workspace |

공유 dev 서버에 저장한 secret 이름도 공개 문서에는 구체값을 남기지 않습니다. 스크립트가 관리하는 범주는 PostgreSQL 연결 문자열/비밀번호, MinIO root credential, Cloudflare token, 외부 API key입니다.

초기 설정 또는 재검증:

```powershell
npm run azure:keyvault:setup
```

비밀값 저장은 값을 명령줄 인자로 넘기지 않고 프롬프트 또는 현재 프로세스 환경변수에서만 가져옵니다.

```powershell
# 프롬프트로 입력. 빈 값은 건너뜁니다.
npm run azure:keyvault:set-secrets

# 이미 현재 PowerShell 환경변수에 값이 있을 때만 저장.
npm run azure:keyvault:set-secrets -- -FromEnv
```

개발 DB 비밀번호 로테이션:

```powershell
npm run db:rotate-password:keyvault
```

이 명령은 PostgreSQL `onmu` 계정의 새 비밀번호를 생성하고 Key Vault의 DB password/connection string secret에 저장합니다. 출력에는 비밀번호를 표시하지 않습니다.

서버 시작 시 Key Vault에서 환경변수 주입:

```powershell
npm run host:windows:keyvault
npm run api:dev:keyvault
```

팀원 로컬 개발 기준:

- 팀원 개인 PC는 Key Vault 직접 접근 권한을 기본으로 받지 않습니다.
- 필요한 경우 기능별 임시 API key 또는 개인별 DB 계정을 짧은 기간으로 발급합니다.
- DB 직접 점검은 `db-dev.onmu.cloud` Cloudflare Access TCP와 개인별 DB 계정으로 제한합니다.
- 로컬 `.env`는 각자 개발용 임시값만 두고, 공유 dev/운영 secret을 복사하지 않습니다.

참고:

- Azure Key Vault secret CLI quickstart: <https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-cli>
- Azure Key Vault multiline/file secret: <https://learn.microsoft.com/en-us/azure/key-vault/secrets/multiline-secrets>
- Azure App Service Key Vault references: <https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references>

## 12. 장애 대응 체크리스트

접속이 안 될 때 Windows 서버에서 확인:

```powershell
hostname
ipconfig
docker compose -f infra/compose/docker-compose.yml ps
netstat -ano | findstr :8080
Get-NetFirewallRule -DisplayName "ONMU*"
curl http://localhost:8080/healthz
```

다른 PC에서 확인:

```powershell
Test-NetConnection -ComputerName <windows-lan-ip> -Port 8080
curl http://<windows-lan-ip>:8080/healthz
```

자주 나는 원인:

| 증상 | 원인 | 해결 |
| --- | --- | --- |
| 서버 PC에서는 되지만 다른 PC에서는 안 됨 | API가 `localhost`에만 바인딩됨 | `0.0.0.0`으로 실행 |
| 다른 PC에서 포트 연결 실패 | 방화벽 차단 | `ONMU API 8080` 방화벽 규칙 확인 |
| IP가 어제와 다름 | DHCP로 IP 변경 | 공유기 DHCP reservation 설정 |
| Docker 서비스가 사라짐 | Docker Desktop 미실행 또는 재부팅 | Docker Desktop 실행 후 compose 재시작 |
| 외부 네트워크에서 안 됨 | 같은 LAN이 아니거나 NAT 차단 | VPN/터널/HTTPS reverse proxy 사용 |

## 13. Azure로 옮길 때 기준

Windows 노트북 서버는 dev 서버입니다. 다음 조건이 맞으면 Azure staging으로 옮깁니다.

- API와 realtime gateway 또는 worker가 Docker image로 빌드됩니다.
- `/healthz`, `/readyz`가 있습니다.
- DB migration이 자동화되어 있습니다.
- GitHub Actions에서 image build와 test가 통과합니다.
- Azure Container Apps 또는 AKS 중 배포 대상이 정해졌습니다.
- 외부 API 키가 Azure Key Vault에 들어갔습니다.
- 로그와 에러 추적이 Application Insights 또는 OpenTelemetry로 연결됩니다.
- `dev-api.onmu.cloud`가 로컬 터널인지 Azure staging인지 팀원이 혼동하지 않게 DNS와 문서를 갱신합니다.

Windows 서버에서 검증한 compose 설정은 Azure Container Apps, AKS manifest, Helm/Kustomize 설정을 만들 때 기준 입력으로 사용합니다. Azure staging으로 옮긴 뒤에는 Cloudflare Tunnel을 끄고, `onmu.cloud` 또는 `www.onmu.cloud`는 제품/비즈니스 소개 페이지로만 사용합니다.
