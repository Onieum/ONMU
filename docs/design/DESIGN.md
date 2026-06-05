# ONMU Design System

이 문서는 ONMU 앱 화면을 AI로 생성하거나 팀원들과 디자인을 맞출 때 사용하는 전체 디자인 시스템이다.
ONMU는 **오늘의 코디와 일상을 픽셀 캐릭터로 기록하는 감성 다이어리 앱**이다. 화면은 흰색 배경을 기본으로 하며, 귀여운 픽셀 캐릭터, 손그림 스티커, 마스킹 테이프, 종이 카드, 파스텔 포인트를 사용해 따뜻하고 아기자기한 분위기를 만든다.

AI로 화면을 만들 때는 이 문서를 기준으로 모든 화면이 같은 앱처럼 보이도록 생성한다.

---

## 1. Brand Identity

### App Name

ONMU

### Brand Concept

오늘 입은 코디, 약속, 장소, 기분, 날씨, 일상 기록을 귀여운 픽셀 캐릭터와 함께 남기는 모바일 다이어리 앱.

### Core Keywords

- White Base
- Pixel Character
- Cute Diary
- OOTD
- Daily Record
- Scrapbook
- Soft Pastel
- Sticker Decoration
- Cozy Fashion Archive

### Design Sentence

> 흰 종이 위에 픽셀 캐릭터, 사진, 스티커, 손글씨 메모를 붙여 오늘의 코디와 하루를 기록하는 귀여운 모바일 다이어리.

---

## 2. Overall Visual Direction

### Must Keep

- 기본 배경은 흰색이다.
- 전체 톤은 귀엽고 따뜻해야 한다.
- 픽셀 캐릭터가 브랜드의 핵심 시각 요소로 반복 등장해야 한다.
- 카드와 입력창은 종이 조각, 기록지, 다이어리 페이지처럼 부드럽게 보여야 한다.
- 하트, 별, 반짝이, 구름, 리본, 옷걸이, 카메라, 커피컵, 마스킹 테이프 같은 장식 요소를 사용한다.
- 버튼과 선택 상태는 코랄 또는 핑크 계열 포인트를 사용한다.
- 화면은 정보가 많아도 복잡하거나 차갑게 보이면 안 된다.

### Avoid

- 어두운 배경 중심 디자인
- 차가운 SaaS 대시보드 느낌
- 네온 컬러
- 강한 블랙 라인 위주의 투박한 UI
- 과한 그라데이션 배경
- 지나치게 현실적인 사진 앱 스타일
- 픽셀 캐릭터 없이 일반 캐릭터 일러스트만 사용하는 방향
- 장식이 너무 많아 정보가 안 보이는 화면

---

## 3. Color System

ONMU는 흰색 배경을 중심으로 코랄 핑크, 핑크, 브라운, 웜 파스텔을 사용한다.
현재 Flutter 코드의 `AppColors.primaryPurple` 이름은 남아 있지만 실제 색상은 코랄 계열이다. 새 화면에서는 토큰 이름보다 실제 역할을 기준으로 이해한다.

### Background

| Token | Color | Usage |
| --- | --- | --- |
| `bg.default` | `#FFFFFF` | 전체 기본 배경 |
| `bg.warm` | `#FFFDF9` | 따뜻한 화면 배경, 섹션 배경 |
| `bg.paper` | `#FFFAF3` | 종이 카드, 기록지 |
| `bg.grid` | `#FFF7EF` | 다이어리 격자 배경 |
| `bg.purpleSoft` | `#F6F1FF` | 온보딩, 브랜드 강조 영역 |

### Primary

| Token | Color | Usage |
| --- | --- | --- |
| `primary.purple` | `#E86D75` | 코드상 이름은 purple이지만 실제 사용은 코랄 메인 브랜드 포인트 |
| `primary.purpleDark` | `#C94C56` | 강한 CTA, 활성 상태 |
| `primary.purpleSoft` | `#FAD8DC` | 코랄 선택 배경 |
| `primary.pink` | `#FF8FA3` | OOTD, 기록, 선택 상태 |
| `primary.pinkSoft` | `#FFE3E8` | 핑크 선택 배경, 탭 활성 배경 |

