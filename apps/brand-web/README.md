# ONMU 브랜드 웹

브랜드 웹 앱은 공개 제품 소개만 담당합니다.

포함해야 할 내용:

- 제품 개념
- 팀/프로젝트 소개
- 앱 screenshot 또는 prototype 영상
- 준비된 경우 store/download 링크
- 개인정보 처리방침/contact 링크

로그인, 약속 생성, 장소 선택, 기록 생성 같은 핵심 제품 흐름은 포함하지 않습니다. 해당 흐름은 Flutter 앱에 둡니다.

## 현재 구현

`onmu.cloud` 루트 도메인에서 바로 제공할 수 있는 의존성 없는 정적 페이지입니다.

- `index.html`: 제품/프로젝트 소개와 SEO 메타데이터
- `privacy/index.html`: 개인정보 처리방침
- `terms/index.html`: 이용약관
- `download/index.html`: iOS/Android 다운로드 안내와 QR
- `download/ios/index.html`, `download/android/index.html`: 스토어 링크 연결 전 stable QR 목적지
- `404.html`: 정적 호스팅용 오류 페이지
- `styles.css`: ONMU 디자인 시스템을 반영한 반응형 스타일
- `brand-config.js`: 공개 사이트 기본 runtime 설정. Sentry DSN은 빈 값으로 둡니다.
- `brand-observability.js`: Sentry Browser SDK를 조건부로 로드하는 오류 관측성 부트스트랩
- `robots.txt`, `sitemap.xml`: 검색 엔진 수집 기준
- `site.webmanifest`: 브라우저/PWA 기본 메타데이터
- `assets/`: 모바일 앱의 브랜드 자산을 브랜드 웹용 크기로 복사한 이미지, WebP 변형, QR 자산

## 현재 공개 섹션

- 문제/서사: 약속 전, 약속 중, 약속 후가 여러 앱에 흩어지는 문제를 설명합니다.
- 제품 흐름: 약속 만들기, 장소 후보, 채팅과 결정, 기록 남기기 흐름을 소개합니다.
- 앱 화면 데모: 실제 사용자 데이터 없이 CSS 기반 phone mock과 화면 갤러리로 제품 구조를 보여줍니다.
- 기능: 온모임, 채팅, 장소 후보, 정산, 기록, 신뢰 기능을 현재/준비 상태와 함께 설명합니다.
- 신뢰/로드맵: 공개하지 않는 정보 경계, 정책 초안, 스토어 링크 준비 상태를 명확히 둡니다.
- 다운로드: iOS/Android stable URL과 QR 코드를 제공합니다.

## 공개 링크 원칙

GitHub, Notion, Jira, PR, CI 같은 내부 협업 링크는 브랜드 웹에 공개하지 않습니다.
앱 다운로드는 `/download/ios/`, `/download/android/` stable URL을 QR 목적지로 두고,
스토어 링크가 확정되면 해당 페이지에서 이동시키는 방식으로 관리합니다.
Naver Search Advisor, Bing Webmaster 같은 사이트 인증 메타는 실제 검증 값이 확정된 뒤에만 추가합니다.

## 로컬 확인

```bash
cd apps/brand-web
python3 -m http.server 4173
```

브라우저에서 `http://127.0.0.1:4173`을 연 뒤 첫 화면, 모바일 폭, SEO 메타 태그를 확인합니다.

## Sentry 관측성

브랜드 웹은 `brand-config.js`의 `sentryDsn`이 비어 있으면 Sentry SDK를 로드하지 않습니다.
배포 시에만 `ONMU_BRAND_SENTRY_DSN` 또는 `SENTRY_DSN`으로 값을 주입합니다. 실제 DSN, token,
OAuth code/state, request/response body, 사용자 이름, 채팅/사진/정산 원문은 repo, PR, 로그에 남기지 않습니다.

Sentry 이벤트는 Flutter 관측성 정책과 같은 방향으로 제한합니다.

- `sendDefaultPii=false`로 초기화합니다.
- request query/body/cookie와 Authorization 계열 header를 제거합니다.
- console breadcrumb는 전송하지 않습니다.
- tag는 `feature`, `page`, `environment`, `kind`, `statusCode`, `method`, `endpoint_template`, `retryable`처럼 안전한 메타데이터만 남깁니다.
- 기본 성능 trace sample rate는 `0`입니다.

```bash
export ONMU_BRAND_SENTRY_DSN="<Key Vault sentry-dsn에서 읽은 값>"
export ONMU_BRAND_SENTRY_ENVIRONMENT="production"
export ONMU_BRAND_SENTRY_RELEASE="$(git rev-parse --short HEAD)"
```

## Cloudflare Tunnel 배포

`onmu.cloud` 임시 공개는 Mac에서 정적 서버를 띄우고 Cloudflare named tunnel로 연결합니다.
Cloudflare 인증 파일과 tunnel route는 운영자 계정에서 준비해야 하며, credential 파일과 token 값은 커밋하지 않습니다.

사전 준비:

```bash
cloudflared tunnel login
cloudflared tunnel create onmu-brand-web
cloudflared tunnel route dns onmu-brand-web onmu.cloud
cloudflared tunnel route dns onmu-brand-web www.onmu.cloud
```

배포 실행:

```bash
scripts/macos/deploy-brand-web-cloudflared.sh
```

스크립트는 `apps/brand-web`을 `$HOME/.codex/local/ONMU/brand-web/deploy/current`로 복사한 뒤,
환경변수 기반 `brand-config.js`를 생성하고 `http://127.0.0.1:4173` 정적 서버와
`infra/cloudflare/cloudflared-brand-web.yml` 기반 tunnel을 시작합니다.

주요 옵션:

- `ONMU_BRAND_PORT`: 로컬 정적 서버 포트. 기본값은 `4173`입니다.
- `ONMU_BRAND_TUNNEL_NAME`: Cloudflare named tunnel. 기본값은 `onmu-brand-web`입니다.
- `ONMU_BRAND_ROUTE_DNS=true`: 실행 중 DNS route를 함께 갱신합니다.
- `ONMU_BRAND_QUICK_TUNNEL=true`: 루트 도메인이 아닌 임시 trycloudflare URL로 smoke할 때만 사용합니다.
