# ONMU 모바일 주말 프로토타입 작업 계획

## 1. 목적

이번 프로토타입의 목표는 기능을 완성하는 것이 아니라, 주말 동안 팀원이 각자 맡은 플로우를 병렬로 만들 수 있는 Flutter 앱 뼈대를 먼저 세우는 것이다.

월요일에는 각자 만든 화면을 한 앱처럼 보이게 통합하고, 재사용 가능한 상단 네비게이션, 하단 메뉴바, 카드, 버튼, 칩 같은 공통 UI를 정리한 뒤 비즈니스 로직 작업으로 넘어간다.

## 2. 기준 문서와 원본

작업자는 아래 문서를 먼저 확인한다.

- 팀 공통 Agent 규칙: `AGENTS.md`
- Flutter 디자인 기준: `docs/design/DESIGN.md`
- AI 도구와 Skill 운영 기준: `docs/development/team-ai-tooling.md`
- Flutter 디자인 작업 참고: `docs/development/codex-flutter-design-workflow.md`
- Git/Jira workflow: `docs/development/git-workflow.md`
- 현재 아키텍처: `docs/architecture/current-architecture-diagram.md`
- 작업자용 폴더 구조 요약: `docs/development/mobile-prototype-folder-structure.md`

현재 UI 라우트와 화면 기준은 아래 로컬 아카이브를 원본으로 본다.

```text
C:\Users\EL035\Downloads\아카이브\ONMU Flutter Flow 스토리보드 36d5e2e83ef481008686c58a0e6392ef.md
C:\Users\EL035\Downloads\아카이브\ONMU Flutter Flow 스토리보드\
```

스토리보드 안에서 `/meetups/:id`, `/memories/:id`처럼 쓰인 route parameter는 Flutter 구현에서 각각 `/meetups/:meetupId`, `/memories/:memoryId`로 통일한다.

## 3. 이번 주말의 핵심 원칙

- 단일 `main.dart`에 모든 화면을 몰아넣지 않는다.
- 공통 shell과 feature 폴더를 분리해서 Git conflict를 줄인다.
- 실제 API, DB, 인증, 추천 로직은 붙이지 않고 mock data로 화면 흐름만 연결한다.
- 화면은 `docs/design/DESIGN.md`의 흰 배경, 핑크/보라 포인트, 따뜻한 브라운 텍스트, 종이 카드 톤을 따른다.
- 색상, 간격, 반경은 가능한 한 theme token과 공통 위젯을 통해 사용한다.
- 주말 목표는 "완성된 기능"이 아니라 "끊기지 않는 클릭 흐름"이다.

## 4. 오늘 먼저 만들 프로토타입 shell

오늘 먼저 해야 할 일은 각자 화면을 만들기 전에 공통 기반을 잡는 것이다.

권장 브랜치 이름은 Jira 번호를 붙여 다음처럼 만든다.

```text
feat/SCRUM-번호-mobile-prototype-shell
```

초기 의존성은 최소로 둔다.

```yaml
dependencies:
  go_router: ^버전
  flutter_riverpod: ^버전
```

`dio`, `freezed`, `json_serializable`은 API와 비즈니스 로직을 시작할 때 추가한다. 이번 프로토타입 단계에서는 단순 Dart class 기반 mock model이면 충분하다.

## 5. 권장 폴더 구조

작업자에게 공유할 폴더 구조만 따로 볼 때는 `docs/development/mobile-prototype-folder-structure.md`를 사용한다.

```text
apps/mobile-flutter/lib
├── main.dart
├── app
│   └── onmu_app.dart
├── core
│   ├── routing
│   │   ├── app_router.dart
│   │   └── route_paths.dart
│   └── theme
│       ├── app_colors.dart
│       ├── app_spacing.dart
│       ├── app_radius.dart
│       ├── app_theme.dart
│       └── theme_extensions.dart
├── shared
│   ├── models
│   │   ├── character_models.dart
│   │   ├── preference_models.dart
│   │   ├── meetup_models.dart
│   │   ├── place_models.dart
│   │   ├── onchat_models.dart
│   │   ├── ootd_models.dart
│   │   ├── memory_models.dart
│   │   └── settlement_models.dart
│   └── widgets
│       ├── onmu_scaffold.dart
│       ├── onmu_top_bar.dart
│       ├── onmu_bottom_nav_bar.dart
│       ├── onmu_card.dart
│       ├── onmu_button.dart
│       ├── onmu_chip.dart
│       ├── onmu_step_progress.dart
│       └── selection_card.dart
└── features
    ├── launch
    ├── character
    ├── preferences
    ├── home
    ├── meetup
    ├── place
    ├── onchat
    ├── ootd
    ├── memory
    └── my
```

