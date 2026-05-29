# ONMU 모바일 프로토타입 폴더 구조

이 문서는 주말 프로토타입 작업자가 수정 범위를 빠르게 확인하기 위한 폴더 구조 전용 문서다. 전체 작업 계획과 라우트 기준은 `docs/development/mobile-prototype-weekend-plan.md`를 따른다.

## 수정 원칙

- 각 담당자는 자기 feature 폴더 안에서만 화면을 만든다.
- 공통 위젯, 공통 모델, 라우팅, 테마를 수정해야 하면 팀에 먼저 공유한다.
- 실제 API, DB, 인증, 추천 로직은 붙이지 않고 mock data로 화면 흐름만 연결한다.
- 비어 있는 폴더는 Git 추적을 위해 `.gitkeep`을 둔다. 실제 Dart 파일이 추가된 폴더에서는 필요하면 `.gitkeep`을 삭제해도 된다.

## 폴더 구조

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
    │   └── presentation
    │       └── pages
    ├── character
    │   └── presentation
    │       └── pages
    ├── preferences
    │   └── presentation
    │       ├── pages
    │       └── widgets
    ├── home
    │   └── presentation
    │       └── pages
    ├── meetup
    │   └── presentation
    │       ├── pages
    │       └── widgets
    ├── place
    │   └── presentation
    │       ├── pages
    │       └── widgets
    ├── onchat
    │   └── presentation
    │       ├── pages
    │       └── widgets
    ├── ootd
    │   └── presentation
    │       ├── pages
    │       └── widgets
    ├── memory
    │   └── presentation
    │       ├── pages
    │       └── widgets
    └── my
        └── presentation
            ├── pages
            └── widgets
```

## 담당별 수정 위치

| 담당 | 수정 위치 |
| --- | --- |
| 시작/스플래시 | `features/launch` |
| 캐릭터 생성 | `features/character` |
| 취향 입력/수정 | `features/preferences` |
| 홈 | `features/home` |
| 약속 생성/상세 | `features/meetup` |
| 장소 추천/검색/리스크 | `features/place` |
| 온챗/정산 | `features/onchat` |
| OOTD 기록 | `features/ootd` |
| 기억 상세/템플릿 | `features/memory` |
| 마이 ONMU | `features/my` |

## 공통 영역

| 영역 | 수정 기준 |
| --- | --- |
| `core/routing` | route 추가나 shell 구조 변경 시 수정 |
| `core/theme` | 색상, 간격, 반경, typography token 수정 시 사용 |
| `shared/models` | 여러 feature가 같이 쓰는 mock model만 추가 |
| `shared/widgets` | 2개 이상 feature에서 재사용할 UI만 추가 |
