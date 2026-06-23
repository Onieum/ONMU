# ONMU API Contract Map

## 목적

프론트 화면이 요구하는 API와 read model을 화면 단위로 정리한다. Flutter 앱이 직접 호출하는 공개 API는 Spring Boot Main API가 제공하고, FastAPI Worker는 Spring Boot 뒤에서 AI/Data 작업을 처리한다.

## 공통 원칙

- API prefix는 `/api/v1`를 사용한다.
- Flutter 앱은 Spring Boot Main API만 직접 호출한다.
- FastAPI Worker는 모바일 앱에서 직접 호출하지 않고, Spring Boot가 내부 작업 요청과 결과 반영을 관리한다.
- `/healthz`, `/readyz`는 Spring Boot Main API의 개발 서버 연결 검증용 계약이며, 제품 도메인 API 계약으로 보지 않는다.
- UI 용어가 `온모임`, `약속`이어도 API 리소스는 `groups`, `plans`를 우선한다.
- 정산은 반드시 `groups/{groupId}/plans/{planId}` 하위에 둔다.
- 장소 후보(`place-candidates`)와 일정 등록 장소(`schedule places`)를 분리한다.
- 채팅/알림은 domain action의 side effect를 activity event로 받는다.
- 첫 OAuth provider는 Naver를 우선 구현한다.
- 인증은 access token + refresh token 방식을 사용하고 Flutter는 secure storage에 보관한다.
- Worker 작업은 queue/outbox로 연결한다.
- Notification / Push / Devices의 상세 Current-to-Target 경계는 [Notification / Push / Devices 아키텍처](./notification-push-devices-architecture.md)를 따른다.

## Auth / User

Auth / Session / OAuth와 User / Profile / Character / Friends의 상세 Current-to-Target 경계는 [Auth / User / Profile 아키텍처](./auth-user-profile-architecture.md)를 따른다.

| 화면 | API |
| --- | --- |
| 로그인 | `POST /api/v1/auth/oauth/{provider}` |
| Naver 로그인 | `POST /api/v1/auth/oauth/naver` |
| session 확인 | `GET /api/v1/auth/session` |
| refresh | `POST /api/v1/auth/refresh` |
| logout | `DELETE /api/v1/auth/session` |
| 내 정보 | `GET /api/v1/users/me` |
| 내 정보 수정 | `PATCH /api/v1/users/me` |
| 내 캐릭터 조회/저장 | `GET/PUT /api/v1/users/me/character` |
| Push token 등록 | `POST /api/v1/devices/push-token` |
| Push token 비활성화 | `DELETE /api/v1/devices/push-token` |

`GET /api/v1/users/me`는 현재 사용자 private profile surface다. 응답은 `id`, `databaseId`, `nickname`, `email`, `profileImageUrl`, `preferenceProfile`, `pixelCharacter`, `onboardingStatus`, `authProvider`, `authStatus`, `tokenContract`, `userCode`를 포함할 수 있다. `userCode`는 현재 숫자 10자리 active code 형식을 기준으로 한다. `PATCH /api/v1/users/me`는 authenticated principal의 사용자만 수정하며, 표시 이름은 `nickname`으로만 저장한다. 취향/지역/지역 공개 범위는 `preferenceProfile` 안에 저장한다. 지역 설정은 현재 온보딩 완료 조건에 포함하지 않는다. 친구 상세 또는 공개 프로필은 `regionVisibility`와 viewer 권한에 맞춰 지역 field를 제한해야 한다.

Push token API는 로그인된 현재 사용자 기기만 대상으로 한다. 요청 body의 `provider`는 `fcm`, `apns`, `dev` 중 하나이며, `token`은 URL query가 아니라 JSON body로만 전달한다. 응답은 `deviceId`, `provider`, `platform`, `status`, `registered`, `tokenLast4`, `updatedAt`만 반환하고 token 원문은 반환하지 않는다. 현재 Flutter token source는 실제 FCM/APNs provider와 연결되지 않은 dev-safe readiness 경계일 수 있으며, 실제 provider token source와 provider delivery는 별도 보안/인프라 slice에서 켠다. 실제 FCM/APNs provider secret과 JWT signing secret은 모바일 bundle에 넣지 않는다.

## Friends

