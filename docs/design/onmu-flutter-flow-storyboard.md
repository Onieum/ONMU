# ONMU Flutter Flow 스토리보드

## 1. 목적

이 문서는 최종 `screens` 화면 묶음과 스크린별 와이어프레임을 바탕으로 Flutter 또는 FlutterFlow에서 페이지를 만들 수 있도록 정리한 스토리보드다.

기준 자료는 다음 문서를 따른다.

- [ONMU UI 캡처 종합 정리](./onmu-ui-screen-summary.md)
- [ONMU 디자인 시스템 기준](./onmu-design-system.md)

구현 기준 화면은 `docs/design/assets/figma-captures/onmu-meeting-aligned/screens`의 64장이다. 원본 추적과 누락 확인은 `docs/design/assets/figma-captures/onmu-workspace-screens/contact-sheet.png`에 정리된 36장 원본 이미지 레이어 접촉시트를 기준으로 한다.

## 2. 화면 사용 범위

이 스토리보드는 화면 64장을 그대로 64개 페이지로 만들기보다, 반복 구조는 공통 페이지와 컴포넌트로 묶어서 FlutterFlow에서 유지보수하기 쉽게 만드는 것을 기준으로 한다.

| 화면 묶음 | 수량 | FlutterFlow 적용 방식 |
| --- | ---: | --- |
| 캐릭터 생성 여자 화면 | 10장 | 캐릭터 생성 공통 페이지 구조의 기준 시안 |
| 캐릭터 생성 남자 화면 | 10장 | 같은 페이지 구조에서 `CharacterDraft.gender`와 에셋 세트만 분기 |
| OOTD 기록 화면 | 10장 | OOTD 기록 플로우 페이지 |
| 장소 및 외부 API 경고 | 3장 | `PlaceRiskDialog` 컴포넌트 3종 |
| 기존 단일 페이지 선별본 | 31장 | 홈, 취향 입력, 장소 후보, 기록 상세, 마이 ONMU 보조 플로우 |

전체 64장의 스크린별 와이어프레임은 [ONMU UI 캡처 종합 정리](./onmu-ui-screen-summary.md)의 `9. 스크린별 와이어프레임`을 기준으로 한다.

## 3. 전체 앱 흐름

```mermaid
flowchart TD
    A["앱 실행"] --> B["스플래시 / 시작"]
    B --> C{"캐릭터 생성 여부"}
    C -->|없음| D["캐릭터 생성 플로우"]
    C -->|있음| E{"취향 데이터 충분 여부"}
    D --> E
    E -->|부족| F["취향 입력 플로우"]
    E -->|충분| G["홈 / 메인 탭"]
    F --> G

    G --> H["약속 생성 / 장소 추천"]
    H --> I["장소 후보 탐색"]
    I --> J{"장소 리스크 발생"}
    J -->|비선호 키워드| J1["싫어하는 키워드 경고"]
    J -->|브레이크 타임| J2["브레이크 타임 경고"]
    J -->|휴무일| J3["휴무일 경고"]
    J -->|없음| K["장소 후보 확정"]
    J1 --> K
    J2 --> K
    J3 --> K

    G --> L["OOTD 기록"]
    L --> M["기록 방법 선택"]
    M -->|사진| N["사진 업로드"]
    M -->|설명| O["설명 입력"]
    N --> P["추가 정보 / 스타일 옵션"]
    O --> P
    P --> Q["AI 분석"]
    Q --> R["기록 완료"]
    R --> S["기록 목록 / 상세"]

    G --> T["마이 ONMU"]
    T --> U["취향 데이터 수정 바텀시트"]
```

## 4. FlutterFlow 페이지 구조

