# Azure smoke checklist

이 문서는 Azure staging/production 배포 후 최소 확인해야 하는 smoke 목록이다. 모든 결과는 status/count/field presence 중심으로 보고하고, secret/token/raw body/사용자 개인정보 실제 값은 출력하지 않는다.

## 1. 공통 기본 smoke

| Check | 기대 결과 |
| --- | --- |
| `GET /healthz` | 200 |
| `GET /readyz` | 200 |
| no-token `GET /api/v1/users/me` | 401 |
| authenticated `GET /api/v1/users/me` | 200 |
| public endpoint와 internal endpoint 상태 비교 | 일치 또는 edge 이슈 분리 |

최신 `origin/dev`가 fallback runtime이 아니라 실제 배포 대상 commit으로 serving 중인지도 확인한다. 빌드 성공만으로 최신 runtime serving을 인정하지 않는다.

공통 CORS/edge smoke:

- Flutter web origin 후보별 `OPTIONS` preflight status 확인
- allowed method는 `GET/POST/PUT/PATCH/DELETE/OPTIONS` presence 중심으로 확인
- allowed header는 `Authorization`, `Content-Type` presence 중심으로 확인
- credential 허용 여부는 환경별 정책과 일치하는지 확인
- preflight cache header는 값 자체보다 presence/policy 일치 여부만 기록
- Container Apps ingress, Front Door/WAF, API Management 중 실제 요청을 받은 edge layer를 구분해서 보고

## 2. Auth/OAuth smoke

- Kakao/Naver/Google env var present 여부
- OAuth secret은 Spring runtime에만 주입
- Flutter에는 공개 client id/redirect URI만 포함
- provider callback/URL scheme이 환경별 host와 일치
- no-token `GET /api/v1/auth/session` 401
- authenticated `GET /api/v1/auth/session` 200
- `POST /api/v1/auth/refresh` token rotation status 확인
- `DELETE /api/v1/auth/session` logout idempotent behavior 확인
- Google Android smoke는 provider 화면 진입, 앱 복귀, Spring exchange status, secure storage 저장 여부를 분리 보고
- Google iOS smoke는 generated `GOOGLE_IOS_REVERSED_CLIENT_ID` URL scheme, 앱 복귀, Spring exchange status를 분리 보고
- Kakao/Naver smoke는 provider callback path와 mobile deep link 앱 복귀를 분리 보고
- 실제 code/state/idToken 값은 출력 금지
- access/refresh token 값, `Authorization` header, raw response body 출력 금지
- 실패 시 provider console, mobile platform config, Spring verifier, token exchange를 분리

## 3. User/Profile smoke

- `/api/v1/users/me` field count
- `userCode` 존재 여부와 10자리 숫자 형식만 확인
- `preferenceProfile` 존재 여부와 key count
- `region`, `regionVisibility`, `preferredTimes`, `preferredWeekdays` presence
- `regionVisibility=PRIVATE`이면 공개 프로필 또는 친구 상세에 raw region이 노출되지 않는지 확인
- 공개 또는 제한 공개 설정이면 active friend/허용 viewer 기준으로만 region field가 노출되는지 확인
- region smoke는 raw 지역명 대신 field presence/status/count 중심으로 보고
- mojibake 의심 count scan은 row count/field count만 보고
- raw display name/profile value는 출력 금지

## 4. Home/Plan/Vote smoke

홈/약속/투표 smoke는 Azure 전환 후 핵심 사용자 흐름이 서버 read model, Flutter ViewModel, outbox side effect까지 끊기지 않았는지 확인한다. 모든 결과는 status/count/field presence 중심으로 보고하고, 모임명, 사용자 이름, 위치, 메모 같은 raw 사용자 데이터는 출력하지 않는다.

