# ONMU API Contract Map

## 목적

프론트 화면이 요구하는 API와 read model을 화면 단위로 정리한다. 실제 서버 기술스택이 Spring Boot든 FastAPI든 이 계약은 먼저 맞춘다.

## 공통 원칙

- API prefix는 `/api/v1`를 사용한다.
- UI 용어가 `온모임`, `약속`이어도 API 리소스는 `groups`, `plans`를 우선한다.
- 정산은 반드시 `plans/{planId}` 하위에 둔다.
- 장소 후보(`place-candidates`)와 일정 등록 장소(`schedule places`)를 분리한다.
- 채팅/알림은 domain action의 side effect를 activity event로 받는다.

## Auth / User

| 화면 | API |
| --- | --- |
| 로그인 | `POST /api/v1/auth/oauth/{provider}` |
| session 확인 | `GET /api/v1/auth/session` |
| refresh | `POST /api/v1/auth/refresh` |
| logout | `DELETE /api/v1/auth/session` |
| 내 정보 | `GET /api/v1/users/me` |

## Home

| 화면 | API | Read model |
| --- | --- | --- |
| 홈 | `GET /api/v1/home/summary` | `HomeSummary` |
| 다가오는 약속 | `GET /api/v1/users/me/plans?status=upcoming` | `UpcomingPlanCard` |
| 알림 | `GET /api/v1/notifications` | `NotificationItem` |
| 최근 기록 | `GET /api/v1/users/me/records/recent` | `RecordCard` |

## Groups

| 화면 | API |
| --- | --- |
| 모임 목록 | `GET /api/v1/groups` |
| 모임 만들기 | `POST /api/v1/groups` |
| 모임 홈 | `GET /api/v1/groups/{groupId}/summary` |
| 멤버 목록 | `GET /api/v1/groups/{groupId}/members` |
| 모임 설정 | `GET/PATCH /api/v1/groups/{groupId}` |
| 모임 나가기 | `DELETE /api/v1/groups/{groupId}/members/me` |

## Plans

| 화면 | API |
| --- | --- |
| 약속 목록 | `GET /api/v1/groups/{groupId}/plans` |
| 약속 만들기 | `POST /api/v1/groups/{groupId}/plans` |
| 약속 상세 | `GET /api/v1/groups/{groupId}/plans/{planId}` |
| 약속 수정 | `PATCH /api/v1/groups/{groupId}/plans/{planId}` |
| 참여자 변경 | `POST/DELETE /api/v1/groups/{groupId}/plans/{planId}/participants` |

## Place / Vote

| 화면 | API |
| --- | --- |
| 후보 리스트 | `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates` |
| 후보 추가 | `POST /api/v1/groups/{groupId}/plans/{planId}/place-candidates` |
| 장소 검색 | `GET /api/v1/place-search?query=...` 또는 복합 조건이면 `POST /api/v1/place-search` |
| 일정에 장소 등록 | `POST /api/v1/groups/{groupId}/plans/{planId}/schedule-places` |
| 투표 만들기 | `POST /api/v1/groups/{groupId}/plans/{planId}/votes` |
| 투표 목록 | `GET /api/v1/groups/{groupId}/votes` |
| 투표 상세 | `GET /api/v1/groups/{groupId}/votes/{voteId}` |

## Settlement

| 화면 | API |
| --- | --- |
| 정산 draft | `GET/PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft` |
| 대상자 선택 | `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft/items/{itemId}/targets` |
| 미리보기 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/preview` |
| 최종 생성 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements` |
| 결과 보기 | `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}` |

## Activity / Notification

| 이벤트 | 발생 조건 |
| --- | --- |
| `PLAN_CREATED` | 약속 생성 |
| `PLACE_CANDIDATES_UPDATED` | 장소 후보 추가 |
| `VOTE_CREATED` | 투표 생성 |
| `VOTE_CLOSED` | 투표 종료 |
| `SETTLEMENT_CREATED` | 정산 최종 생성 |
| `RECORD_CREATED` | 기록 작성 |
