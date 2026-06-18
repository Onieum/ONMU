# OAuth 모바일 smoke 검증 워크플로

이 문서는 Kakao/Naver browser authorization-code 로그인을 웹 smoke와 모바일 smoke로 나누어 검증하는 기준이다. 목표는 provider 설정 문제, Spring callback 문제, 모바일 deep link 문제, 앱 세션 저장 문제를 서로 섞지 않는 것이다.

현재 팀 기본 smoke 환경은 Azure staging이다. 특별히 지정하지 않은 Flutter 기본 실행, OAuth-only define 생성, callback 기준은 `staging-api.onmu.cloud`를 사용하고, Windows dev/local 경로는 명시 opt-in일 때만 사용한다.

일반 staging 실행, 보호 API define, dev/local opt-in 경로는 [Flutter staging 실행 runbook](./flutter-staging-runbook.md)을 먼저 보고, 이 문서는 actual OAuth smoke 절차와 판정 기준에만 집중한다.

## 핵심 원칙

- 웹 빌드와 모바일 빌드는 로그인 완료 기준이 다르다.
- Flutter web/Chrome smoke는 provider authorize URL과 Spring callback까지의 연결 확인이다.
- Android/iOS smoke는 모바일 custom scheme deep link를 앱이 받고, Spring token exchange 후 ONMU 세션이 저장되는지 확인한다.
- 실제 OAuth smoke에는 JWT 우회용 define을 넣지 않는다. JWT 우회 define은 보호 API 화면 개발용이고, 로그인 완료 검증용이 아니다.
- secret, API key, token, authorization code, callback full URL은 채팅, 로그 요약, PR 본문에 출력하지 않는다. 필요하면 env var 이름, secret name, 값 길이, HTTP status, path, parameter 존재 여부만 기록한다.

## 판정 기준

| 구분 | 확인 가능 항목 | 완료 판정 |
| --- | --- | --- |
| Web/Chrome smoke | provider authorize URL, redirect URI, Spring callback의 `code`/`state` 수신 | OAuth 설정과 callback wiring 확인까지만 완료 |
| Android/iOS smoke | provider 로그인, `io.onieum.onmu://oauth/<provider>/callback`, 앱 복귀, token 저장, 온보딩/홈 진입, 재실행 후 세션 유지 | 모바일 로그인 완료 |

웹/Chrome에서 callback 뒤 빈 화면처럼 보이는 것은 모바일 custom scheme을 데스크톱 웹이 처리하지 못해서 생길 수 있다. 이 현상만으로 앱 로그인 실패라고 판단하지 않는다.

## 사전 확인

백엔드:

```powershell
curl.exe -i https://staging-api.onmu.cloud/healthz
curl.exe -i https://staging-api.onmu.cloud/readyz
curl.exe -i https://staging-api.onmu.cloud/api/v1/users/me
```

- `/healthz`: `200`
- `/readyz`: `200`
- `/api/v1/users/me` token 없음: `401`

Kakao 설정:

- Flutter 공개 define: `ONMU_API_BASE_URL`, `KAKAO_REST_API_KEY`, `KAKAO_OAUTH_REDIRECT_URI`
- Spring 서버 env: `KAKAO_REST_API_KEY`, `KAKAO_CLIENT_SECRET`, `KAKAO_OAUTH_REDIRECT_URI`, `KAKAO_OAUTH_MOBILE_CALLBACK_URI`
- Key Vault secret name: `staging-kakao-rest-api-key`, `staging-kakao-client-secret`
- ACA plain env: `KAKAO_OAUTH_REDIRECT_URI`, `KAKAO_OAUTH_MOBILE_CALLBACK_URI`
- Kakao Developers redirect URI: `https://staging-api.onmu.cloud/api/v1/auth/oauth/kakao/callback`
- Android deep link: `io.onieum.onmu://oauth/kakao/callback`
- iOS URL scheme: `io.onieum.onmu`

Naver 설정:

- Flutter 공개 define: `ONMU_API_BASE_URL`, `NAVER_OAUTH_CLIENT_ID`, `NAVER_OAUTH_REDIRECT_URI`
- Spring 서버 env: `NAVER_OAUTH_CLIENT_ID`, `NAVER_OAUTH_CLIENT_SECRET`, `NAVER_OAUTH_REDIRECT_URI`, `NAVER_OAUTH_MOBILE_CALLBACK_URI`
- Key Vault secret name: `staging-naver-oauth-client-id`, `staging-naver-oauth-client-secret`
- ACA plain env: `NAVER_OAUTH_REDIRECT_URI`, `NAVER_OAUTH_MOBILE_CALLBACK_URI`
- Android deep link: `io.onieum.onmu://oauth/naver/callback`
- iOS URL scheme: `io.onieum.onmu`

Google 설정:

- Flutter 공개 define: `ONMU_API_BASE_URL`, `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`
- Spring 서버 env: `GOOGLE_OAUTH_CLIENT_ID` 또는 `GOOGLE_SERVER_CLIENT_ID`
- Key Vault secret name: `staging-google-oauth-client-id`
- `GOOGLE_SERVER_CLIENT_ID` fallback secret name: `staging-google-server-client-id`
- iOS generated xcconfig: `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_IOS_SERVER_CLIENT_ID`, `GOOGLE_IOS_REVERSED_CLIENT_ID`
- Flutter는 Google idToken을 Spring `POST /api/v1/auth/oauth/google`의 `providerIdToken`으로 전달한다.
- Spring은 Google tokeninfo 응답에서 issuer, audience, subject, expiration을 검증한 뒤 ONMU access/refresh token을 발급한다.
- 현재 repo의 public define 생성 스크립트는 별도 `GOOGLE_ANDROID_CLIENT_ID` Key Vault secret을 직접 읽지 않는다. Android/iOS 플랫폼별 client id를 분리하려면 Flutter 코드, define 생성 스크립트, Spring audience 검증 값을 함께 갱신한다.

## Web/Chrome smoke

이 smoke는 모바일 로그인 완료 검증이 아니다. provider 설정과 Spring callback wiring만 빠르게 확인한다.

1. Flutter web을 provider 공개 define으로 실행한다.
2. 로그인 버튼이 provider authorize URL을 여는지 확인한다.
3. provider 인증 후 Spring callback path로 `code`와 `state`가 도달하는지 확인한다.
4. callback 뒤 custom scheme 단계가 웹에서 비거나 중단되어도 모바일 smoke로 이어서 판단한다.

기록할 증거:

- authorize host와 path
- redirect URI host와 path
- callback parameter 중 `code`/`state` 존재 여부
- provider `error` parameter 존재 여부

기록하지 않는 것:

- 실제 `client_id`
- 실제 `code`
- 실제 `state`
- 실제 token
- 계정 이메일, 이름, 전화번호

## Android smoke

Android는 Windows controller 또는 Android 검증 세션에서 수행한다. 좌표를 누를 때는 가능하면 `uiautomator` bounds를 기준으로 한다.

```powershell
adb devices
adb -s <serial> shell getprop sys.boot_completed
```

OAuth 전용 define 파일을 만든다. 이 파일은 `.dart_tool` 아래에 두고 커밋하지 않는다. Key Vault에서는 Flutter에 넣어도 되는 공개 provider 값만 읽고, provider client secret, JWT signing secret, DB password는 dart-define 파일에 쓰지 않는다.

Windows PowerShell:

```powershell
cd C:\dev\ONMU
python scripts\new-flutter-access-jwt.py `
  --vault-name $env:AZURE_KEY_VAULT_NAME `
  --oauth-only `
  --include-provider-oauth
```

macOS:

```bash
cd <ONMU repo>
./scripts/macos/new-flutter-oauth-defines.sh \
  --vault-name "$AZURE_KEY_VAULT_NAME"
```

생성되는 `.dart_tool/onmu-staging-oauth.defines.json`은 `ONMU_API_BASE_URL`, `KAKAO_REST_API_KEY`, `KAKAO_OAUTH_REDIRECT_URI`, `NAVER_OAUTH_CLIENT_ID`, `NAVER_OAUTH_REDIRECT_URI`, `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`를 포함한다. Google이 포함된 경우 iOS 빌드용 `ios/Flutter/GoogleOAuth.generated.xcconfig`도 생성되어 `GOOGLE_IOS_REVERSED_CLIENT_ID`를 제공한다. 실제 값은 문서나 채팅에 붙이지 않는다. 값 확인이 필요하면 길이와 키 이름만 출력한다.

빌드와 설치:

```powershell
cd apps\mobile-flutter
flutter pub get
flutter build apk --debug --dart-define-from-file=.dart_tool\onmu-staging-oauth.defines.json
adb -s <serial> install -r -d build\app\outputs\flutter-apk\app-debug.apk
adb -s <serial> shell pm clear io.onieum.onmu_mobile
adb -s <serial> shell am start -n "io.onieum.onmu_mobile/.MainActivity"
```

로그인 버튼을 누르기 전 로그를 비운다.

```powershell
adb -s <serial> logcat -c
```

검증 순서:

1. 로그인 화면에서 `카카오로 시작하기`, `네이버로 시작하기`, 또는 `Google로 시작하기`를 누른다.
2. Android가 Chrome 또는 provider 로그인 화면으로 이동하는지 확인한다.
3. 계정/비밀번호/2FA/동의가 필요하면 사용자가 직접 조작하게 한다.
4. 앱이 `io.onieum.onmu://oauth/<provider>/callback`으로 복귀하는지 확인한다.
5. Google은 idToken을 Spring `POST /api/v1/auth/oauth/google`로 교환하는 status/path를 확인한다.
6. 온보딩 또는 홈 화면으로 이동하는지 확인한다.
7. 앱을 강제 종료한 뒤 다시 실행해 로그인 화면이 아니라 온보딩/홈으로 돌아오는지 확인한다.

증거 수집 예시:

```powershell
adb -s <serial> shell dumpsys window | rg -n "mCurrentFocus|mFocusedApp|topResumedActivity|mResumedActivity"
adb -s <serial> exec-out uiautomator dump /dev/tty
adb -s <serial> logcat -d -v time | rg -i "onieum|onmu|kakao|naver|oauth|callback|auth|error|exception"
```

로그를 공유할 때는 다음 값을 반드시 redaction한다.

- `client_id`
- `code`
- `state`
- access token
- refresh token
- `Authorization: Bearer ...`
- 사용자 이메일, 이름, 전화번호

정상 로그 신호:

- provider authorize URL이 Chrome으로 열린다.
- Android가 `io.onieum.onmu://oauth/<provider>/callback` intent를 ONMU 앱으로 전달한다.
- `app_links`가 callback intent를 처리한다.
- 앱이 온보딩 또는 홈 화면으로 복귀한다.

## iOS smoke

iOS는 Mac 검증 세션에서 수행한다. Android와 같은 provider 공개 define을 사용하되, iOS 앱 bundle에 provider secret 또는 JWT signing secret을 넣지 않는다.

Mac에서 OAuth 전용 define 파일을 먼저 생성한다.

```bash
cd <ONMU repo>
./scripts/macos/new-flutter-oauth-defines.sh \
  --vault-name "$AZURE_KEY_VAULT_NAME"
```

검증 순서:

1. `.dart_tool/onmu-staging-oauth.defines.json`을 `--dart-define-from-file`로 넣어 실행한다.
2. provider 로그인 화면이 열린다.
3. 계정/비밀번호/2FA/동의가 필요하면 사용자가 직접 조작한다.
4. `io.onieum.onmu://oauth/<provider>/callback`을 iOS 앱이 받는지 확인한다.
5. 온보딩/홈 진입과 앱 재실행 후 세션 유지를 확인한다.

필수 정적 확인:

- `ios/Runner/Info.plist`에 `io.onieum.onmu` URL scheme이 있다.
- `ios/Runner/Info.plist`에 `$(GOOGLE_IOS_REVERSED_CLIENT_ID)` URL scheme 참조가 있고, OAuth define 생성 후 `ios/Flutter/GoogleOAuth.generated.xcconfig`가 존재한다.
- iOS bundle id가 provider console 설정과 일치한다.
- callback URL은 Spring public endpoint이고, 모바일 callback은 custom scheme이다.

## 실패 판별

| 증상 | 우선 의심 지점 | 다음 조치 |
| --- | --- | --- |
| Kakao `KOE101` 또는 Admin Settings Issue | Kakao Developers REST API key와 `KAKAO_REST_API_KEY` 불일치 | Key Vault 값과 console REST API key 길이/형식 확인, Spring 재기동, 앱 재빌드 |
| provider callback에 `error` parameter가 있음 | provider console, 동의 항목, redirect URI | provider error code만 기록하고 console 설정 확인 |
| callback에 `code`/`state`가 오지만 웹이 빈 화면 | 웹이 모바일 custom scheme을 처리하지 못함 | Android/iOS smoke로 이어서 확인 |
| Android/iOS가 앱으로 복귀하지 않음 | AndroidManifest/Info.plist deep link 설정 | `io.onieum.onmu://oauth/<provider>/callback` intent filter 또는 URL scheme 확인 |
| 앱 복귀 후 로그인 화면으로 돌아감 | Spring token exchange 또는 secure storage 저장 | 앱 로그와 Spring access log에서 status/path만 확인 |
| 앱 재실행 후 로그인 화면으로 돌아감 | 세션 저장 또는 bootstrap session restore | secure storage 저장 경로, session bootstrap 로직 확인 |
| 보호 API가 `401` | ONMU access JWT 저장/첨부 실패 | provider token을 bearer로 쓰고 있지 않은지 확인 |

## 사용자 수동 조작 지점

다음 단계는 사용자가 직접 조작하게 하고, 컨트롤러는 화면과 다음 선택지만 안내한다.

- provider 계정/비밀번호 입력
- 2FA, CAPTCHA, 본인 확인
- OAuth 동의 화면에서 계정 권한 승인
- 브라우저가 외부 앱 열기 권한을 묻는 경우

컨트롤러나 검증 세션은 사용자 credential을 입력하거나 읽지 않는다.

## 오늘 검증에서 얻은 기준

2026-06-12 Android emulator smoke 기준으로, 웹/Chrome에서는 Spring callback의 `code`/`state` 수신까지만 확인했고 데스크톱 웹은 모바일 custom scheme을 완료 처리하지 못했다. 같은 설정으로 Android 앱을 재빌드해 실행했을 때는 Chrome authorize URL, Spring callback, `io.onieum.onmu://oauth/kakao/callback` 앱 복귀, `app_links` 처리, 온보딩 화면, 홈 화면, 앱 재실행 후 세션 유지까지 확인했다.

따라서 앞으로 Kakao/Naver OAuth 완료 판정은 Android/iOS 모바일 smoke 결과를 기준으로 내린다.