### Text

| Token | Color | Usage |
| --- | --- | --- |
| `text.main` | `#3A2A23` | 제목, 본문 |
| `text.sub` | `#7A6258` | 보조 설명 |
| `text.muted` | `#A9948A` | placeholder, 비활성 |
| `text.inverse` | `#FFFFFF` | 코랄/핑크 버튼 위 텍스트 |

### Line / Border

| Token | Color | Usage |
| --- | --- | --- |
| `line.soft` | `#EAD8CC` | 카드, 입력 필드 |
| `line.brown` | `#C9A995` | 종이 느낌 테두리 |
| `line.pink` | `#FF9CAD` | 선택 카드, 강조 |
| `line.purple` | `#BDA4FF` | 브랜드 선택 상태 |

### Accent

| Token | Color | Usage |
| --- | --- | --- |
| `accent.brown` | `#B98562` | 코디 색상, 통계 |
| `accent.orange` | `#FFB35C` | 별점, 날씨, 따뜻한 강조 |
| `accent.green` | `#A8C58B` | 북마크, 평온한 상태 |
| `accent.blue` | `#8CC6E8` | 날씨, 캘린더 포인트 |
| `accent.red` | `#FF6B7A` | 하트, 체크, 중요 표시 |

---

## 4. Typography

픽셀 타이틀과 부드러운 한글 본문 폰트를 함께 사용한다. Flutter 앱의 `TextStyle.fontSize` 값은 CSS px나 인쇄용 pt가 아니라 device-independent logical pixel이다. 디자인 문서의 size도 Flutter 구현값과 1:1로 맞추기 위해 `logical px`로 기록한다.

### Font Families

| Role | Font Family | Usage |
| --- | --- | --- |
| Pixel Title | `Mona12`, `Mona10x12` | 월 이름, 기록 제목, OOTD 타이틀, 스티커형 라벨 |
| Body | `Mona12TextKR` | 본문, 버튼, 입력 필드, 탭, 카드 정보 |
| Fallback | `Mona12TextJP`, `Mona12TextSC`, `Mona12TextTC`, `Mona12TextHK`, `Mona12Emoji`, `Mona12ColorEmoji` | 다국어 문자와 이모지 보조 |

### Type Scale

| Token | Size | Weight | Usage |
| --- | --- | --- | --- |
| `display.lg` | 40 logical px | 700 | 월 이름, 브랜드형 큰 픽셀 타이틀 |
| `display.md` | 32 logical px | 700 | 큰 기록 제목, 완료 화면 타이틀 |
| `display.sm` | 28 logical px | 700 | 온보딩/시작 화면 강조 제목 |
| `headline.lg` | 28 logical px | 800 | 화면 메인 제목 |
| `headline.md` | 24 logical px | 800 | 기록/상세 상단 제목 |
| `headline.sm` | 22 logical px | 800 | 큰 카드 제목 |
| `title.lg` | 20 logical px | 700 | 페이지 섹션 제목 |
| `title.md` | 18 logical px | 700 | 카드 제목, 설정 단계 제목 |
| `title.sm` | 16 logical px | 700 | 리스트 제목, 버튼형 텍스트 |
| `body.lg` | 16 logical px | 500 | 강조 본문, 입력값 |
| `body.md` | 14 logical px | 500 | 기본 본문 |
| `body.sm` | 13 logical px | 400 | 보조 설명, 메타 정보 |
| `label.lg` | 14 logical px | 700 | CTA, 선택 칩, 강한 라벨 |
| `label.md` | 12 logical px | 700 | 날짜, 태그, 카운터, 탭 라벨 |
| `label.sm` | 11 logical px | 600 | 작은 배지, 보조 라벨 |
| `sticker` | 10 logical px | 700 | 스티커/픽셀 배지 텍스트 |
| `tiny` | 9 logical px | 600 | 아주 작은 장식 라벨 |
| `micro` | 8 logical px | 600 | 미니 캘린더, 픽셀 카드 내부 최소 라벨 |
| `emoji.lg` | 32 logical px | 400 | 단독 이모지 표시 |