- `GET /api/v1/home/summary` authenticated 200
- home summary의 `viewer`, `groups`, `upcomingPlans`, `activeVotes`, `nextPlan` field presence 확인
- Flutter 홈이 서버 `HomeSummary`를 직접 소비하는지, 임시 fallback으로 groups/plans 조합을 쓰는지 구분 보고
- `GET /api/v1/groups/{groupId}/summary` status와 group/plans/votes field presence 확인
- `GET /api/v1/groups/{groupId}/plans` status/count 확인
- `GET /api/v1/groups/{groupId}/plans/{planId}` status와 plan/member/count field presence 확인
- `GET /api/v1/groups/{groupId}/plans/{planId}/participants` status/count와 participant `preferenceProfile` presence 확인
- `POST /api/v1/groups/{groupId}/plans`는 `participantUserIds` 포함 요청으로 생성자와 추가 참여자 count를 확인
- `GET /api/v1/groups/{groupId}/plans/participant-candidates?userIds=<db-user-uuid>`가 선택된 후보 멤버의 `preferenceProfile`을 반환하는지 확인한다. `GET /groups/{groupId}/members`는 전체 모임원 `preferenceProfile`을 미리 싣지 않는 lightweight 계약으로 확인한다.
- 일반 약속 수정은 명시 status 변경이 없을 때 기존 status가 draft로 회귀하지 않는지 확인
- `GET /api/v1/groups/{groupId}/votes?targetType=PLAN&targetId=...` status/count 확인
- `GET /api/v1/groups/{groupId}/votes/{voteId}` status와 options/responseCount/progress field presence 확인
- 후보별 voters projection이 아직 없으면 empty-map을 성공으로 판정하지 않고 미구현 gap으로 기록
- `plan.created`, `plan.updated`, `plan.participant_added`, `vote.created` outbox event count/status/field presence 확인
- plan/vote write 이후 home summary와 plan/vote detail 재조회가 새 상태를 반영하는지 확인

## 5. Chat smoke

- `GET /api/v1/groups/{groupId}/chat/messages` status/count
- `POST /api/v1/groups/{groupId}/chat/messages` status와 created id presence
- `PUT /api/v1/groups/{groupId}/chat/read-state` status
- `GET /api/v1/groups/{groupId}/chat/events` short stream status
- `isMine`은 viewer 기준으로 계산되는지 확인
- SSE는 delivery layer이며 DB 원장을 source of truth로 본다

## 6. Notification smoke

- `GET /api/v1/notifications/unread-count`
- `GET /api/v1/notifications`
- `PUT /api/v1/notifications/{notificationId}/read`
- `PUT /api/v1/notifications/read-all`
- `GET /api/v1/notification-preferences`
- `PUT /api/v1/notification-preferences`
- 타 사용자 notification read 요청은 404 기대
- chat message 생성 시 notification row와 outbox event 생성 여부 count로 확인
- provider delivery 대상 `notification.requested` outbox payload에는 `notificationId` field presence 확인
- `notificationId` 없는 activity-only event는 실제 FCM/APNs provider delivery 성공으로 해석하지 않음
- `notification_deliveries` dev-safe/provider/status count 확인

## 7. Push token readiness smoke

- `POST /api/v1/devices/push-token`
- `DELETE /api/v1/devices/push-token`
- token은 request body로만 전달
- URL/query에 token 없음
- response에는 raw token 없이 `tokenLast4` 같은 제한된 메타데이터만 존재
- 같은 token이 다른 사용자 active row에 남으면 inactive 처리
- 실제 FCM/APNs 발송은 별도 승인 전 비활성

## 8. Settlement smoke

- `POST /api/v1/groups/{groupId}/plans/{planId}/settlement-draft` status와 active draft/finalized field presence
- `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft` section/item/target 저장 status와 item count
- `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/preview` status와 transfer/item count
- preview는 DB write와 outbox write 없이 계산되는지 확인
- `POST /api/v1/groups/{groupId}/plans/{planId}/settlements` status와 created id presence
- `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/current` status와 active draft/finalized result field presence
- settlement create 후 `settlement.finalized`, 수취 완료 후 `settlement.completed` outbox count/status 확인
- completed 이후 current settlement는 `404 settlement_not_found`로 채팅 상단 배너가 사라지는지 확인
- provider delivery 대상 notification row가 없으면 push 성공으로 해석하지 않음
- 금액/참여자 raw body, 실사용자 이름, 계좌/정산 개인정보 출력 금지

## 9. Records/Media/OOTD smoke

