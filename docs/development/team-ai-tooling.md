# ONMU 팀 AI 도구, MCP, Skill 운영 가이드

## 1. 문서 목적

이 문서는 ONMU 팀 프로젝트에서 Codex, GitHub Copilot, Cursor, Claude 같은 AI 도구를 함께 사용할 때 공통으로 지킬 기준을 정리한다.

핵심은 다음과 같다.

1. 도구가 달라도 같은 저장소 규칙을 읽게 한다.
2. MCP는 필요한 범위만 연결하고, secret과 개인정보를 노출하지 않는다.
3. `SKILL.md`는 반복 작업 절차를 고정하는 용도로 사용한다.
4. Flutter 디자인 시스템, Jira/GitHub workflow, Azure/AWS 아키텍처가 AI 도구마다 다르게 해석되지 않게 한다.

## 2. 용어 정리

| 항목 | 역할 | ONMU에서의 사용 방식 |
| --- | --- | --- |
| `AGENTS.md` | Codex 계열 에이전트가 저장소 규칙을 읽는 기준 파일 | 저장소 루트에 두고, 언어/브랜치/Flutter/보안/검증 규칙을 짧게 고정한다. |
| `.github/copilot-instructions.md` | GitHub Copilot이 참고하는 저장소 규칙 | 이미 존재하는 파일이다. `AGENTS.md`와 같은 방향으로 유지한다. |
| `.cursor/rules` | Cursor에서 경로별 규칙을 적용하는 방식 | Cursor 사용 팀원이 있으면 선택적으로 둔다. 긴 규칙을 복사하지 말고 docs 링크만 둔다. |
| `CLAUDE.md` | Claude Code 사용 시 프로젝트 지침으로 쓰는 파일 | Claude 사용 팀원이 있으면 선택적으로 둔다. `AGENTS.md`와 중복 작성하지 않는다. |
| `SKILL.md` | 특정 작업을 반복 가능하게 만드는 절차 문서 | Flutter 화면 구현, 아키텍처 업데이트, PR 리뷰, 배포 점검 같은 팀 반복 작업에 사용한다. |
| MCP | AI 도구가 외부 도구/데이터에 접근하는 표준 연결 방식 | GitHub, Jira, Notion, Browser, Azure 같은 도구를 연결하되 권한과 secret 관리를 엄격히 한다. |

## 3. 팀 공통 기준 파일 우선순위

AI 도구가 서로 다른 답을 하지 않게 아래 순서로 기준을 둔다.

1. `AGENTS.md`
2. `.github/copilot-instructions.md`
3. `docs/development/team-ai-tooling.md`
4. `docs/design/DESIGN.md`
5. `docs/architecture/current-architecture-diagram.md`
6. `docs/development/git-workflow.md`

팀원이 다른 AI 도구를 쓰더라도 새 규칙을 각 도구에 복사해서 흩뿌리지 않는다. 루트 규칙 파일은 짧게 두고, 자세한 내용은 `docs`의 기준 문서로 연결한다.

`docs/development/codex-flutter-design-workflow.md`는 참고용 문서다. `AGENTS.md`, Copilot instructions, Skill 필수 문서 목록에는 넣지 않는다.

## 4. ONMU 추천 MCP 구성

MCP는 많이 붙일수록 좋아지는 것이 아니다. 팀 프로젝트에서는 필요한 도구만 붙이고, 읽기 권한과 쓰기 권한을 분리하는 것이 안전하다.

| 우선순위 | MCP/도구 | 권장 여부 | 사용 목적 | 권한 기준 |
| ---: | --- | --- | --- | --- |
| 1 | GitHub MCP 또는 GitHub Connector | 권장 | 이슈, PR, 코드 리뷰, Actions 상태 확인 | 개인 계정 최소 권한. main/dev 직접 push 금지. |
| 1 | Browser/Chrome 자동화 | 권장 | Jira, GitHub, 배포 페이지, Flutter 웹 미리보기 확인 | 로그인 세션을 쓰되 secret 입력 자동화는 피한다. |
| 1 | Filesystem 또는 로컬 파일 접근 | 권장 | 저장소 파일 읽기/수정 | ONMU 저장소 루트 안으로 범위를 제한한다. |
| 2 | Jira/Atlassian MCP | 권장 | Sprint, Epic, Story, Task 생성/상태 변경 | 프로젝트 범위 권한만 부여한다. 관리자 권한은 피한다. |
| 2 | Notion MCP | 권장 | 회의록, 의사결정, 발표 자료 초안 정리 | 팀 워크스페이스 중 ONMU 페이지만 접근하게 제한한다. |
| 2 | Azure MCP 또는 Azure CLI | 권장 | 리소스 조회, 배포 상태, 비용/로그 확인 | 조회 권한부터 시작하고, 배포/삭제 권한은 별도 승인 후 사용한다. |
| 3 | AWS MCP 또는 AWS CLI | 선택 | S3 백업, CloudFront, Route 53, Lambda 실험 | ONMU sandbox 계정/role만 사용한다. 루트 계정 사용 금지. |
| 3 | PostgreSQL MCP | 제한적 | 스키마 확인, read-only 쿼리 | 운영 DB 직접 연결 금지. 로컬 또는 staging read-only만 허용한다. |
| 3 | Figma MCP | 현재 제외 | Figma 디자인 가져오기/수정 | 현재 ONMU는 Figma 없이 Codex+Markdown+Flutter 기준으로 진행한다. |

