# ONMU 백엔드 기술스택 선택지

## 결정 상태

Flutter는 확정이다. 백엔드 Main API는 아직 확정하지 않고, Sprint 0 spike 후 팀 논의로 결정한다.

## 선택지

| 선택지 | 설명 | 장점 | 주의점 |
| --- | --- | --- | --- |
| Spring Boot Main API 단독 | 공식 API를 Spring Boot 한 서비스로 구현 | 인증/권한/정산/트랜잭션에 강함 | AI/추천 Python 작업은 나중에 분리 필요 |
| FastAPI Main API 단독 | 공식 API를 FastAPI 한 서비스로 구현 | 구현 속도와 Python AI 연계가 빠름 | 권한/트랜잭션 기준을 엄격히 잡아야 함 |
| Spring Boot Main API + FastAPI Worker | Spring은 공식 API, FastAPI는 AI/Data worker | 운영 API 안정성과 AI 확장성을 동시에 확보 | 서비스 2개라 초기 세팅 비용 증가 |
| FastAPI Main API + worker 없음 | Python 한 서비스로 빠르게 시작 | prototype 속도 우수 | 운영형 확장 시 worker 분리 기준 필요 |
| Node/TypeScript Main API | 현재 smoke API를 확장 | 현재 Node 서버와 이어가기 쉬움 | Flutter와 타입 공유 이점이 작고 팀 논의 중심이 아님 |

## 현재 추천안

임시 추천안은 `Spring Boot Main API + FastAPI Worker`다.

추천 이유:

- `groups/plans/settlements`는 권한과 트랜잭션 정합성이 중요하다.
- 장소 추천 설명, OOTD 분석, 기록 설명 생성은 Python worker가 자연스럽다.
- 발표에서 Main API와 AI/Data Worker 경계를 설명하기 쉽다.
- FastAPI Worker는 Sprint 0에서 mock scoring 정도로 작게 시작할 수 있다.

## Sprint 0 Spike

1일 단위로 같은 세로 흐름을 양쪽에서 비교한다.

```text
OAuth provider 검증
  -> users/me
  -> groups 생성
  -> plans 생성
  -> place-candidates 조회
```

비교 기준:

- 코드량
- 디버깅 난이도
- 테스트 작성 난이도
- CI 구성 난이도
- 팀원이 이해하고 이어받기 쉬운 정도
