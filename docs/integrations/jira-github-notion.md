# Jira, GitHub, Notion 운영 가이드

이 문서는 ONMU 개발에서 Jira, GitHub, Notion을 어떤 역할로 나눠 쓰는지 정리합니다. 핵심은 한 가지입니다. Jira는 일정과 상태, GitHub는 코드와 검증, Notion은 맥락과 의사결정을 맡습니다.

## 도구별 역할

| 도구 | 기준 역할 | 저장하면 좋은 내용 |
| --- | --- | --- |
| Jira | 백로그, 스프린트, 담당자, 진행 상태 | Epic, Story, Task, Bug, Sprint, Release |
| GitHub | 코드, PR, 리뷰, CI/CD | 브랜치, 커밋, PR, Actions, 릴리스 태그 |
| Notion | 문서, 회의록, 결정 기록, 리서치 | 제품 설명, 회의록, 결정 로그, 회고, 링크 모음 |

운영 원칙:

- Jira 이슈가 없는 코드는 만들지 않습니다.
- GitHub PR이 없는 코드는 `dev`나 `main`에 넣지 않습니다.
- Notion은 Jira의 대체 보드로 쓰지 않습니다. Notion에는 Jira와 GitHub 링크를 붙여 맥락을 남깁니다.

## Jira 현재 구조

Jira 사이트:

```text
https://onmu.atlassian.net/jira/software/projects/SCRUM/boards/1
```

생성된 Epic:

| Key | Epic | 책임 범위 |
| --- | --- | --- |
| `SCRUM-5` | Platform / Infra | Docker, AKS, CI/CD, 관측성, 보안 |
| `SCRUM-6` | Flutter Mobile | iOS/Android 앱, 라우팅, 공통 UI, 앱 설정 |
| `SCRUM-7` | Profile & Preference | 사용자 프로필, 취향, 저장 장소 |
| `SCRUM-8` | Meetup & Realtime | 약속 생성, 참여자 상태, 실시간 협업 |
| `SCRUM-9` | Place & External API | 장소 검색, 외부 API, 후보 점수, 캐시 |
| `SCRUM-10` | Memory / Character | 사진, 기록, 캐릭터, 스티커 |
| `SCRUM-11` | Brand Web | 브랜드 및 프로젝트 소개 웹 |
| `SCRUM-12` | QA / Release / Observability | 테스트, 릴리스, 품질, 로그/알림 |

첫 백로그는 `docs/integrations/jira-bootstrap-result.md`에 기록되어 있습니다.

## 이슈 타입 사용법

| Type | 언제 쓰는가 | 작성 기준 |
| --- | --- | --- |
| Epic | 여러 스프린트에 걸친 제품/기술 영역 | 도메인 단위로 유지하고 자주 만들지 않습니다. |
| Story | 사용자가 느낄 수 있는 가치 단위 | "사용자가 무엇을 할 수 있어야 하는가"와 완료 조건을 씁니다. |
| Task | 개발, 설정, 문서, 인프라 작업 | 결과물이 명확한 기술 작업에 씁니다. |
| Bug | 기대 동작과 실제 동작이 다른 문제 | 재현 방법, 기대 동작, 환경을 적습니다. |

Story 작성 템플릿:

```text
사용자로서:
  어떤 상황에서 무엇을 하고 싶은가?

완료 조건:
  - Given ...
  - When ...
  - Then ...

연결 범위:
  - Flutter 화면:
  - API/Realtime:
  - 데이터:
  - 테스트:
```

Task 작성 템플릿:

```text
목표:
  무엇을 세팅하거나 변경하는가?

작업:
  - [ ] 구현
  - [ ] 문서
  - [ ] 검증

완료 확인:
  어떤 명령, 화면, PR로 확인할 수 있는가?
```

## 스프린트 운영 방식

권장 흐름:

| Sprint | 목표 |
| --- | --- |
| Sprint 0 | 저장소, Flutter 기본 앱, Docker Compose, CI, Jira/GitHub 연결 |
| Sprint 1 | 네 파트가 한 번씩 이어지는 얇은 세로 프로토타입 |
| Sprint 2 | 약속 생성과 실시간 참여자 상태 강화 |
| Sprint 3 | 장소 검색, 외부 API 캐시, 후보 점수 강화 |
| Sprint 4 | 사진/기록/캐릭터 결과물 강화 |
| Sprint 5 | 릴리스 품질, 테스트, 관측성, 배포 자동화 강화 |

보드 상태:

| Status | 의미 | 이동 기준 |
| --- | --- | --- |
| Backlog | 아직 스프린트에 넣지 않은 후보 | 요구사항을 더 다듬어야 합니다. |
| To Do | 이번 스프린트에서 하기로 정한 작업 | 담당자와 완료 조건이 있어야 합니다. |
| In Progress | 실제 작업 중 | 브랜치가 있거나 작업 산출물이 진행 중입니다. |
| In Review | PR, 디자인, 문서 리뷰 중 | GitHub PR 또는 Figma/문서 리뷰 링크가 있어야 합니다. |
| Blocked | 외부 승인, 권한, API 키 등으로 막힘 | 막힌 이유와 필요한 결정을 댓글로 남깁니다. |
| Done | 완료 | PR merge, 검증, 문서 반영이 끝났습니다. |

Done 기준:

- PR이 `dev`에 머지되었습니다.
- 필요한 로컬 검증 또는 CI가 통과했습니다.
- 화면 변경은 스크린샷이나 녹화가 첨부되었습니다.
- API/데이터 변경은 계약 문서 또는 테스트가 갱신되었습니다.
- 후속 작업이 있으면 새 Jira 이슈로 분리했습니다.

## Jira와 GitHub 연결 규칙

