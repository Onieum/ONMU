# ONMU Auth/User/Profile 아키텍처

## 목적

이 문서는 로그인, 사용자 세션, 취향 선택, 마이페이지 지역설정 흐름을 Terraform/Azure 전환 전에 현재 구현 기준과 목표 운영 경계로 정리한다. 채팅, 알림, 장소, 정산, 기록 도메인은 각 도메인 문서를 따른다.

PR #147의 채팅/알림 Current-to-Target 아키텍처 정리와 같은 목적의 Auth/User/Profile 보완 문서다. Terraform 작업자가 어느 secret과 env var를 읽어야 하는지, 어떤 값은 앱 bundle에 절대 넣으면 안 되는지, 모바일 OAuth smoke 완료 기준이 무엇인지 빠르게 확인하는 것을 목표로 한다.

## 담당 범위

| 영역 | 현재 책임 | Terraform 전환 시 확인할 경계 |
| --- | --- | --- |
| Social OAuth | Kakao/Naver browser authorization-code, Google idToken을 Spring Boot Main API가 검증한다. | provider secret은 Key Vault/env에만 두고 Flutter bundle에는 넣지 않는다. |
| ONMU session | Spring이 ONMU access JWT와 refresh token을 발급하고 Flutter가 secure storage에 저장한다. | JWT signing secret, refresh token 저장소, TTL은 Terraform/Key Vault/env 기준으로 주입한다. |
| Current user | Flutter는 `/api/v1/auth/session`, `/api/v1/users/me`를 기준으로 현재 사용자 상태를 복원한다. | 보호 API는 token 없을 때 `401`이어야 하며, public logout 정책과 README 설명을 일치시킨다. |
| Preference onboarding | 취향 선택 완료 후 `/api/v1/users/me` PATCH로 `preferenceProfile`과 `onboardingStatus`를 저장한다. | `onboardingStatus=COMPLETED`는 MVP 온보딩 게이트 완료 상태로만 해석한다. |
| Profile region | 마이페이지 프로필 편집에서 `preferenceProfile.region`, `preferenceProfile.regionVisibility`를 저장한다. | 지역설정 완료 여부를 `onboardingStatus` 계산에 섞지 않는다. |

## Current 구현 흐름

```text
Flutter login button
  -> provider OAuth flow
  -> Spring POST /api/v1/auth/oauth/{provider}
  -> provider token/code 검증
  -> ONMU access JWT + refresh token 발급
  -> Flutter secure storage 저장
  -> GET /api/v1/auth/session
  -> GET /api/v1/users/me
  -> 온보딩 또는 홈 진입
```

현재 Flutter 앱은 API mode 개발 중 JWT 우회 define을 사용할 수 있지만, 실제 OAuth smoke와 production 목표 흐름에서는 JWT signing secret을 앱에 넣지 않는다.

## API 계약

| 기능 | Method / Path | 요청/응답 기준 |
| --- | --- | --- |
| OAuth 로그인 | `POST /api/v1/auth/oauth/{provider}` | Flutter가 provider token/code/idToken을 전달하고 Spring이 ONMU token pair를 반환한다. |
| Naver callback | `GET /api/v1/auth/oauth/naver/callback` | Spring callback이 `code`, `state`, `error`를 모바일 deep link로 전달한다. |
| Kakao callback | `GET /api/v1/auth/oauth/kakao/callback` | Spring callback이 `code`, `state`, `error`를 모바일 deep link로 전달한다. |
| 세션 확인 | `GET /api/v1/auth/session` | 현재 ONMU access JWT 기준 사용자/session 상태를 반환한다. |
| refresh | `POST /api/v1/auth/refresh` | refresh token 기준 access token 재발급 경로다. |
| logout | `DELETE /api/v1/auth/session` | 현재 session을 종료한다. |
| 내 정보 조회 | `GET /api/v1/users/me` | `displayName`, `preferenceProfile`, `pixelCharacter`, `onboardingStatus` 등을 반환한다. |
| 내 정보 수정 | `PATCH /api/v1/users/me` | 프로필, 취향, 지역, 온보딩 상태를 부분 갱신한다. |

## Preference/Profile payload

`PATCH /api/v1/users/me`는 현재 사용자만 수정한다. 다른 사용자 id를 body로 받아 권한을 우회하지 않는다.

```json
{
  "displayName": "사용자 표시명",
  "preferenceProfile": {
    "foods": ["한식", "디저트"],
    "avoidFoods": ["매운 음식"],
    "moods": ["조용한 공간"],
    "avoidMoods": ["사람이 너무 많은 곳"],
    "promiseStyle": ["주말에 여유롭게 만나고 싶어요"],
    "preferredDays": ["FRIDAY", "SATURDAY"],
    "preferredTimeSlots": ["EVENING"],
    "region": {
      "country": "KR",
      "sido": "서울",
      "sigungu": "성동구",
      "displayName": "서울 성동구"
    },
    "regionVisibility": "PRIVATE"
  },
  "onboardingStatus": "COMPLETED"
}
```

지역 공개 범위는 `PRIVATE`를 기본값으로 둔다. 친구/타인 프로필 read path는 공개 상태가 아닐 때 거주지역을 노출하지 않는다.

## Provider별 설정 경계