세부 Current-to-Target 기준은 [User/Profile/Character/Friends 아키텍처](./user-profile-character-friends-architecture.md)를 따른다.

| 화면 | API | Read model |
| --- | --- | --- |
| 마이페이지 친구 목록 | `GET /api/v1/users/me/friends` | `FriendResponse[]` |
| 친구 상세 프로필 | `GET /api/v1/users/me/friends/{friendUserId}/profile` | `UserProfile` |
| 친구 코드/이름 검색 | `GET /api/v1/users/search?query={query}` | `FriendResponse[]` |
| 친구 추가 | `POST /api/v1/users/me/friends` | `FriendResponse` |
| 친구 메모/즐겨찾기 수정 | `PATCH /api/v1/users/me/friends/{friendUserId}` | `FriendResponse` |
| 친구 삭제 | `DELETE /api/v1/users/me/friends/{friendUserId}` | `204 No Content` |

친구 관계 원장은 `friendships(user_low_id, user_high_id)` canonical pair를 사용한다. 요청 방향은 `friend_requests`가 필요할 때 보존하고, MVP 친구 추가 API는 관계를 바로 `active`로 만든다. 사용자별 메모, 숨김, 즐겨찾기는 `friend_settings(friendship_id, user_id)` 기준으로 관리한다.
친구 상세 프로필은 active friendship을 확인한 뒤 상대 사용자의 `users.preference_profile`, `users.pixel_character`, 기본 표시 정보를 반환한다. 이메일, 인증 provider, token contract 같은 내 계정 전용 필드는 포함하지 않는다. 친구 관계가 아니거나 숨김/삭제된 관계면 `404 friend_not_found`를 반환한다.
## Home

홈/약속/투표의 Current-to-Target 경계는 [ONMU 홈 / 약속 / 투표 아키텍처](./home-plans-vote-architecture.md)를 따른다.

| 화면 | API | Read model |
| --- | --- | --- |
| 홈 | `GET /api/v1/home/summary` | `HomeSummary` |
| 다가오는 약속 | `GET /api/v1/users/me/plans?status=upcoming` | `UpcomingPlanCard` |
| 알림 | `GET /api/v1/notifications` | `NotificationItem[]` |
| 알림 unread count | `GET /api/v1/notifications/unread-count` | `{ "unreadCount": 0 }` |
| 알림 단건 읽음 | `PUT /api/v1/notifications/{notificationId}/read` | `NotificationItem` |
| 알림 전체 읽음 | `PUT /api/v1/notifications/read-all` | `{ "updatedCount": 0 }` |
| 알림 설정 | `GET/PUT /api/v1/notification-preferences` | `NotificationPreferences` |
| 최근 기록 | `GET /api/v1/users/me/records/recent` | `RecordCard` |

목표 구조에서 Flutter 홈은 `GET /api/v1/home/summary`를 canonical read model로 소비한다. 현재 dev Flutter는 아직 groups/plans API 조합으로 오늘/다가오는 약속을 계산하는 fallback 구조이므로, Azure smoke에서는 서버 `HomeSummary` 응답과 앱 소비 경로를 분리해서 보고한다.

알림은 현재 사용자 inbox만 반환하며, 단건/전체 읽음 처리는 `notifications.read_at`과 `status=read`를 갱신한다. 다른 사용자의 알림 id를 읽음 처리하려고 하면 `404 notification_not_found`로 응답한다. 알림 설정은 `(notificationType, channel)` 단위로 저장하며 기본 타입은 `chat_message`, `plan_reminder`, `vote_created`, `settlement_requested`, `record_created`, 기본 채널은 `in_app`, `push`다. 정산 확정 알림은 canonical type `settlement_requested`를 사용하고, `settlement_requested/in_app=false`이면 inbox notification row와 push 대상 `notification.requested` 이벤트를 만들지 않는다. `notification.requested` outbox 이벤트는 dev-safe push abstraction으로 소비하고, 실제 FCM/APNs push delivery는 별도 보안/인프라 slice로 분리한다. Provider delivery로 이어질 `notification.requested` payload는 `notificationId`를 포함해야 한다. `notificationId`가 없거나 aggregate가 `notification`이 아니면 현재 delivery service는 dev-safe skip으로 처리할 수 있다. Push token 등록/비활성화는 `user_devices`에 연결되지만, 실제 provider delivery는 feature flag와 secret 검증 전까지 켜지 않는다.

