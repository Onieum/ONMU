# 무료 우선 티어 전환 런북 (Azure 유료 → 12개월 무료 한도 내 운영)

> 관련 변경: `infra/compose/docker-compose.prod-vm.yml`, `.github/workflows/deploy-staging-vm.yml`, `infra/terraform/environments/staging/main.tf`(ACR Standard), `scripts/prod-vm/bootstrap-vm.sh`, `services/api-spring/Dockerfile`(JAVA_OPTS).
> 참고 런북: `vm-hosting-migration-runbook.md`, `azure-data-migration-runbook.md`, `azure-cost-permission-review.md`.

## 1. 배경 / 목표

Azure free trial 크레딧 소진 시, 현재 staging 은 **유료 리소스 2개**에 의존해 spending limit 으로 앱이 자동 정지한다.

| 리소스 | 현재 | 무료 해당 | 조치 |
| --- | --- | --- | --- |
| VM `onmu-staging-vm` | `Standard_D2ats_v5`(2vCPU/8GB, 유료) | ❌ | `Standard_B2ats_v2`(750h/월 무료) 로 복귀 |
| PostgreSQL Flexible `onmu-staging-pg` | `B1ms` 32GB PostGIS(유료) | ❌(무료 DB 는 Azure SQL=MSSQL) | VM 컨테이너(`postgis/postgis:16-3.4`)로 이관 |
| ACR | `Basic` | ⚠️ | `Standard`(1개, 100GB, 12개월 무료)로 승격 |
| Cloudflare R2/Pages/Tunnel | — | ✅ $0 | 유지 |

**목표 아키텍처**: VM 1대(B2ats_v2, 무료) 위에 Postgres/Redis/api/worker 컨테이너 + Cloudflare 수신 + ACR(무료) CI 빌드 = $0.

수행 순서(위험 최소): **Phase A(ACR/CI) → Phase B(DB 컷오버, 아직 8GB VM) → Phase C(VM 축소)**.

> ⚠️ **머지 타이밍 주의**: 본 런북의 **사전 준비(§2)가 끝나기 전에 dev 로 머지하면 자동 배포가 고장난다**(ACR 에 이미지가 없거나 VM 이 pull 자격이 없기 때문). PR 은 열되 §2 완료 확인 후 머지.

---

## 2. 사전 준비 (dev 머지 **이전**에 수행 — 사용자 Azure op)

> 리소스그룹(RG)은 실제 값을 사용. `az group list -o table` 로 확인(후보: `onmu-staging-rg` / `3dt-final-team1`). 아래 `<RG>`, `<ACR_NAME>`, `<ACR_LOGIN_SERVER>` 치환.

### 2.1 ACR Standard 승격 + admin 자격 확보
```bash
# 현재 SKU 확인
az acr show --name <ACR_NAME> --query sku.name -o tsv

# Basic 이면 Standard 로(terraform apply 로 대체 가능). 무료 한도: Standard 1개.
az acr update --name <ACR_NAME> --sku Standard

# CI push + VM pull 용 admin 자격 활성화(가장 단순한 경로)
az acr update --name <ACR_NAME> --admin-enabled true
az acr credential show --name <ACR_NAME>   # username / passwords 출력
```
- `<ACR_LOGIN_SERVER>` = `<ACR_NAME>.azurecr.io`.

### 2.2 GitHub secrets (`vm-staging-apply` environment)
- `ACR_LOGIN_SERVER` = `<ACR_NAME>.azurecr.io`
- `ACR_USERNAME` = admin username(기본 `<ACR_NAME>`)
- `ACR_PASSWORD` = admin password(위 출력의 password 또는 password2)

> managed identity 선호 시(§2.4). 단 이 경우 CI push 도 OIDC 연합 자격 증명으로 전환해야 하므로, 해커톤에서는 admin 자격이 더 빠르다.

### 2.3 VM 에 ACR pull 자격(1회)
```bash
# VM SSH 내부에서
docker login <ACR_LOGIN_SERVER> -u <ACR_USERNAME> -p <ACR_PASSWORD>
# 자격은 ~/.docker/config.json 에 저장되어 이후 deploy-staging-vm.yml 의 pull 이 그대로 동작.
```

### 2.4 (옵션) managed identity 방식 — 비밀 없음
```bash
# VM system-assigned identity 할당
az vm identity assign --name onmu-staging-vm -g <RG> --assign-system
PID=$(az vm show -g <RG> -n onmu-staging-vm --query identity.principalId -o tsv)
ACR_ID=$(az acr show -n <ACR_NAME> --query id -o tsv)
# ACRPull 부여
az role assignment create --role ACRPull --assignee "$PID" --scope "$ACR_ID"
# VM 에 az cli 설치 후 1회: az acr login --name <ACR_NAME> --identity
```