### Flutter Mapping

| Flutter Slot | ONMU Token |
| --- | --- |
| `displayLarge` | `display.lg` |
| `displayMedium` | `display.md` |
| `displaySmall` | `display.sm` |
| `headlineLarge` | `headline.lg` |
| `headlineMedium` | `headline.md` |
| `headlineSmall` | `headline.sm` |
| `titleLarge` | `title.lg` |
| `titleMedium` | `title.md` |
| `titleSmall` | `title.sm` |
| `bodyLarge` | `body.lg` |
| `bodyMedium` | `body.md` |
| `bodySmall` | `body.sm` |
| `labelLarge` | `label.lg` |
| `labelMedium` | `label.md` |
| `labelSmall` | `label.sm` |

### Usage Rules

- 화면과 공통 위젯은 `Theme.of(context).textTheme` 또는 ONMU typography extension을 사용한다.
- 화면 코드에서 `TextStyle(fontSize: ...)`, `fontWeight: ...`를 직접 지정하지 않는다.
- 색상, 줄높이, 정렬처럼 문맥에 따라 달라지는 값은 `copyWith`로 조정할 수 있다.
- 장식용 극소 텍스트는 `sticker`, `tiny`, `micro` 토큰 중 하나를 사용한다.
- 터치 가능한 버튼과 칩 텍스트는 최소 `label.md` 이상을 사용한다.

### Copy Tone

- 다정하고 귀엽게 말한다.
- 사용자를 재촉하지 않는다.
- 기록을 부담스럽지 않게 유도한다.
- 문장은 짧고 명확하게 쓴다.

Example:

- `오늘의 코디를 기록해볼까요?`
- `나만의 캐릭터를 만들어봐요!`
- `사진을 올리면 캐릭터가 자동으로 꾸며져요.`
- `오늘의 모임을 기록해보세요...`
- `다음엔 이렇게 입고 싶어요!`

---

## 5. Layout System

### Mobile Base

- 기준 화면: iPhone 17 QA viewport `402 x 874`
- 보조 기준 화면: iPhone 390px width
- 기본 좌우 여백: 20px
- 작은 요소 간격: 8px
- 컴포넌트 간격: 12-16px
- 섹션 간격: 24-32px
- 하단 버튼과 탭은 safe area를 고려한다.

### Common Page Structure

1. Status bar
2. Top navigation: back, title, more/edit
3. Page title or date
4. Main content: character, cards, calendar, record
5. Supporting info: tags, mood, weather, stats
6. CTA or bottom navigation

### Screen Mood by Feature

| Feature | Mood |
| --- | --- |
| Onboarding | 코랄 브랜드 포인트, 귀여운 캐릭터, 가볍고 설레는 느낌 |
| Character Create | 흰 배경, 픽셀 캐릭터 중심, 선택 타일 |
| OOTD Record | 다이어리 페이지, 스티커, 손글씨 메모 |
| Calendar | 픽셀 캐릭터 아카이브, 날짜별 수집감 |
| Daily Record | 스크랩북, 사진 콜라주, 장소/기분/날씨 기록 |
| Place / Promise | 코랄 포인트, 카드형 정보 구조, 명확한 흐름 |
| My Page / Stats | 흰 배경, 부드러운 카드, 캐릭터와 기록 요약 |

---

## 6. Component System

### Buttons

#### Primary Button

- 높이: 52-56px
- radius: 10-12px
- 배경: `primary.purple` 또는 `primary.pink`
- 텍스트: `text.inverse` 또는 `text.main`
- 사용: 다음, 시작하기, 저장하기, 추천하기

#### Secondary Button

- 배경: `#FFFFFF`
- 테두리: `line.soft`
- 텍스트: `text.main`
- 사용: 이전, 취소, 홈으로 가기

