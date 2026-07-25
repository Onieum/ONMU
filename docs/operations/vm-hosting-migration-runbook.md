# VM 하이브리드 호스팅 마이그레이션 Runbook

> **상태**: 이 문서는 **현재 개발 단계 임시 운영 런타임(VM + Cloudflare, 비용 $0/월)** runbook이다. 정식 운영 target은 검증된 관리형(`infra/terraform/`)이며, 정식 운영 전환 시 관리형 runbook(`azure-*.md`)으로 넘어간다.


**대상**: Azure VM(compute) + Azure PostgreSQL Flexible(DB) + Cloudflare R2(객체/타일) + Cloudflare Pages(brand-web) + Cloudflare Tunnel(수신)
**목적**: 무료/최소 비용 + 해커톤 속도로 운영 환경을 1-2일 안에 가동.
**전제 산출물(이미 코드 반영)**:
- `services/api-spring` R2/S3 저장소 지원(`ObjectStorageProvider.R2`, `R2ObjectStorageClient`, AWS SDK v2).
- `infra/compose/docker-compose.prod-vm.yml`(api/worker/redis, 외부 Postgres, R2).
- `apps/brand-web` 다운로드 URL → `tiles.onmu.cloud`(R2).
- `apps/mobile-flutter` 타일 manifest 기본 URL → `tiles.onmu.cloud/manifest.json`(R2).
- `.env.example` R2/VM 변수 문서화.

> 배경·비교·결정 근거: `tmp/onmu-cloud-hosting-comparison-2026-07-07.md`, 실행 계획: `~/.claude/plans/parallel-meandering-kurzweil.md`.

---

## 아키텍처

```
[Flutter] ─► Cloudflare DNS ─► Tunnel ─► Azure VM (B2ats_v2, koreacentral)
                                          ├─ Spring API        :8080
                                          ├─ FastAPI worker    :8000(내부)
                                          └─ Redis             :6379
                                   │
                                   └─► Azure PostgreSQL Flexible (B1ms + PostGIS) [관리형, 외부]
[brand-web] ─► Cloudflare Pages (onmu.cloud)
[타일/미디어] ─► Cloudflare R2 (tiles.onmu.cloud)
```

예상 비용: **$0/월**(VM+DB 12개월 무료 한도 + Cloudflare 무료).

---

## WS0 — 사전 준비 (사용자 실습 가이드)

> 이전 예산 게이트/`3dt-final-team1` RG는 사라졌습니다. 프로젝트에 맞춰 새 RG `onmu-staging-rg` 를 만듭니다.

### 0-1. Docker Desktop 재부팅 (로컬 검증용)
- Docker 데몬이 응답하지 않으면 PC 재부팅 후 Docker Desktop 실행 → 상단 톱니바퀴가 회전 중이고 `docker ps` 가 응답하면 준비 완료.
- 확인: `docker version` 에 Server 버전이 출력되면 OK.

### 0-2. Azure 리소스 그룹 신규 생성
```bash
az login
az group create --name onmu-staging-rg --location koreacentral
az group show -g onmu-staging-rg --query '{name,location}' -o tsv   # 확인
```
- 이 RG 안에 Postgres(WS1) + VM(WS2)을 만듭니다. 12개월 무료 한도 내에서 $0 목표.

### 0-3. Kakao OAuth 키 발급 (REST API 키 + Client Secret + Redirect URI)
1. https://developers.kakao.com → 로그인 → **내 애플리케이션** → 앱 선택(또는 신규 생성).
2. **앱 키** 항목에서 **REST API 키** 복사 → 이것이 OAuth `client_id`. (JavaScript 키는 웹 클라이언트용, Admin 키는 앱 관리용이라 인증에 안 씀.)
3. **보안** 메뉴 → **Client Secret** → 활성화 후 발급 → 복사 → `KAKAO_CLIENT_SECRET`.
4. **카카오 로그인** → 활성화 ON → **Redirect URI** 등록:
   - 웹: `https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback`
   - (모바일은 동적 스킴) `io.onieum.onmu://oauth/kakao/callback` — 앱 설정의 플랫폼>Android/iOS redirect 에도 추가.