- `POST /api/v1/media/upload` small image upload status와 `storageKey/publicUrl` presence 확인
- `POST /api/v1/memories` DAILY create status와 created id presence 확인
- `POST /api/v1/memories` OOTD create status와 character snapshot presence 확인
- `GET /api/v1/memories` 또는 date/month query smoke로 created record count 확인
- `GET /api/v1/memories/{memoryId}` detail에서 `type`, `imageUrls`, target `media[]` metadata presence 확인
- `PATCH /api/v1/memories/{memoryId}` update 후 mood/weather/layout payload field presence 확인
- `DELETE /api/v1/memories/{memoryId}` 후 list/detail 재조회에서 제거 또는 `404 memory_not_found` 확인
- 사진 포함 기록은 object key/storage key, content type, sort order presence만 보고하고 실제 사용자 사진 URL/raw filename은 출력하지 않음
- OOTD 없는 DAILY 날짜는 character thumbnail이 표시되지 않는지 확인
- DAILY와 OOTD가 같은 날짜에 공존할 때 바텀시트 탭/상세 진입이 분리되는지 확인
- 저장된 `layoutType`과 decoration seed 또는 selected asset key가 상세 재진입 후 유지되는지 확인
- upload limit smoke는 허용 MIME, file count limit, file size limit, `unsupported_media_type`/`media_file_too_large` 계열 error code 중심으로 보고
- Flutter Web smoke는 `ONMU_API_BASE_URL` 기준 media public URL 정규화와 `127.0.0.1:5173` CORS preflight를 분리 확인

## 10. Place/Search/Route/Map smoke

- `GET /manifest.json` 200
- `GET /styles/onmu-light.json` 200
- PMTiles Range 206
- `Access-Control-Allow-Origin` 유지
- `Accept-Ranges` 유지
- `Content-Range` 유지
- `Access-Control-Expose-Headers` 유지
- PMTiles `Content-Type`과 `Cache-Control` policy presence 확인
- manifest/style `Cache-Control`은 rollback 가능성을 해치지 않는지 확인
- tile manifest가 current pointer와 rollback 판단에 필요한 version/build 식별자를 포함하는지 확인
- tile asset을 교체한 배포라면 이전 manifest/style/PMTiles object가 보존되어 있는지 확인
- edge cache를 사용하는 배포라면 CDN/Front Door purge 또는 cache invalidation 실행 여부를 status/count 중심으로 기록
- place-search provider smoke는 status/result_count/provider_counts/source_counts/coordinate_count만 보고
- Naver/Kakao provider availability를 분리
- provider raw response, provider secret, 사용자 검색 raw body는 smoke artifact와 log에 남기지 않음
- provider production readiness는 Kakao Local 심사/권한, Naver/Kakao quota, route provider quota/약관을 provider별로 분리 판정
- route provider는 status/count/distance/duration presence 중심으로 보고
- target DB에 PostGIS를 활성화한 환경이면 extension/index/query smoke는 name/count/presence만 기록하고 실제 사용자 좌표나 검색어를 출력하지 않음
- Android emulator에서 blank/fallback/water-style 회귀 확인
- Android smoke는 emulator/device id, 담당자, 결과 status, screenshot/video artifact path만 남김. 화면에 실제 사용자 위치/사진/PII가 있으면 artifact를 공유하지 않음
- Azure Pricing Calculator 산출물은 staging/prod resource SKU, count, 월 예상 범위 presence만 확인하고 결제 정보나 account 식별자는 남기지 않음

## 11. Media/Object storage smoke

- upload presign status
- object write/read status
- content-type presence
- sample object count
- signed URL expiry policy 확인
- 실제 사용자 사진/파일명/URL 값 출력 금지

## 12. Worker/AI smoke

- Worker health/readiness
- queue receive/process count
- HTTP internal call을 쓰는 경우 timeout/error status count
- queue 기반이면 retry count와 dead-letter count
- AI 결과 저장 location은 worker schema/object key/metadata presence만 보고
- AI provider env present 여부
- rule-based fallback 존재 여부
- Azure OpenAI 응답 raw body 출력 금지

## 13. Observability smoke

- Application Insights request/dependency/error count
- Log Analytics query 가능 여부
- alert rule enabled 여부
- deploy correlation id 또는 image tag 기록
- request id 또는 trace id가 API log와 smoke summary에 연결되는지 확인
- API latency p95/p99 후보와 5xx/4xx error rate query 가능 여부
- `/readyz` failure alert 후보
- DB connection pool saturation/error count query 가능 여부
- storage upload/read failure count query 가능 여부
- SSE reconnect/error count 후보
- secret 값이 log에 남지 않았는지 scan