| FlutterFlow 페이지 | 라우트 이름 | 역할 |
| --- | --- | --- |
| `SplashPage` | `/splash` | 로고/일러스트 기반 초기 진입 |
| `StartPage` | `/start` | 오늘의 약속/취향 입력 시작 |
| `CharacterStartPage` | `/character/start` | 캐릭터 생성 시작 |
| `CharacterAppearanceMenuPage` | `/character/appearance` | 외형 설정 메뉴 |
| `CharacterSkinTonePage` | `/character/skin-tone` | 피부색 선택 |
| `CharacterEyeShapePage` | `/character/eye-shape` | 눈 모양 선택 |
| `CharacterEyeColorPage` | `/character/eye-color` | 눈 색상 선택 |
| `CharacterHairColorPage` | `/character/hair-color` | 헤어 컬러 선택 |
| `CharacterHairStylePage` | `/character/hair-style` | 헤어 스타일 선택 |
| `CharacterPreviewPage` | `/character/preview` | 캐릭터 미리보기 |
| `CharacterNamePage` | `/character/name` | 이름/닉네임/이모지 입력 |
| `CharacterCompletePage` | `/character/complete` | 캐릭터 생성 완료 |
| `PreferenceIntroPage` | `/preferences/intro` | 취향 입력 시작 |
| `PreferenceCategoryPage` | `/preferences/category` | 취향 카테고리 소개 |
| `PreferenceFoodPage` | `/preferences/food` | 음식 선호 |
| `PreferenceDislikePage` | `/preferences/dislike` | 비선호 음식/조건 |
| `PreferenceTimePage` | `/preferences/time` | 선호 시간 |
| `PreferenceUnavailableDatePage` | `/preferences/unavailable-dates` | 불가능 날짜 |
| `HomePage` | `/home` | 메인 탭 진입 |
| `PlaceCandidatePage` | `/meetups/:meetupId/places` | 장소 후보 탐색 |
| `PlaceComparePage` | `/meetups/:meetupId/place-compare` | 후보 비교 |
| `OotdEntryPage` | `/ootd/new` | OOTD 기록 시작 |
| `OotdMethodPage` | `/ootd/method` | 사진/설명 기록 방식 선택 |
| `OotdPhotoUploadPage` | `/ootd/photo` | 코디 사진 업로드 |
| `OotdDescriptionPage` | `/ootd/description` | 코디 설명 입력 |
| `OotdExtraInfoPage` | `/ootd/extra-info` | 태그/장소/계절 입력 |
| `OotdStylePage` | `/ootd/style` | 스타일 옵션 |
| `OotdPropsMoodPage` | `/ootd/props-mood` | 소품/분위기 |
| `OotdAnalysisPage` | `/ootd/analysis` | AI 분석 중 |
| `OotdCompletePage` | `/ootd/complete` | 기록 완료 |
| `OotdListPage` | `/ootd/list` | 기록 목록 |
| `MemoryDetailPage` | `/memories/:memoryId` | 기록 상세 |
| `MyPage` | `/my` | 프로필/취향 데이터 |

모달과 바텀시트는 페이지가 아니라 공통 컴포넌트로 둔다.

| 컴포넌트 | 역할 |
| --- | --- |
| `PlaceRiskDialog` | 싫어하는 키워드, 브레이크 타임, 휴무일 경고 |
| `PreferenceEditBottomSheet` | 선호 키워드, 비선호 조건, 시간, 날짜 수정 |
| `StepProgressBar` | 캐릭터/OOTD/약속 생성 단계 표시 |
| `PrimaryBottomButton` | 화면 하단 주요 CTA |
| `SelectionCard` | 선택형 카드 |
| `PaletteSelector` | 제한 팔레트 선택 |
| `CharacterPreviewCard` | 캐릭터 미리보기 |
| `OotdRecordCard` | OOTD 기록 카드 |
| `PlaceCandidateCard` | 장소 후보 카드 |

## 5. App State / 데이터 모델

| 상태 이름 | 주요 필드 | 사용 화면 |
| --- | --- | --- |
| `CharacterDraft` | `gender`, `skinTone`, `eyeShape`, `eyeColor`, `hairColor`, `hairStyle`, `name`, `nickname`, `emojis` | 캐릭터 생성 |
| `PreferenceProfile` | `favoriteFoods`, `dislikedFoods`, `placeConditions`, `preferredTimes`, `unavailableDates`, `preferredWeekdays` | 취향 입력, 마이 |
| `OotdDraft` | `method`, `photos`, `description`, `tags`, `place`, `season`, `expression`, `pose`, `backgroundColor`, `props`, `memo` | OOTD 기록 |
| `PlaceCandidate` | `id`, `name`, `category`, `distance`, `openStatus`, `breakTime`, `closedDays`, `matchedPreferences`, `riskFlags` | 장소 추천 |
| `PlaceRisk` | `type`, `message`, `evidence`, `primaryAction`, `secondaryAction` | 장소 경고 모달 |
| `MemoryRecord` | `id`, `date`, `title`, `photos`, `characters`, `memo`, `tags` | 기록 목록/상세 |