Provider delivery 대상 `notification.requested` payload는 실제 `notifications.id` UUID인 `notificationId`, `notificationType`, `channels`를 포함해야 한다. `groupId`, `planId`, `voteId`, `settlementId`, `recordId` 같은 public id는 화면 이동용 보조 payload로 둔다. `channel=activity`처럼 ChatActivity 공유나 inbox 생성만 의미하는 이벤트는 실제 push provider delivery 대상과 분리한다. Flutter 앱은 Event Hubs, Notification Worker internal endpoint, FCM/APNs provider API, Key Vault를 직접 호출하지 않는다.

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

약속 참여자와 홈 read model의 목표 구조는 [ONMU 홈 / 약속 / 투표 아키텍처](./home-plans-vote-architecture.md)를 따른다.

| 화면 | API |
| --- | --- |
| 약속 목록 | `GET /api/v1/groups/{groupId}/plans` |
| 약속 만들기 | `POST /api/v1/groups/{groupId}/plans` |
| 약속 상세 | `GET /api/v1/groups/{groupId}/plans/{planId}` |
| 약속 수정 | `PATCH /api/v1/groups/{groupId}/plans/{planId}` |
| 참여자 목록 | `GET /api/v1/groups/{groupId}/plans/{planId}/participants` |
| 참여자 추가 | `POST /api/v1/groups/{groupId}/plans/{planId}/participants` |
| 내 참여 응답 변경 | `PUT/PATCH /api/v1/groups/{groupId}/plans/{planId}/participants/me` |
| 생성 후보 보강 | `GET /api/v1/groups/{groupId}/plans/participant-candidates?userIds=<db-user-uuid>` |

약속 생성 요청은 `participantUserIds`로 초기 참여자 public id 목록을 전달할 수 있다. 서버는 생성자를 항상 참여자로 포함하고, 추가 참여자는 해당 모임의 멤버인 경우에만 허용한다.

약속 참여자 추가는 모임 멤버가 같은 모임 안의 다른 멤버를 약속에 추가하는 흐름을 지원한다. 요청 body는 `userId`를 사용한다. 약속 나가기 또는 내 참여 취소는 본인만 수행할 수 있으며, 타인의 참여 취소는 이 계약에 포함하지 않는다.

`GET /api/v1/groups/{groupId}/members`는 모임원 목록/초대 화면용 lightweight 계약이다. 약속에 참여하지 않을 수 있는 모임원 전체의 `preferenceProfile`을 이 응답에서 미리 싣지 않는다. 약속 생성 화면에서 사용자가 실제 참여 후보로 선택한 멤버의 선호/비선호 시간을 추천과 저장 경고에 쓰려면 `GET /api/v1/groups/{groupId}/plans/participant-candidates`를 `userIds` query로 호출한다. 서버는 요청자와 대상 userId가 모두 같은 모임 멤버인지 확인한 뒤 `userId`, `nickname`, `profileImageUrl`, `preferenceProfile`을 반환한다.

약속 날짜 추천 UX는 단일 날짜와 다중 날짜 범위를 분리한다. 시작/종료 날짜가 같은 경우 `추천 날짜` 칩은 선택 가능한 날짜 후보로 동작한다. 시작/종료 날짜가 다른 경우 추천 날짜는 `선택 범위의 추천 방문일`로 표시하며, 이미 선택된 범위 안에서 실제 방문 가능성이 높은 날짜를 읽기 전용으로 보여 준다. 시간 추천은 다중 범위에서도 시작 날짜 기준으로 계산하고, 날짜별 상세 방문 시간은 일정 장소/동선 단계에서 별도로 다룬다.

추천 계산은 약속에 실제 참여할 멤버의 `preferenceProfile`만 사용한다. `preferredWeekdays`가 겹치는 날짜와 `preferredTimes`가 겹치는 시간대를 우선 제안하되, `unavailableDates`와 겹치는 참여자가 있어도 후보에서 제외하지 않는다. 대신 날짜/시간 후보에 `OO님이 불가능해요`, `OO님 외 N명이 불가능해요`처럼 충돌 사유를 표시한다. 선호 데이터가 없어 기본 시간대를 보여줄 때의 상태 라벨은 `제안`이다.

