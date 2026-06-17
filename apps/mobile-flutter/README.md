# ONMU 모바일

ONMU 핵심 제품을 위한 Flutter 앱입니다.

## 프로토타입 목표

첫 앱 골격은 네 가지 전달 파트를 연결합니다.

1. 프로필 취향
2. 약속 방과 실시간 협업
3. 장소 후보와 외부 API 데이터
4. 기억 카드와 캐릭터 요소

## 로컬 명령

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

`flutter run`, `flutter build apk`, `flutter build ios`를 define 없이 실행하면 기본 API base URL은 `https://staging-api.onmu.cloud`입니다. 현재 팀 표준 검증 동선은 Azure staging을 기본값으로 두고, Windows dev 또는 로컬 Spring은 명시 opt-in define으로만 연결합니다. 보호 API 화면까지 검증하려면 아래 Azure staging API mode처럼 짧은 수명의 JWT가 들어간 dart-define 파일을 함께 전달합니다.

## MapLibre 지도 manifest

지도 화면은 PMTiles object URL을 앱에 직접 넣지 않고 tile manifest pointer를 읽습니다.

- 기본 manifest: `https://tiles.onmu.cloud/manifest.json`
- 로컬 MinIO smoke: `--dart-define=ONMU_TILE_MANIFEST_URL=http://localhost:9000/onmu-tiles/tiles/manifest.json`

Flutter web은 `web/index.html`에서 MapLibre GL JS/CSS를 로드합니다. Spring 장소 검색과 동선 추천 API credential은 서버 환경변수로만 주입하고 Flutter bundle에는 넣지 않습니다.

## Azure staging API mode

Azure staging 보호 화면을 검증할 때는 정적 token을 넣지 말고, Key Vault의 `staging-access-token-secret`으로 짧은 수명의 access JWT를 발급해 사용합니다. token 값은 콘솔에 출력하지 않고 `.dart_tool/onmu-staging-api.defines.json`에만 저장합니다.

Windows PowerShell:

```powershell
cd C:\dev\ONMU
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\new-flutter-access-jwt.ps1 `
  -VaultName $env:AZURE_KEY_VAULT_NAME

cd apps\mobile-flutter
flutter run --dart-define-from-file=.dart_tool\onmu-staging-api.defines.json
```

macOS:

```bash
cd <ONMU repo>
./scripts/macos/new-flutter-access-jwt.sh \
  --vault-name "$AZURE_KEY_VAULT_NAME"

./scripts/macos/run-flutter-staging-api.sh
```

Provider 로그인을 실제 Android/iPhone 기기에서 smoke할 때는 JWT 우회용 define이 아니라 OAuth 전용 공개 define 파일을 사용합니다. Mac에서는 Key Vault에서 Flutter에 필요한 공개 provider 값만 읽어 `.dart_tool/onmu-staging-oauth.defines.json`을 만들 수 있습니다. Google iOS 로그인을 위해 같은 명령이 `ios/Flutter/GoogleOAuth.generated.xcconfig`도 생성합니다. 이 파일들에는 `KAKAO_REST_API_KEY`, `NAVER_OAUTH_CLIENT_ID`, `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`, Google iOS reversed client id와 redirect URI만 들어가며, `KAKAO_CLIENT_SECRET`, `NAVER_OAUTH_CLIENT_SECRET`, JWT signing secret, DB password는 들어가지 않습니다.

Windows PowerShell:

```powershell
cd C:\dev\ONMU
python scripts\new-flutter-access-jwt.py `
  --vault-name $env:AZURE_KEY_VAULT_NAME `
  --oauth-only `
  --include-provider-oauth

cd apps\mobile-flutter
flutter run --dart-define-from-file=.dart_tool\onmu-staging-oauth.defines.json
```

macOS:

```bash
cd <ONMU repo>
./scripts/macos/new-flutter-oauth-defines.sh \
  --vault-name "$AZURE_KEY_VAULT_NAME"

cd apps/mobile-flutter
flutter run -d <ios-device-or-simulator> \
  --dart-define-from-file=.dart_tool/onmu-staging-oauth.defines.json
```

Android emulator smoke도 같은 define 파일을 사용합니다.

```powershell
cd apps\mobile-flutter
flutter build apk --debug --dart-define-from-file=.dart_tool\onmu-staging-oauth.defines.json
adb -s <serial> install -r -d build\app\outputs\flutter-apk\app-debug.apk
adb -s <serial> shell am start -n "io.onieum.onmu_mobile/.MainActivity"
```

Kakao 인증 페이지에서 `Admin Settings Issue (KOE101)`이 보이면 앱 코드보다 Kakao Developers 앱 키 설정을 먼저 확인합니다.

- Key Vault `staging-kakao-rest-api-key`가 ONMU Kakao Developers 앱의 REST API 키와 정확히 일치해야 합니다.
- `staging-kakao-rest-api-key`는 앞뒤 공백이나 따옴표 없이 32자리 hex 형태여야 합니다.
- Kakao Developers 로그인 Redirect URI에 `https://staging-api.onmu.cloud/api/v1/auth/oauth/kakao/callback`이 등록되어 있어야 합니다.
- iPhone smoke 전 Kakao Developers 네이티브 앱 키의 iOS 번들 ID에 `io.onieum.onmuMobile`이 등록되어 있어야 합니다.
- Key Vault 값을 고친 뒤에는 Flutter 앱을 같은 dart-define 파일로 다시 빌드/실행해야 합니다.

`run-flutter-staging-api.sh`는 Flutter web을 `127.0.0.1:5173`에서 실행합니다. 현재 기본 검증 대상은 Azure staging이므로 Mac 브라우저 검증도 이 기준을 우선 사용합니다. `ONMU_ACCESS_TOKEN_SECRET`이 이미 로컬 환경변수에 있으면 macOS JWT 스크립트는 Key Vault를 호출하지 않습니다.

`flutter run -d web-server`는 hot reload에는 적합하지만 `/home`, `/groups` 같은 Flutter path URL을 브라우저에서 직접 새로고침하면 dev server가 `index.html`로 fallback하지 않아 `404`가 날 수 있습니다. 인앱 브라우저에서 path URL을 직접 열거나 새로고침까지 검증할 때는 build 산출물을 SPA fallback 서버로 실행합니다.

```bash
cd <ONMU repo>/apps/mobile-flutter
flutter build web --dart-define-from-file=.dart_tool/onmu-staging-api.defines.json

cd <ONMU repo>
./scripts/macos/serve-flutter-web-spa.sh --port 5173
```

Windows에서 `flutter build web` 산출물을 정적 서버로 확인할 때는 Python `http.server` 대신 SPA fallback 서버를 사용합니다. Flutter 라우트인 `/home`, `/groups`, `/onboarding`을 직접 새로고침해도 `index.html`로 돌아가야 브라우저 검증이 안정적입니다.

```powershell
cd C:\dev\ONMU
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\serve-flutter-web-spa.ps1 `
  -WebRoot apps\mobile-flutter\build\web `
  -Port 5173
```

## Windows dev / local opt-in mode

Windows dev backend나 로컬 Spring을 확인하고 싶다면 명시적으로 환경을 지정합니다. 이 경로를 쓰지 않으면 앱 기본값은 staging입니다.

Windows PowerShell:

```powershell
cd C:\dev\ONMU
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\new-flutter-access-jwt.ps1 `
  -Environment dev `
  -VaultName $env:AZURE_KEY_VAULT_NAME

cd apps\mobile-flutter
flutter run --dart-define-from-file=.dart_tool\onmu-dev-api.defines.json
```

macOS:

```bash
cd <ONMU repo>
./scripts/macos/new-flutter-access-jwt.sh \
  --environment dev \
  --vault-name "$AZURE_KEY_VAULT_NAME"

./scripts/macos/run-flutter-dev-api.sh
```