## 5. MCP 보안 원칙

MCP는 AI에게 도구 사용 능력을 주는 것이므로 권한 관리가 중요하다.

| 원칙 | 설명 |
| --- | --- |
| 저장소에 실제 MCP 설정을 커밋하지 않는다. | 토큰, 로컬 경로, 계정 정보가 들어갈 수 있다. 예시는 `.example`로만 둔다. |
| 개인 토큰은 최소 권한으로 만든다. | GitHub는 repo 범위, Jira/Notion은 ONMU 프로젝트 범위만 허용한다. |
| 운영 DB, 운영 Redis, 운영 Storage 직접 연결을 피한다. | AI 도구는 local 또는 staging read-only부터 사용한다. |
| 삭제/배포/결제 관련 작업은 사람 승인 후 실행한다. | Azure/AWS 리소스 삭제, 비용 발생 작업, 도메인 변경은 자동 실행하지 않는다. |
| secret은 Key Vault, GitHub Secrets, 로컬 `.env`에 둔다. | Jira, Notion, Markdown, PR 본문에 secret을 적지 않는다. |
| MCP 로그에 개인정보를 남기지 않는다. | 실제 사용자 사진, 위치, 전화번호, 결제/정산 정보는 테스트 데이터로 대체한다. |

Notification / Push / Devices처럼 Terraform 전환과 앱 런타임 변경이 함께 걸린 문서 작업에서는 소유 경계를 먼저 분리한다. Terraform/Azure 작업은 Key Vault, Managed Identity, Service Bus/Event Queue, Application Insights, runtime identity, provider secret reference 같은 클라우드 리소스 경계를 만든다. DB table, index, enum-like 체크 제약, seed/default preference 같은 schema와 데이터 계약은 Spring Flyway가 소유하며 Terraform으로 생성하지 않는다. AI Agent는 provider secret 값, JWT signing secret, OAuth secret을 출력하거나 Flutter bundle에 넣는 제안을 하지 않는다.

## 6. 추천 Skill 목록

`SKILL.md`는 "AI에게 매번 설명하기 귀찮은 반복 절차"를 고정하는 문서다. 팀 공통으로 아래 skill을 준비하면 좋다.

| Skill | 목적 | 주요 입력 | 주요 출력 |
| --- | --- | --- | --- |
| `flutter-screen-implementation` | 요구사항의 한 화면을 Flutter 코드로 구현 | 라우트, 기능 요구사항, 디자인 기준 | page, shared widget, provider, widget test |
| `flutter-design-review` | 구현된 화면이 디자인 시스템을 지켰는지 검토 | Flutter 파일, 스크린샷 | 색상/간격/컴포넌트 위반 목록 |
| `architecture-update` | 피드백을 아키텍처 문서와 다이어그램에 반영 | 피드백 문서, 현재 아키텍처 | Mermaid/PNG 업데이트, 기술 스택 표 |
| `jira-backlog-sync` | 문서 변경을 Jira Epic/Story/Task로 나눔 | docs 변경 내용 | Jira 등록용 이슈 목록 |
| `pr-review-checklist` | PR 리뷰 기준을 통일 | PR diff, 관련 Jira | 버그/리스크/테스트 누락 |
| `release-readiness` | 데모/배포 전 점검 | release checklist, CI 결과 | 배포 가능/보류 판단 |
| `docs-korean-style` | 문서와 주석의 한국어 스타일 통일 | Markdown, 코드 주석 | 수정 제안 또는 패치 |
| `security-secret-audit` | secret/개인정보 유출 점검 | diff, 설정 파일 | 위험 파일/문자열 목록 |

## 7. Skill 파일 템플릿

팀 skill은 저장소에 바로 실행 파일처럼 두기보다, 우선 `docs/development/ai-skills` 아래 템플릿으로 관리한다. 각 도구에 설치할 때는 이 템플릿을 복사해서 사용한다.

예시:

```text
docs/development/ai-skills
├── flutter-screen-implementation
│   └── SKILL.md
├── architecture-update
│   └── SKILL.md
└── pr-review-checklist
    └── SKILL.md
```

