# Naver OAuth 준비 기준

이 문서는 ONMU 로그인용 Naver OAuth 설정만 다룬다. Naver 검색 API, Naver Maps, NCP 계정/지도 API는 이 문서 범위가 아니다.

## 인증 흐름

Flutter는 Naver SDK 또는 웹 로그인에서 얻은 provider access token 또는 authorization code를 Spring `POST /api/v1/auth/oauth/naver`로 전달한다. Spring은 Naver provider identity를 검증한 뒤 ONMU access JWT와 refresh token을 발급한다. Flutter는 이 ONMU token만 secure storage에 저장하고, 보호된 `/api/v1/**` 요청의 `Authorization` bearer token으로 사용한다.

Naver provider access token은 ONMU API bearer token으로 직접 사용하지 않는다.

## Key Vault 이름

| 환경 | Flutter/Spring env var | Key Vault secret name |
| --- | --- | --- |
| dev | `NAVER_OAUTH_CLIENT_ID` | `dev-naver-oauth-client-id` |
| dev | `NAVER_OAUTH_CLIENT_SECRET` | `dev-naver-oauth-client-secret` |
| integration | `NAVER_OAUTH_CLIENT_ID` | `int-naver-oauth-client-id` |
| integration | `NAVER_OAUTH_CLIENT_SECRET` | `int-naver-oauth-client-secret` |

`dev-naver-client-id`, `dev-naver-client-secret`은 이름이 모호하므로 OAuth 로그인 설정에는 사용하지 않는다. 기존 검색/지도/NCP 계열 설정이 필요하면 별도 문서와 env var로 구분한다.

dev 값은 Key Vault에 저장되어 있다. integration 값은 dev 값을 재사용하지 않고, 별도로 발급된 뒤 `int-naver-oauth-client-id`, `int-naver-oauth-client-secret`에 저장한다.

secret 값은 문서, PR 본문, 로그, 채팅에 남기지 않는다.

## Redirect URI 후보

Naver 개발자 콘솔에는 환경별 callback 후보를 아래처럼 등록한다.

- `http://localhost:8080/api/v1/auth/oauth/naver/callback`
- `https://dev-api.onmu.cloud/api/v1/auth/oauth/naver/callback`
- `https://int-api.onmu.cloud/api/v1/auth/oauth/naver/callback`
- future prod: `https://api.onmu.cloud/api/v1/auth/oauth/naver/callback`

## 구현 상태

현재 Spring은 `providerAccessToken` 경로를 우선 지원한다. Spring은 `GET https://openapi.naver.com/v1/nid/me`를 호출해 Naver `response.id`를 provider subject로 사용하고, `response.name`, `response.email`, `response.profile_image`는 있으면 ONMU 사용자 프로필 입력값으로 매핑한다.

`authorizationCode` 경로는 Kakao와 같은 provider-neutral exchange seam을 사용한다. token endpoint 교환에 필요한 client id, client secret, redirect URI 설정은 위 env var와 redirect URI 기준으로 연결하되, 실제 code exchange 구현은 별도 후속 작업에서 마무리한다.

`devVerifiedSubject`는 `onmu.auth.dev-oauth-enabled=true` 또는 `ONMU_DEV_OAUTH_ENABLED=true`일 때만 로컬/dev scaffold로 허용한다. provider token 또는 authorization code가 있으면 dev subject fallback을 사용하지 않는다.