## 6. 스토리보드

### 6.1 앱 시작과 취향 입력

| 단계 | 스크린샷 | 라우트 | 와이어프레임 | 다음 액션 |
| ---: | --- | --- | --- | --- |
| 1 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/08-existing-08-figma-image-28.png" width="160"> | `/splash` | `로고` -> `일러스트` -> `로딩 표시` | 자동으로 `/start` 또는 `/character/start` |
| 2 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/09-existing-09-figma-image-29.png" width="160"> | `/start` | `로고` -> `캐릭터` -> `시작 CTA` | 시작 시 캐릭터/취향 상태 확인 |
| 3 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/10-existing-10-figma-image-30.png" width="160"> | `/preferences/intro` | `질문형 헤드라인` -> `말풍선 카드` -> `취향 생성 CTA` | `/preferences/category` |
| 4 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/11-existing-11-figma-image-31.png" width="160"> | `/preferences/category` | `기능 소개 카드 3개` -> `확인 CTA` | `/preferences/food` |
| 5 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/13-existing-13-figma-image-37.png" width="160"> | `/preferences/food` | `질문` -> `음식 아이콘 그리드` -> `다음 CTA` | 음식 선호 저장 후 다음 질문 |
| 6 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/17-existing-17-figma-image-46.png" width="160"> | `/preferences/dislike` | `질문` -> `비선호 음식 그리드` -> `다음 CTA` | 비선호 조건 저장 |
| 7 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/22-existing-22-figma-image-52.png" width="160"> | `/preferences/time` | `질문` -> `시간대 카드 그리드` -> `다음 CTA` | 선호 시간 저장 |
| 8 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/23-existing-23-figma-image-53.png" width="160"> | `/preferences/unavailable-dates` | `달력` -> `날짜 선택` -> `다음 CTA` | 불가능 날짜 저장 |
| 9 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/16-existing-16-figma-image-44.png" width="160"> | `/preferences/summary` | `캐릭터` -> `취향 요약 카드` -> `진행도` | `/home` 또는 `/my` |

```mermaid
flowchart LR
    A["/splash"] --> B["/start"]
    B --> C["/preferences/intro"]
    C --> D["/preferences/category"]
    D --> E["/preferences/food"]
    E --> F["/preferences/dislike"]
    F --> G["/preferences/time"]
    G --> H["/preferences/unavailable-dates"]
    H --> I["/preferences/summary"]
    I --> J["/home"]
```

### 6.2 캐릭터 생성

여자/남자 캐릭터 생성은 같은 FlutterFlow 페이지 구조를 공유하고, `CharacterDraft.gender`와 에셋 세트만 다르게 적용한다.

