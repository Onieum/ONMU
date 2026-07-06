#!/usr/bin/env bash
# VM 하이브리드 호스팅용 부트스트랩 (Ubuntu 24.04 VM 내부에서 실행).
# Docker + compose plugin + cloudflared 를 설치한다. 비밀값/clone/.env.production 은 별도 주입.
# 사용: bash scripts/prod-vm/bootstrap-vm.sh
# 상세: docs/operations/vm-hosting-migration-runbook.md (WS2)
set -euo pipefail

log() { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }

if command -v docker >/dev/null 2>&1; then
  log "Docker already installed: $(docker --version)"
else
  log "Installing Docker Engine + compose plugin..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER" || true
  log "Docker installed. (현재 셀에 그룹 적용: newgrp docker 또는 재로그인)"
fi

if docker compose version >/dev/null 2>&1; then
  log "Compose plugin OK: $(docker compose version)"
else
  echo "ERROR: docker compose plugin not found" >&2
  exit 1
fi

if command -v cloudflared >/dev/null 2>&1; then
  log "cloudflared already installed: $(cloudflared --version)"
else
  log "Installing cloudflared..."
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
    | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-main.gpg
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(. /etc/os-release && echo "$VERSION_CODENAME") main" \
    | sudo tee /etc/apt/sources.list.d/cloudflared.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y cloudflared
fi

log "Done. 다음 단계:"
cat <<'NEXT'
  1. git clone <ONMU_REPO> && cd ONMU  (또는 이미 clone 한 repo 로 이동)
  2. repo 루트에 .env.production 작성 (runbook WS2 의 예시 참조)
  3. docker compose -f infra/compose/docker-compose.prod-vm.yml --env-file .env.production up -d --build
NEXT