로컬 Spring을 직접 볼 때는 base URL을 지정합니다.

```powershell
cd C:\dev\ONMU
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\new-flutter-access-jwt.ps1 `
  -Environment dev `
  -ApiBaseUrl http://127.0.0.1:8080 `
  -VaultName $env:AZURE_KEY_VAULT_NAME
```

```bash
cd <ONMU repo>
./scripts/macos/new-flutter-access-jwt.sh \
  --environment dev \
  --api-base-url http://127.0.0.1:8080 \
  --vault-name "$AZURE_KEY_VAULT_NAME"
```

## 플레이버 방향

앱은 다음 플레이버를 지원해야 합니다.

- `dev`
- `staging`
- `prod`

첫 백엔드 통합 스프린트 전에 플레이버별 API base URL을 설정해야 합니다.

## OAuth 로그인 경계

Flutter는 provider access token이나 authorization code를 Spring `POST /api/v1/auth/oauth/{provider}`로 전달하고, Spring이 provider 검증 뒤 발급한 ONMU access JWT와 refresh token만 저장합니다. 보호된 `/api/v1/**` 요청의 `Authorization` bearer token은 ONMU access JWT여야 하며, Kakao/Naver/Google provider access token을 직접 넣지 않습니다.

Kakao 버튼은 browser authorization-code 흐름을 사용합니다. Flutter는 `KAKAO_REST_API_KEY`(또는 호환 alias `KAKAO_OAUTH_CLIENT_ID`)와 `KAKAO_OAUTH_REDIRECT_URI` dart-define으로 Kakao 인증 URL을 열고, `io.onieum.onmu://oauth/kakao/callback` deep link에서 받은 `authorizationCode`와 `state`를 Spring `POST /api/v1/auth/oauth/kakao`로 전달합니다. Spring은 서버 환경변수의 `KAKAO_REST_API_KEY`와 선택적 `KAKAO_CLIENT_SECRET`으로 provider token을 교환하고 ONMU access JWT와 refresh token을 발급합니다.

Naver 버튼은 browser authorization-code 흐름을 사용합니다. Flutter는 `NAVER_OAUTH_CLIENT_ID`와 `NAVER_OAUTH_REDIRECT_URI` dart-define으로 Naver 인증 URL을 열고, `io.onieum.onmu://oauth/naver/callback` deep link에서 받은 `authorizationCode`와 `state`를 Spring `POST /api/v1/auth/oauth/naver`로 전달합니다. Spring은 서버 환경변수의 `NAVER_OAUTH_CLIENT_SECRET`으로 provider token을 교환하고 ONMU access JWT와 refresh token을 발급합니다.

Google 버튼은 Google idToken을 Spring `POST /api/v1/auth/oauth/google`의 `providerIdToken`으로 전달하고, Spring이 Google tokeninfo 검증 뒤 발급한 ONMU access JWT와 refresh token만 저장합니다.

`KAKAO_CLIENT_SECRET`은 Spring 서버 환경변수 또는 Key Vault secret 역할로만 관리합니다. Flutter dart-define, 앱 bundle, 문서 본문에는 secret 값을 넣지 않습니다.

`NAVER_OAUTH_CLIENT_SECRET`도 Spring 서버 환경변수 또는 Key Vault secret 역할로만 관리합니다. Flutter dart-define, 앱 bundle, 문서 본문에는 secret 값을 넣지 않습니다.

로컬 Spring callback을 사용할 때는 `KAKAO_OAUTH_REDIRECT_URI=http://localhost:8080/api/v1/auth/oauth/kakao/callback`, `NAVER_OAUTH_REDIRECT_URI=http://localhost:8080/api/v1/auth/oauth/naver/callback`처럼 각 provider 콘솔에 등록된 callback URL 중 하나를 dart-define으로 지정합니다.
