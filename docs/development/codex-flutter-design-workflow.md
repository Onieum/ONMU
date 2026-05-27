# Codex Flutter 디자인 작업 참고 문서

이 문서는 Codex로 Flutter UI를 만들 때 참고할 수 있는 보조 가이드다. 저장소의 필수 지침이나 디자인 기준 문서는 아니며, 실제 디자인의 기준은 항상 `docs/design/DESIGN.md`를 따른다.

## 1. 현재 위치

ONMU는 Figma 의존 없이 Markdown 디자인 시스템과 Flutter 코드베이스를 기준으로 개발한다.

| 항목 | 기준 |
| --- | --- |
| 에이전트 공통 규칙 | `AGENTS.md` |
| Copilot 규칙 | `.github/copilot-instructions.md` |
| 디자인 시스템 | `docs/design/DESIGN.md` |
| 팀 AI 도구 운영 | `docs/development/team-ai-tooling.md` |
| Git/Jira workflow | `docs/development/git-workflow.md` |

이 문서는 위 문서들을 보조하는 참고 자료로만 사용한다. 다른 지침 파일에서 이 문서를 필수 선행 문서로 연결하지 않는다.

## 2. 검증된 방향

| 주제 | 판단 |
| --- | --- |
| `AGENTS.md` | Codex 계열 도구가 저장소 규칙을 빠르게 읽도록 유지한다. |
| `SKILL.md` | 반복 작업 절차를 고정하는 데 사용한다. 다만 실제 디자인 기준은 `DESIGN.md`로 둔다. |
| FlutterFlow | 프로토타입 확인용으로는 가능하지만, 최종 소스는 Flutter 코드베이스에서 관리한다. |
| Figma to Code | 현재 기본 workflow에서 제외한다. |
| Flutter Theme | `ThemeData`, `ColorScheme`, `TextTheme`, `ThemeExtension`을 사용한다. |
| 상태 관리 | 화면 draft, 서버 상태, 전역 상태는 Riverpod을 기본으로 설계한다. |

## 3. Codex에 화면 구현을 요청하는 방식

화면 구현 요청은 아래 순서로 한다.

1. `AGENTS.md`와 `docs/design/DESIGN.md`를 먼저 읽게 한다.
2. 대상 기능의 라우트, 입력 데이터, 저장 데이터, 예외 상태를 설명한다.
3. 사용할 공통 컴포넌트와 새로 만들 파일 계획을 먼저 말하게 한다.
4. 구현 후 `flutter analyze`와 관련 `flutter test`를 실행하게 한다.
5. 결과 요약에는 변경 파일과 검증 명령을 남긴다.

예시:

```text
AGENTS.md와 docs/design/DESIGN.md를 먼저 읽고,
/ootd/method 화면을 구현하기 위한 공통 컴포넌트와 파일 계획을 먼저 작성해줘.

반드시 지킬 것:
- DESIGN.md의 색상, 타이포그래피, 간격, 컴포넌트 기준 사용
- 하드코딩 색상 금지
- 공통 컴포넌트가 없으면 shared/widgets에 먼저 만들기
- Riverpod 상태는 화면 draft provider로 분리
- 구현 후 flutter analyze와 관련 widget test 실행
```

## 4. Flutter 코드 기준

디자인 시스템은 문서로만 두지 않고 코드 토큰으로 고정한다.

```text
mobile-flutter/lib/core/theme
├── app_colors.dart
├── app_spacing.dart
├── app_radius.dart
├── app_typography.dart
├── app_theme.dart
└── theme_extensions.dart
```

화면 코드에서는 아래 패턴을 피한다.

```dart
Container(color: Color(0xFFFFB7B7))
Text('다음', style: TextStyle(color: Colors.black))
```

대신 테마 토큰을 사용한다.

```dart
Container(color: Theme.of(context).colorScheme.primary)
Text('다음', style: Theme.of(context).textTheme.labelLarge)
```

## 5. 공통 컴포넌트 우선순위

화면마다 새 컴포넌트를 만들기보다 아래 컴포넌트를 우선 재사용한다.

| 컴포넌트 | 용도 |
| --- | --- |
| `OnmuScaffold` | 흰색 배경, SafeArea, 기본 page padding |
| `OnmuPrimaryButton` | 다음, 저장, 시작하기 같은 주요 CTA |
| `OnmuSecondaryButton` | 이전, 취소, 홈으로 가기 같은 보조 액션 |
| `OnmuIconButton` | 뒤로가기, 더보기, 편집, 업로드 |
| `OnmuCard` | 일반 카드 표면 |
| `OnmuSelectionTile` | 캐릭터 옵션, 취향 옵션, OOTD 옵션 |
| `OnmuChip` | 태그, 계절, 장소 유형 |
| `OnmuStepProgress` | 캐릭터/OOTD/약속 생성 단계 표시 |
| `PixelCharacterPreview` | 캐릭터 미리보기 |
| `OotdRecordCard` | OOTD 기록 카드 |
| `PlaceCandidateCard` | 장소 후보 카드 |
| `PlaceRiskDialog` | 휴무, 브레이크타임, 비선호 키워드 경고 |
| `PreferenceEditBottomSheet` | 취향 수정 바텀시트 |

## 6. 검증 루프

| 검증 | 명령/방법 | 목적 |
| --- | --- | --- |
| 정적 분석 | `flutter analyze` | 문법, lint, 잘못된 import 확인 |
| 단위/위젯 테스트 | `flutter test` | 컴포넌트 동작과 화면 렌더링 확인 |
| Golden test | `matchesGoldenFile` 또는 golden test 패키지 | 디자인 회귀 확인 |
| 이미지 확인 | 시뮬레이터/스크린샷 | 실제 모바일 비율에서 레이아웃 깨짐 확인 |
| 금지 패턴 검색 | `rg "Color\\(0x|Colors\\.|TextStyle\\(" mobile-flutter/lib` | 하드코딩 스타일 발견 |

금지 패턴 검색은 `app_colors.dart`, `app_typography.dart`, 테스트 파일처럼 의도적으로 스타일을 정의하는 파일은 예외로 본다.

## 7. 참고용 결론

현재 ONMU에 가장 맞는 조합은 다음과 같다.

```text
Codex
+ AGENTS.md
+ docs/design/DESIGN.md
+ docs/development/team-ai-tooling.md
+ Flutter ThemeData/ThemeExtension
+ Riverpod
+ go_router
+ Dio
+ freezed/json_serializable
+ widget/golden tests
```

이 문서는 위 조합을 설명하는 참고 자료일 뿐이며, 팀 공통 규칙은 `AGENTS.md`, 디자인 기준은 `docs/design/DESIGN.md`로 관리한다.
