# Windows 노트북 백엔드 서버 세팅 가이드

이 문서는 Windows 노트북을 팀 개발용 백엔드 서버로 사용할 때 필요한 세팅과 운영 기준입니다. OBS와 캡처보드는 화면 공유와 모니터링 용도이고, 백엔드 서비스 자체는 Windows, Docker Desktop, WSL2, 방화벽, 네트워크 설정으로 운영합니다.

## 운영 목표

목표:

- 팀원이 각자 다른 PC나 모바일 기기에서 같은 백엔드에 접속할 수 있게 합니다.
- 로컬 개발 환경과 나중의 Azure/AKS 환경이 크게 다르지 않게 Docker 기반으로 맞춥니다.
- 외부 API 키, DB, Redis, Object Storage 같은 민감한 리소스를 직접 인터넷에 열지 않습니다.
- 초기에는 Windows 노트북을 임시 dev 서버로 쓰고, 배포 준비가 되면 AKS staging으로 옮깁니다.

권장 구조:

```text
Team devices
  -> http://<windows-lan-ip>:8080
  -> ONMU API or gateway
  -> Docker Desktop / WSL2
     -> PostgreSQL + PostGIS
     -> Redis
     -> MinIO
     -> optional Redpanda / OpenSearch
```

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
저장소를 clone한 뒤 npm install, docker compose config, docker compose up을 실행해줘.
API가 생기면 0.0.0.0:8080으로 열고, Windows Defender Firewall에서 8080만 인바운드 허용해줘.
PostgreSQL 5432, Redis 6379, MinIO 9000/9001은 외부 네트워크에 열지 말고 로컬 또는 Docker network 내부에서만 쓰게 해줘.
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
```

Docker Compose 설정 확인:

```powershell
docker compose -f infra/compose/docker-compose.yml config
```

현재 Compose 의존성 포트는 `127.0.0.1`에만 바인딩합니다. Windows 서버에서 직접 띄운 API는 `localhost:5432`, `localhost:6379`, `localhost:9000`으로 의존성에 접근할 수 있지만, 다른 팀원 PC에서는 이 포트에 직접 접근할 수 없어야 합니다.

기본 의존성 실행:

```powershell
docker compose -f infra/compose/docker-compose.yml up -d postgres redis minio
docker compose -f infra/compose/docker-compose.yml ps
```

이벤트나 검색 기능을 함께 테스트할 때만 선택적으로 실행합니다.

```powershell
docker compose -f infra/compose/docker-compose.yml --profile events --profile search up -d
```

## 4. API 서버 바인딩 규칙

팀원이 다른 장치에서 접속하려면 API 서버가 `localhost`가 아니라 `0.0.0.0`에 바인딩되어야 합니다.

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

권장 순서:

1. Tailscale 같은 VPN으로 팀원 장치를 같은 사설망처럼 묶습니다.
2. 임시 데모는 Cloudflare Tunnel 또는 ngrok를 사용합니다.
3. 장기 운영은 Azure staging 환경으로 옮깁니다.
4. 공유기 port forwarding은 HTTPS reverse proxy와 인증을 준비한 뒤 사용합니다.

외부 공개 시 금지:

- DB 포트 공개
- Redis 포트 공개
- MinIO console 공개
- `.env`나 API 키를 화면 공유 또는 Notion/Jira에 노출
- 기본 비밀번호를 그대로 사용

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
- 실제 외부 API 키는 팀 채팅이나 Notion에 쓰지 않습니다.
- GitHub Actions에는 GitHub Secrets를 사용합니다.
- Azure 배포에서는 Azure Key Vault를 사용합니다.
- 키가 화면에 노출되었으면 즉시 폐기하고 재발급합니다.

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

- API와 realtime gateway가 Docker image로 빌드됩니다.
- `/healthz`, `/readyz`가 있습니다.
- DB migration이 자동화되어 있습니다.
- GitHub Actions에서 image build와 test가 통과합니다.
- AKS 또는 Azure Container Apps 중 배포 대상이 정해졌습니다.
- 외부 API 키가 Azure Key Vault에 들어갔습니다.
- 로그와 에러 추적이 Application Insights 또는 OpenTelemetry로 연결됩니다.

Windows 서버에서 검증한 compose 설정은 AKS manifest나 Helm/Kustomize 설정을 만들 때 기준 입력으로 사용합니다.