약속 상태 contract는 `scheduled`, `active`, `completed`, `cancelled` 네 값만 허용한다. 새 약속의 기본 상태는 `scheduled`이며 표시명은 `예정`이다. 일반 약속 수정은 명시적인 상태 변경 action이 아닌 한 status를 보내지 않고 일정/장소/메모만 갱신한다. 서버는 허용되지 않은 status 입력을 `400 invalid_plan_status`로 거절하고, DB는 같은 허용 목록 check constraint를 가진다.

## Place

| 화면 | API |
| --- | --- |
| 후보 리스트 | `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates` |
| 후보 추가 | `POST /api/v1/groups/{groupId}/plans/{planId}/place-candidates` |
| 후보 상세 | `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}` |
| 내 후보 하트 설정 | `PUT /api/v1/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}/heart` |
| 장소 검색 | `POST /api/v1/place-search` |
| 장소 대표 이미지 공개 proxy | `GET /api/v1/place-images/public` |
| 지도 catalog points/clusters | `POST /api/v1/map-points` |
| 동선 추천 | `POST /api/v1/routes/recommend` |
| 일정에 장소 등록 | `POST /api/v1/groups/{groupId}/plans/{planId}/schedule-places` |
| 일정 등록 장소 목록 | `GET /api/v1/groups/{groupId}/plans/{planId}/schedule-places` |

장소 검색은 취향, 태그, 참여자 선호, 지도 bounds, 날짜/시간 조건이 함께 들어올 수 있으므로 `POST /api/v1/place-search`를 canonical로 둔다. 단순 `GET /api/v1/place-search?query=...`는 dev stub 또는 호환용으로만 둘 수 있다.

장소 검색 응답은 기존 `query`, `canonical`, `results` wrapper를 유지한다. `results[]`는 기존 `id`, `name`, `category`, `address`, `lat`, `lng`, `heartCount`, `myHearted`, `canAddCandidate`를 유지하고, 외부 provider 연결을 위해 `provider`, `providerPlaceId`, `roadAddress`, `latitude`, `longitude`, `sourceUrl`, `providerLink`, `imageUrl`, `fetchedAt`을 추가할 수 있다. Spring은 `summary`, `tags`, `reasons`, `distanceLabel`, `recommendation`을 rule-based 추천 설명 read model로 함께 내려준다. Flutter는 provider/source 진단값을 사용자-facing 텍스트로 노출하지 않고, `reasons`만 추천 근거로 표시한다. `imageUrl`은 원본 TourAPI URL을 직접 노출하지 않고 ONMU 공개 proxy path를 사용한다.

후보 저장 요청 `POST /api/v1/groups/{groupId}/plans/{planId}/place-candidates`는 검색 결과에서 내려온 `reasons`, `distanceLabel`, `travelTimeLabel`, `priceLabel`, `openingLabel`, `imageUrl`을 선택적으로 받을 수 있다. Spring은 해당 값을 `place_candidates.payload`에 보존하고 `place_candidate.created` outbox payload에는 `reasonCount`, `recommendationVersion`, `hasCoordinate`, `sourceType` 같은 작업용 metadata만 넣는다.

지도 catalog API는 하단 top20 장소 검색 결과와 분리한다. `POST /api/v1/map-points`는 같은 `groupId`, `planId` membership guard를 거친 뒤 정적 catalog를 지도 context용 cluster/dot으로 반환한다. 낮은 zoom에서는 `clusters[]`, 높은 zoom(현재 15 이상)에서는 `points[]`만 채운다. 이 응답을 top20 숫자 marker나 후보 검색 결과로 사용하지 않는다.

Request:

```json
{
  "groupId": "1",
  "planId": "101",
  "bounds": { "south": 37.50, "west": 126.90, "north": 37.62, "east": 127.08 },
  "zoom": 12,
  "category": "카페",
  "filter": "all",
  "query": "성수"
}
```

Response:

```json
{
  "canonical": true,
  "mode": "clusters",
  "zoom": 12,
  "bounds": { "south": 37.50, "west": 126.90, "north": 37.62, "east": 127.08 },
  "clusters": [
    {
      "id": "cluster:1",
      "type": "cluster",
      "count": 24,
      "lat": 37.55,
      "lng": 127.02,
      "bounds": { "south": 37.54, "west": 127.01, "north": 37.56, "east": 127.03 },
      "categories": ["카페"]
    }
  ],
  "points": [],
  "cluster_count": 1,
  "point_count": 0,
  "schema_version": "external_places_postgis_v1"
}
```

