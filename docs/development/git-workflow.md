# GitHub 작업 흐름

이 문서는 ONMU 저장소에서 코드를 올리고 리뷰하는 기준입니다. Jira는 작업 계획과 상태의 기준이고, GitHub는 코드, 리뷰, CI 기록의 기준입니다.

## 브랜치 전략

```text
main  -> 안정 릴리스 브랜치
dev   -> 개발 통합 브랜치, 기본 작업 기준
type/SCRUM-번호-short-description -> 개별 작업 브랜치
```

핵심 규칙:

- 작업은 Jira 이슈를 먼저 만들고 시작합니다.
- 새 브랜치는 항상 최신 `dev`에서 만듭니다.
- `dev`와 `main`에는 PR로만 머지합니다.
- `main`은 릴리스 후보가 검증된 뒤 릴리스 PR로만 갱신합니다.
- 브랜치, 커밋, PR 제목이나 본문 중 최소 한 곳에는 Jira 키를 넣습니다.

## 브랜치 보호

ONMU 저장소는 public 저장소 기준으로 `dev`와 `main`에 브랜치 보호를 적용합니다.

| 브랜치 | 용도 | 강제 기준 |
| --- | --- | --- |
| `dev` | 개발 통합 | PR 필수, 최신 브랜치 기준 CI 통과, 리뷰 1명 이상 |
| `main` | 안정 릴리스 | PR 필수, 최신 브랜치 기준 CI 통과, 리뷰 2명 이상 |

필수 CI check:

- `Repository checks`
- `Flutter app` (`flutter analyze`만 게이트. 개발 편의를 위해 `flutter test`, gradle wrapper 확인은 로컬/릴리스로 이관)

임시 운영 배포:

- 현재 개발 단계에서는 `dev` 머지/푸시 후 `Deploy Staging VM`(`.github/workflows/deploy-staging-vm.yml`)이 Azure VM + Cloudflare 임시 운영 런타임에 자동 배포한다. 정식 운영 target(관리형) 전환은 별도 단계다. 자세한 분기는 `docs/operations/staging-cutover-status.md`를 본다.

공통 보호 기준:

- force push 금지
- 브랜치 삭제 금지
- 관리자도 보호 규칙 적용
- 대화가 해결되지 않은 PR은 머지하지 않음
- PR merge 후 작업 브랜치 자동 삭제 권장

## 일일 작업 루틴

작업 시작:

```bash
git switch dev
git pull origin dev
```

Jira 이슈 확인 후 브랜치 생성:

```bash
git switch -c feat/SCRUM-16-place-candidate-score
```

작업 후 의미 단위로 커밋:

```bash
git add <changed-files>
git commit -m "feat(place): SCRUM-16 add candidate score model"
```

검증 후 push:

```bash
npm run compose:config
uvx pre-commit run --all-files
git push -u origin feat/SCRUM-16-place-candidate-score
```

Flutter 앱을 바꿨다면 추가로 실행합니다.

```bash
cd apps/mobile-flutter
flutter pub get
flutter analyze
flutter test
```

Android Gradle 설정을 바꿨거나 Windows/CI 빌드 경로를 확인해야 하면 JDK 17 이상을 준비한 뒤 wrapper도 확인합니다.

```bash
cd apps/mobile-flutter/android
./gradlew --version
```

## 브랜치 이름

권장 형식:

```text
type/SCRUM-번호-short-description
```

허용 type:

| Type | 용도 | 예시 |
| --- | --- | --- |
| `feat` | 기능 추가 | `feat/SCRUM-16-place-candidate-score` |
| `fix` | 버그 수정 | `fix/SCRUM-31-realtime-reconnect` |
| `hotfix` | 릴리스 긴급 수정 | `hotfix/SCRUM-44-api-timeout` |
| `docs` | 문서 작업 | `docs/SCRUM-20-jira-github-guide` |
| `chore` | 의존성, 설정 | `chore/SCRUM-18-compose-env` |
| `refactor` | 구조 개선 | `refactor/SCRUM-25-room-state` |
| `test` | 테스트 보강 | `test/SCRUM-19-vertical-smoke` |
| `set` | 초기 세팅 | `set/SCRUM-18-ci-baseline` |

규칙:

- 소문자와 하이픈을 사용합니다.
- 작업 내용을 3~5단어 정도로 짧게 표현합니다.
- Jira 키를 넣기 어렵다면 PR 본문 `관련` section에 반드시 넣습니다.

## 커밋 메시지

형식:

```text
type(scope): SCRUM-번호 short description
```

허용 type:

```text
feat, fix, docs, refactor, chore, test, ci, build, perf
```

권장 scope:

```text
mobile, brand-web, api, realtime, worker, profile, meetup, place, memory, infra, ci, docs
```

예시:

```text
feat(mobile): SCRUM-13 add app flavor shell
feat(place): SCRUM-16 add place candidate contract
docs(infra): SCRUM-18 add windows backend server guide
ci(repo): SCRUM-20 check jira key in pull requests
```

## PR 규칙

PR 대상:

- 일반 작업: `작업 브랜치 -> dev`
- 릴리스: `dev -> main`

PR 제목:

```text
[Feat] SCRUM-16 장소 후보 점수 모델 추가
```

PR 본문은 저장소의 `.github/pull_request_template.md`를 사용합니다.

```markdown
## 요약
- 무엇을 왜 바꿨는지 한두 줄로 설명

## 변경 사항
- 주요 변경 파일과 동작 요약

## 검증
- 실행한 검증 명령
- UI 변경이면 스크린샷 또는 녹화 링크

## 관련
- Jira: SCRUM-16
- GitHub Issue: 필요 시 링크
```

리뷰 기준:

- `dev` 머지는 최소 1명 리뷰 후 진행합니다.
- `main` 릴리스 PR은 팀 합의와 최소 2명 리뷰 후 진행합니다.
- 머지는 squash merge를 기본으로 합니다.
- PR 머지 후 원격 작업 브랜치는 삭제합니다.

GitHub 보호 규칙은 위 기준 중 최소선을 강제합니다. 릴리스 전 판단, 디자인 승인, Jira 상태 전환은 PR 설명과 리뷰에서 별도로 확인합니다.

### Windows에서 한글 PR/Issue 본문 작성

Windows PowerShell에서 `gh pr create --body-file -`처럼 stdin pipe로 한글 본문을 넘기면 GitHub에 `??`로 저장될 수 있습니다. 한글이 포함된 Issue/PR 본문은 UTF-8 no BOM 파일로 만든 뒤 `--body-file <path>`로 전달합니다.

권장 방식:

```powershell
. .\scripts\windows\lib\utf8.ps1
Set-OnmuUtf8Console

$bodyPath = Join-Path $env:TEMP "onmu-pr-body.md"
$body = @'
## 요약
- 한글 본문을 여기에 작성합니다.
'@
Write-Utf8NoBom -Path $bodyPath -Content $body
gh pr create --base dev --head <branch> --title "<title>" --body-file $bodyPath
Remove-Item -LiteralPath $bodyPath -Force
```

생성 또는 수정 후에는 반드시 본문을 다시 확인합니다.

```powershell
gh pr view <number> --json body
gh issue view <number> --json body
```

본문에 `??`, `�`, 맨 앞 BOM 문자가 보이면 즉시 UTF-8 no BOM 파일 방식으로 `gh pr edit --body-file <path>` 또는 `gh issue edit --body-file <path>`를 실행합니다.

### Windows PowerShell 스크립트 UTF-8 기준

새 Windows `.ps1` 스크립트에서 한글 Markdown, GitHub 본문, Azure CLI stdout, JSON 파일을 다루면 공통 helper를 먼저 사용합니다.

```powershell
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\utf8.ps1")
Set-OnmuUtf8Console
```

스크립트 위치가 `scripts/windows` 하위가 아니면 helper 경로만 현재 파일 기준으로 조정합니다. 한글이 포함된 파일을 만들거나 읽을 때는 `Set-Content -Encoding UTF8`, 기본 `Get-Content`에 의존하지 않고 `Write-Utf8NoBom`, `Read-Utf8`를 사용합니다.

Azure CLI 결과에서 한글 subscription display name, PR body, Markdown 문자열을 비교할 때는 Windows PowerShell 5.x와 PowerShell 7의 인코딩 차이로 깨질 수 있습니다. 필수 gate는 한글 display name strict compare보다 resource group name, storage account name, location, status, HTTP status처럼 안정적인 필드를 우선 사용합니다. display name 비교가 꼭 필요하면 옵션성 검증으로 두고, 실패 시 식별자 실제 값은 출력하지 않습니다.

