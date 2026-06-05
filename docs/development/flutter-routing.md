# Flutter Routing 운영 규칙

## 기준 파일

| 파일 | 역할 |
| --- | --- |
| `lib/core/routing/route_paths.dart` | 운영 route helper |
| `lib/core/routing/app_router.dart` | 실제 `GoRouter` route tree |
| `lib/core/routing/navigation_extensions.dart` | 뒤로가기 fallback, route 이동 보조 |
| `lib/main.dart` | path URL strategy 설정과 `OnmuApp` 실행 |

## Naming

| UI 용어 | Route/API 이름 |
| --- | --- |
| 온모임 | `groups` |
| 약속 | `plans` |
| 기록 | `records` |
| 장소 후보 | `place-candidates` |
| 동선 | `itinerary` |

## 규칙

- 새 화면 route는 먼저 `RoutePaths`에 추가한다.
- `RoutePaths` helper를 추가하면 실제 `GoRoute`도 함께 추가한다.
- demo id를 `RoutePaths`에 넣지 않는다.
- 기존 URL 호환이 꼭 필요하면 `app_router.dart`에 명시적 redirect route를 추가하고 테스트를 남긴다.
- query parameter로 상태를 표현하기보다 명확한 route를 우선한다.
- route 변경 시 `route_paths_test.dart`와 관련 widget test를 갱신한다.

## 확인 체크리스트

- `/onmoim`, `/meetups`, `/ootd/list`, `/memories` 같은 legacy segment가 새 helper에 남아 있지 않은가?
- `friends`, `demo`, `lunch-split` 같은 demo seed가 helper에 남아 있지 않은가?
- helper는 있는데 실제 `GoRoute`가 없는 route가 없는가?
- legacy redirect를 추가했다면 target route로 정상 이동하는가?