### 2.5 `.env.production` 항목 확인/추가
- `ACR_LOGIN_SERVER=<acr>.azurecr.io`
- `POSTGRES_PASSWORD=...`(컨테이너 PG 비밀번호 — 관리형 비번과 달라도 됨, Phase B restore 시 사용)
- `POSTGRES_USER`/`POSTGRES_DB`(기본 onmu)
- (Phase B 전까지) `SPRING_DATASOURCE_URL` / `DATABASE_URL` 은 관리형 호스트(`onmu-staging-pg.postgres.database.azure.com`) 유지.

**§2 전부 완료 후에만 dev 머지.**

---

## 3. Phase A — ACR + CI 빌드/푸시 파이프라인

dev 머지 시 `deploy-staging-vm.yml` 이 동작:
1. runner 가 api/worker 이미지 빌드 → ACR 푸시(`:dev` + `:sha-xxxxxxx`).
2. SSH 로 VM → `docker compose pull` → `up -d`(빌드 없음).

### 검증(Phase A)
- GH Actions: "Build & push images to ACR" 단계 성공.
- `az acr repository list --name <ACR_NAME> -o table` → `onmu-api-spring`, `onmu-ai-data-worker` 존재.
- VM: `docker compose -f infra/compose/docker-compose.prod-vm.yml --env-file .env.production ps` → api/worker running(빌드 로그 없이 pull 로 기동).
- `https://dev-api.onmu.cloud/healthz` 200.
- VM 메트릭: B2ats_v2 기준 burst credit 방전 없음(빌드가 VM 밖으로 이동했으므로).

---

## 4. Phase B — PostgreSQL 이관 (관리형 → 컨테이너, 단축 다운타임)

> 아직 D2as_v5(8GB) 상태에서 수행(pg_restore + 두 DB 잠시 병행 여유). 컷오버 중 약 10~20분 staging 쓰기 불가.

### 4.1 컨테이너 PG 기동(빈 DB)
```bash
cd ~/ONMU
docker compose -f infra/compose/docker-compose.prod-vm.yml --env-file .env.production up -d postgres
# initdb(001_extensions.sql) 로 postgis/pg_trgm 생성. pgcrypto 는 Flyway V1 이 생성.
docker compose -f infra/compose/docker-compose.prod-vm.yml exec postgres \
  psql -U onmu -d onmu -c "select extname from pg_extension order by 1;"
# → postgis, pg_trgm (pgcrypto 는 아직. restore 또는 Flyway 후 생성)
```

### 4.2 데이터 덤프(관리형 → 파일)
```bash
# .env.production 의 관리형 비밀번호 사용(SPRING_DATASOURCE_PASSWORD 또는 별도 SOURCE_PG_PASSWORD)
SOURCE_PG_PASSWORD="<관리형 onmu 비번>"
docker run --rm --network onmu-prod-vm_default \
  -e PGPASSWORD="$SOURCE_PG_PASSWORD" postgres:16 \
  pg_dump -Fc --no-owner --no-acl --no-tablespaces \
    "host=onmu-staging-pg.postgres.database.azure.com port=5432 dbname=onmu user=onmu sslmode=require" \
  > /tmp/onmu-source.dump
ls -lh /tmp/onmu-source.dump
```
> 네트워크명은 compose `name: onmu-prod-vm` → `onmu-prod-vm_default`. `docker network ls` 로 확인.

### 4.3 컨테이너 PG 로 restore
```bash
docker run --rm --network onmu-prod-vm_default -i \
  -e PGPASSWORD="$POSTGRES_PASSWORD" postgres:16 \
  pg_restore --no-owner --no-acl --no-tablespaces --exit-on-error \
    --dbname "host=postgres port=5432 dbname=onmu user=onmu" \
  < /tmp/onmu-source.dump
# warning 분류는 azure-data-migration-runbook.md §검증 커맨드 사용:
#   rg -n "ERROR|FATAL|could not|permission denied|constraint|extension|role|already exists" restore.err.log
```

### 4.4 검증(데이터 정합성)
```bash
docker compose -f infra/compose/docker-compose.prod-vm.yml exec postgres psql -U onmu -d onmu -Atc \
  "select extname from pg_extension order by 1;"            # postgis, pg_trgm, pgcrypto
docker compose -f infra/compose/docker-compose.prod-vm.yml exec postgres psql -U onmu -d onmu -Atc \
  "select installed_rank, version, success from flyway_schema_history order by installed_rank desc limit 5;"
# 핵심 테이블 row count 를 관리형 vs 컨테이너로 비교(users, groups, records, ...).
```
Go 기준: extension 3개 존재, Flyway 최신 success, 핵심 count 일치. (상세는 `azure-data-migration-runbook.md` Go/No-Go 표.)