각 담당자는 자기 feature 폴더 안에서만 화면을 확장한다. 공통 위젯을 바꿔야 하면 팀에 먼저 공유한다.

## 6. 라우팅 기준

하단 탭바가 유지되는 앱 구조이므로 `go_router`의 `StatefulShellRoute`를 기본으로 사용한다.

이 방식은 홈, 약속, 온챗, 기록, 마이 탭이 각각 독립적인 navigation stack을 가질 수 있게 한다. 주말에 각 담당자가 탭 안에서 상세 화면을 만들어도 하단 메뉴가 깨지지 않는다.

권장 하단 탭 branch는 다음과 같다.

| 탭 | 루트 route | 담당 feature |
| --- | --- | --- |
| 홈 | `/home` | `features/home` |
| 약속 | `/meetups` | `features/meetup` |
| 온챗 | `/onchat` | `features/onchat` |
| 기록 | `/ootd/list` | `features/ootd`, `features/memory` |
| 마이 | `/my` | `features/my`, `features/preferences` |

스플래시, 시작, 캐릭터 생성, 취향 입력은 하단 탭 밖의 onboarding route로 둔다. 장소 화면은 독립 탭이 아니라 약속 상세 아래의 nested route로 둔다.

## 7. 스토리보드 기준 route map

### 7.1 앱 시작과 취향 입력

| Page | Route | Feature |
| --- | --- | --- |
| `SplashPage` | `/splash` | `launch` |
| `StartPage` | `/start` | `launch` |
| `PreferenceIntroPage` | `/preferences/intro` | `preferences` |
| `PreferenceCategoryPage` | `/preferences/category` | `preferences` |
| `PreferenceFoodPage` | `/preferences/food` | `preferences` |
| `PreferenceDislikePage` | `/preferences/dislike` | `preferences` |
| `PreferenceTimePage` | `/preferences/time` | `preferences` |
| `PreferenceUnavailableDatePage` | `/preferences/unavailable-dates` | `preferences` |
| `PreferenceSummaryPage` | `/preferences/summary` | `preferences` |

### 7.2 캐릭터 생성

| Page | Route | Feature |
| --- | --- | --- |
| `CharacterStartPage` | `/character/start` | `character` |
| `CharacterAppearanceMenuPage` | `/character/appearance` | `character` |
| `CharacterSkinTonePage` | `/character/skin-tone` | `character` |
| `CharacterEyeShapePage` | `/character/eye-shape` | `character` |
| `CharacterEyeColorPage` | `/character/eye-color` | `character` |
| `CharacterHairColorPage` | `/character/hair-color` | `character` |
| `CharacterHairStylePage` | `/character/hair-style` | `character` |
| `CharacterPreviewPage` | `/character/preview` | `character` |
| `CharacterNamePage` | `/character/name` | `character` |
| `CharacterCompletePage` | `/character/complete` | `character` |

### 7.3 약속과 장소

| Page | Route | Feature |
| --- | --- | --- |
| `MeetupListPage` | `/meetups` | `meetup` |
| `MeetupMemberSelectPage` | `/meetups/new/members` | `meetup` |
| `MeetupDateSelectPage` | `/meetups/new/schedule` | `meetup` |
| `MeetupDetailPage` | `/meetups/:meetupId` | `meetup` |
| `PlaceCandidatePage` | `/meetups/:meetupId/places` | `place` |
| `PlaceCandidateWithVoteResultPage` | `/meetups/:meetupId/places?voteResult=1` | `place` |
| `PlaceSearchFilterPage` | `/meetups/:meetupId/places/search` | `place` |
| `PlaceMapPage` | `/meetups/:meetupId/places/map` | `place` |
| `PlaceDetailSheet` | `/meetups/:meetupId/places/:placeId` | `place` |
| `PlaceComparePage` | `/meetups/:meetupId/place-compare` | `place` |
| `PlaceRisksPage` | `/meetups/:meetupId/places/risks` | `place` |
| `MeetupRouteReviewPage` | `/meetups/:meetupId/route-review` | `meetup` |
| `MeetupCompletePage` | `/meetups/:meetupId/complete` | `meetup` |

### 7.4 온챗과 정산