#### Icon Button

- 크기: 40-48px
- 배경: 흰색 또는 `bg.warm`
- 테두리: `line.soft`
- radius: 8-10px
- 사용: 뒤로가기, 더보기, 편집, 업로드

### Cards

- 배경: 흰색 또는 `bg.paper`
- 테두리: `line.soft`
- radius: 10-12px
- 그림자: 매우 약하게 사용
- 내부 여백: 16-20px
- 정보 카드에는 제목, 보조 설명, 태그, 상태 배지를 명확하게 배치한다.
- 다이어리 카드에는 테이프, 클립, 손그림 장식을 살짝 겹쳐도 된다.

### Inputs

- 배경: 흰색
- 테두리: `line.soft`
- focus: `primary.pink` 또는 `primary.purple`
- radius: 8-10px
- placeholder: `text.muted`
- 글자 수 카운터는 우측 하단에 작게 표시한다.

### Selection Tiles

- 선택 전: 흰색 배경, 얇은 테두리
- 선택 후: 코랄/핑크 테두리, 체크 배지
- 캐릭터 커스터마이징 옵션은 4열 또는 5열 그리드를 사용한다.
- 음식, 취향, 장소 선택은 아이콘 또는 이미지가 들어간 카드 그리드를 사용한다.

### Progress Stepper

- 원형 번호와 얇은 라인으로 구성한다.
- 현재 단계는 코랄 또는 핑크 배경으로 표시한다.
- 완료/비활성 단계는 흰색 배경과 브라운 또는 코랄 라인을 사용한다.
- 단계명은 작게 표시한다.

### Bottom Navigation

- 배경: 흰색
- 아이콘 + 라벨 구조
- 활성 탭은 코랄 또는 핑크 포인트를 사용한다.
- 주요 탭: 홈, 온모임, 기록, 마이
- 온모임 아이콘은 여러 사람을 뜻하는 `Icons.groups_*` 계열을 사용한다.
- 기록 아이콘은 달력 느낌의 `Icons.calendar_month_*` 계열을 사용한다.
- 직접 그린 아이콘은 겹침, 왜곡, stroke 불일치가 생기기 쉬우므로 Material/Lucide 등 검증된 아이콘을 우선한다.
- OOTD/기록 추가 버튼은 중앙 플로팅 버튼으로 사용할 수 있다.

---

## 7. Pixel Character System

픽셀 캐릭터는 ONMU의 핵심 브랜드 자산이다.

### Character Style

- 2D 픽셀 아트
- 큰 눈, 작은 입, 부드러운 표정
- 귀엽고 둥근 인상
- 옷, 가방, 신발, 머리 스타일이 알아보이도록 표현
- 캐릭터 아래에는 연한 타원형 그림자를 둔다.

### Character Usage

- 온보딩
- 캐릭터 만들기
- OOTD 기록
- 캘린더 날짜 셀
- 데일리 기록 상세
- 장소/약속 추천 결과
- 프로필, 마이페이지, 통계

### Customizing Categories

- 피부색
- 눈 모양
- 눈 색상
- 헤어 컬러
- 헤어 스타일
- 표정
- 포즈
- 소품
- 배경 색상

---

## 8. Screen Guidelines

### Onboarding

- ONMU 로고는 코랄 포인트를 사용한다.
- 화면은 흰 배경 또는 아주 연한 코랄/핑크 배경을 사용한다.
- 캐릭터 일러스트 또는 픽셀 캐릭터를 중앙에 둔다.
- CTA는 코랄 버튼을 우선 사용한다.
- 장식은 별, 하트, 테이프, 작은 말풍선을 사용한다.

### Character Create

- 흰 배경에 캐릭터를 크게 보여준다.
- 상단에는 단계 표시를 둔다.
- 선택지는 카드 또는 타일 그리드로 배치한다.
- 선택 상태는 체크 배지와 코랄/핑크 테두리로 표시한다.
- 완료 화면은 폴라로이드나 종이 카드 느낌으로 만든다.

### Calendar

