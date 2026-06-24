# 브랜드 웹 Search Console 운영 가이드

이 문서는 `onmu.cloud` 브랜드 웹의 Google Search Console 등록과 기본 SEO 운영 절차를 정리합니다.
정적 브랜드 웹 범위만 다루며, Flutter 앱 내부 화면이나 Spring API indexing 이슈는 포함하지 않습니다.

## 목적

- Google이 `onmu.cloud`를 더 빨리 발견하고 인덱싱하도록 기본 절차를 표준화한다.
- Search Console 검증 값을 repo에 직접 커밋하지 않고도 운영자가 재현 가능하게 만든다.
- sitemap 제출, URL Inspection, canonical 운영의 최소 기준을 맞춘다.

## 현재 기본선

브랜드 웹은 이미 아래 기본 요소를 포함합니다.

- `robots.txt`
- `sitemap.xml`
- `canonical`
- `meta name="robots" content="index,follow"`
- Open Graph / Twitter card
- `Organization`, `WebSite`, `SoftwareApplication`, `FAQPage` JSON-LD

주의:

- 위 요소가 있다고 해서 Google indexing이 보장되지는 않습니다.
- 신생 도메인은 외부 링크와 Search Console 신호가 약하면 `site:onmu.cloud` 검색에 한동안 바로 안 나올 수 있습니다.

## 권장 검증 방식

우선순위는 아래 순서를 권장합니다.

1. Domain property + Cloudflare DNS TXT 검증
2. URL prefix property + HTML file 검증
3. URL prefix property + meta tag 검증

이유:

- Domain property는 `onmu.cloud`, `www.onmu.cloud`, 향후 서브도메인까지 한 번에 묶어 관리하기 쉽습니다.
- 정적 사이트는 HTML file 검증도 안정적입니다.
- meta tag 검증은 가장 단순하지만, 루트 페이지 head 유지에 더 민감합니다.

## 운영 절차

### 1. property 등록

- Google Search Console에서 `onmu.cloud`를 등록합니다.
- 가능하면 Domain property를 먼저 시도합니다.

### 2. 소유권 검증

#### A. DNS TXT 검증 권장

- Search Console이 제시한 TXT 값을 Cloudflare DNS에 추가합니다.
- 실제 TXT 값은 repo, PR, 문서에 커밋하지 않습니다.
- DNS 전파 후 Search Console에서 verify를 실행합니다.

#### B. URL prefix + HTML file 검증

Google이 `google1234567890abcdef.html` 같은 파일명과 내용을 주면 배포 직전에 env var로 주입합니다.

```bash
export ONMU_BRAND_GOOGLE_VERIFICATION_FILE_NAME="google1234567890abcdef.html"
export ONMU_BRAND_GOOGLE_VERIFICATION_FILE_CONTENT="google-site-verification: google1234567890abcdef.html"
scripts/macos/deploy-brand-web-cloudflared.sh
```

배포 후 아래 URL이 정확히 열리는지 확인합니다.

```text
https://onmu.cloud/google1234567890abcdef.html
```

#### C. URL prefix + meta tag 검증

Google이 meta verification token을 주면 배포 직전에 env var로 주입합니다.

```bash
export ONMU_BRAND_GOOGLE_SITE_VERIFICATION="verification-token-from-google"
scripts/macos/deploy-brand-web-cloudflared.sh
```

배포 후 홈 HTML source에 아래 메타가 들어갔는지 확인합니다.

```html
<meta name="google-site-verification" content="verification-token-from-google">
```

## sitemap 제출

검증이 끝나면 Search Console에서 아래 sitemap을 제출합니다.

```text
https://onmu.cloud/sitemap.xml
```

현재 포함 URL:

- `/`
- `/download/`
- `/download/ios/`
- `/download/android/`
- `/privacy/`
- `/terms/`

## URL Inspection 권장 대상

초기에는 아래 URL만 먼저 요청해도 충분합니다.

- `https://onmu.cloud/`
- `https://onmu.cloud/download/`
- `https://onmu.cloud/privacy/`
- `https://onmu.cloud/terms/`

## canonical / 도메인 운영 메모

- 브랜드 웹 canonical은 현재 apex인 `https://onmu.cloud/` 기준입니다.
- `www.onmu.cloud`도 함께 열리면 duplicate candidate가 될 수 있으므로, 가능하면 Cloudflare Redirect Rule에서 `www -> onmu.cloud` 301을 설정합니다.
- Search Console에서 Domain property를 쓰면 apex와 www를 함께 관찰하기 쉽습니다.

## 금지 사항

- Google verification token, HTML verification 파일 내용, DNS TXT 값을 repo에 직접 커밋하지 않습니다.
- PR 본문, 리뷰 댓글, 작업 로그에 실제 verification 값을 남기지 않습니다.
- Search Console 검증과 무관한 내부 링크, GitHub/Notion/Jira 링크를 public 브랜드 웹에 추가하지 않습니다.

## 점검 체크리스트

- `https://onmu.cloud/robots.txt` 응답 200
- `https://onmu.cloud/sitemap.xml` 응답 200
- 홈 HTML에 `canonical=https://onmu.cloud/`
- 홈 HTML에 `meta name="robots" content="index,follow"`
- Search Console property verified
- sitemap submitted
- 주요 4개 URL inspection requested
- 가능하면 `www -> apex` redirect rule 설정
