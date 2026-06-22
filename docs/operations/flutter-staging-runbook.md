# Flutter staging 실행 runbook

이 문서는 ONMU Flutter 앱을 지금 팀 표준 경로대로 실행하고 검증할 때 가장 먼저 보는 문서다. 현재 기본값은 Azure staging이며, Windows dev/local은 명시 opt-in일 때만 사용한다.

## 1. 현재 기본 원칙

- `flutter run`, `flutter build apk`, `flutter build ios`를 define 없이 실행하면 기본 API base URL은 `https://staging-api.onmu.cloud`다.
- define 없이 실행하는 staging 앱의 기본 tile manifest는 Azure Front Door default endpoint `https://fde-onmustagingkrc001-hgbmd5cah5bke7c9.a01.azurefd.net/manifest.json`다.
- `tiles.onmu.cloud` custom domain은 Front Door cutover가 끝날 때까지 기본 모바일 smoke 기준으로 쓰지 않는다.
- actual OAuth smoke는 `.dart_tool/onmu-staging-oauth.defines.json`을 사용한다.
- staging 보호 API 화면 검증은 `.dart_tool/onmu-staging-api.defines.json`을 사용한다.
- Windows dev/local 또는 로컬 Spring은 `--environment dev` 또는 `-ApiBaseUrl http://127.0.0.1:8080`처럼 명시 opt-in일 때만 사용한다.
- JWT 우회 define과 actual OAuth define을 같은 실행에 섞지 않는다.

## 2. 가장 자주 쓰는 파일과 스크립트

| 용도 | 파일/스크립트 | 결과 |
| --- | --- | --- |
| staging 기본 앱 실행 | define 없음 | public staging API base URL 사용 |
| staging 보호 API 실행 | `scripts/windows/new-flutter-access-jwt.ps1`, `scripts/new-flutter-access-jwt.py`, `scripts/macos/new-flutter-access-jwt.sh` | `.dart_tool/onmu-staging-api.defines.json` 생성 |
| staging actual OAuth smoke | `scripts/new-flutter-access-jwt.py --oauth-only --include-provider-oauth`, `scripts/macos/new-flutter-oauth-defines.sh` | `.dart_tool/onmu-staging-oauth.defines.json` 생성 |
| macOS staging 실행 | `scripts/macos/run-flutter-staging-api.sh` | staging 보호 API define으로 실행 |
| Windows dev opt-in | `scripts/windows/new-flutter-access-jwt.ps1 -Environment dev` | `.dart_tool/onmu-dev-api.defines.json` 생성 |
| local Spring opt-in | 위 dev 스크립트 + `-ApiBaseUrl http://127.0.0.1:8080` | local Spring 기준 define 생성 |

## 3. 팀 표준 실행 경로

### 3.1 일반 staging 앱 실행

로그인 화면, 공개 화면, UI 기본 흐름만 보려면 define 없이 실행한다.

```powershell
cd apps\mobile-flutter
flutter run
```

```bash
cd apps/mobile-flutter
flutter run
```

판정 기준:

- 앱이 별도 staging define 없이도 staging host를 기본값으로 사용한다.
- 팀원이 fresh build를 다시 해도 dev backend로 붙지 않는다.

### 3.2 staging 보호 API 실행

보호 API 화면, `/api/v1/users/me`, 알림, 그룹 read 화면처럼 access JWT가 필요한 경우에만 staging API define을 생성한다.

Windows PowerShell:

```powershell
cd C:\dev\ONMU
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\new-flutter-access-jwt.ps1 `
  -VaultName $env:AZURE_KEY_VAULT_NAME `
  -IncludeSentry

cd apps\mobile-flutter
flutter run --dart-define-from-file=.dart_tool\onmu-staging-api.defines.json
```

macOS:

```bash
cd <ONMU repo>
./scripts/macos/new-flutter-access-jwt.sh \
  --vault-name "$AZURE_KEY_VAULT_NAME" \
  --include-sentry

./scripts/macos/run-flutter-staging-api.sh
```

판정 기준:

- define 파일명이 `.dart_tool/onmu-staging-api.defines.json`이다.
- `ONMU_API_BASE_URL`이 staging host다.
- JWT signing secret 자체는 앱 bundle이나 문서에 들어가지 않는다.
- `--include-sentry`를 쓰면 Key Vault secret `sentry-dsn` 값이 git ignored define 파일에만 들어가고, 로그에는 출력되지 않는다.

### 3.3 staging actual OAuth smoke

실제 Kakao/Naver/Google 로그인 검증은 JWT 우회 define이 아니라 OAuth 전용 define으로만 실행한다. 상세 절차는 [OAuth 모바일 smoke 검증 워크플로](./oauth-mobile-smoke.md)를 따른다.

Windows PowerShell:

```powershell
cd C:\dev\ONMU
python scripts\new-flutter-access-jwt.py `
  --vault-name $env:AZURE_KEY_VAULT_NAME `
  --oauth-only `
  --include-provider-oauth `
  --include-sentry

cd apps\mobile-flutter
flutter run --dart-define-from-file=.dart_tool\onmu-staging-oauth.defines.json
```

