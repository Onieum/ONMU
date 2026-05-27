# Flutter Screen Implementation Skill

## 언제 사용하나

ONMU의 특정 라우트, 기능 요구사항, 또는 화면 설명을 Flutter 화면으로 구현할 때 사용한다.

예시:

- `/ootd/method` 화면 구현
- `/character/skin-tone` 화면 구현
- `PlaceRiskDialog.keyword` 컴포넌트 구현
- `PreferenceEditBottomSheet.times` 바텀시트 구현

## 반드시 먼저 읽을 문서

1. `AGENTS.md`
2. `docs/design/DESIGN.md`
3. `docs/development/team-ai-tooling.md`
4. 관련 Jira 이슈 또는 기능 요구사항 문서

## 작업 순서

1. 대상 라우트, 사용자 흐름, 입력/출력 데이터를 확인한다.
2. 필요한 공통 컴포넌트를 먼저 나열한다.
3. 새 파일과 수정 파일 계획을 작성한다.
4. 기존 `shared/widgets` 컴포넌트를 우선 사용한다.
5. 없으면 재사용 가능한 공통 컴포넌트를 먼저 만든다.
6. feature page를 만든다.
7. Riverpod provider/state가 필요하면 presentation/application/data 경계를 나눠 만든다.
8. `flutter analyze`와 관련 widget test를 실행한다.
9. 결과 요약에 변경 파일과 검증 명령을 남긴다.

## 디자인 규칙

- 스크린샷을 배경 이미지로 붙여서 UI를 끝내지 않는다.
- 텍스트, 버튼, 카드, 입력 필드, 아이콘은 수정 가능한 Flutter widget으로 만든다.
- 화면 코드에서 `Color(0x...)`, `Colors.*`, 직접 `TextStyle(...)`을 반복하지 않는다.
- 간격은 8px 단위 토큰을 우선한다.
- 버튼, 카드, 입력, 선택 타일은 8px radius를 기준으로 한다.

## 파일 배치 기준

```text
mobile-flutter/lib
├── core
│   ├── theme
│   ├── routing
│   └── network
├── features
│   └── <feature>
│       ├── application
│       ├── data
│       ├── domain
│       └── presentation
│           ├── pages
│           └── widgets
└── shared
    └── widgets
```

## 완료 기준

- 요구사항의 화면 의도와 사용자 흐름이 Flutter 화면에 반영되어 있다.
- 공통 디자인 토큰을 사용한다.
- iPhone 17 계열 세로 화면에서 텍스트가 넘치지 않는다.
- 관련 test 또는 최소한 `flutter analyze`를 통과한다.