GitHub에서 Jira가 자동으로 연결되려면 `SCRUM-번호`가 필요합니다.

브랜치:

```text
feat/SCRUM-16-place-candidate-score
```

커밋:

```text
feat(place): SCRUM-16 add place candidate score
```

PR 제목:

```text
[Feat] SCRUM-16 장소 후보 점수 모델 추가
```

PR 본문:

```markdown
## 관련
- Jira: SCRUM-16
```

저장소에는 `.github/workflows/jira-sync.yml`이 있어 PR 제목이나 본문에 Jira 키가 없으면 경고를 띄웁니다. 경고는 실패가 아니라 알림입니다. 실제 강제는 GitHub for Jira 앱과 브랜치 보호 설정이 완료된 뒤 강화합니다.

## GitHub for Jira 설정

필요 작업:

1. Jira 관리자 권한으로 Atlassian Marketplace에서 GitHub for Jira 앱을 설치합니다.
2. GitHub 조직에 접근 권한을 승인합니다.
3. `Onieum/ONMU` 저장소를 연결합니다.
4. 테스트 PR을 열고 Jira 이슈 화면에 branch, commit, pull request 정보가 보이는지 확인합니다.

관리자 권한이 필요한 단계라 자동 스크립트만으로 끝나지 않을 수 있습니다. 현재 이 작업은 `SCRUM-20`에 연결되어 있습니다.

## Smart Commits 사용 기준

Smart Commits를 켜면 커밋 메시지로 Jira 댓글, 시간 기록, 상태 변경을 할 수 있습니다.

```text
SCRUM-16 #comment place API contract drafted
SCRUM-16 #time 1h 30m
SCRUM-16 #transition "In Review"
```

팀 기준:

- Jira 키는 항상 넣습니다.
- `#comment`, `#time`은 사용해도 됩니다.
- `#transition "Done"`은 초기에 금지합니다. 완료 처리는 리뷰와 검증 후 Jira에서 수동으로 합니다.
- 상태 자동화가 필요해지면 PR merge 이벤트 기준으로만 전환합니다.

## Notion 연결 방식

추천 구조:

```text
ONMU Home
  - 제품 소개
  - 릴리스 아키텍처
  - 스프린트 현황
  - 회의록
  - 결정 로그
  - 리서치
  - Jira synced database
  - GitHub PR / Release 링크 모음
```

운영 방식:

- Jira synced database로 Jira 이슈를 Notion에 읽기 형태로 보여줍니다.
- 작업 상태 수정은 Jira에서 합니다.
- Notion에는 회의 결과, 왜 그런 결정을 했는지, API 선택 이유, 디자인 합의 내용을 남깁니다.
- 결정 로그에는 관련 Jira Epic과 PR 링크를 붙입니다.
- 매 스프린트 마지막에는 "완료한 것, 남은 리스크, 다음 스프린트 후보"를 회고 페이지로 남깁니다.

중요한 금지 사항:

- Jira 작업을 Notion task database에 다시 수동으로 복사하지 않습니다.
- 같은 작업의 상태를 Jira와 Notion에서 동시에 관리하지 않습니다.
- 권한이 필요한 API 키나 계정 정보는 Notion에 쓰지 않습니다.

## 자동화 로드맵

| 단계 | 자동화 | 상태 |
| --- | --- | --- |
| 1 | PR에 Jira 키가 있는지 경고 | 설정됨 |
| 2 | GitHub for Jira로 PR/커밋/배포 표시 | 관리자 승인 필요 |
| 3 | PR merge 시 Jira 댓글 추가 | GitHub for Jira 이후 진행 |
| 4 | release tag 생성 시 Jira release version 연결 | 릴리스 파이프라인 이후 진행 |
| 5 | GitHub Actions 실패 시 Jira 댓글 또는 Teams 알림 | CI 안정화 이후 진행 |

## Jira 초기화 스크립트

저장소에는 Jira 백로그를 만드는 스크립트가 있습니다.

```bash
scripts/bootstrap-jira.mjs
```

필요 환경 변수:

```bash
export JIRA_BASE_URL="https://onmu.atlassian.net"
export JIRA_PROJECT_KEY="SCRUM"
export JIRA_EMAIL="your-atlassian-email@example.com"
export JIRA_API_TOKEN="your-api-token"
npm run jira:bootstrap
```

API 토큰을 쓰기 어렵다면 CSV를 가져옵니다.

```text
docs/integrations/jira-seed-backlog.csv
```

CSV import 시 매핑:

| CSV 열 | Jira 필드 |
| --- | --- |
| `이슈 유형` | Issue Type |
| `요약` | Summary |
| `설명` | Description |
| `라벨` | Labels |
| `Epic 이름` | Epic Name |
| `Epic 링크` | Parent 또는 Epic Link |

## 권한과 보안

- Jira 관리자, GitHub 조직 관리자, Notion 워크스페이스 관리자는 최소 인원으로 둡니다.
- 외부 API 키, Firebase 설정, Azure credential은 Jira/Notion 본문에 쓰지 않습니다.
- GitHub Secrets와 Azure Key Vault를 사용합니다.
- Jira 댓글에는 접근 가능한 링크와 결정만 남기고 secret 값은 남기지 않습니다.
- 팀원이 나가면 GitHub, Jira, Notion, Azure 권한을 함께 회수합니다.

## 참고 링크

- Atlassian CLI: https://developer.atlassian.com/cloud/acli/guides/install-acli/
- Jira Cloud REST API: https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/
- Jira Smart Commits: https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/
- GitHub for Jira: https://support.atlassian.com/jira-cloud-administration/docs/integrate-with-github/
- Notion Jira integration: https://www.notion.com/integrations/jira