| 단계 | 스크린샷 | 라우트 | 와이어프레임 | 다음 액션 |
| ---: | --- | --- | --- | --- |
| 1 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/01-character-create/female/01-character-female-start.png" width="160"> | `/character/start` | `제목` -> `캐릭터 히어로` -> `안내 카드` -> `시작 CTA` | `/character/appearance` |
| 2 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/01-character-create/female/02-character-female-appearance-menu.png" width="160"> | `/character/appearance` | `5단계 인디케이터` -> `외형 항목 리스트` -> `다음 CTA` | 항목 선택 또는 `/character/skin-tone` |
| 3 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/01-character-create/female/03-character-female-skin-tone.png" width="160"> | `/character/skin-tone` | `캐릭터 프리뷰` -> `피부색 팔레트` -> `밝기 슬라이더` | 피부색 저장 |
| 4 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/01-character-create/female/04-character-female-eye-shape.png" width="160"> | `/character/eye-shape` | `눈 확대 프리뷰` -> `눈 모양 그리드` | 눈 모양 저장 |
| 5 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/01-character-create/female/05-character-female-eye-color.png" width="160"> | `/character/eye-color` | `캐릭터 프리뷰` -> `눈 색상 팔레트` | 눈 색상 저장 |
| 6 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/01-character-create/female/06-character-female-hair-color.png" width="160"> | `/character/hair-color` | `캐릭터 프리뷰` -> `헤어 컬러 그리드` | 헤어 컬러 저장 |
| 7 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/01-character-create/female/07-character-female-hair-style.png" width="160"> | `/character/hair-style` | `헤어 스타일 그리드` -> `다음 CTA` | 헤어 스타일 저장 |
| 8 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/01-character-create/female/08-character-female-preview.png" width="160"> | `/character/preview` | `메모지 프리뷰` -> `회전하기` -> `이전/다음 CTA` | `/character/name` |
| 9 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/01-character-create/female/09-character-female-name-input.png" width="160"> | `/character/name` | `이름 필드` -> `닉네임 필드` -> `이모지 슬롯` | 이름 저장 |
| 10 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/01-character-create/female/10-character-female-complete.png" width="160"> | `/character/complete` | `완료 제목` -> `완성 캐릭터 카드` -> `시작하기 CTA` | `/ootd/new` 또는 `/home` |

```mermaid
flowchart LR
    A["start"] --> B["appearance"]
    B --> C["skin-tone"]
    C --> D["eye-shape"]
    D --> E["eye-color"]
    E --> F["hair-color"]
    F --> G["hair-style"]
    G --> H["preview"]
    H --> I["name"]
    I --> J["complete"]
```

### 6.3 OOTD 기록

| 단계 | 스크린샷 | 라우트 | 와이어프레임 | 다음 액션 |
| ---: | --- | --- | --- | --- |
| 1 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/02-ootd-record/01-ootd-new-record-entry.png" width="160"> | `/ootd/new` | `제목` -> `캐릭터 히어로` -> `안내 카드` -> `다음 CTA` | `/ootd/method` |
| 2 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/02-ootd-record/02-ootd-record-method-select.png" width="160"> | `/ootd/method` | `3단계 인디케이터` -> `사진 기록 카드` -> `설명 기록 카드` | 사진 또는 설명 방식 선택 |
| 3A | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/02-ootd-record/03-ootd-photo-upload.png" width="160"> | `/ootd/photo` | `드롭존` -> `사진 예시` -> `다음 CTA` | 사진 업로드 후 `/ootd/extra-info` |
| 3B | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/02-ootd-record/04-ootd-description-input.png" width="160"> | `/ootd/description` | `텍스트 입력 박스` -> `글자 수` -> `팁 카드` | 설명 입력 후 `/ootd/extra-info` |
| 4 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/02-ootd-record/05-ootd-extra-info-input.png" width="160"> | `/ootd/extra-info` | `태그 필드` -> `장소 필드` -> `날씨/계절 칩` | 메타데이터 저장 |
| 5 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/02-ootd-record/06-ootd-style-options.png" width="160"> | `/ootd/style` | `표정 행` -> `포즈 행` -> `배경 색상 팔레트` | 스타일 옵션 저장 |
| 6 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/02-ootd-record/07-ootd-props-mood.png" width="160"> | `/ootd/props-mood` | `소품 그리드` -> `스티커 그리드` -> `메모 입력` | 소품/분위기 저장 |
| 7 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/02-ootd-record/08-ootd-ai-analysis.png" width="160"> | `/ootd/analysis` | `분석 단계 카드` -> `팁 카드` | 분석 완료 시 `/ootd/complete` |
| 8 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/02-ootd-record/09-ootd-record-complete.png" width="160"> | `/ootd/complete` | `완성 기록 카드` -> `홈/기록 더 하기 CTA` | 홈 또는 새 기록 |
| 9 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/02-ootd-record/10-ootd-record-list.png" width="160"> | `/ootd/list` | `필터 탭` -> `기록 카드 그리드` -> `하단 탭바` | 기록 상세로 이동 |

```mermaid
flowchart TD
    A["/ootd/new"] --> B["/ootd/method"]
    B -->|사진으로 기록| C["/ootd/photo"]
    B -->|설명으로 기록| D["/ootd/description"]
    C --> E["/ootd/extra-info"]
    D --> E
    E --> F["/ootd/style"]
    F --> G["/ootd/props-mood"]
    G --> H["/ootd/analysis"]
    H --> I["/ootd/complete"]
    I --> J["/ootd/list"]
```