동선 추천은 `POST /api/v1/routes/recommend`를 canonical로 둔다. 요청은 `groupId`, `planId`, `travelMode`(`car`, `walk`, `bike`)를 받고, 응답은 `provider`, `stops`, `geometry`(`[lng, lat]` LineString points), `distanceMeters`, `durationSeconds`, `travelMode`, `fetchedAt`을 포함한다. OpenRouteService credential이 없으면 provider를 `dev-mock`으로 명시한 deterministic geometry를 반환해 Flutter MapLibre UI smoke를 막지 않는다.

장소 후보 응답은 목록/추가/상세에서 `id`, `name`, `category`, `address`, `source`, `lat`, `lng`, `heartCount`, `myHearted`, `createdAt`을 가능한 범위에서 포함한다. `PUT .../heart`는 body의 `hearted`가 `true` 또는 생략이면 내 하트를 켜고, `false`면 내 하트를 끈다. 같은 사용자가 같은 후보에 여러 번 하트를 켜도 중복 row를 만들지 않는다.

일정 등록 장소 생성은 `candidateId` 기반 등록과 직접 장소명 등록을 모두 허용한다. 응답은 일정 등록 장소 id, 후보 id, 장소명, 시작/종료 시각, 메모를 포함한다.

## Votes

투표/결정의 Current-to-Target 경계는 [ONMU 홈 / 약속 / 투표 아키텍처](./home-plans-vote-architecture.md)를 따른다.

| 화면 | API |
| --- | --- |
| 투표 만들기 | `POST /api/v1/groups/{groupId}/votes` |
| 투표 목록 | `GET /api/v1/groups/{groupId}/votes` |
| 투표 상세 | `GET /api/v1/groups/{groupId}/votes/{voteId}` |

투표는 모임 전체 자체 생성 리소스로 둔다. 장소/일정/정산/준비물/일반 투표를 모두 `Vote`로 표현하고, 약속 관련 투표는 `targetType`, `targetId`, `voteType`으로 연결한다.

약속별 투표 목록은 같은 endpoint에 query parameter를 추가해 조회한다. 예를 들어 `GET /api/v1/groups/{groupId}/votes?targetType=PLAN&targetId={planId}`는 특정 약속에 연결된 투표만 반환한다.

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

투표 read model의 `participantCount`와 `participantCountLabel`은 모임 멤버 수나 약속 참여자 수가 아니라 실제 투표에 응답한 distinct user 수를 의미한다. 따라서 투표 생성 직후 아직 응답자가 없다면 `participantCount=0`, `participantCountLabel="0명 참여"`가 정상이다.

투표 상세 화면은 option별 `responseCount`, `progress`, voters projection을 실제 응답과 연결해야 한다. voters projection API가 아직 없거나 Flutter mapper가 빈 map을 반환하면 투표 결과 확인은 미완성으로 보고, Azure smoke에서 성공으로 판정하지 않는다.

`POST /api/v1/groups/{groupId}/plans/{planId}/votes`는 canonical로 사용하지 않는다. 필요한 경우 기존 Flutter 화면 전환을 위한 alias 또는 compatibility route로만 검토한다.

## Settlement

세부 Current-to-Target 기준은 [Settlement 아키텍처](./settlement-architecture.md)를 따른다.

| 화면 | API |
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

Spring Boot Main API는 `settlement_sections`, `settlement_items`, `settlement_item_targets`, `settlement_transfers` read/write 결과를 정산 계산과 조회의 우선 원장으로 사용한다. `settlement_drafts.payload`와 `settlements.payload`는 화면 snapshot이며 사용자 resolve나 계산 source of truth가 아니다.

정산 create/preview/update 요청은 section 단위 `payerUserId`, item 단위 `targetUserIds`, 사람별 부담 금액용 `targetShares`, `amountWon`을 canonical로 사용한다. 이름은 표시용 응답 필드로만 내려주며 요청 fallback으로 쓰지 않는다. DB 물리 컬럼도 `amount_won`이다. `targetShares` 합계는 item `amountWon`과 정확히 같아야 하며, 이 모드가 아니면 서버가 선택 대상자 안에서 균등 배분한다.

