# ONMU 데이터/리포팅 로드맵

## 목적

이 문서는 ONMU가 나중에 기업 대상 데이터 리포트, 광고 세그먼트, OOTD/persona feature, Databricks 기반 주간/월간 리포트로 확장될 때의 방향을 정리한다.

현재 구현 범위에는 Databricks, 광고 API 연동, persona segmentation, Bronze/Silver/Gold table 구현을 포함하지 않는다. 지금은 core service가 나중에 analytics layer를 붙일 수 없게 막는 구조를 피하는 데 집중한다.

MVP/dev 단계에서는 CDC, Databricks, analytics 기준을 현재 인증 구현에 적용하지 않는다. 즉, HS256 JWT access token의 `sub=<users.public_id>` 흐름과 Spring의 DB 사용자 조회 흐름은 그대로 유지한다. 이 문서의 analytics subject 기준은 Azure/Terraform 전환 또는 After MVP 단계에서 적용할 경계다.

## 비즈니스 방향

ONMU의 앱 데이터는 약속, 장소 후보, 투표, 기록, OOTD, 정산, 알림 반응 같은 생활 맥락을 포함한다. 이 데이터는 동의와 비식별화가 전제될 때 아래 형태의 기업 대상 상품으로 확장될 수 있다.

| 방향 | 예시 |
| --- | --- |
| 주간/월간 트렌드 리포트 | 지역/시기별 약속 유형, 장소 카테고리, OOTD 스타일 변화 |
| 광고 세그먼트 | 카페/여행/러닝/전시 관심 group, 특정 persona의 소비 맥락 |
| OOTD/persona feature | 날씨, 장소, 약속 유형별 스타일 태그와 색상/무드 feature |
| 파트너 리포트 | 특정 지역의 모임/방문 선호, 후보 선택 패턴, 재방문 기록 |

## 레이어 구조

```text
Flutter App
  -> Spring Boot Main API
  -> Core DB + outbox_events
  -> FastAPI ai-data-worker
  -> Analytics/Reporting Layer
  -> Databricks/Lakehouse
  -> Weekly/Monthly Reports
  -> Enterprise Reports / Ad Segments
```

## 현재 구현 범위

현재 Sprint 0-1에서 구현하거나 scaffold에 남길 것은 아래 정도로 제한한다.

| 영역 | 현재 범위 |
| --- | --- |
| Core DB | users, auth_identities, groups, plans, votes, settlements, records, consent/privacy |
| Outbox | domain event와 worker 요청을 `outbox_events`에 기록 |
| Worker schema | `worker_ai` schema에 AI job 상태와 결과 metadata 저장 |
| Taxonomy 여지 | place category, plan type, OOTD tag, record tag, region/time bucket을 나중에 연결할 수 있게 모델링 |
| 동의/공개 범위 | 기록 공개 범위와 analytics 활용 동의 여부를 core domain에서 관리 |

## 현재 구현하지 않는 것

| 항목 | 제외 이유 |
| --- | --- |
| Databricks 연결 | MVP core API와 인증/약속/투표/정산 구현이 먼저다. |
| Bronze/Silver/Gold table | 원천 이벤트와 taxonomy가 안정화된 뒤 설계한다. |
| 광고 API 연동 | 개인정보/동의/광고 정책과 파트너 요구사항이 필요하다. |
| persona segmentation | 충분한 기록/OOTD/장소 데이터가 쌓인 뒤 모델링한다. |
| 기업용 리포트 생성 | 먼저 비식별/집계 기준과 사용 동의 정책이 필요하다. |

## 데이터 흐름 구상

장기적으로는 core DB에서 기업용 데이터를 직접 꺼내지 않는다. core service는 제품 운영을 책임지고, analytics/reporting layer는 비식별화와 집계를 책임진다.

미래 CDC/Databricks/analytics layer는 JWT `sub`를 영구 사용자 식별자로 사용하지 않는다. Core CDC는 DB의 `users.id` 같은 core FK 기준으로 수집하고, reporting/analytics layer는 `analytics_subjects.anonymous_subject_id` 같은 별도 비식별 subject로 변환해 집계한다.

```text
Core domain event
  -> outbox_events
  -> ETL / worker
  -> Bronze: 원천 이벤트 스냅샷
  -> Silver: 비식별/정제 feature
  -> Gold: 리포트/광고/페르소나 집계
```

예시:

```text
record.created
  -> record_id, user_id, group_id, plan_id, created_at
  -> 익명 subject, week bucket, region bucket, style tags, place category
  -> 월간 OOTD/약속 맥락 리포트
```

## 개인정보와 동의 원칙

기업 대상 데이터와 광고 세그먼트는 개인정보와 직접 연결되지 않는 집계 데이터여야 한다.

| 원칙 | 설명 |
| --- | --- |
| 데이터 최소화 | outbox payload에는 민감한 원문을 넣지 않는다. |
| 동의 우선 | analytics/reporting 활용 동의와 공개 범위를 core domain에서 관리한다. |
| 비식별화 | 사용자 식별자와 analytics subject를 분리한다. |
| 집계 제공 | 기업에는 개인 단위 데이터가 아니라 충분한 표본의 집계 데이터만 제공한다. |
| 삭제 가능성 | 사용자 삭제/철회 요청이 analytics layer에 전파될 수 있어야 한다. |

## Migration 소유권

| 저장 위치 | Migration 소유권 | 예시 |
| --- | --- | --- |
| Core schema | Spring Boot Flyway | users, groups, plans, votes, records, consent, privacy, outbox_events |
| Worker schema | FastAPI Alembic | worker_ai.ai_job_runs, worker_ai.prompt_runs, worker_ai.feature_extraction_jobs |
| Lakehouse | 미래 Databricks/IaC/ETL 관리 | Bronze/Silver/Gold table |

FastAPI Alembic은 core domain table을 수정하지 않는다. worker schema는 AI job 상태, prompt run, feature extraction job처럼 worker가 직접 소유하는 데이터만 관리한다.

## 단계별 도입

| 단계 | 범위 |
| --- | --- |
| Sprint 0-1 | core DB, Naver OAuth, access/refresh token, outbox_events, worker_ai schema scaffold |
| Sprint 2 | ai-data-worker 실제 작업, AI 요약/추천 설명, worker job 상태 관리 |
| After MVP | Databricks/lakehouse 연결, 비식별 이벤트 적재, 주간/월간 리포트 |
| Business Pilot | 광고 세그먼트, 기업 리포트, OOTD/persona feature 검증 |