macOS:

```bash
cd <ONMU repo>
./scripts/macos/new-flutter-oauth-defines.sh \
  --vault-name "$AZURE_KEY_VAULT_NAME" \
  --include-sentry

cd apps/mobile-flutter
flutter run --dart-define-from-file=.dart_tool/onmu-staging-oauth.defines.json
```

Android emulator:

```powershell
cd apps\mobile-flutter
flutter build apk --debug --dart-define-from-file=.dart_tool\onmu-staging-oauth.defines.json
adb -s <serial> install -r -d build\app\outputs\flutter-apk\app-debug.apk
adb -s <serial> shell am start -n "io.onieum.onmu_mobile/.MainActivity"
```

판정 기준:

- OAuth callback host가 `staging-api.onmu.cloud`다.
- 로그인 성공 후 `/api/v1/users/me` 200과 앱 재실행 후 세션 유지까지 확인한다.

### 3.4 Sentry 모바일 smoke

Sentry 연결 확인은 실제 모바일 runtime에서 SDK가 이벤트를 보내는지까지 본다. DSN은 Key Vault secret `sentry-dsn`에서 읽되, 값 자체를 terminal, 채팅, 문서, PR 본문에 출력하지 않는다.

권장 흐름:

```bash
cd <ONMU repo>
python3 scripts/new-flutter-access-jwt.py \
  --vault-name "$AZURE_KEY_VAULT_NAME" \
  --include-sentry \
  --output-path apps/mobile-flutter/.dart_tool/onmu-sentry-smoke.defines.json

cd apps/mobile-flutter
flutter run \
  -d <ios-simulator-device-id> \
  --dart-define-from-file=.dart_tool/onmu-sentry-smoke.defines.json \
  --dart-define=SENTRY_TRACES_SAMPLE_RATE=0
```

판정 기준:

- 앱 runtime에서 의도적으로 발생시킨 reportable 오류가 Sentry Issues에 표시된다.
- Sentry UI 반영에는 수십 초 정도 지연이 있을 수 있다. 바로 안 보이면 event id, issue title, environment, tag 기준으로 다시 검색한다.
- `flutter run` 로그나 process list에 `-DSENTRY_DSN=`처럼 빈 값으로 보이면 DSN이 주입되지 않은 것이다. inline shell 변수와 `--dart-define=SENTRY_DSN="$SENTRY_DSN_VALUE"`를 한 줄에서 섞으면 이 상태가 될 수 있으므로 쓰지 않는다.
- `--dart-define-from-file`을 사용하면 DSN 값이 command line argument에 직접 노출되지 않고, git ignored define 파일에만 남는다.
- iOS 26.2 이상 simulator에서 `sentry_flutter` 8.x 계열 iOS plugin compile error가 나면 9.x 이상으로 올린 뒤 `flutter pub get`, `flutter analyze`, `flutter test`를 다시 실행한다.

## 4. dev/local opt-in 경로

### 4.1 Windows dev backend opt-in

```powershell
cd C:\dev\ONMU
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\new-flutter-access-jwt.ps1 `
  -Environment dev `
  -VaultName $env:AZURE_KEY_VAULT_NAME

cd apps\mobile-flutter
flutter run --dart-define-from-file=.dart_tool\onmu-dev-api.defines.json
```

### 4.2 local Spring opt-in

```powershell
cd C:\dev\ONMU
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\new-flutter-access-jwt.ps1 `
  -Environment dev `
  -ApiBaseUrl http://127.0.0.1:8080 `
  -VaultName $env:AZURE_KEY_VAULT_NAME
```

이 경로를 쓰지 않으면 앱 기본값은 staging이다.

## 5. 실수 방지 체크

- `.dart_tool/onmu-dev-api.defines.json`을 썼다면 dev opt-in이다.
- `.dart_tool/onmu-staging-api.defines.json` 또는 `.dart_tool/onmu-staging-oauth.defines.json`을 썼다면 staging이다.
- define 없이 실행했다면 기본은 staging이다.
- 실제 OAuth smoke에서는 `ONMU_API_ACCESS_JWT`, `ONMU_DEV_ACCESS_TOKEN`을 넣지 않는다.
- staging 검증 중인데 callback host가 `dev-api.onmu.cloud`로 보이면 잘못된 define을 사용한 것이다.
- Sentry smoke에서 DSN을 직접 `--dart-define=SENTRY_DSN=...`로 넘기지 않는다. Key Vault에서 만든 git ignored define file과 `--dart-define-from-file`을 사용한다.

## 6. 다음에 읽을 문서

1. staging actual OAuth만 확인할 때: [OAuth 모바일 smoke 검증 워크플로](./oauth-mobile-smoke.md)
2. staging 백엔드 배포/운영 순서를 볼 때: [Azure staging 배포/운영 runbook](./azure-staging-deploy-runbook.md)
3. 전체 acceptance smoke를 닫을 때: [Azure staging smoke checklist](./azure-staging-smoke-checklist.md)
4. Windows dev/rollback 경계가 필요할 때만: [Windows 노트북 백엔드 서버 세팅 가이드](./windows-backend-server.md)