`POST /settlement-draft`는 eligible plan에서 active draft를 생성하거나 기존 active draft를 반환한다. 이미 finalized 또는 completed settlement가 있으면 새 draft를 만들지 않고 기존 결과 정산 카드를 반환한다. 시작 전 약속은 `settlement_plan_not_eligible`, `GET /settlement-draft`는 active draft가 없으면 `settlement_draft_not_found`를 반환한다. `GET /settlements/current`는 active draft 또는 active finalized만 반환하며, completed 정산만 남은 경우 채팅 상단 배너가 남지 않도록 `404 settlement_not_found`를 반환한다.

`POST /settlements`는 저장된 draft를 `finalized` settlement로 확정하고, 정산 카드용 `chat_activity_events`, 사용자별 notification, `settlement.finalized`, `notification.requested` outbox를 같은 domain transaction 안에서 남긴다. transfer가 없으면 즉시 `completed`로 전환하고 `settlement.completed` outbox를 남긴다.

## Chat

채팅의 제품/운영 목표는 [ONMU 채팅 및 ChatActivity 아키텍처](./chat-activity-architecture.md)를 따른다. 현재 계약은 `GET/POST /chat/messages`, `PUT /chat/read-state`, `GET /chat/events`, image attachment metadata를 포함하는 Spring in-process vertical slice다. production 목표는 카카오톡 수준의 기본 메시징 UX 위에 ONMU의 약속, 투표, 장소 후보, 정산, 기록 action card를 얹는 것이다.

| 화면 | API |
| --- | --- |
| 채팅 메시지 목록 | `GET /api/v1/groups/{groupId}/chat/messages` |
| 채팅 메시지 작성 | `POST /api/v1/groups/{groupId}/chat/messages` |
| 채팅 읽음 상태 갱신 | `PUT /api/v1/groups/{groupId}/chat/read-state` |
| 채팅 실시간 수신 | `GET /api/v1/groups/{groupId}/chat/events` |

Spring Boot Main API는 `chat_activity_events`를 모임별 메시지/activity stream으로 노출한다. `POST /chat/messages`는 텍스트 메시지와 이미지 첨부 metadata를 지원하고, 응답은 기존 Flutter `GroupMessage` UI 모델에 매핑 가능한 메시지 객체를 반환한다.

`GET`은 선택 query로 `beforeCursor`, `limit`을 받는다. 응답은 `{ "messages": [...], "nextCursor": "...", "hasMore": true, "unreadCount": 0 }` 형태이며, 각 메시지는 `id`, `cursor`, `senderUserId`, `senderName`, `message`, `attachments`, `messageType`, `cardType`, `createdAt`, `timeLabel`, `isMine`, `sendStatus`를 가능한 범위에서 포함한다. `POST` 요청 body는 `{ "message": "...", "attachments": [...] }`이다. 첨부가 없을 때 빈 메시지는 `400 blank_chat_message`로 거부하고, 이미지 첨부가 있으면 `message`는 빈 문자열을 허용한다. 이번 slice의 첨부 `type`은 `image`만 허용하며 최대 4개까지 받는다. `PUT /chat/read-state` 요청 body는 `{ "lastReadMessageId": "..." }`이고, 생략하면 최신 메시지를 기준으로 읽음 상태를 갱신한다. 모임 멤버가 아닌 사용자는 `403 group_member_required`로 거부한다.

`GET /chat/events`는 SCRUM-50의 첫 실시간 fan-out slice다. `text/event-stream`으로 `chat.message` SSE 이벤트를 보내며, payload는 `data: { ...message... }` 형태다. 선택 query `afterCursor`는 기존 메시지 `cursor`와 같은 ISO timestamp 문자열만 사용하고, 구독 시 누락 메시지를 replay할 수 있다. 현재 구현은 Spring Boot 단일 runtime 안의 in-process room broadcaster이며, 메시지 source of truth는 계속 `chat_activity_events`다. `isMine`은 발신자 응답을 그대로 공유하지 않고 subscriber별 viewer 기준으로 다시 계산한다. 멤버가 아닌 사용자는 stream 구독도 `403 group_member_required`로 거부한다.