- 월 이름은 픽셀 폰트로 크게 표시한다.
- 날짜 셀 안에는 픽셀 캐릭터 또는 OOTD 썸네일을 넣는다.
- 셀 테두리는 핑크, 블루, 그린, 오렌지, 퍼플 등 파스텔 색을 섞는다.
- 특별한 날은 하트, 별, 구름, 북마크 스티커로 표시한다.
- 하단에는 월간 통계 카드를 배치할 수 있다.

### OOTD Record

- 중앙에 오늘의 픽셀 캐릭터 룩을 크게 배치한다.
- 주변에 mood, point, hair, weather, outfit info를 메모 카드처럼 배치한다.
- 배경은 흰색 또는 연한 격자 종이 느낌을 사용한다.
- 태그는 하단에 작은 칩으로 정리한다.
- 별점과 다음 코디 메모를 함께 제공한다.

### Daily Record

- 사진, 장소 메모, 체크리스트, 캐릭터를 스크랩북처럼 배치한다.
- 사진에는 흰색 프레임을 사용하고, 모서리에 테이프 스티커를 붙일 수 있다.
- 장소 정보는 종이 카드처럼 배치한다.
- 하단에는 함께한 사람, 기분, 날씨를 요약한다.

### Place / Promise Recommendation

- 코랄 CTA와 카드형 정보 구조를 사용한다.
- 점수, 운영 리스크, 후보 비교 화면은 현재 제품 합의에서 제외한다.
- 장소 검색은 지도 화면 상단 검색바와 지도 위 하단 시트 안에서 이어간다.
- 장소 추가 액션은 `일정에 추가`와 `후보에 추가`를 모두 제공한다.
- 후보 리스트는 약속 단위 공유 리스트이므로 날짜 탭을 넣지 않는다.
- 배경은 흰색 또는 아주 연한 회색 톤을 사용한다.
- 캐릭터나 작은 스티커는 정보 판독을 방해하지 않는 보조 장식으로만 활용한다.

### OnMoim

- 온모임 목록은 스크롤을 많이 하지 않아도 모임명, 멤버 수, 다가오는 약속, 최근 대화, unread count가 보이도록 조밀하게 만든다.
- 모임 홈 제목은 `모임 홈` 같은 설명 문구가 아니라 실제 모임 이름을 사용한다.
- 모임 홈은 `다가오는 약속`, `최근 기록`, `최근 대화`를 먼저 보여주고, 중복되는 모임원 하단 섹션은 만들지 않는다.
- 약속 만들기는 우하단 FAB 또는 명확한 단일 CTA로 제공한다.

### Settlement

- 정산은 모임 단위가 아니라 약속 단위 화면에서만 진입한다.
- 정산 만들기는 긴 입력 폼보다 결제 항목 카드 리스트와 하단 CTA를 우선한다.
- `참여자별`보다 `개별 금액`, `대상자`처럼 사용자가 바로 이해하는 말을 쓴다.
- 결과 화면은 총액 카드가 과하게 커지지 않게 압축형 요약으로 보여준다.
- 정산 결과는 채팅 카드와 알림 카드로 공유될 수 있어야 한다.

---

## 9. Sticker & Decoration

### Sticker Types

- 하트
- 별
- 반짝이
- 리본
- 구름
- 커피컵
- 옷걸이
- 카메라
- 꽃
- 마스킹 테이프
- 종이 클립
- 말풍선
- 위치 핀

### Decoration Rules

- 화면당 포인트 스티커는 3-7개 정도로 제한한다.
- 중요한 텍스트, 입력창, 버튼을 가리지 않는다.
- 스티커는 살짝 기울이거나 겹쳐서 손으로 꾸민 느낌을 준다.
- 사진 위에는 핵심 텍스트를 직접 올리지 않는다.
- 정보 중심 화면에서는 장식을 줄이고, 기록 화면에서는 장식을 더 사용할 수 있다.

---

## 10. Motion

모션은 작고 귀엽게 사용한다.