`flutter-screen-implementation/SKILL.md` 예시:

```md
# Flutter Screen Implementation Skill

## 언제 사용하나

ONMU의 특정 라우트, 기능 요구사항, 또는 화면 설명을 Flutter 화면으로 구현할 때 사용한다.

## 반드시 먼저 읽을 문서

1. `AGENTS.md`
2. `docs/design/DESIGN.md`
3. `docs/development/team-ai-tooling.md`
4. 관련 Jira 이슈 또는 기능 요구사항 문서

## 작업 순서

1. 대상 라우트, 사용자 흐름, 입력/출력 데이터를 확인한다.
2. 필요한 공통 컴포넌트를 먼저 나열한다.
3. 새 파일과 수정 파일 계획을 작성한다.
4. `shared/widgets`에 재사용 컴포넌트를 만든다.
5. feature page를 만든다.
6. Riverpod provider/state가 필요하면 presentation/application/data 경계를 나눠 만든다.
7. `flutter analyze`와 관련 widget test를 실행한다.
8. 결과 요약에 실행한 검증 명령을 남긴다.

## 금지

- 스크린샷을 배경 이미지로 붙여서 UI를 끝내지 않는다.
- 화면 코드에서 `Color(0x...)`, `Colors.*`, 직접 `TextStyle(...)`을 반복하지 않는다.
- 하나의 build method에 전체 화면을 몰아넣지 않는다.
```

## 8. MCP와 Skill을 함께 쓰는 작업 흐름

### Flutter 화면 구현

```text
Jira MCP 또는 Browser로 작업 이슈 확인
-> GitHub MCP로 관련 PR/branch 확인
-> Filesystem으로 AGENTS.md와 docs/design/DESIGN.md 읽기
-> flutter-screen-implementation skill 실행
-> 로컬 Flutter 테스트 실행
-> GitHub PR 생성/업데이트
```

### 아키텍처 문서 업데이트

```text
회의록 또는 피드백 문서 확인
-> architecture-update skill 실행
-> Mermaid 다이어그램 갱신
-> PNG/SVG 산출물 생성
-> docs 링크 검증
-> PR에 변경 요약과 검증 명령 작성
```

### Jira 백로그 업데이트

```text
docs 변경 내용 확인
-> jira-backlog-sync skill 실행
-> Epic/Story/Task 후보 생성
-> 사람 검토 후 Jira 등록
-> GitHub 이슈/PR과 연결
```

## 9. 팀원별 권장 세팅

| 역할 | 추천 도구 | 이유 |
| --- | --- | --- |
| Flutter UI 담당 | Codex, Browser, GitHub MCP, Filesystem | 화면 구현과 검증 루프가 중요하다. |
| 백엔드/API 담당 | Codex, GitHub MCP, PostgreSQL read-only, Browser | API 계약, DB 스키마, PR 리뷰가 중요하다. |
| 인프라 담당 | Codex, Azure CLI/MCP, AWS CLI/MCP, GitHub MCP | Azure/AWS 리소스와 CI/CD 흐름을 봐야 한다. |
| 기획/문서 담당 | Codex, Notion MCP, Jira MCP, Browser | 회의록, 백로그, 발표 문서 연결이 중요하다. |
| 디자인/QA 담당 | Browser, Flutter screenshot, GitHub MCP | 화면 스냅샷과 이슈 등록이 중요하다. |

## 10. 팀 공통 금지 사항

- AI 도구에게 GitHub/Jira/Notion 관리자 권한을 주지 않는다.
- 운영 DB를 MCP에 직접 연결하지 않는다.
- 실제 API key, access token, refresh token을 채팅이나 Markdown에 붙이지 않는다.
- AI가 만든 PR을 검토 없이 merge하지 않는다.
- Figma를 쓰지 않는 현재 workflow에서 Figma MCP를 필수 도구로 만들지 않는다.
- 같은 규칙을 `AGENTS.md`, `CLAUDE.md`, `.cursor/rules`, Copilot instructions에 서로 다르게 복사하지 않는다.

## 11. ONMU에서 지금 바로 할 일

| 우선순위 | 작업 |
| ---: | --- |
| 1 | 루트 `AGENTS.md`를 만들고 `.github/copilot-instructions.md`와 같은 기준을 보게 한다. 완료됨. |
| 1 | `docs/design/DESIGN.md`를 Flutter 디자인 시스템 기준 문서로 고정한다. 완료됨. |
| 1 | `flutter-screen-implementation`, `architecture-update`, `pr-review-checklist` skill 템플릿을 만든다. 완료됨. |
| 2 | Jira/Notion/GitHub MCP 사용 여부를 팀원별로 정한다. |
| 2 | Azure/AWS MCP 또는 CLI는 인프라 담당자부터 read-only로 시작한다. |
| 2 | PR 템플릿에 "AI 사용 여부와 검증 명령" 항목을 유지한다. |
| 3 | Figma 없는 workflow가 안정화된 뒤 필요한 경우에만 Figma MCP를 재검토한다. |

