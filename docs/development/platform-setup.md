# 플랫폼 세팅 가이드

이 문서는 macOS, Windows, Linux에서 ONMU 로컬 개발 환경을 준비하는 방법을 설명합니다.

## 공통 계정

필수:

- `Onieum/ONMU` GitHub 접근 권한
- `https://onmu.atlassian.net` Jira 접근 권한
- AKS와 관리형 서비스를 위한 Azure 계정
- 제품 디자인을 위한 Figma 접근 권한
- 팀이 Notion을 문서 허브로 쓸 경우 Notion 워크스페이스 접근 권한

## macOS

도구 설치:

```bash
brew install git gh node uv azure-cli openjdk@17
brew install --cask docker
brew install --cask flutter
brew tap atlassian/homebrew-acli
brew install acli
```

JDK 경로가 자동으로 잡히지 않으면 shell 설정에 `JAVA_HOME`을 추가합니다.

```bash
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
```

인증:

```bash
gh auth login
az login
acli jira auth login --site onmu.atlassian.net
```

저장소 클론과 준비:

```bash
gh repo clone Onieum/ONMU
cd ONMU
npm install
docker compose -f infra/compose/docker-compose.yml config
```

Flutter 확인:

```bash
flutter doctor
cd apps/mobile-flutter
flutter pub get
flutter analyze
flutter test
cd android
./gradlew --version
```

## Windows

권장 기준:

- Windows 11
- 백엔드/인프라 작업용 WSL2 Ubuntu
- Android emulator용 Android Studio
- GitHub Desktop 또는 Git CLI

PowerShell에서 설치:

```powershell
winget install Git.Git
winget install GitHub.cli
winget install OpenJS.NodeJS.LTS
winget install EclipseAdoptium.Temurin.17.JDK
winget install Docker.DockerDesktop
winget install Microsoft.AzureCLI
winget install Google.Flutter
```

그 다음:

```powershell
gh auth login
az login
gh repo clone Onieum/ONMU
cd ONMU
npm install
docker compose -f infra/compose/docker-compose.yml config
flutter doctor
cd apps\mobile-flutter
flutter pub get
flutter analyze
flutter test
cd android
.\gradlew.bat --version
```

Windows 장비를 팀 공용 백엔드 서버로 쓸 경우, 이 로컬 세팅 이후 `docs/operations/windows-backend-server.md`를 따릅니다. 해당 문서는 `0.0.0.0` 바인딩, LAN IP 확인, 방화벽 규칙, 외부에 열면 안 되는 Docker 포트를 다룹니다.

WSL2:

```bash
sudo apt update
sudo apt install -y git curl unzip
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Linux

공통 도구 설치:

```bash
sudo apt update
sudo apt install -y git curl unzip nodejs npm docker.io docker-compose-plugin openjdk-17-jdk
curl -LsSf https://astral.sh/uv/install.sh | sh
```

GitHub CLI와 Azure CLI는 각 공식 패키지 저장소 기준으로 설치합니다.

Flutter:

```bash
mkdir -p ~/dev
cd ~/dev
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$HOME/dev/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
flutter doctor
```

저장소:

```bash
gh auth login
gh repo clone Onieum/ONMU
cd ONMU
npm install
docker compose -f infra/compose/docker-compose.yml config
```

Android Gradle wrapper는 저장소에 포함되어 있습니다. 팀원과 CI는 시스템에 설치된 Gradle이 아니라 `apps/mobile-flutter/android/gradlew` 또는 `gradlew.bat`을 사용합니다.

## 로컬 의존성 스택

핵심 의존성 실행:

```bash
docker compose -f infra/compose/docker-compose.yml up -d postgres redis minio
```

선택 이벤트/검색 서비스 실행:

```bash
docker compose -f infra/compose/docker-compose.yml --profile events --profile search up -d
```

서비스:

| 서비스 | URL |
| --- | --- |
| PostgreSQL | `localhost:5432` |
| Redis | `localhost:6379` |
| MinIO API | `http://localhost:9000` |
| MinIO Console | `http://localhost:9001` |
| Redpanda | `localhost:9092` |
| OpenSearch | `http://localhost:9200` |

## 참고

- `.env`는 커밋하지 않습니다.
- `.env.example`을 템플릿으로 사용합니다.
- Jira와 GitHub가 작업을 자동 연결할 수 있도록 PR에 Jira 이슈 키를 넣습니다.
- Flutter 빌드 캐시인 `.dart_tool/`, `build/`, platform별 ephemeral 파일은 커밋하지 않습니다.
- Android Gradle wrapper 3개 파일은 커밋합니다: `gradlew`, `gradlew.bat`, `gradle-wrapper.jar`.
- Flutter가 재생성하는 registrant와 `pubspec.lock` 헤더는 도구 원본 형식을 유지합니다.