### 6.4 장소 추천과 외부 API 경고

| 단계 | 스크린샷 | 라우트/컴포넌트 | 와이어프레임 | 다음 액션 |
| ---: | --- | --- | --- | --- |
| 1 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/01-existing-01-figma-image-07.png" width="160"> | `/meetups/:id/places` | `약속 요약` -> `지도 미리보기` -> `장소 후보 리스트` | 후보 선택 |
| 2 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/02-existing-02-figma-image-08.png" width="160"> | `/meetups/:id/places` | `검색/필터` -> `장소 카드 리스트` -> `후보 추가 CTA` | 후보 카드 상세 |
| 3 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/04-existing-04-figma-image-10.png" width="160"> | `PlaceDetailBottomSheet` | `지도 배경` -> `장소 상세 바텀시트` -> `적합도 막대` | 후보 추가 |
| 4 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/06-existing-06-figma-image-12.png" width="160"> | `/meetups/:id/place-compare` | `비교 표` -> `적합도 막대` -> `추천 설명` | 최종 선택 |
| 5A | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/03-place-external-api/warnings/01-place-warning-disliked-keyword.png" width="160"> | `PlaceRiskDialog.keyword` | `장소 화면 배경` -> `경고 모달` -> `취소/그래도 추가` | 비선호 키워드 리스크 처리 |
| 5B | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/03-place-external-api/warnings/02-place-warning-break-time.png" width="160"> | `PlaceRiskDialog.breakTime` | `장소 화면 배경` -> `브레이크 타임 모달` -> `시간 변경/그래도 추가` | 시간 변경 또는 후보 추가 |
| 5C | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/03-place-external-api/warnings/03-place-warning-closed-day.png" width="160"> | `PlaceRiskDialog.closedDay` | `장소 화면 배경` -> `휴무일 모달` -> `날짜 변경/그래도 추가` | 날짜 변경 또는 후보 추가 |

```mermaid
flowchart TD
    A["장소 후보 검색"] --> B["장소 상세 확인"]
    B --> C{"리스크 존재"}
    C -->|비선호 키워드| D["keyword dialog"]
    C -->|브레이크 타임| E["break time dialog"]
    C -->|휴무일| F["closed day dialog"]
    C -->|없음| G["후보 추가"]
    D --> G
    E --> G
    F --> G
    G --> H["후보 비교"]
    H --> I["장소 확정"]
```

### 6.5 기록과 아카이브

| 단계 | 스크린샷 | 라우트 | 와이어프레임 | 다음 액션 |
| ---: | --- | --- | --- | --- |
| 1 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/14-existing-14-figma-image-40.png" width="160"> | `/memories/:id` | `날짜/장소 헤더` -> `사진 콜라주` -> `메모 카드` -> `하단 액션` | 공유, 수정, 목록 복귀 |
| 2 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/18-existing-18-figma-image-48.png" width="160"> | `/memories/:id` | `기록 제목` -> `큰 사진 콜라주` -> `참여 캐릭터` -> `기록 메모` | 상세 보기 |
| 3 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/19-existing-19-figma-image-49.png" width="160"> | `/memories/:id/template-diary` | `사진 콜라주` -> `스티커` -> `텍스트 기록` -> `액션 버튼` | 감성형 템플릿 참고 |

### 6.6 마이 ONMU와 취향 데이터 수정