5. `.env.production` (VM) / Kakao 콘솔 값:
   - `KAKAO_REST_API_KEY=<REST API 키>`, `KAKAO_CLIENT_SECRET=<secret>`,
   - `KAKAO_OAUTH_REDIRECT_URI=https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback`,
   - `KAKAO_OAUTH_TOKEN_URL=https://kauth.kakao.com/oauth/token`.

### 0-4. Cloudflare API 토큰 발급 (R2 + Pages + DNS)
1. https://dash.cloudflare.com → 우상단 프로필 → **My Profile** → **API Tokens** → **Create Token**.
2. **Create Custom Token** → 권한:
   - Account · **Workers R2 Storage** · **Edit**
   - Account · **Cloudflare Pages** · **Edit**
   - Account · **Account Settings** · **Read**
   - Zone · **DNS** · **Edit** (`onmu.cloud` zone) — 터널/도메인 자동 route 용
3. Account Resources = 본인 계정, Zone Resources = `onmu.cloud`. Create → 토큰 복사(한 번만 표시).
4. 설치 + 인증:
   ```bash
   npm i -g wrangler
   export CLOUDFLARE_API_TOKEN='<위 토큰>'   # 또는 wrangler login (브라우저)
   wrangler whoami                             # 계정 연결 확인
   ```
   - 간편하게는 `wrangler login`(브라우저 OAuth) 로 R2/Pages 인증 처리 가능. DNS/터널 자동화가 필요하면 위 API 토큰 방식 사용.

### 0-5. 도구 설치 확인
```bash
az --version | head -1; cloudflared --version; wrangler --version; docker version --format 'server {{.Server.Version}}'
```

### 0-6. 팀원 초대
- Azure: RG `onmu-staging-rg` → Access control (IAM) → Add role assignment → **Contributor** → 팀원 3명.
- Cloudflare: 대시보드 → 계정 → Members → Invite(무료, 멤버 무제한).

---

## WS1 — 관리형 PostgreSQL (Azure Flexible, PostGIS)

```bash
# 1) 서버 생성 (koreacentral, B1ms 12개월 무료 한도)
az group create --name onmu-staging-rg --location koreacentral   # WS0-2 에서 이미 만들었으면 생략
az postgres flexible-server create \
  --name onmu-staging-pg --resource-group onmu-staging-rg \
  --location koreacentral --sku-name Standard_B1ms --tier Burstable \
  --version 16 --storage-size 32 --admin-user onmu --admin-password '<강력한비밀번호>' \
  --yes

# 2) DB 생성
az postgres flexible-server db create --server-name onmu-staging-pg \
  --resource-group onmu-staging-rg --database-name onmu

# 3) VM 공용 IP(WS2 생성 후)만 허용. 우선 임시 전체 허용 후 좁힘:
az postgres flexible-server firewall-rule create --server-name onmu-staging-pg \
  --resource-group onmu-staging-rg --name allow-vm --start-ip-address <VM_PUBLIC_IP> --end-ip-address <VM_PUBLIC_IP>

# 4) PostGIS / pg_trgm 확장 (Flyway initdb 와 동일)
PGPASSWORD='<강력한비밀번호>' psql "host=onmu-staging-pg.postgres.database.azure.com \
  port=5432 dbname=onmu user=onmu sslmode=require" \
  -c "CREATE EXTENSION IF NOT EXISTS postgis;" \
  -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
```

**출력 보관**:
- `SPRING_DATASOURCE_URL=jdbc:postgresql://onmu-staging-pg.postgres.database.azure.com:5432/onmu?sslmode=require`
- `SPRING_DATASOURCE_USERNAME=onmu` / `SPRING_DATASOURCE_PASSWORD=<비밀번호>`
- `DATABASE_URL=postgresql://onmu:<비밀번호>@onmu-staging-pg.postgres.database.azure.com:5432/onmu?sslmode=require`(워커용)