| Page | Route | Feature |
| --- | --- | --- |
| `OnChatListPage` | `/onchat` | `onchat` |
| `OnChatGroupHomePage` | `/onchat/groups/:groupId` | `onchat` |
| `OnChatThreadPage` | `/onchat/groups/:groupId/chat` | `onchat` |
| `OnChatMeetupCreatePage` | `/onchat/groups/:groupId/meetups/new` | `onchat`, `meetup` |
| `OnChatMeetupBoardPage` | `/onchat/groups/:groupId/meetups/:meetupId/board` | `onchat`, `place` |
| `OnChatMemoryBoardPage` | `/onchat/groups/:groupId/memories` | `onchat`, `memory` |
| `OnChatSettlementCreatePage` | `/onchat/groups/:groupId/settlements/new` | `onchat` |
| `OnChatSettlementSharePage` | `/onchat/groups/:groupId/settlements/:settlementId` | `onchat` |

### 7.5 OOTD 기록과 기억

| Page | Route | Feature |
| --- | --- | --- |
| `OotdEntryPage` | `/ootd/new` | `ootd` |
| `OotdMethodPage` | `/ootd/method` | `ootd` |
| `OotdPhotoUploadPage` | `/ootd/photo` | `ootd` |
| `OotdDescriptionPage` | `/ootd/description` | `ootd` |
| `OotdExtraInfoPage` | `/ootd/extra-info` | `ootd` |
| `OotdStylePage` | `/ootd/style` | `ootd` |
| `OotdPropsMoodPage` | `/ootd/props-mood` | `ootd` |
| `OotdAnalysisPage` | `/ootd/analysis` | `ootd` |
| `OotdCompletePage` | `/ootd/complete` | `ootd` |
| `OotdListPage` | `/ootd/list` | `ootd` |
| `MemoryDetailPage` | `/memories/:memoryId` | `memory` |
| `MemoryDiaryTemplatePage` | `/memories/:memoryId/template-diary` | `memory` |

### 7.6 마이 ONMU

| Page | Route | Feature |
| --- | --- | --- |
| `MyPage` | `/my` | `my` |
| `PreferenceEditBottomSheet.keywords` | modal | `preferences`, `my` |
| `PreferenceEditBottomSheet.dislikes` | modal | `preferences`, `my` |
| `PreferenceEditBottomSheet.times` | modal | `preferences`, `my` |
| `PreferenceEditBottomSheet.dates` | modal | `preferences`, `my` |

## 8. Theme token 기준

`docs/design/DESIGN.md`의 색상을 Flutter theme에 먼저 고정한다.

우선 등록할 색상은 다음과 같다.

| Token | Color | 용도 |
| --- | --- | --- |
| `bg.default` | `#FFFFFF` | 전체 기본 배경 |
| `bg.warm` | `#FFFDF9` | 따뜻한 화면 배경 |
| `bg.paper` | `#FFFAF3` | 종이 카드 |
| `bg.grid` | `#FFF7EF` | 다이어리 격자 배경 |
| `primary.purple` | `#8B5CF6` | 브랜드 포인트, CTA |
| `primary.pink` | `#FF8FA3` | 선택 상태, 기록 CTA |
| `text.main` | `#3A2A23` | 제목, 본문 |
| `text.sub` | `#7A6258` | 보조 설명 |
| `line.soft` | `#EAD8CC` | 카드와 입력 테두리 |
| `line.brown` | `#C9A995` | 종이 느낌 테두리 |

화면 코드에서는 `Color(0x...)`, `Colors.*`, 직접 `TextStyle(...)` 반복을 피한다. 예외는 theme token을 정의하는 파일과 테스트 코드로 제한한다.

## 9. 공통 위젯 초안

이번 주말 전에 최소한 아래 위젯을 만든다.

