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

## 오류 처리와 관측성

Flutter API 오류는 `OnmuApiClient`에서 `OnmuApiException`으로 정규화한다. ViewModel과 repository는 raw `DioException`에 직접 의존하지 않고, `OnmuErrorKind`를 기준으로 사용자 상태와 보고 정책을 나눈다.

| 범주 | 대표 상황 | 사용자 처리 | 보고 정책 |
| --- | --- | --- | --- |
| `validation`, `conflict`, `notFound`, `forbidden` | 입력 오류, 이미 처리됨, 삭제됨, 예상 권한 오류 | inline 또는 snackbar | 기본 보고하지 않음 |
| `unauthorized` | 세션 없음 또는 만료 | 로그인 흐름 전환 | bootstrap의 정상 401은 보고하지 않음 |
| `server`, `unavailable`, `unknown` | 5xx, 장애, 알 수 없는 실패 | retryable card 또는 snackbar | 보고 |
| `timeout`, `network`, `rateLimited` | 시간 초과, 네트워크, 요청 제한 | 재시도 안내 | 필요 시 샘플링 보고 |
| `contractMismatch` | 필수 JSON 필드 누락, enum 불일치 | fallback 또는 오류 UI | 반드시 보고 |
| `backgroundSync` | push token, 채팅 읽음 동기화, 보조 카드 로딩 | 화면 유지 | reportable일 때만 보고 |

보고 경계는 `core/observability/OnmuErrorReporter`로 감싼다. `SENTRY_DSN` dart-define이 있으면 `SentryOnmuErrorReporter`가 정책에 맞는 오류만 Sentry로 직접 전송하고, DSN이 없으면 `FlutterError.reportError` 기반 local reporter로 동작한다. Sentry DSN은 Key Vault secret `sentry-dsn`에서 git ignored `.dart_tool/*.defines.json` 또는 CI secret으로만 주입한다. 로컬 실행에서도 `--dart-define=SENTRY_DSN=...` inline 주입은 shell history와 process args 노출 위험이 있으므로 쓰지 않는다.

iOS 시뮬레이터 smoke 기준 Sentry Flutter SDK는 `sentry_flutter` 9.x 이상을 사용한다. 8.x 계열은 최신 Xcode/iOS simulator 조합에서 iOS plugin compile error가 날 수 있으므로, iOS 26.2 이상 smoke가 필요한 브랜치에서는 9.x lockfile을 유지한다.

Sentry 오류 이벤트 샘플링은 `OnmuReportPolicy.sampleRateFor`를 기준으로 한다. `server`, `unavailable`, `contractMismatch`, `unknown`은 1.0으로 전부 보고한다. `timeout`, `rateLimited`는 반복 노이즈를 줄이기 위해 0.2로 보고한다. `network`는 사용자 네트워크 환경 영향이 커서 0.05로 낮게 보고한다. validation, conflict, notFound, forbidden 같은 예상 가능한 사용자/권한 흐름은 0으로 보고하지 않는다.

Sentry tag로 보낼 수 있는 값은 `feature`, `kind`, `statusCode`, `method`, `endpoint_template`, `retryable`, `environment`처럼 안전한 메타데이터뿐이다. JWT, Authorization header, request/response body, nickname, email, 채팅/메모/기록 원문은 보고 필드에 넣지 않는다.

## Settlement

정산 화면은 Spring Boot Main API의 `groups/{groupId}/plans/{planId}` 하위 contract만 호출한다. Flutter는 입력 전달과 UI 상태 전환을 담당하고, 정산 계산과 원장 저장은 서버 응답을 source of truth로 사용한다.

| 화면/액션 | API |
| --- | --- |
| 정산 draft 생성/조회 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlement-draft` |
| 정산 draft 조회 | `GET /api/v1/groups/{groupId}/plans/{planId}/settlement-draft` |
| 정산 draft 저장 | `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft` |
| 대상자 선택 | `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft/items/{itemId}/targets` |
| 미리보기 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/preview` |
| 정산 확정 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements` |
| 현재 정산 보기 | `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/current` |
| 결과 보기 | `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}` |
| 정산 근거 | `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}/basis` |
| 송금 완료 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}/transfers/{transferId}/sent` |
| 수취 완료 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}/transfers/{transferId}/received` |

정산 요청은 `sections[].payerUserId`, `items[].targetUserIds`, `amountWon`을 canonical로 사용한다. 이름은 표시용 응답 필드로만 다루며 사용자 resolve fallback으로 쓰지 않는다.

정산 오류는 공통 `OnmuApiException`으로 매핑한다. `settlement_plan_not_eligible`, `active_settlement_exists`, `settlement_write_conflict`, `invalid_settlement_amount`, `missing_settlement_targets`, `settlement_confirmation_forbidden` 같은 400/409 계열은 snackbar 또는 inline 안내 중심으로 처리하고 기본 Sentry 보고 대상에서 제외한다. 5xx, `contractMismatch`, `unknown`은 `feature=settlement` tag로 보고한다.

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
