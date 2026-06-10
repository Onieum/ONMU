# ONMU API Contract Map

## 목적

프론트 화면이 요구하는 API와 read model을 화면 단위로 정리한다. Flutter 앱이 직접 호출하는 공개 API는 Spring Boot Main API가 제공하고, FastAPI Worker는 Spring Boot 뒤에서 AI/Data 작업을 처리한다.

## 공통 원칙

- API prefix는 `/api/v1`를 사용한다.
- Flutter 앱은 Spring Boot Main API만 직접 호출한다.
- FastAPI Worker는 모바일 앱에서 직접 호출하지 않고, Spring Boot가 내부 작업 요청과 결과 반영을 관리한다.
- 현재 Node smoke API의 `/healthz`, `/readyz`는 개발 서버 연결 검증용 계약이며, 제품 도메인 API 계약으로 보지 않는다.
- UI 용어가 `온모임`, `약속`이어도 API 리소스는 `groups`, `plans`를 우선한다.
- 정산은 반드시 `groups/{groupId}/plans/{planId}` 하위에 둔다.
- 장소 후보(`place-candidates`)와 일정 등록 장소(`schedule places`)를 분리한다.
- 채팅/알림은 domain action의 side effect를 activity event로 받는다.
- 첫 OAuth provider는 Naver를 우선 구현한다.
- 인증은 access token + refresh token 방식을 사용하고 Flutter는 secure storage에 보관한다.
- Worker 작업은 queue/outbox로 연결한다.

## Auth / User

| 화면 | API |
| --- | --- |
| 로그인 | `POST /api/v1/auth/oauth/{provider}` |
| Naver 로그인 | `POST /api/v1/auth/oauth/naver` |
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
| 참여자 목록 | `GET /api/v1/groups/{groupId}/plans/{planId}/participants` |
| 내 참여 응답 변경 | `PUT/PATCH /api/v1/groups/{groupId}/plans/{planId}/participants/me` |

## Place

| 화면 | API |
| --- | --- |
| 후보 리스트 | `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates` |
| 후보 추가 | `POST /api/v1/groups/{groupId}/plans/{planId}/place-candidates` |
| 후보 상세 | `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}` |
| 내 후보 하트 설정 | `PUT /api/v1/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}/heart` |
| 장소 검색 | `POST /api/v1/place-search` |
| 일정에 장소 등록 | `POST /api/v1/groups/{groupId}/plans/{planId}/schedule-places` |
| 일정 등록 장소 목록 | `GET /api/v1/groups/{groupId}/plans/{planId}/schedule-places` |

장소 검색은 취향, 태그, 참여자 선호, 지도 bounds, 날짜/시간 조건이 함께 들어올 수 있으므로 `POST /api/v1/place-search`를 canonical로 둔다. 단순 `GET /api/v1/place-search?query=...`는 dev stub 또는 호환용으로만 둘 수 있다.

장소 후보 응답은 목록/추가/상세에서 `id`, `name`, `category`, `address`, `source`, `lat`, `lng`, `heartCount`, `myHearted`, `createdAt`을 가능한 범위에서 포함한다. `PUT .../heart`는 body의 `hearted`가 `true` 또는 생략이면 내 하트를 켜고, `false`면 내 하트를 끈다. 같은 사용자가 같은 후보에 여러 번 하트를 켜도 중복 row를 만들지 않는다.

일정 등록 장소 생성은 `candidateId` 기반 등록과 직접 장소명 등록을 모두 허용한다. 응답은 일정 등록 장소 id, 후보 id, 장소명, 시작/종료 시각, 메모를 포함한다.

## Votes

| 화면 | API |
| --- | --- |
| 투표 만들기 | `POST /api/v1/groups/{groupId}/votes` |
| 투표 목록 | `GET /api/v1/groups/{groupId}/votes` |
| 투표 상세 | `GET /api/v1/groups/{groupId}/votes/{voteId}` |

투표는 모임 전체 자체 생성 리소스로 둔다. 장소/일정/정산/준비물/일반 투표를 모두 `Vote`로 표현하고, 약속 관련 투표는 `targetType`, `targetId`, `voteType`으로 연결한다.