## 12. 실제 세팅 순서

### 12.1 모든 팀원 공통

1. ONMU 저장소를 clone한다.
2. 사용하는 AI 도구에서 ONMU 저장소 루트를 workspace로 연다.
3. 작업 시작 전에 루트 `AGENTS.md`를 확인한다.
4. Flutter 화면 작업이면 `docs/design/DESIGN.md`를 확인한다.
5. PR을 만들 때는 실행한 검증 명령을 PR 본문에 적는다.

### 12.2 Codex 사용자

Codex는 루트 `AGENTS.md`를 기준으로 작업하게 한다.

권장 첫 요청:

```text
AGENTS.md와 docs/development/team-ai-tooling.md를 먼저 읽고,
ONMU Flutter 화면 구현 규칙을 요약해줘.
그 다음 docs/design/DESIGN.md를 기준으로 /ootd/method 화면 구현 계획을 세워줘.
아직 코드는 수정하지 마.
```

MCP나 플러그인은 필요한 것만 켠다.

- GitHub: PR, issue, Actions 확인
- Browser/Chrome: Jira, GitHub, 배포 페이지 확인
- Azure/AWS: 인프라 담당자만 read-only부터 시작

### 12.3 GitHub Copilot 사용자

Copilot은 `.github/copilot-instructions.md`를 기준으로 작업한다.

작업 전에 Copilot Chat에 아래처럼 요청한다.

```text
.github/copilot-instructions.md와 docs/development/team-ai-tooling.md를 기준으로
이 저장소의 Flutter UI 규칙과 PR 검증 규칙을 요약해줘.
```

### 12.4 Cursor 사용자

Cursor를 쓰는 팀원은 `.cursor/rules`를 선택적으로 만든다. 단, 긴 규칙을 복사하지 말고 문서 링크만 둔다.

예시:

```md
---
description: ONMU repository rules
alwaysApply: true
---

- Read `AGENTS.md` first.
- Follow `docs/development/team-ai-tooling.md`.
- For Flutter UI, follow `docs/design/DESIGN.md`.
- Do not hardcode colors, text styles, or spacing outside ONMU theme tokens.
- Do not commit secrets or local MCP configuration.
```

### 12.5 Claude Code 사용자

Claude Code를 쓰는 팀원은 `CLAUDE.md`를 선택적으로 만든다. 내용은 `AGENTS.md`를 다시 길게 복사하지 않고 연결만 둔다.

예시:

```md
# ONMU Claude Rules

- Read `AGENTS.md` first.
- Follow `docs/development/team-ai-tooling.md`.
- For Flutter UI, follow `docs/design/DESIGN.md`.
- For Git workflow, follow `docs/development/git-workflow.md`.
```

### 12.6 Skill 템플릿 사용법

팀 skill 템플릿은 아래 위치에 있다.

```text
docs/development/ai-skills
├── architecture-update/SKILL.md
├── flutter-screen-implementation/SKILL.md
└── pr-review-checklist/SKILL.md
```

Codex에서 사용할 때는 이렇게 요청한다.

```text
docs/development/ai-skills/flutter-screen-implementation/SKILL.md 절차를 따라
docs/design/DESIGN.md의 디자인 기준으로 /ootd/method 화면을 구현해줘.
먼저 사용할 공통 컴포넌트와 수정 파일 계획을 말해줘.
```

### 12.7 MCP 세팅 원칙

MCP 설정 파일은 도구마다 위치가 다르고 개인 토큰이 들어갈 수 있으므로 저장소에 커밋하지 않는다.

저장소에 남길 수 있는 것은 다음뿐이다.

- 어떤 MCP를 쓸지에 대한 목록
- 권한 기준
- read-only로 시작한다는 원칙
- secret을 어디에 저장할지에 대한 설명
- `.example` 형태의 샘플

실제 토큰과 개인 로컬 경로가 들어간 설정은 각자 로컬에만 둔다.

## 13. 공식 참고 문서

- [Model Context Protocol architecture](https://modelcontextprotocol.io/docs/learn/architecture)
- [OpenAI Codex AGENTS.md 안내](https://github.com/openai/codex/blob/main/docs/agents_md.md)
- [Cursor Rules 공식 문서](https://docs.cursor.com/en/context)
- [Claude Code memory 공식 문서](https://docs.anthropic.com/en/docs/claude-code/memory)