| 위젯 | 역할 |
| --- | --- |
| `OnmuScaffold` | 기본 흰색 배경, SafeArea, page padding, 선택적 다이어리 격자 배경 |
| `OnmuTopBar` | 뒤로가기, 제목, 편집/더보기 액션 |
| `OnmuBottomNavBar` | 홈, 약속, 온챗, 기록, 마이 탭 |
| `OnmuCard` | 종이 카드 배경, 연한 브라운 테두리, 부드러운 radius |
| `OnmuPrimaryButton` | 주요 CTA, 52px 높이, 보라/핑크 배경 |
| `OnmuSecondaryButton` | 이전, 취소, 보조 액션 |
| `OnmuChip` | 태그, 취향, 장소 유형, 선택 상태 |
| `OnmuStepProgress` | 캐릭터, 취향, OOTD, 약속 생성 단계 표시 |
| `SelectionCard` | 선택형 카드 |
| `PaletteSelector` | 캐릭터 팔레트 선택 |
| `CharacterPreviewCard` | 캐릭터 미리보기 |
| `OotdRecordCard` | OOTD 기록 카드 |
| `MemberAvatarSelector` | 약속 참가자 선택과 온챗 멤버 표시 |
| `DateCandidatePicker` | 참가자 가능 날짜와 시간 선택 |
| `PlaceCandidateCard` | 장소 후보 카드 |
| `PlaceRiskDialog` | 싫어하는 키워드, 브레이크 타임, 휴무일 경고 |
| `VoteResultCarryoverCard` | 온챗 장소 투표 결과를 장소 추천 상단에 연결 |
| `OnChatGroupCard` | 온챗 모임 목록 카드 |
| `PinnedMeetupCard` | 채팅 상단 고정 약속 요약 |
| `ChatMessageBubble` | 온챗 메시지 말풍선 |
| `OnChatMemoryCard` | 온챗 추억 보드의 기록 카드 |
| `SettlementTargetSelector` | 결제자, 금액, 정산 대상자 선택 |
| `SettlementStatusRow` | 정산 참여자별 입금 상태 행 |
| `PreferenceEditBottomSheet` | 선호 키워드, 비선호 조건, 시간, 날짜 수정 |

초기 공통 위젯은 너무 많은 옵션을 넣지 않는다. 주말에는 화면을 빠르게 만들 수 있는 최소 props만 제공한다.

## 10. Mock data model 기준

타입 불일치를 막기 위해 mock model은 각 feature 안에서 새로 만들지 않고 `shared/models`에 둔다.

초기 모델 후보는 다음과 같다.

```text
CharacterDraft
PreferenceProfile
OotdDraft
MeetupDraft
Meetup
PlaceCandidate
PlaceVoteResult
PlaceRisk
MemoryRecord
OnChatGroup
OnChatMessage
SettlementSummary
```

이 단계에서는 `freezed`를 쓰지 않고 단순 class 또는 immutable data class 형태로 만든다. API 응답 구조와 영속성 모델은 월요일 이후 비즈니스 로직 단계에서 다시 정리한다.

## 11. 주말 담당 플로우 작업 규칙

### 시작, 캐릭터, 취향 플로우

- `/splash`, `/start`, `/character/*`, `/preferences/*` 화면을 만든다.
- 실제 로그인이나 온보딩 분기 로직은 붙이지 않고 mock state로 이동만 연결한다.
- `CharacterDraft`, `PreferenceProfile`을 shared model로 사용한다.

### 약속 플로우

- `/meetups`, `/meetups/new/members`, `/meetups/new/schedule`, `/meetups/:meetupId`, `/meetups/:meetupId/route-review`, `/meetups/:meetupId/complete` 화면을 만든다.
- 참여자, 날짜 후보, 준비 상태, 장소 선택 진입 버튼을 mock data로 표현한다.
- 장소 선택으로 넘어가는 route를 연결한다.

### 장소 플로우

- `/meetups/:meetupId/places` 아래 장소 후보, 검색/필터, 지도, 상세, 비교, 리스크 화면을 만든다.
- 영업시간, 거리, 취향 매칭, 휴무/브레이크타임 경고는 mock data로 표현한다.
- 온챗 투표 결과가 넘어온 경우 `VoteResultCarryoverCard`로 상단에 고정한다.

### 온챗 플로우

- `/onchat`, `/onchat/groups/:groupId`, `/onchat/groups/:groupId/chat`, 약속 보드, 추억 보드, 정산 생성/공유 화면을 만든다.
- 실제 WebSocket은 붙이지 않는다.
- mock message list와 입력창 UI만 구현한다.

### OOTD와 기록 플로우

- `/ootd/new`부터 `/ootd/complete`, `/ootd/list`까지 기록 생성 흐름을 만든다.
- 사진 영역은 placeholder로 두고, 캐릭터/스티커/메모 톤을 살린다.
- `/memories/:memoryId`, `/memories/:memoryId/template-diary`로 기록 상세와 템플릿 화면을 연결한다.

### 마이 ONMU 플로우

- `/my` 화면과 취향 수정 바텀시트를 만든다.
- 취향 수정은 modal/bottom sheet로 처리하고 별도 page route로 만들지 않는다.
- 홈, 온챗, 기록에서 마이 화면으로 이동했을 때 하단 탭 상태가 유지되는지 확인한다.

## 12. 월요일 통합 기준

월요일에는 기능을 더 추가하기보다 통일성 정리에 집중한다.