```json
{
  "voteType": "PLACE",
  "targetType": "PLAN",
  "targetId": "101",
  "title": "제주도 여행 장소 투표",
  "placeCandidateIds": ["201", "202"]
}
```

장소 후보 기반 투표는 `targetType=PLAN`, `targetId=<planId>`, `voteType=PLACE` 조합을 기준으로 연결한다. 요청은 기존 `options: ["카페", "식당"]` 문자열 방식을 계속 허용하고, 후보 기반 생성에는 `placeCandidateIds`를 우선 사용한다. 호환을 위해 `options`에 후보 public id 문자열만 들어온 경우에도 후보 option으로 연결할 수 있다.

투표 목록/상세의 `options`는 문자열 fallback을 유지하되, 후보 option이면 다음 필드를 포함한 object를 반환한다.

```json
{
  "label": "온무식당",
  "targetType": "PLACE_CANDIDATE",
  "targetId": "201",
  "candidateId": "201",
  "candidateName": "온무식당",
  "address": "서울",
  "heartCount": 3,
  "responseCount": 0,
  "countLabel": "0표",
  "progress": 0
}
```

`POST /api/v1/groups/{groupId}/plans/{planId}/votes`는 canonical로 사용하지 않는다. 필요한 경우 기존 Flutter 화면 전환을 위한 alias 또는 compatibility route로만 검토한다.

## Settlement

| 화면 | API |
| --- | --- |
| 정산 draft | `GET/PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft` |
| 대상자 선택 | `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft/items/{itemId}/targets` |
| 미리보기 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/preview` |
| 최종 생성 | `POST /api/v1/groups/{groupId}/plans/{planId}/settlements` |
| 최신 결과 보기 | `GET /api/v1/groups/{groupId}/plans/{planId}/settlements` |
| 결과 보기 | `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}` |

Spring Boot Main API는 정산 draft/result 응답을 `settlement_drafts`, `settlements`의 `payload`만으로 만들지 않고 `settlement_items`, `settlement_item_targets`, `settlement_transfers` read/write 결과를 우선 사용한다. `payload`는 payer user id 같은 표시/계산 보조 필드와 이전 Flutter mock contract 호환을 위한 compact 백업으로 유지한다.

정산 create/preview/update 요청은 `payerUserId`, `targetUserIds` 같은 안정적인 사용자 public id를 우선 사용한다. `payerName`, `targetNames`는 dev seed와 기존 mock 호환용 fallback이며, 이름이 중복되면 API는 조용히 오배정하지 않고 `400 ambiguous_settlement_member_name`을 반환한다. 금액 필드는 `amountWon`을 권장하고, 과거 `amount`는 호환용으로 허용한다. 현재 DB 컬럼명은 `amount_cents`지만 ONMU 정산 API에서는 KRW 원 단위 integer를 저장한다.

`GET /settlement-draft`는 저장되지 않은 synthetic draft를 만들 수 있으며 이때 `persisted=false`, `targetPatchAvailable=false`를 반환한다. 항목별 target PATCH는 `PATCH /settlement-draft`로 저장된 draft/item이 생긴 뒤에만 가능하다.

## Activity / Notification

| 이벤트 | 발생 조건 |
| --- | --- |
| `plan.created` | 약속 생성 |
| `place_candidate.created` | 장소 후보 추가 |
| `place_candidate.heart_updated` | 장소 후보 하트 변경 |
| `vote.created` | 투표 생성 |
| `vote.closed` | 투표 종료 |
| `settlement.created` | 정산 최종 생성 |
| `record.created` | 기록 작성 |
| `ai.summary.requested` | AI 요약/추천 설명 작업 요청 |
| `notification.requested` | 알림 발송 요청 |
| `media.thumbnail.requested` | 미디어 후처리 요청 |

Spring Boot는 domain transaction과 함께 `outbox_events`에 이벤트를 기록한다. `ai.summary.requested`는 `services/workers/ai-data-worker`가 소비하고, 아직 구현하지 않은 notification/media worker 이벤트는 `no_consumer` 또는 `skipped_dev` 상태로 남길 수 있다.
