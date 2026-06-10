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

`flutter run` 기본값은 Windows dev Spring API(`https://dev-api.onmu.cloud`)를 바라봅니다. 보호 API 화면까지 검증하려면 아래 Spring dev API mode처럼 짧은 수명의 JWT가 들어간 dart-define 파일을 함께 전달합니다. token 없이 실행하면 앱은 dev API base URL을 사용하지만 보호 API 요청은 401이 날 수 있습니다.

## Spring dev API mode

Windows dev Spring API 보호 화면을 검증할 때는 정적 `dev-api-access-token`을 넣지 말고, Key Vault의 `dev-access-token-secret`으로 짧은 수명의 access JWT를 발급해 사용합니다. token 값은 콘솔에 출력하지 않고 `.dart_tool/onmu-dev-api.defines.json`에만 저장합니다.

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

`run-flutter-dev-api.sh`는 Flutter web을 `127.0.0.1:5173`에서 실행합니다. 이 포트는 dev Spring CORS 허용 origin에 포함되어 있으므로 Mac 브라우저 검증은 이 포트를 기준으로 맞춥니다. `ONMU_ACCESS_TOKEN_SECRET`이 이미 로컬 환경변수에 있으면 macOS JWT 스크립트는 Key Vault를 호출하지 않습니다.

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

Kakao 버튼은 Spring exchange 경로를 사용하도록 분리되어 있습니다. 현재 Flutter bundle에는 Kakao native/web SDK 설정이 없으므로 기본 Kakao credential acquisition은 안전하게 실패하며, SDK 설정이 완료되면 같은 provider credential seam에 Kakao provider access token 또는 authorization code를 연결합니다.

Naver는 기존 dev scaffold를 유지하되 최종 앱 세션은 Spring OAuth exchange 응답으로 받은 ONMU token을 기준으로 만듭니다. Google은 이후 idToken 검증 provider를 Spring에 추가할 때까지 ONMU 인증 완료 세션으로 처리하지 않고 안전하게 실패합니다.

`KAKAO_CLIENT_SECRET`은 Spring 서버 환경변수 또는 Key Vault secret 역할로만 관리합니다. Flutter dart-define, 앱 bundle, 문서 본문에는 secret 값을 넣지 않습니다.