- 상단 네비게이션 제목, 뒤로가기, 액션 버튼 패턴 통일
- 하단 메뉴 탭 이름, 아이콘, 선택 상태 통일
- 각 feature에 흩어진 카드, 버튼, 칩을 `shared/widgets`로 추출
- 하드코딩 색상과 간격 제거
- 텍스트 톤을 `docs/design/DESIGN.md`의 다정하고 짧은 문장으로 정리
- iPhone 390px 기준에서 텍스트 overflow 확인
- 시작 -> 캐릭터 -> 취향 -> 홈 smoke flow 확인
- 약속 생성 -> 장소 선택 -> 온챗 약속 보드 -> 기록 저장 smoke flow 확인
- OOTD 기록 -> 기록 목록 -> 기억 상세 smoke flow 확인

## 13. 검증 명령

Flutter 앱을 바꾼 뒤에는 가능한 범위에서 아래 명령을 실행한다.

```bash
cd apps/mobile-flutter
flutter pub get
flutter analyze
flutter test
```

하드코딩 스타일을 확인할 때는 아래 검색을 사용한다.

```bash
rg "Color\\(0x|Colors\\.|TextStyle\\(" apps/mobile-flutter/lib
```

단, `core/theme` 아래 token 정의 파일은 예외로 본다.

## 14. 완료 기준

이번 프로토타입 shell의 완료 기준은 다음과 같다.

- `main.dart`가 앱 초기화만 담당하고, 라우팅과 화면은 분리되어 있다.
- `StatefulShellRoute` 기반 하단 탭 구조가 동작한다.
- 공통 theme token과 shared widget이 존재한다.
- 각 담당자가 수정할 feature 폴더가 명확하다.
- 스토리보드의 핵심 route가 placeholder page라도 연결되어 있다.
- mock data만으로 주요 화면 이동이 가능하다.
- `flutter analyze`가 통과한다.

## 15. 팀원에게 줄 작업 요청 예시

약속 플로우 담당에게는 아래처럼 요청한다.

```text
AGENTS.md와 docs/design/DESIGN.md를 기준으로 features/meetup 안에서만 약속 플로우 UI를 만들어줘.
shared/widgets와 shared/models의 기존 타입을 우선 사용하고, 실제 API나 비즈니스 로직은 붙이지 마.
필요한 화면은 /meetups, /meetups/new/members, /meetups/new/schedule, /meetups/:meetupId, /meetups/:meetupId/route-review, /meetups/:meetupId/complete야.
완료 후 flutter analyze 결과와 변경 파일을 알려줘.
```

장소 플로우 담당에게는 아래처럼 요청한다.

```text
AGENTS.md와 docs/design/DESIGN.md를 기준으로 features/place 안에서만 장소 후보 UI를 만들어줘.
PlaceCandidate, PlaceVoteResult, PlaceRisk mock model을 사용하고, 실제 지도 API는 붙이지 마.
필요한 화면은 /meetups/:meetupId/places, /meetups/:meetupId/places/search, /meetups/:meetupId/places/map, /meetups/:meetupId/places/:placeId, /meetups/:meetupId/place-compare, /meetups/:meetupId/places/risks야.
완료 후 flutter analyze 결과와 변경 파일을 알려줘.
```

온챗 플로우 담당에게는 아래처럼 요청한다.

```text
AGENTS.md와 docs/design/DESIGN.md를 기준으로 features/onchat 안에서만 온챗 UI를 만들어줘.
OnChatGroup, OnChatMessage, SettlementSummary mock model을 사용하고, 실제 WebSocket은 붙이지 마.
필요한 화면은 /onchat, /onchat/groups/:groupId, /onchat/groups/:groupId/chat, /onchat/groups/:groupId/meetups/:meetupId/board, /onchat/groups/:groupId/memories, /onchat/groups/:groupId/settlements/new, /onchat/groups/:groupId/settlements/:settlementId야.
완료 후 flutter analyze 결과와 변경 파일을 알려줘.
```

기록 플로우 담당에게는 아래처럼 요청한다.

```text
AGENTS.md와 docs/design/DESIGN.md를 기준으로 features/ootd와 features/memory 안에서만 기록 플로우 UI를 만들어줘.
사진은 placeholder로 두고, ONMU의 다이어리/스티커/캐릭터 감성을 살려줘.
필요한 화면은 /ootd/new, /ootd/method, /ootd/photo, /ootd/description, /ootd/extra-info, /ootd/style, /ootd/props-mood, /ootd/analysis, /ootd/complete, /ootd/list, /memories/:memoryId, /memories/:memoryId/template-diary야.
완료 후 flutter analyze 결과와 변경 파일을 알려줘.
```