> Flyway clean full migration는 API 기동 시 자동 수행. DB는 비어있어야 함(DECISIONS.md #11).
> Terraform `postgres` 모듈과의 reconcile(상태 import)은 데모 이후로 미룸.

---

## WS2 — VM compute (단일 Azure VM)

```bash
# 1) VM 생성 (B2ats_v2 2vCPU/3.5GB, 12개월 무료 한도. 할당량 문제 시 B2s 로 fallback)
az vm create \
  --name onmu-staging-vm --resource-group onmu-staging-rg --location koreacentral \
  --image Canonical:ubuntu-24_04-lts:server:latest --size Standard_B2ats_v2 \
  --admin-username onmu --ssh-key-values ~/.ssh/id_rsa.pub \
  --public-ip-sku Standard --os-disk-size-gb 30
VM_IP=$(az vm show -d -g onmu-staging-rg -n onmu-staging-vm --query publicIps -o tsv)

# 2) Postgres 방화벽에 VM IP 허용 (WS1 의 <VM_PUBLIC_IP> 자리에 $VM_IP)
az postgres flexible-server firewall-rule create --server-name onmu-staging-pg \
  --resource-group onmu-staging-rg --name allow-vm --start-ip-address $VM_IP --end-ip-address $VM_IP

# 3) VM 진입 후 부트스트랩
ssh onmu@$VM_IP
# VM 내부에서:
git clone <ONMU_REPO> ~/onmu && cd ~/onmu
bash scripts/prod-vm/bootstrap-vm.sh     # Docker + compose plugin + cloudflared 설치
```

**`.env.production` 작성**(VM의 repo 루트, 커밋 금지):
```dotenv
# DB (WS1)
SPRING_DATASOURCE_URL=jdbc:postgresql://onmu-staging-pg.postgres.database.azure.com:5432/onmu?sslmode=require
SPRING_DATASOURCE_USERNAME=onmu
SPRING_DATASOURCE_PASSWORD=<비밀번호>
DATABASE_URL=postgresql://onmu:<비밀번호>@onmu-staging-pg.postgres.database.azure.com:5432/onmu?sslmode=require
# 객체 스토리지 R2 (WS3)
OBJECT_STORAGE_PROVIDER=r2
OBJECT_STORAGE_ENDPOINT=https://<accountid>.r2.cloudflarestorage.com
OBJECT_STORAGE_BUCKET=onmu-media
OBJECT_STORAGE_ACCESS_KEY_ID=<R2_ACCESS_KEY_ID>
OBJECT_STORAGE_SECRET_ACCESS_KEY=<R2_SECRET_ACCESS_KEY>
OBJECT_STORAGE_REGION=auto
# 인증/OAuth (기존 .env 의 실제 값 복사)
ONMU_ACCESS_TOKEN_SECRET=<generate-strong-secret>
ONMU_ALLOWED_ORIGINS=https://dev-api.onmu.cloud,https://onmu.cloud
KAKAO_CLIENT_SECRET=... ; KAKAO_OAUTH_* / NAVER_OAUTH_* / 외부 API 키 ...
```

**기동**:
```bash
docker compose -f infra/compose/docker-compose.prod-vm.yml --env-file .env.production up -d --build
docker compose -f infra/compose/docker-compose.prod-vm.yml logs -f api   # Flyway migration / 기동 확인
```

**Tunnel(수신)**: VM에서 기존 터널 패턴 재사용.
```bash
cloudflared tunnel login
cloudflared tunnel create onmu-dev-api
# infra/cloudflare/cloudflared-local.yml 을 VM 용으로 복사/수정(localhost:8080 유지)
cloudflared tunnel route dns onmu-dev-api dev-api.onmu.cloud
cloudflared tunnel run --config infra/cloudflare/cloudflared-local.yml onmu-dev-api
```

---

## WS3 — Cloudflare R2 (객체/타일/다운로드)

```bash
# 1) R2 버킷 2개
wrangler r2 bucket create onmu-tiles   # public: 타일/스타일/manifest + 다운로드
wrangler r2 bucket create onmu-media   # private: 사용자 업로드

# 2) R2 API 토큰(Access Key ID / Secret) 대시보드 → R2 → Manage R2 API Tokens → Create
#    → Object Read & Write, 버킷 지정 → 키 저장 → .env.production 의 OBJECT_STORAGE_ACCESS_KEY_ID/SECRET

# 3) 업로드 (기존 Blob stonmustagingkrc001/tiles/ 에서 다운로드 후 R2 로)
wrangler r2 object put onmu-tiles/manifest.json         --file tiles/manifest.json
wrangler r2 object put onmu-tiles/styles/onmu-light.json --file styles/onmu-light.json
wrangler r2 object put onmu-tiles/pmtiles/korea-dev.pmtiles --file pmtiles/korea-dev.pmtiles
# 모바일 다운로드 아티팩트 (brand-config.js/index.html 이 가리키는 경로와 일치)
wrangler r2 object put onmu-tiles/downloads/mobile/latest/onmu-android-arm64.apk --file onmu-android-arm64.apk
wrangler r2 object put onmu-tiles/downloads/mobile/latest/onmu-ios-unsigned-xcarchive.zip --file onmu-ios-unsigned-xcarchive.zip
wrangler r2 object put onmu-tiles/downloads/mobile/latest/SHA256SUMS.txt --file SHA256SUMS.txt

# 4) 커스텀 도메인 + CORS: 대시보드 R2 → onmu-tiles → Settings → Custom Domain "tiles.onmu.cloud"
#    MapLibre origin 허용 CORS 규칙 추가(onmu.cloud, https://dev-api.onmu.cloud, capacitor/앱 origin).
```

> `tiles.onmu.cloud` 는 brand-web 다운로드 URL·Flutter manifest URL 과 동일. 코드는 이미 이 도메인을 가리킴.

---

## WS4 — Cloudflare Pages (brand-web)

- 대시보드 Pages → Create project → `apps/brand-web` 디렉토리 업로드(빌드 명령 없음, 출력 `.`).
- Custom domain: `onmu.cloud`, `www.onmu.cloud`.
- brand-web 코드는 이미 R2 다운로드 URL(`tiles.onmu.cloud/downloads/...`)을 가리키도록 수정됨.

---

## WS5 — realtime-gateway (결정)
- 현재 stub. 데모에 라이브 방 동기화 불필수 → **defer**. compose의 `realtime` 서비스 주석 유지.
- 필요 시: 런타임(Node/Python) 확정 → `services/realtime-gateway/Dockerfile` 작성 → compose 주석 해제.

---

## WS6 — Cutover & 검증
1. **DNS 라우팅 확인**: `dev-api.onmu.cloud`(→Tunnel→VM API), `tiles.onmu.cloud`(→R2), `onmu.cloud`(→Pages).
2. **OAuth redirect URI**: Kakao/Naver 콘솔의 콜백이 `https://dev-api.onmu.cloud/api/v1/auth/oauth/{kakao,naver}/callback` 과 일치.
3. **Smoke**:
   ```bash
   curl -fsS https://dev-api.onmu.cloud/healthz        # API live
   curl -fsS https://dev-api.onmu.cloud/actuator/health # DB/Redis/R2 포함 readiness
   curl -I  https://tiles.onmu.cloud/manifest.json      # 200 + CORS 헤더
   ```
   VM 내: `PGPASSWORD=... psql "$DATABASE_URL" -c "SELECT postgis_full_version();"`
4. **brand-web**: `https://onmu.cloud` 로딩 + 다운로드 버튼이 R2 URL 에서 APK/xcarchive 정상 다운로드.
5. **Flutter**: `--dart-define=ONMU_TILE_MANIFEST_URL=https://tiles.onmu.cloud/manifest.json` 빌드로 지도 타일 렌더링 + 로그인 정상.
6. **비용**: Azure Cost Management → VM+Postgres 12개월 무료 한도 내, Cloudflare 청구 $0.

---

## 롤백
- VM 장애 시 기존 로컬/Mac 백업 구동으로 복귀.
- DB는 관리형(자체 백업). 일일 `pg_dump` → R2 스크립트 권장.
- R2/Pages는 독립적이라 compute 교체에 영향 없음.
- OAuth 도메인은 `dev-api.onmu.cloud` 유지 → 콘솔 재설정 최소화.