| 단계 | 스크린샷 | 라우트/컴포넌트 | 와이어프레임 | 다음 액션 |
| ---: | --- | --- | --- | --- |
| 1 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/26-existing-26-figma-image-57.png" width="160"> | `/my` | `프로필 카드` -> `레벨/진행도` -> `취향 데이터 카드` -> `하단 탭바` | 카드 선택 시 수정 바텀시트 |
| 2 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/31-existing-31-figma-image-63.png" width="160"> | `/my` empty | `빈 프로필 카드` -> `취향 빈 카드` -> `추천 개선 배너` -> `하단 탭바` | 취향 입력 CTA |
| 3 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/27-existing-27-figma-image-58.png" width="160"> | `PreferenceEditBottomSheet.keywords` | `딤 배경` -> `선호 키워드 그리드` -> `저장 CTA` | 선호 키워드 저장 |
| 4 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/28-existing-28-figma-image-59.png" width="160"> | `PreferenceEditBottomSheet.dislikes` | `딤 배경` -> `비선호 조건 그리드` -> `저장 CTA` | 비선호 조건 저장 |
| 5 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/29-existing-29-figma-image-61.png" width="160"> | `PreferenceEditBottomSheet.times` | `딤 배경` -> `시간 선택 칩` -> `저장 CTA` | 선호 시간 저장 |
| 6 | <img src="./assets/figma-captures/onmu-meeting-aligned/screens/04-existing-workspace-pages/30-existing-30-figma-image-62.png" width="160"> | `PreferenceEditBottomSheet.dates` | `딤 배경` -> `캘린더` -> `저장 CTA` | 불가능 날짜 저장 |

## 7. FlutterFlow 빌드 순서

1. `Theme`에서 색상 토큰을 먼저 등록한다.
2. `PrimaryBottomButton`, `StepProgressBar`, `SelectionCard`, `PaletteSelector`를 컴포넌트로 만든다.
3. 캐릭터 생성 페이지 10개를 만든 뒤 여자/남자 에셋을 `gender` 조건으로 분기한다.
4. OOTD 기록 페이지 10개를 만든다.
5. 장소 후보 페이지와 `PlaceRiskDialog` 모달 3종을 만든다.
6. 마이 ONMU와 `PreferenceEditBottomSheet` 바텀시트를 만든다.
7. 앱 상태 모델을 연결하고, 각 CTA의 `Navigate To` 액션을 연결한다.
8. API 연결 전에는 FlutterFlow Local State 또는 App State mock 데이터로 먼저 화면 이동을 검증한다.

## 8. FlutterFlow 액션 규칙

| 액션 | FlutterFlow 설정 |
| --- | --- |
| 다음 단계 이동 | `Navigate To` + 현재 draft state 저장 |
| 이전 단계 이동 | `Navigate Back` 또는 이전 route 명시 |
| 팔레트 선택 | `Update App State`로 선택 토큰 저장 |
| 사진 업로드 | `Upload Media` 후 `OotdDraft.photos`에 저장 |
| AI 분석 | 초기에는 `Wait` 또는 mock API, 이후 backend API 연결 |
| 장소 리스크 | 조건별로 `Show Dialog` 또는 `Show Bottom Sheet` |
| 취향 수정 | `Show Bottom Sheet` -> 저장 시 `Update App State` |

## 9. 프로토타입 우선 구현 흐름

첫 FlutterFlow 프로토타입은 모든 세부 화면을 완성하기보다 아래 흐름을 먼저 연결한다.

```mermaid
flowchart LR
    A["스플래시"] --> B["캐릭터 생성"]
    B --> C["취향 입력"]
    C --> D["마이 ONMU"]
    D --> E["장소 후보"]
    E --> F["장소 경고 모달"]
    F --> G["OOTD 기록"]
    G --> H["기록 완료"]
```

이 흐름이 연결되면 4개 파트가 한 앱 안에서 이어지는 vertical prototype이 된다.

## 10. 검증 체크리스트

- [ ] FlutterFlow 페이지가 라우트 표와 동일하게 생성되었는지 확인한다.
- [ ] 하단 CTA가 모두 다음 화면으로 이동하는지 확인한다.
- [ ] 캐릭터 생성 draft state가 단계 이동 후 유지되는지 확인한다.
- [ ] OOTD 기록 draft state가 사진/설명 분기 이후에도 유지되는지 확인한다.
- [ ] 장소 리스크 3종 모달이 조건별로 뜨는지 확인한다.
- [ ] 마이 ONMU 바텀시트 저장 후 카드 값이 갱신되는지 확인한다.
- [ ] 강한 보라색 대신 디자인 시스템의 핑크/코랄/연노랑 계열 토큰을 사용하는지 확인한다.
- [ ] 화면 배경은 기본 흰색을 유지하는지 확인한다.
