# Jira 초기화 결과

`https://onmu.atlassian.net`의 Jira project `SCRUM`에 생성했습니다.

Jira 온보딩에서 자동 생성된 sample issue는 삭제했습니다. 보드는 ONMU 전용 작업만 있는 상태로 시작합니다.

## Epic

| 키 | Epic |
| --- | --- |
| `SCRUM-5` | Platform / Infra |
| `SCRUM-6` | Flutter Mobile |
| `SCRUM-7` | Profile & Preference |
| `SCRUM-8` | Meetup & Realtime |
| `SCRUM-9` | Place & External API |
| `SCRUM-10` | Memory / Character |
| `SCRUM-11` | Brand Web |
| `SCRUM-12` | QA / Release / Observability |

## 첫 백로그

| 키 | 유형 | 요약 |
| --- | --- | --- |
| `SCRUM-13` | Story | `dev`/`staging`/`prod` flavor가 있는 Flutter 앱 skeleton 구축 |
| `SCRUM-14` | Story | 프로필 취향 입력 흐름 생성 |
| `SCRUM-15` | Story | 약속 방과 참여자 join 흐름 생성 |
| `SCRUM-16` | Story | 장소 후보 검색과 점수화 prototype 추가 |
| `SCRUM-17` | Story | 약속 결정 이후 기억 카드 stub 생성 |
| `SCRUM-18` | Story | 로컬 Compose와 AKS staging baseline 준비 |
| `SCRUM-19` | Story | 세로 prototype smoke test 정의 |
| `SCRUM-20` | Task | GitHub 저장소를 Jira에 연결 |
| `SCRUM-21` | Task | Notion 프로젝트 허브 생성 |
| `SCRUM-22` | Task | 브랜드 웹 콘텐츠 구조 초안 작성 |
| `SCRUM-23` | Task | GitHub plan이 지원되면 branch protection 활성화 |

## 추가 세팅 기록

2026년 5월 26일 저장소를 public으로 전환한 뒤 GitHub 설정을 보강했습니다.

| 항목 | 결과 |
| --- | --- |
| 기본 브랜치 | `dev` |
| 브랜치 보호 | `dev`, `main` 적용 |
| 필수 CI check | `Repository checks`, `Flutter app` |
| 리뷰 기준 | `dev` 1명 이상, `main` 2명 이상 |
| Dependabot | GitHub Actions, npm, Flutter pub 주간 점검 |
| Android Gradle wrapper | 저장소에 포함 |

`SCRUM-23`은 GitHub plan 제한이 풀린 뒤 수행해야 했던 작업이므로, public 전환 이후 완료된 것으로 봅니다.
