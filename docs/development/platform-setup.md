# Platform Setup Guide

This guide describes local setup for macOS, Windows, and Linux.

## Common Accounts

Required:

- GitHub access to `Onieum/ONMU`
- Jira access to `https://onmu.atlassian.net`
- Azure account for AKS and managed services
- Figma access for product design
- Notion workspace access if the team uses Notion for docs

## macOS

Install tools:

```bash
brew install git gh node uv azure-cli
brew install --cask docker
brew install --cask flutter
brew tap atlassian/homebrew-acli
brew install acli
```

Authenticate:

```bash
gh auth login
az login
acli jira auth login --site onmu.atlassian.net
```

Clone and prepare:

```bash
gh repo clone Onieum/ONMU
cd ONMU
npm install
docker compose -f infra/compose/docker-compose.yml config
```

Flutter check:

```bash
flutter doctor
cd apps/mobile-flutter
flutter pub get
flutter analyze
```

## Windows

Recommended base:

- Windows 11
- WSL2 Ubuntu for backend/infra work
- Android Studio for Android emulator
- GitHub Desktop or Git CLI

Install in PowerShell:

```powershell
winget install Git.Git
winget install GitHub.cli
winget install OpenJS.NodeJS.LTS
winget install Docker.DockerDesktop
winget install Microsoft.AzureCLI
winget install Google.Flutter
```

Then:

```powershell
gh auth login
az login
gh repo clone Onieum/ONMU
cd ONMU
npm install
docker compose -f infra/compose/docker-compose.yml config
flutter doctor
```

For WSL2:

```bash
sudo apt update
sudo apt install -y git curl unzip
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Linux

Install common tools:

```bash
sudo apt update
sudo apt install -y git curl unzip nodejs npm docker.io docker-compose-plugin
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Install GitHub CLI and Azure CLI from their official package repositories.

Flutter:

```bash
mkdir -p ~/dev
cd ~/dev
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$HOME/dev/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
flutter doctor
```

Repository:

```bash
gh auth login
gh repo clone Onieum/ONMU
cd ONMU
npm install
docker compose -f infra/compose/docker-compose.yml config
```

## Local Dependency Stack

Start core dependencies:

```bash
docker compose -f infra/compose/docker-compose.yml up -d postgres redis minio
```

Start optional event/search services:

```bash
docker compose -f infra/compose/docker-compose.yml --profile events --profile search up -d
```

Services:

| Service | URL |
| --- | --- |
| PostgreSQL | `localhost:5432` |
| Redis | `localhost:6379` |
| MinIO API | `http://localhost:9000` |
| MinIO Console | `http://localhost:9001` |
| Redpanda | `localhost:9092` |
| OpenSearch | `http://localhost:9200` |

## Notes

- Do not commit `.env`.
- Use `.env.example` as the template.
- Use Jira issue keys in PRs so Jira and GitHub can link work automatically.