### 4.5 접속처 전환(컷오버)
`.env.production`:
```
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/onmu
DATABASE_URL=postgresql://onmu:<POSTGRES_PASSWORD>@postgres:5432/onmu
# sslmode 제거(컨테이너 내부 네트워크)
```
재배포(workflow_dispatch `full-stack` 또는 api-spring 경로 트리거):
```bash
docker compose -f infra/compose/docker-compose.prod-vm.yml --env-file .env.production pull
docker compose -f infra/compose/docker-compose.prod-vm.yml --env-file .env.production up -d
```
- `/readyz` ok:true, `/users/me` 등 주요 엔드포인트 스모크, 공간 쿼리(catalog map) 동작 확인.

### 4.6 관리형 PG 폐기(24시간 롤백 창 후)
```bash
# 24시간 이상 안정 운영 확인 후. 이것으로 Postgres 과금(≈$15~30/월) 중단.
az postgres flexible-server delete --name onmu-staging-pg -g <RG>
```
> 롤백 창 동안 관리형 PG 를 삭제하지 않는다. 문제 시 §6 롤백.

---

## 5. Phase C — VM 무료 SKU 복귀 (B2ats_v2, 3.5GB)

> Phase A 로 VM 빌드 부하가 제거되어 버스트 방전 위험이 사라진 뒤 축소.

### 5.1 라이브 SKU 확인(포털/CLI) — devlog 는 D2as_v5 이지만 out-of-band 변경 가능
```bash
az vm show -g <RG> -n onmu-staging-vm -d --query hardwareProfile.vmSize -o tsv
```

### 5.2 메모리 튜닝 사전 적용(이미 compose 에 반영됨)
- API: `JAVA_OPTS=-Xmx512m -XX:MaxMetaspaceSize=256m`(compose `api.environment`).
- Postgres: `shared_buffers=256MB / work_mem=4MB / effective_cache_size=1GB / max_connections=100`(compose `postgres.command`).
- VM 2GB swap:
```bash
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 5.3 리사이즈
```bash
az vm deallocate -g <RG> -n onmu-staging-vm
az vm resize   -g <RG> -n onmu-staging-vm --size Standard_B2ats_v2
az vm start    -g <RG> -n onmu-staging-vm
```
- 재기동 후 cloudflared 와 docker 스택 자동 복구(`restart: unless-stopped`).
- `docker compose ... ps` → 전체 running, `/readyz` ok:true.
- 30분 부하 관찰: burst credit 잔존, OOM 없음, `free -h` 여유.

---

## 6. 롤백

| Phase | 롤백 |
| --- | --- |
| B(DB) | 관리형 PG 를 24h 유지 중이므로, `.env.production` 접속처를 관리형 호스트로 되돌려 `up -d`(데이터는 덤프 시점). |
| A(레지스트리) | ACR push/VM pull 실패 시 `docker-compose.prod-vm.yml` 의 `image:` 를 임시 `build:` 로 되돌려 기존 VM 빌드 경로로 복귀(VM 일시 과부하 허용). |
| C(VM) | B2ats_v2 에서 OOM 지속 시 `az vm resize --size Standard_D2ats_v5` 로 재확장(유료, 비상시만). |

---

## 7. 백업(관리형 PITR 상실 대체)

일일 `pg_dump -Fc` → Cloudflare R2. 보존: 최근 7 일간 일일 + 주간 4 개(`azure-data-migration-runbook.md:173-181` 기준).

`scripts/prod-vm/pg-backup-to-r2.sh` 스켈레톤(VM 에서 cron `0 18 * * *`):
```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/ONMU"
COMPOSE="docker compose -f $ROOT/infra/compose/docker-compose.prod-vm.yml --env-file $ROOT/.env.production"
STAMP=$(date -u +%Y%m%dT180000Z)
DUMP="/tmp/onmu-${STAMP}.dump"
$COMPOSE exec -T postgres pg_dump -Fc -U onmu -d onmu > "$DUMP"
sha256sum "$DUMP" | tee "${DUMP}.sha256"
rclone copy "$DUMP"        r2:onmu-pg-backups/daily/
rclone copy "${DUMP}.sha256" r2:onmu-pg-backups/daily/
rm -f "$DUMP" "${DUMP}.sha256"
# 주간(일요일)은 weekly/ 로 추가 복사; retention 은 R2 lifecycle 또는 rclone delete-older-than
```
> R2 lifecycle 규칙으로 `daily/` 7일, `weekly/` 28일 보존 권장. restore 검증는 주 1회 scratch DB 로 수행(`azure-staging-data-rehearsal.md`).

---

## 8. 비용 검증(전환 후)

Azure Cost Analysis(staging RG)에서 월별:
- VM: 750h/월 이내(B2ats_v2 무료).
- ACR: Standard 1개(12개월 무료 한도 내).
- PostgreSQL Flexible: **0원**(폐기 완료).
- Cloudflare: R2/Pages/Tunnel $0.
- 예상 청구: $0(12개월 무료 창 내). 12개월 경과 후 VM/ACR 과금 시작 → 해커톤 이후 축소/destroy.