| Provider | Flutter 공개 define | Spring env | Key Vault secret name |
| --- | --- | --- | --- |
| Kakao | `KAKAO_REST_API_KEY`, `KAKAO_OAUTH_REDIRECT_URI` | `KAKAO_REST_API_KEY`, `KAKAO_CLIENT_SECRET`, `KAKAO_OAUTH_REDIRECT_URI`, `KAKAO_OAUTH_MOBILE_CALLBACK_URI` | `dev-kakao-rest-api-key`, `dev-kakao-client-secret` |
| Naver | `NAVER_OAUTH_CLIENT_ID`, `NAVER_OAUTH_REDIRECT_URI` | `NAVER_OAUTH_CLIENT_ID`, `NAVER_OAUTH_CLIENT_SECRET`, `NAVER_OAUTH_MOBILE_CALLBACK_URI` | `dev-naver-oauth-client-id`, `dev-naver-oauth-client-secret` |
| Google | `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID` | `GOOGLE_OAUTH_CLIENT_ID` 또는 `GOOGLE_SERVER_CLIENT_ID` | `dev-google-oauth-client-id`, `dev-google-server-client-id` |

Kakao/Naver OAuth 설정은 dev Key Vault의 OAuth 전용 secret name을 기준으로 관리한다. Google OAuth 설정은 dev Google OAuth client id와 server client id secret을 기준으로 관리하며, Google idToken의 `aud` 검증에 사용된다.

## Terraform/Azure 전환 시 Agent가 읽어야 할 값

Terraform 또는 배포 Agent는 실제 secret 값을 문서, PR 본문, 로그에 출력하지 않는다. 필요한 것은 secret value가 아니라 다음 매핑이다.

| 목적 | dev secret | integration/prod 후보 |
| --- | --- | --- |
| dev API access JWT signing | `dev-access-token-secret` | `int-access-token-secret`, prod 전용 signing secret |
| Kakao REST API key | `dev-kakao-rest-api-key` | `int-kakao-rest-api-key`, prod 전용 Kakao app key |
| Kakao OAuth secret | `dev-kakao-client-secret` | `int-kakao-client-secret`, prod 전용 secret |
| Naver OAuth client id | `dev-naver-oauth-client-id` | `int-naver-oauth-client-id`, prod 전용 client id |
| Naver OAuth secret | `dev-naver-oauth-client-secret` | `int-naver-oauth-client-secret`, prod 전용 secret |
| Google OAuth audience | `dev-google-oauth-client-id` | `int-google-oauth-client-id`, prod 전용 OAuth client id |
| Google server client fallback | `dev-google-server-client-id` | `int-google-server-client-id`, prod 전용 server client id |

Terraform이 Key Vault secret을 만들거나 참조할 때는 `secret name`과 runtime env var 매핑만 관리한다. 실제 값 주입은 권한 있는 운영자가 Azure Key Vault, GitHub Secrets, 또는 배포 환경변수로 수행한다.

## 모바일 OAuth smoke 기준

웹/Chrome smoke는 provider authorize URL과 Spring callback wiring 확인까지만 완료로 본다. 실제 로그인 완료 판정은 Android/iOS에서 다음이 모두 확인되어야 한다.

1. provider 로그인 화면 진입
2. provider 인증 후 `io.onieum.onmu://oauth/<provider>/callback` deep link 수신
3. Spring token exchange 성공
4. Flutter secure storage에 ONMU access/refresh token 저장
5. 온보딩 또는 홈 진입
6. 앱 재실행 후 세션 유지

실제 OAuth smoke에는 JWT 우회용 dart-define을 섞지 않는다. `ONMU_API_BASE_URL`과 provider 공개 client id/redirect URI만 사용한다.

## 보안/개인정보 경계

- provider access token, authorization code, refresh token, ONMU access JWT 원문은 로그나 PR에 남기지 않는다.
- Google/Kakao/Naver client secret은 Flutter bundle과 dart-define에 넣지 않는다.
- `preferenceProfile.region`은 약속 장소 추천과 구성원 간 위치 조율을 위한 프로필 데이터이며, 기본 공개 범위는 `PRIVATE`다.
- 지역설정을 analytics/CDC 기준으로 선제 변경하지 않는다. MVP/dev에서는 `sub=<users.public_id>`와 Spring DB 사용자 조회 흐름을 유지한다.
- `onboardingStatus`는 지역설정 완료 여부와 분리한다. 나중에 지역설정을 가입 필수 단계로 올리기로 합의하면 별도 PR에서 `deriveOnboardingStatus` 조건을 확장한다.

## PR/QA 체크리스트

- [ ] `/healthz`, `/readyz`가 public dev endpoint에서 `200`인지 확인
- [ ] 보호 API `/api/v1/users/me`는 token 없을 때 `401`인지 확인
- [ ] OAuth 실제 smoke는 Android/iOS에서 JWT 우회 define 없이 수행
- [ ] Google은 dev Key Vault의 Google secret name과 Flutter 공개 define 값이 같은 OAuth client를 가리키는지 확인
- [ ] `PATCH /api/v1/users/me`가 `preferenceProfile.regionVisibility`를 `PRIVATE` 기본값으로 저장/복원하는지 확인
- [ ] PR 본문과 로그에 secret/token/provider code/state가 출력되지 않았는지 확인
