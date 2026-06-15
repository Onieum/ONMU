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

## 2. Auth/OAuth smoke

- Kakao/Naver/Google env var present 여부
- OAuth secret은 Spring runtime에만 주입
- Flutter에는 공개 client id/redirect URI만 포함
- provider callback/URL scheme이 환경별 host와 일치
- 실제 code/state/idToken 값은 출력 금지
- 실패 시 provider console, mobile platform config, Spring verifier, token exchange를 분리

## 3. User/Profile smoke

- `/api/v1/users/me` field count
- `userCode` 존재 여부와 형식만 확인
- `preferenceProfile` 존재 여부와 key count
- `region`, `regionVisibility`, `preferredTimes`, `preferredWeekdays` presence
- mojibake 의심 count scan은 row count/field count만 보고
- raw display name/profile value는 출력 금지

## 4. Chat smoke

- `GET /api/v1/groups/{groupId}/chat/messages` status/count
- `POST /api/v1/groups/{groupId}/chat/messages` status와 created id presence
- `PUT /api/v1/groups/{groupId}/chat/read-state` status
- `GET /api/v1/groups/{groupId}/chat/events` short stream status
- `isMine`은 viewer 기준으로 계산되는지 확인
- SSE는 delivery layer이며 DB 원장을 source of truth로 본다

## 5. Notification smoke

- `GET /api/v1/notifications/unread-count`
- `GET /api/v1/notifications`
- `PUT /api/v1/notifications/{notificationId}/read`
- `PUT /api/v1/notifications/read-all`
- `GET /api/v1/notification-preferences`
- `PUT /api/v1/notification-preferences`
- 타 사용자 notification read 요청은 404 기대
- chat message 생성 시 notification row와 outbox event 생성 여부 count로 확인
- `notification_deliveries` dev-safe/provider/status count 확인

## 6. Push token readiness smoke

- `POST /api/v1/devices/push-token`
- `DELETE /api/v1/devices/push-token`
- token은 request body로만 전달
- URL/query에 token 없음
- response에는 raw token 없이 `tokenLast4` 같은 제한된 메타데이터만 존재
- 같은 token이 다른 사용자 active row에 남으면 inactive 처리
- 실제 FCM/APNs 발송은 별도 승인 전 비활성

## 7. Place/Search/Route/Map smoke

- `GET /manifest.json` 200
- `GET /styles/onmu-light.json` 200
- PMTiles Range 206
- `Access-Control-Allow-Origin` 유지
- `Accept-Ranges` 유지
- `Content-Range` 유지
- `Access-Control-Expose-Headers` 유지
- place-search provider smoke는 status/result_count/provider_counts/source_counts/coordinate_count만 보고
- Naver/Kakao provider availability를 분리
- route provider는 status/count/distance/duration presence 중심으로 보고
- Android emulator에서 blank/fallback/water-style 회귀 확인

## 8. Media/Object storage smoke

- upload presign status
- object write/read status
- content-type presence
- sample object count
- signed URL expiry policy 확인
- 실제 사용자 사진/파일명/URL 값 출력 금지

## 9. Worker/AI smoke

- Worker health/readiness
- queue receive/process count
- AI provider env present 여부
- rule-based fallback 존재 여부
- Azure OpenAI 응답 raw body 출력 금지

## 10. Observability smoke

- Application Insights request/dependency/error count
- Log Analytics query 가능 여부
- alert rule enabled 여부
- deploy correlation id 또는 image tag 기록
- secret 값이 log에 남지 않았는지 scan
