# ONMU 백엔드 기술스택 결정

## 결정 상태

Flutter 모바일 앱은 확정 프론트엔드이고, 백엔드는 `Spring Boot Main API + FastAPI Worker`로 확정한다.

- Spring Boot Main API: Flutter 앱이 직접 호출하는 공식 제품 API
- FastAPI Worker: Spring Boot 뒤에서 호출되는 내부 AI/Data worker
- Node smoke/contract stub: Windows backend-host와 Cloudflare Tunnel 연결을 검증하기 위한 임시 개발 도구

Node stub은 최종 백엔드가 아니며, Spring Boot Main API가 준비되면 `/healthz`, `/readyz`, `dev-api.onmu.cloud`, `/api/v1` contract 검증 계약을 Spring Boot로 넘긴다.

## 확정 구조

| 구성 | 역할 | 이유 |
| --- | --- | --- |
| Spring Boot Main API | 인증/인가, 사용자, 온모임, 약속, 장소 후보, 투표, 정산, 기록, 공개 범위의 공식 API | 권한과 트랜잭션 정합성이 중요한 도메인 로직을 안정적으로 처리한다. |
| FastAPI Worker | 장소 후보 설명, OOTD 분석, 추천 설명, 비동기 데이터 처리 | Python AI/데이터 라이브러리와 붙이기 쉽고, Main API와 역할을 분리할 수 있다. |
| PostgreSQL/PostGIS | 약속, 장소, 정산, 권한 데이터 원본 | 관계형 정합성과 위치 기반 질의를 함께 처리한다. |
| Redis | 캐시, presence, rate limit 보조 | 짧게 변하는 상태를 DB와 분리한다. |
| Azure Blob Storage/MinIO | 사진, 기록 이미지, 공유 카드 이미지 | 큰 바이너리 파일을 DB와 분리한다. |

## 결정 이유

- `groups/plans/settlements`는 권한과 트랜잭션 정합성이 중요하다.
- Flutter 앱은 하나의 공개 API 계층만 호출해야 인증, 로깅, 장애 대응이 단순하다.
- AI/추천/분석 작업은 시간이 걸릴 수 있으므로 Spring Boot 요청 처리와 분리한다.
- FastAPI Worker를 내부 worker로 두면 Azure OpenAI, 검색, 이미지 분석 같은 Python 생태계를 활용하기 쉽다.
- 발표에서 Main API와 AI/Data Worker 경계를 명확히 설명할 수 있다.

## 비채택 대안

| 대안 | 비채택 이유 |
| --- | --- |
| Spring Boot Main API 단독 | AI/추천 Python 작업을 결국 별도 worker로 분리해야 한다. |
| Python API 단독 | 정산, 권한, 트랜잭션 중심의 운영 API 기준을 팀이 더 엄격히 설계해야 한다. |
| Node/TypeScript Main API | 현재 Node 서버와 이어가기 쉽지만, 팀 결정과 제품 도메인 API 기준이 아니다. |

## Sprint 0 구현 기준

첫 세로 흐름은 Spring Boot Main API 기준으로 구현한다.

```text
OAuth provider 검증
  -> users/me
  -> groups 생성
  -> plans 생성
  -> place-candidates 조회/추가
  -> settlement-draft 조회
```

FastAPI Worker는 모바일 앱에서 직접 호출하지 않는다. 필요한 경우 Spring Boot Main API가 내부 API, queue, 또는 service client로 worker를 호출한다.
