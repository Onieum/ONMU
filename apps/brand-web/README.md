# ONMU 브랜드 웹

브랜드 웹 앱은 공개 제품 소개만 담당합니다.

포함해야 할 내용:

- 제품 개념
- 팀/제품 소개
- 앱 screenshot 또는 prototype 영상
- 준비된 경우 store/download 링크
- 개인정보 처리방침/contact 링크

로그인, 약속 생성, 장소 선택, 기록 생성 같은 핵심 제품 흐름은 포함하지 않습니다. 해당 흐름은 Flutter 앱에 둡니다.

## 현재 구현

`onmu.cloud` 루트 도메인에서 바로 제공할 수 있는 의존성 없는 정적 브랜드 페이지입니다.

- `index.html`: 제품 소개, 팀 서사, FAQ, SEO 메타데이터
- `privacy/index.html`: 개인정보 처리방침
- `terms/index.html`: 이용약관
- `download/index.html`: iOS/Android 다운로드 안내와 QR
- `download/ios/index.html`, `download/android/index.html`: 스토어 링크 연결 전 stable QR 목적지
- `404.html`: 정적 호스팅용 오류 페이지
- `styles.css`: ONMU 디자인 시스템을 반영한 반응형 스타일
- `brand-site.js`: 모바일 내비게이션 토글과 접근성을 해치지 않는 섹션 reveal 인터랙션
- `brand-config.js`: 공개 사이트 기본 runtime 설정. Sentry DSN과 스토어 URL은 빈 값으로 둡니다.
- `brand-observability.js`: Sentry Browser SDK를 조건부로 로드하는 오류 관측성 부트스트랩
- `robots.txt`, `sitemap.xml`: 검색 엔진 수집 기준
- `site.webmanifest`: 브라우저/PWA 기본 메타데이터
- `assets/`: 모바일 앱의 브랜드 자산, 실제 Flutter 캡처 PNG, 생성 일러스트, WebP 변형, QR 자산

## 현재 공개 섹션

- 문제와 관점: 약속 하나를 위해 여러 앱을 오가는 문제와 ONieum의 관점을 설명합니다.
- 약속 하루 흐름: 만나기, 장소 정하기, 대화와 결정, 남기기 흐름을 소개합니다.
- 앱 미리 보기: 실제 사용자 데이터 없이 만든 Flutter 캡처 PNG로 제품 경험을 보여줍니다.
- 기능: 온모임, 채팅, 장소 후보, 정산, 기록, 신뢰 기능을 사용자 혜택 중심으로 설명합니다.
- 팀: ONMU를 만드는 ONieum의 비전과 역할을 소개합니다.
- 신뢰/FAQ/로드맵: 사진, 위치, 정산 데이터의 사용자 관점 경계와 출시 전 질문, 앞으로의 방향을 안내합니다.
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

## 화면 캡처와 일러스트 자산

- `assets/images/screenshots/`: 실제 ONMU Flutter 공용 위젯을 데모 데이터로 렌더링한 브라우저 캡처입니다.
- `assets/images/illustrations/`: 생성 이미지 원본을 repo용으로 복사하고 섹션별로 자른 브랜드 일러스트입니다.
- `assets/fonts/`: 브랜드 웹에서 제한적으로 쓰는 픽셀 wordmark용 폰트입니다. 본문에는 적용하지 않습니다.
- `onmu-team-pixel.webp`: 팀 섹션에서 우선 로드하는 경량 팀 일러스트입니다.
- `onmu-social-preview.svg`: 공유 카드 이미지를 재생성하기 위한 원본입니다.
- `onmu-social-preview.png`: Open Graph와 Twitter card에서 사용하는 1200x630 공유 이미지입니다.
- `onmu-social-preview.webp`: 같은 공유 이미지의 경량 WebP 변형입니다. 외부 공유 메타는 호환성을 위해 PNG를 우선합니다.
- `onmu-illustration-suite.png`, `onmu-illustration-support-suite.png`: 원본 보관용 생성 이미지입니다.
- `onmu-illustration-*.png`: 원본 또는 보관용 일러스트입니다.
- `onmu-illustration-*.webp`: 브랜드 웹에서 우선 로드하는 경량 배포용 일러스트입니다.
- 캡처와 일러스트에는 실제 사용자 이름, 실제 채팅, 실제 사진, 실제 위치, 실제 정산 데이터를 넣지 않습니다.
- 캡처 갱신에는 임시 Flutter web capture target을 사용할 수 있지만, 최종 커밋에는 생성된 PNG와 브랜드 웹 소스만 남깁니다.

```bash
export ONMU_BRAND_SENTRY_DSN="<Key Vault sentry-dsn에서 읽은 값>"
export ONMU_BRAND_SENTRY_ENVIRONMENT="production"
export ONMU_BRAND_SENTRY_RELEASE="$(git rev-parse --short HEAD)"
export ONMU_BRAND_IOS_STORE_URL=""
export ONMU_BRAND_ANDROID_STORE_URL=""
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
- `ONMU_BRAND_IOS_STORE_URL`, `ONMU_BRAND_ANDROID_STORE_URL`: 스토어 공개 후 다운로드 CTA를 실제 스토어로 연결할 때만 설정합니다.