- 버튼 탭: 살짝 눌리는 느낌
- 선택 타일: 체크 배지가 pop-in
- 저장 완료: 하트나 반짝이가 짧게 나타남
- 로딩: 캐릭터가 깜빡이거나 반짝이가 순서대로 나타남
- 화면 전환: 200-300ms ease-out

---

## 11. Accessibility

- 본문 텍스트는 최소 13px 이상 사용한다.
- 주요 버튼은 최소 44px 이상의 터치 영역을 확보한다.
- 선택 상태는 색상만으로 표현하지 않고 체크, 테두리, 배지를 함께 사용한다.
- 흰 배경 위 연한 컬러를 사용할 때 텍스트 대비를 확인한다.
- 장식 요소가 정보 전달을 방해하지 않게 한다.

---

## 12. AI Screen Generation Rules

AI로 앱 화면을 만들 때 아래 규칙을 반드시 따른다.

### Prompt Must Include

- ONMU mobile app screen
- white background
- cute pixel character
- soft pastel coral and pink accents
- diary scrapbook mood
- rounded cards
- hand-drawn stickers
- masking tape decoration
- Korean mobile UI
- clean spacing

### Prompt Should Avoid

- dark theme
- neon colors
- cyberpunk
- realistic 3D character
- corporate SaaS dashboard
- heavy gradients
- overly glossy UI
- too many decorative stickers
- 점수 중심 장소 추천
- 운영 리스크 문구
- 후보 비교 화면
- 장소 후보 리스트의 날짜 탭

### Example Prompt

```text
Create a Korean mobile app screen for ONMU, a cute pixel OOTD diary app. Use a clean white background, soft pastel coral and pink accents, rounded paper-like cards, pixel character avatar, hand-drawn heart and sparkle stickers, masking tape decorations, and cozy scrapbook diary mood. Keep the UI readable, warm, cute, and consistent with a fashion daily record app.
```

---

## 13. CSS Token Example

```css
:root {
  --bg-default: #ffffff;
  --bg-warm: #fffdf9;
  --bg-paper: #fffaf3;
  --bg-grid: #fff7ef;
  --bg-purple-soft: #f6f1ff;

  --primary-purple: #e86d75;
  --primary-purple-dark: #c94c56;
  --primary-purple-soft: #fad8dc;
  --primary-pink: #ff8fa3;
  --primary-pink-soft: #ffe3e8;

  --text-main: #3a2a23;
  --text-sub: #7a6258;
  --text-muted: #a9948a;
  --text-inverse: #ffffff;

  --line-soft: #ead8cc;
  --line-brown: #c9a995;
  --line-pink: #ff9cad;
  --line-purple: #bda4ff;

  --accent-brown: #b98562;
  --accent-orange: #ffb35c;
  --accent-green: #a8c58b;
  --accent-blue: #8cc6e8;
  --accent-red: #ff6b7a;

  --radius-sm: 8px;
  --radius-md: 10px;
  --radius-lg: 12px;
}
```

```css
.diary-grid {
  background-color: var(--bg-default);
  background-image:
    linear-gradient(var(--bg-grid) 1px, transparent 1px),
    linear-gradient(90deg, var(--bg-grid) 1px, transparent 1px);
  background-size: 18px 18px;
}
```

---

## 14. Final Checklist

- 흰색 배경을 기본으로 사용했는가?
- ONMU의 코랄 브랜드 포인트가 필요한 곳에 들어갔는가?
- OOTD/기록 화면에서는 핑크와 브라운 감성이 잘 보이는가?
- 픽셀 캐릭터가 화면의 핵심 시각 요소로 사용되었는가?
- 카드, 입력창, 버튼이 둥글고 부드러운가?
- 다이어리, 스티커, 테이프, 손그림 감성이 들어갔는가?
- 정보 중심 화면은 읽기 쉽게 정돈되어 있는가?
- 기록 중심 화면은 스크랩북처럼 감성적으로 보이는가?
- 모든 화면이 같은 ONMU 앱처럼 연결되어 보이는가?