Redis/별도 Realtime Gateway, FCM/APNs push, 파일/위치 첨부, 멤버별 상세 읽음 표시 UI는 이 계약의 현재 범위가 아니다. 사진 첨부는 `POST /api/v1/media/upload`로 먼저 업로드한 뒤 `POST /chat/messages`의 image attachment metadata로 연결한다. 채팅 메시지 작성은 작성자를 제외한 active/joined 멤버와 owner에게 `chat_message` in-app notification row와 `notification.requested` outbox event를 만들 수 있다. 다만 실제 provider push 발송은 production 아키텍처에서 Realtime Gateway, Notification Worker, FCM/APNs delivery 추적으로 확장한다.


## Records / Memories

세부 Current-to-Target 기준은 [Records/Memories/Media/OOTD 아키텍처](./records-memories-media-ootd-architecture.md)를 따른다.

| 화면 | API | Read model |
| --- | --- | --- |
| 기록 탭 월간 목록 | `GET /api/v1/memories` | `MemoryResponse[]` |
| 하루 일과/OOTD 저장 | `POST /api/v1/memories` | `MemoryResponse` |
| 하루 일과 상세/수정 진입 | `GET /api/v1/memories/{memoryId}` | `MemoryResponse` |
| 하루 일과 수정 저장 | `PUT/PATCH /api/v1/memories/{memoryId}` | `MemoryResponse` |
| 하루 일과/OOTD 삭제 | `DELETE /api/v1/memories/{memoryId}` | `204 No Content` |
| 사진 업로드 | `POST /api/v1/media/upload` | `{ storageKey, publicUrl }` |

하루 일과 기록은 `type=DAILY`, OOTD 기록은 `type=OOTD`를 사용한다. 사진은 먼저 `POST /api/v1/media/upload`로 업로드해 `publicUrl`을 받은 뒤, `imageUrls[]`에 담아 memory create/update 요청으로 저장한다.

현재 `/api/v1/memories` 계약은 `imageUrls[]` 호환을 유지한다. Target 계약은 `record_media` source of truth를 명확히 하기 위해 `media[]` metadata를 정식화한다. 개별 media 추가/수정/삭제 API는 후보이며, 구현 전까지는 memory create/update가 media list 전체를 대체하는 것으로 본다.

| Target 후보 | API | 비고 |
| --- | --- | --- |
| 기록 사진 추가 | `POST /api/v1/memories/{memoryId}/media` | upload 완료 후 storage key metadata 연결 |
| 기록 사진 수정 | `PATCH /api/v1/memories/{memoryId}/media/{mediaId}` | comment/sortOrder/alt metadata 수정 |
| 기록 사진 삭제 | `DELETE /api/v1/memories/{memoryId}/media/{mediaId}` | DB row soft delete + object cleanup outbox 후보 |

`media[]` target field는 `id`, `objectKey` 또는 `storageKey`, `publicUrl`, `contentType`, `sizeBytes`, `width`, `height`, `sortOrder`, `comment`를 포함한다. DB에는 원본 이미지 bytes를 저장하지 않고, object storage key와 metadata만 저장한다. Flutter는 MinIO/Azure Blob을 직접 호출하지 않고 Spring Main API upload/download boundary만 사용한다.

`publicUrl`은 API 서버 기준 상대 경로(`/api/v1/media/public?...`)로 내려올 수 있다. Flutter Web에서는 이 값을 그대로 렌더링하면 프론트 dev server를 호출하게 되므로, 클라이언트에서 `ONMU_API_BASE_URL` 기준 absolute URL로 정규화해 사용한다. Flutter Web 수정 저장은 dev CORS 허용 메서드와 맞추기 위해 `PATCH`를 우선 사용한다.

Daily diary UI 복원을 위해 `POST/PUT /api/v1/memories`는 선택 필드 `payload`를 받는다. `payload.timeline[]`은 사진별 코멘트와 image URL 매핑을 보존하고, `payload.brands`, `payload.mood`, `payload.weather`는 결과/수정 화면에서 다시 렌더링할 메타데이터를 보존한다. Target payload는 `layoutType=DIARY|CLEAN`, `decorationSeed` 또는 selected asset key를 포함해 상세 재진입, 바텀시트, export 결과가 같은 화면을 재현하게 한다.

