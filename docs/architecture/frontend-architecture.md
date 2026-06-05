# ONMU Flutter 프론트 아키텍처

## 목적

이 문서는 Flutter 앱의 route, feature 구조, 상태 관리, mock data 전환 기준을 정리한다. 제품 용어는 `온모임`, `약속`을 사용하지만 운영 route와 API 리소스는 `groups`, `plans`, `records`를 우선한다.

## 현재 기준

| 영역 | 기준 |
| --- | --- |
| App framework | Flutter |
| Routing | `go_router`, `StatefulShellRoute.indexedStack` |
| State | Riverpod provider |
| Theme | `AppTheme`, `AppColors`, ONMU typography |
| Bottom tabs | 홈, 온모임, 기록, 마이 |
| Route contract | `RoutePaths` |
| Legacy URL | 별도 legacy redirect 파일 없이 필요한 경우 `app_router.dart`에 명시적으로 추가 |
| Demo seed | 실제 route helper에 넣지 않고 mock repository seed로만 관리 |

## Route 계층

```text
/splash
/login
/onboarding
/onboarding/preferences
/onboarding/character
/home
/home/upcoming-plans
/home/notifications
/home/recent-records
/groups
/groups/new
/groups/:groupId
/groups/:groupId/chat
/groups/:groupId/votes
/groups/:groupId/memories
/groups/:groupId/plans
/groups/:groupId/plans/:planId
/groups/:groupId/plans/:planId/place-candidates
/groups/:groupId/plans/:planId/place-search
/groups/:groupId/plans/:planId/itinerary
/groups/:groupId/plans/:planId/settlements/*
/records
/my
```

## Feature 구조

새 기능은 아래 구조를 기본으로 한다.

```text
lib/features/<feature>/
  view/
  view_model/
  model/
  repository/ 또는 service/
  widgets/
```

기존 feature가 아직 이 구조가 아니면, 새 화면이나 큰 변경 시점에 점진적으로 옮긴다.

## ViewModel 원칙

- View는 렌더링과 사용자 입력 전달만 담당한다.
- ViewModel은 화면 상태, loading/error, 유효성 검증, 사용자 액션 처리를 담당한다.
- API, local storage, DB 접근은 repository/service로 분리한다.
- ViewModel에 `BuildContext`를 저장하지 않는다.
- navigation, snackbar, dialog는 View 또는 UI event 패턴으로 처리한다.

## Mock to API 전환

Flutter repository가 호출하는 실제 서버는 Spring Boot Main API다. FastAPI Worker 결과는 Spring Boot API read model을 통해 전달받고, Flutter 앱에서 Worker를 직접 호출하지 않는다.

| 단계 | 작업 |
| --- | --- |
| 1 | 화면에서 직접 mock list를 읽는 부분을 repository provider로 감싼다. |
| 2 | mock repository와 API repository가 같은 interface를 쓰게 한다. |
| 3 | `RoutePaths`와 API DTO/read model을 맞춘다. |
| 4 | Flutter widget test는 mock repository로 유지한다. |
| 5 | API contract test로 서버 응답과 Flutter model을 검증한다. |

## 테스트 기준

- route helper는 `route_paths_test.dart`에서 legacy/demo segment가 섞이지 않는지 확인한다.
- 주요 CTA는 widget test로 실제 route 이동까지 확인한다.
- iPhone 17 viewport `402 x 874`에서 깨짐 smoke를 반복한다.