### macOS shell과 한글 자동화 기준

macOS는 기본 shell과 Git 도구가 대체로 UTF-8을 사용하지만, 자동화에서는 locale, inline body, Unicode 정규화 차이로 한글이 깨지거나 경로 비교가 흔들릴 수 있습니다. 한글 PR/Issue 본문, Markdown, Azure/GitHub CLI 출력, Flutter dart-define 파일을 다루는 macOS 스크립트는 UTF-8 locale을 명시하고 파일 기반 전달을 우선합니다.

권장 기본값:

```bash
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export PYTHONUTF8=1
```

한글 본문은 Windows와 동일하게 inline 인자보다 UTF-8 파일과 `gh ... --body-file <path>`를 우선합니다. 생성 후에는 `gh pr view <number> --json body` 또는 `gh issue view <number> --json body`로 readback을 확인합니다.

macOS에서도 한글 Azure subscription display name이나 사용자 표시명을 필수 gate로 직접 비교하지 않습니다. 자동화 gate는 resource group name, storage account name, location, status, HTTP status, count처럼 OS와 locale 영향을 덜 받는 필드를 사용합니다. 한글 파일명은 사람이 읽는 문서에는 사용할 수 있지만, 스크립트 경로와 CI 산출물 파일명은 ASCII를 우선합니다.

## GitHub 라벨과 마일스톤

라벨은 리뷰 범위를 빠르게 알려주기 위한 보조 정보입니다.

| 라벨 | 사용 시점 |
| --- | --- |
| `platform-infra` | Docker, Kubernetes, Azure, CI/CD |
| `flutter-mobile` | Flutter 앱 화면, 상태, 네이티브 설정 |
| `profile-preference` | 사용자 프로필, 취향 데이터 |
| `meetup-realtime` | 약속 생성, 참여자 상태, WebSocket |
| `place-api` | 장소 검색, 외부 API, 후보 점수 |
| `memory-character` | 사진, 기록, 캐릭터 |
| `brand-web` | 브랜드 소개 웹 |
| `release-qa` | 테스트, 릴리스, 관측성 |
| `docs` | 문서 |
| `ci` | GitHub Actions |

마일스톤은 Sprint 0~5 단위로 둡니다. Jira Sprint가 실제 진행 상태를 관리하고, GitHub 마일스톤은 PR과 코드 변경 묶음을 보기 위한 보조 지표로 사용합니다.

## 보안 체크

PR 전 확인:

- `.env`, API 키, OAuth secret, Firebase 실제 설정 파일을 커밋하지 않았는지 확인합니다.
- 실제 사용자 데이터, 위치 데이터, 사진, DB dump를 커밋하지 않습니다.
- 외부 API 키는 로컬 `.env`, GitHub Actions secrets, Azure Key Vault 중 하나에서 관리합니다.
- `uvx pre-commit run --all-files`로 기본 포맷, YAML/JSON, 시크릿 검사를 통과시킵니다.

## 의존성 관리

Dependabot은 다음 범위를 주 1회 확인합니다.

- GitHub Actions
- root npm package
- Flutter pub package

Dependabot PR도 일반 PR과 동일하게 Jira 키, 리뷰, CI 기준을 따릅니다. 보안 업데이트는 스프린트 업무보다 우선순위를 높여 처리합니다.

## AI 도구 사용 규칙

Codex, Copilot, Cursor, Claude 같은 AI 도구도 이 문서를 따라야 합니다. 팀 공통 AI 도구, MCP, Skill 운영 기준은 `docs/development/team-ai-tooling.md`를 따릅니다.

- 작업 전에 관련 Jira 이슈와 문서를 확인합니다.
- `.github/copilot-instructions.md`의 저장소 규칙을 우선합니다.
- Codex 또는 호환 에이전트는 루트 `AGENTS.md`가 있으면 우선 확인합니다.
- 자동 생성 코드라도 사람이 리뷰 가능한 크기로 PR을 나눕니다.
- AI가 만든 변경에는 실행한 검증 명령을 PR `검증` section에 남깁니다.