기록 탭 표시 기준은 다음과 같다. 같은 날짜에 DAILY와 OOTD는 공존할 수 있다. OOTD가 없으면 캐릭터 썸네일을 표시하지 않고, DAILY만 있으면 diary/book icon을 표시한다. DAILY와 OOTD가 모두 있으면 월간 셀은 OOTD 캐릭터와 기록 상태 indicator를 보여주고, 바텀시트는 `하루 일과`와 `OOTD 기록` 탭을 분리한다.

삭제 상태 갱신 기준은 `DELETE /api/v1/memories/{memoryId}` 성공 후 Flutter가 해당 record id를 local state에서 즉시 제거하고 records provider를 invalidate/refetch하는 것이다. 이미 삭제된 record의 `404 memory_not_found`는 사용자에게 치명 오류로 표시하지 않고 이미 삭제된 상태로 처리한다.

업로드 정책은 최대 5장 후보, image MIME type만 허용, client compression 우선, Spring multipart limit 검증, 초과 시 `media_file_too_large` 또는 `media_count_exceeded` 계열 error code를 target으로 둔다. 현재 Spring `MediaService`는 image content type과 `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`, `.heic`, `.heif` 확장자만 허용한다.

```json
{
  "type": "DAILY",
  "title": "Daily record 2026-06-13",
  "memo": "오늘의 소중한 순간을 기록했어요.",
  "date": "2026-06-13",
  "tags": ["#하루기록", "#카페"],
  "imageUrls": ["https://.../daily-1.jpg"],
  "visibility": "PRIVATE",
  "payload": {
    "mood": "행복",
    "weather": "맑음",
    "brands": {
      "recordType": "daily",
      "theme": "diary",
      "crew": "userOnly"
    },
    "timeline": [
      {
        "time": "사진 1",
        "placeName": "추가한 사진",
        "category": "photo",
        "description": "케이크가 맛있었어요.",
        "imageUrl": "https://.../daily-1.jpg"
      },
      {
        "time": "오늘",
        "placeName": "하루 일과",
        "category": "daily",
        "description": "오늘의 소중한 순간을 기록했어요."
      }
    ]
  },
  "media": [
    {
      "id": "media_123",
      "objectKey": "records/media/2026/06/13/daily-1.jpg",
      "contentType": "image/jpeg",
      "sizeBytes": 823421,
      "sortOrder": 1,
      "comment": "케이크가 맛있었어요."
    }
  ],
  "payloadTarget": {
    "schemaVersion": 2,
    "layoutType": "DIARY",
    "decorationSeed": 182937,
    "selectedStickers": ["heart_1", "flower_3"]
  }
}
```

## Activity / Notification

| 이벤트 | 발생 조건 |
| --- | --- |
| `plan.created` | 약속 생성 |
| `place_candidate.created` | 장소 후보 추가 |
| `place_candidate.heart_updated` | 장소 후보 하트 변경 |
| `vote.created` | 투표 생성 |
| `vote.closed` | 투표 종료 |
| `settlement.finalized` | 정산 확정 |
| `settlement.completed` | 정산 완료 |
| `record.created` | 기록 작성 |
| `ai.summary.requested` | AI 요약/추천 설명 작업 요청 |
| `notification.requested` | 알림 발송 요청 |
| `media.thumbnail.requested` | 미디어 후처리 요청 |

Spring Boot는 domain transaction과 함께 `outbox_events`에 이벤트를 기록한다. `place_candidate.created`와 `ai.summary.requested`는 `services/workers/ai-data-worker`의 `/tasks/place-reason` 경로가 소비한다. `notification.requested`는 Spring runtime의 dev-safe notification delivery abstraction이 소비하며, 실제 FCM/APNs 발송 없이 `notification_deliveries`에 `provider=dev`, `status=skipped_dev` row를 남긴다. 실제 provider delivery 대상 이벤트는 `payload.notificationId` 또는 `aggregateType=notification` + `aggregateId=<notifications.id>`로 원본 notification을 찾을 수 있어야 한다. `user_devices`는 push token 등록 readiness를 제공하지만 provider delivery secret과 production 발송은 아직 연결하지 않는다. 아직 구현하지 않은 media worker 이벤트는 `no_consumer` 또는 `skipped_dev` 상태로 남길 수 있다.
