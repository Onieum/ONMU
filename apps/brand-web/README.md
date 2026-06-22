# ONMU 브랜드 웹

브랜드 웹 앱은 공개 제품 소개만 담당합니다.

포함해야 할 내용:

- 제품 개념
- 팀/프로젝트 소개
- 앱 screenshot 또는 prototype 영상
- 준비된 경우 store/download 링크
- 개인정보 처리방침/contact 링크

로그인, 약속 생성, 장소 추천, 기록 생성 같은 핵심 제품 흐름은 포함하지 않습니다. 해당 흐름은 Flutter 앱에 둡니다.

## 현재 구현

`onmu.cloud` 루트 도메인에서 바로 제공할 수 있는 의존성 없는 정적 페이지입니다.

- `index.html`: 제품/프로젝트 소개와 SEO 메타데이터
- `styles.css`: ONMU 디자인 시스템을 반영한 반응형 스타일
- `robots.txt`, `sitemap.xml`: 검색 엔진 수집 기준
- `site.webmanifest`: 브라우저/PWA 기본 메타데이터
- `assets/`: 모바일 앱의 브랜드 자산을 브랜드 웹용 크기로 복사한 이미지

## 로컬 확인

```bash
cd apps/brand-web
python3 -m http.server 4173
```

브라우저에서 `http://127.0.0.1:4173`을 연 뒤 첫 화면, 모바일 폭, SEO 메타 태그를 확인합니다.
