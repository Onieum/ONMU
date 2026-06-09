# ONMU 데이터 리포팅 넥스트스텝 사전

## 문서 목적

이 문서는 ONMU core production DB 이후 단계에서 붙일 Analytics/Reporting Layer의 데이터사전이다.

기준 문서는 [ONMU 데이터/리포팅 로드맵](../architecture/data-analytics-reporting-roadmap.md)이다. 해당 로드맵은 Databricks/Lakehouse, 기업 대상 주간/월간 리포트, 광고 세그먼트, OOTD/persona feature를 현재 core 구현 범위가 아니라 next-step 확장으로 분리한다.

따라서 이 문서는 [ONMU 데이터 사전](./ONMU%20데이터%20사전.md)의 core schema와 분리해서 관리한다. Spring Boot Main API의 core DB는 제품 운영과 트랜잭션 정합성을 책임지고, 이 문서의 reporting layer는 비식별화, 집계, 파트너 리포트, 광고 세그먼트를 책임진다.

회의 기준으로 이 문서는 당장 Spring API 구현을 막는 선행 작업이 아니다. core 데이터사전에서 동의 상태와 동의 변경 이력을 준비하고, 실제 analytics/reporting 적재와 partner report product는 core production 안정화 이후 next-step으로 진행한다.

## 범위 구분

| 구분 | 포함 여부 | 설명 |
| --- | --- | --- |
| Core app schema | 제외 | `users`, `groups`, `plans`, `records`, `settlements`, `outbox_events` 등은 core 데이터사전에서 관리 |
| Worker schema | 일부 참조 | `worker_ai` 결과 metadata는 feature 생성 input으로만 참조 |
| Analytics identity | 포함 | core 사용자와 분리된 익명 subject 기준 |
| Bronze/Silver/Gold | 포함 | Lakehouse 계층별 table 설계 |
| 기업 리포트 | 포함 | 주간/월간 트렌드, 파트너 리포트, 광고 세그먼트 |
| 실시간 제품 API | 제외 | Flutter 앱이 직접 호출하지 않는다. |
| Spring 운영 모니터링 | 제외 | Actuator/Micrometer, Prometheus, Grafana는 운영 메트릭 스택이며 reporting/lakehouse 테이블이 아니다. |

## 설계 원칙

- core service는 제품 운영을 책임지고, reporting layer는 비식별 집계와 리포트 생성을 책임진다.
- 기업/파트너에게 개인 단위 row를 제공하지 않는다.
- analytics subject는 core `users.id`와 직접 노출되지 않는 별도 식별자를 사용한다.
- 동의 철회, 사용자 삭제, 기록 삭제 이벤트는 reporting layer까지 전파되어야 한다.
- 충분한 표본 수와 privacy threshold를 통과한 집계만 외부 제공한다.
- 광고 세그먼트는 사용자 개인 targeting이 아니라 집계 기반 segment insight로 시작한다.
- Databricks/Lakehouse 구현 전에도 table grain, 파티션, 품질 기준을 문서로 먼저 고정한다.
- Spring Boot 관측성 메트릭은 Prometheus/Grafana에서 관리하고, 사용자 행동/비즈니스 리포팅 데이터와 섞지 않는다.

## 레이어 구조

```text
Spring Boot Main API
  -> Core DB + outbox_events
  -> ETL / analytics ingest
  -> Bronze: 원천 이벤트 snapshot
  -> Silver: 비식별/정제 feature
  -> Gold: 리포트/광고/페르소나 집계
  -> Report products / Partner exports
```

운영 모니터링은 별도 흐름으로 본다.

```text
Spring Boot Actuator / Micrometer
  -> Prometheus scrape
  -> Grafana dashboard / alert
```

이 흐름은 서버 상태, JVM, HTTP latency, error rate, readiness 같은 운영 메트릭을 다룬다. 사용자 행동 분석, 파트너 리포트, 광고 세그먼트 산출을 위한 Bronze/Silver/Gold layer와 목적과 보존 정책이 다르다.

## 상태 구분

| 상태 | 의미 |
| --- | --- |
| Next-step | core production 안정화 후 설계/구현할 대상 |
| Pilot | 파트너/발표/비즈니스 검증용으로 제한적으로 생성할 대상 |
| Business | 기업 리포트/광고 세그먼트 상품화 대상 |

---

# 1. Analytics Identity / Consent

## `analytics_subjects` (Next-step)

> core 사용자 ID와 analytics layer의 익명 subject를 분리한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Analytics subject ID | UUID | subject row 식별자 | PK |
| `user_id` | Core 사용자 ID | UUID | core 사용자 연결. 외부 제공 금지 | FK, Not Null |
| `anonymous_subject_id` | 익명 subject ID | Text | lakehouse/reporting에서 쓰는 비식별 ID | Unique, Not Null |
| `subject_salt_version` | Salt 버전 | Varchar(30) | subject 생성 salt/key 버전 | Not Null |
| `status` | subject 상태 | Varchar(20) | `active`, `disabled`, `erased` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | subject 생성 시각 | Not Null |
| `disabled_at` | 비활성 시각 | Timestamptz | 동의 철회/탈퇴로 비활성화한 시각 | Nullable |
| `erased_at` | 삭제 반영 시각 | Timestamptz | 삭제 요청 반영 시각 | Nullable |

## `analytics_consent_snapshots` (Next-step)

> analytics 적재 시점의 동의 상태를 snapshot으로 남긴다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 동의 snapshot ID | UUID | snapshot row 식별자 | PK |
| `anonymous_subject_id` | 익명 subject ID | Text | 비식별 subject | Not Null |
| `analytics_opt_in` | Analytics 동의 | Boolean | analytics 활용 동의 여부 | Not Null |
| `marketing_opt_in` | 마케팅 동의 | Boolean | 광고/마케팅 활용 동의 여부 | Not Null |
| `contact_sync_opt_in` | 연락처 동기화 동의 | Boolean | 연락처 동기화 동의 여부 | Not Null |
| `policy_version` | 정책 버전 | Text | 동의한 약관/정책 버전 | Not Null |
| `effective_at` | 적용 시각 | Timestamptz | snapshot 기준 시각 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |

## `analytics_erasure_requests` (Next-step)

> core의 사용자 삭제/동의 철회 요청이 lakehouse에 반영되는 과정을 추적한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Analytics 삭제 요청 ID | UUID | 삭제 요청 row 식별자 | PK |
| `core_request_id` | Core 요청 ID | UUID | core `data_subject_requests.id` 참조 | Not Null |
| `anonymous_subject_id` | 익명 subject ID | Text | 삭제 대상 subject | Not Null |
| `request_type` | 요청 유형 | Varchar(30) | `delete`, `withdraw_consent`, `export` | Not Null |
| `status` | 처리 상태 | Varchar(30) | `received`, `processing`, `completed`, `failed` | Not Null |
| `affected_layers` | 영향 레이어 | JSON | Bronze/Silver/Gold 반영 상태 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 요청 수신 시각 | Not Null |
| `completed_at` | 완료 시각 | Timestamptz | lakehouse 반영 완료 시각 | Nullable |

---

# 2. Taxonomy / Dimension

## `dim_date` (Next-step)

> 리포트 날짜, 주차, 월, 시즌 기준을 통일한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `date_key` | 날짜 키 | Date | 기준 날짜 | PK |
| `year` | 연도 | Integer | 연도 | Not Null |
| `month` | 월 | Integer | 월 | Not Null |
| `week_of_year` | 연중 주차 | Integer | ISO 주차 | Not Null |
| `weekday` | 요일 | Integer | 1-7 요일 | Not Null |
| `season` | 계절 | String | spring, summer 등 | Nullable |
| `holiday_label` | 휴일 라벨 | String | 공휴일/연휴 정보 | Nullable |

## `dim_region` (Next-step)

> 리포트 제공을 위한 비식별 지역 bucket이다. 정밀 위치 대신 충분히 큰 집계 단위만 사용한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `region_bucket` | 지역 bucket | String | 집계용 지역 키 | PK |
| `country_code` | 국가 코드 | String | `KR` 등 | Not Null |
| `region_level_1` | 광역 지역 | String | 시/도 단위 | Nullable |
| `region_level_2` | 세부 지역 | String | 시/군/구 단위. 표본 충분할 때만 사용 | Nullable |
| `display_label` | 표시 라벨 | String | 리포트 표시용 지역명 | Not Null |
| `privacy_min_sample` | 최소 표본 수 | Integer | region별 제공 최소 표본 | Not Null |

## `dim_place_category` (Next-step)

> 외부 provider category를 ONMU 리포팅 taxonomy로 정규화한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `place_category_key` | 장소 카테고리 키 | String | ONMU 표준 category key | PK |
| `display_label` | 표시 라벨 | String | 카페, 한식, 전시 등 | Not Null |
| `parent_category_key` | 상위 카테고리 | String | 상위 category key | Nullable |
| `provider_mapping` | Provider mapping | JSON | Naver/Kakao category mapping | Not Null |
| `active` | 활성 여부 | Boolean | 리포트 사용 여부 | Not Null |

## `dim_plan_type` (Next-step)

> 약속 목적/맥락 taxonomy다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `plan_type_key` | 약속 유형 키 | String | 여행, 카페, 전시, 러닝 등 | PK |
| `display_label` | 표시 라벨 | String | 리포트 표시용 명칭 | Not Null |
| `source_rule` | 분류 규칙 | JSON | tag/category 기반 rule | Nullable |
| `active` | 활성 여부 | Boolean | taxonomy 사용 여부 | Not Null |

## `dim_ootd_style_tag` (Next-step)

> OOTD/persona feature의 스타일 tag taxonomy다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `style_tag_key` | 스타일 태그 키 | String | casual, street, date-look 등 | PK |
| `display_label` | 표시 라벨 | String | 리포트 표시용 태그명 | Not Null |
| `tag_group` | 태그 그룹 | String | mood, color, outfit, occasion 등 | Not Null |
| `source` | 출처 | String | user, ai, taxonomy | Not Null |
| `active` | 활성 여부 | Boolean | tag 사용 여부 | Not Null |

---

# 3. Bronze Layer

## `bronze_app_events` (Next-step)

> core domain event를 analytics layer로 복제한 원천 이벤트 snapshot이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `event_id` | 이벤트 ID | UUID | 원본 outbox 또는 analytics event ID | PK |
| `event_type` | 이벤트 유형 | String | `record.created`, `place_candidate.created` 등 | Not Null |
| `occurred_at` | 발생 시각 | Timestamp | 이벤트 발생 시각 | Not Null |
| `anonymous_subject_id` | 익명 사용자 ID | String | 사용자 ID와 분리한 subject | Nullable |
| `group_bucket` | 모임 bucket | String | 비식별 group bucket | Nullable |
| `region_bucket` | 지역 bucket | String | 세부 위치가 아닌 집계 지역 | Nullable |
| `consent_snapshot_id` | 동의 snapshot ID | UUID | 적재 시점 동의 상태 | Nullable |
| `payload` | 원천 payload | JSON | 개인정보 제거 후 이벤트 snapshot | Not Null |
| `ingested_at` | 적재 시각 | Timestamp | lakehouse 적재 시각 | Not Null |

> Partition: `date(occurred_at)`
> 금지: provider token, refresh token, 전화번호 원문, 개인 위치 원문 저장.

## `bronze_worker_results` (Next-step)

> FastAPI Worker가 만든 AI/Data 결과 metadata를 원천 상태로 적재한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `worker_result_id` | Worker 결과 ID | UUID | worker 결과 row 식별자 | PK |
| `ai_job_run_id` | AI job run ID | UUID | core worker job ID | Not Null |
| `job_type` | Job 유형 | String | `ootd_feature`, `place_explanation`, `record_summary` | Not Null |
| `anonymous_subject_id` | 익명 사용자 ID | String | subject 연결 | Nullable |
| `target_type` | 대상 유형 | String | record, place_candidate 등 | Not Null |
| `target_ref` | 대상 참조 | String | 비식별 대상 참조 | Not Null |
| `result_metadata` | 결과 metadata | JSON | worker 결과 metadata | Not Null |
| `created_at` | 생성 시각 | Timestamp | worker 결과 생성 시각 | Not Null |
| `ingested_at` | 적재 시각 | Timestamp | lakehouse 적재 시각 | Not Null |

## `bronze_external_place_snapshots` (Next-step)

> 장소 provider snapshot과 공지/휴무 정보 snapshot을 분석용으로 적재한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `snapshot_id` | Snapshot ID | UUID | snapshot 식별자 | PK |
| `provider` | 제공자 | String | Naver, manual 등 | Not Null |
| `place_category_key` | 장소 카테고리 키 | String | 정규화 category | Nullable |
| `region_bucket` | 지역 bucket | String | 집계 지역 | Nullable |
| `source_type` | 출처 유형 | String | api, notice, manual, ai_extract | Not Null |
| `payload` | Snapshot payload | JSON | 개인정보 없는 장소 정보 snapshot | Not Null |
| `fetched_at` | 수집 시각 | Timestamp | 외부 조회 시각 | Not Null |
| `ingested_at` | 적재 시각 | Timestamp | lakehouse 적재 시각 | Not Null |

---

# 4. Silver Layer

## `silver_behavior_features` (Next-step)

> 약속, 장소, 기록, OOTD, 정산 행동을 비식별 feature로 정제한 테이블이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `feature_id` | Feature ID | String | 정제 feature 식별자 | PK |
| `anonymous_subject_id` | 익명 사용자 ID | String | 개인 식별자와 분리된 subject | Not Null |
| `week_bucket` | 주차 bucket | String | YYYY-WW 형식 주차 | Not Null |
| `plan_type_key` | 약속 유형 | String | 여행, 카페, 전시 등 taxonomy | Nullable |
| `place_category_key` | 장소 카테고리 | String | 음식점, 카페 등 | Nullable |
| `ootd_style_tags` | OOTD 태그 | Array(String) | 스타일/무드 태그 | Nullable |
| `record_tags` | 기록 태그 | Array(String) | 기록/감정 태그 | Nullable |
| `engagement_metrics` | 참여 지표 | JSON | 투표/기록/알림 반응 집계 | Not Null |
| `consent_snapshot` | 동의 snapshot | JSON | analytics 활용 동의 상태 | Not Null |
| `created_at` | 생성 시각 | Timestamp | feature 생성 시각 | Not Null |

## `silver_place_preference_features` (Next-step)

> 장소 후보 추가, 하트, 투표, 일정 등록을 기반으로 장소 선호 feature를 만든다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `feature_id` | Feature ID | String | row 식별자 | PK |
| `anonymous_subject_id` | 익명 사용자 ID | String | subject | Not Null |
| `week_bucket` | 주차 bucket | String | YYYY-WW | Not Null |
| `region_bucket` | 지역 bucket | String | 집계 지역 | Nullable |
| `place_category_key` | 장소 카테고리 | String | 표준 category | Not Null |
| `candidate_added_count` | 후보 추가 수 | Integer | 해당 category 후보 추가 수 | Not Null |
| `reaction_count` | 반응 수 | Integer | heart/like 등 반응 수 | Not Null |
| `vote_selected_count` | 투표 선택 수 | Integer | 투표에서 선택된 횟수 | Not Null |
| `schedule_registered_count` | 일정 등록 수 | Integer | 일정에 등록된 횟수 | Not Null |
| `created_at` | 생성 시각 | Timestamp | feature 생성 시각 | Not Null |

## `silver_ootd_persona_features` (Next-step)

> OOTD 기록과 약속 맥락을 연결해 persona feature를 만든다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `feature_id` | Feature ID | String | row 식별자 | PK |
| `anonymous_subject_id` | 익명 사용자 ID | String | subject | Not Null |
| `week_bucket` | 주차 bucket | String | YYYY-WW | Not Null |
| `plan_type_key` | 약속 유형 | String | 약속 맥락 | Nullable |
| `region_bucket` | 지역 bucket | String | 집계 지역 | Nullable |
| `style_tags` | 스타일 태그 | Array(String) | 정규화 OOTD style tags | Not Null |
| `color_palette` | 색상 팔레트 | JSON | 대표 색상 feature | Nullable |
| `weather_bucket` | 날씨 bucket | String | sunny, rainy 등 | Nullable |
| `mood_bucket` | 무드 bucket | String | calm, excited 등 | Nullable |
| `created_at` | 생성 시각 | Timestamp | feature 생성 시각 | Not Null |

---

# 5. Gold Layer

## `gold_monthly_trend_report` (Business)

> 주간/월간 리포트, 기업용 trend insight, 광고 세그먼트의 소스가 되는 집계 테이블이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `report_month` | 리포트 월 | String | YYYY-MM 월 bucket | PK 후보 |
| `region_bucket` | 지역 bucket | String | 충분히 큰 단위의 지역 집계 | PK 후보 |
| `segment_key` | 세그먼트 키 | String | 카페/여행/OOTD/persona 등 | PK 후보 |
| `sample_size` | 표본 수 | Integer | 집계에 포함된 익명 subject 수 | Not Null |
| `plan_count` | 약속 수 | Integer | 해당 bucket의 약속 수 | Not Null |
| `top_place_categories` | 상위 장소 카테고리 | JSON | category별 count/rank | Not Null |
| `top_ootd_tags` | 상위 OOTD 태그 | JSON | OOTD tag별 count/rank | Nullable |
| `trend_summary` | 트렌드 요약 | Text | 리포트 표시용 요약 | Nullable |
| `privacy_status` | Privacy 상태 | String | 표본 수/동의 기준 통과 여부 | Not Null |
| `created_at` | 생성 시각 | Timestamp | 집계 생성 시각 | Not Null |

## `gold_partner_place_insights` (Business)

> 지역/장소 카테고리별 파트너 리포트용 insight다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `insight_id` | Insight ID | String | insight row 식별자 | PK |
| `report_month` | 리포트 월 | String | YYYY-MM | Not Null |
| `region_bucket` | 지역 bucket | String | 집계 지역 | Not Null |
| `place_category_key` | 장소 카테고리 | String | 표준 category | Not Null |
| `sample_size` | 표본 수 | Integer | privacy threshold 판단 표본 수 | Not Null |
| `candidate_count` | 후보 수 | Integer | 후보로 오른 횟수 | Not Null |
| `selected_count` | 선택 수 | Integer | 일정/투표에서 선택된 횟수 | Not Null |
| `conversion_rate` | 전환율 | Numeric | 후보 대비 선택 비율 | Nullable |
| `time_bucket_distribution` | 시간대 분포 | JSON | 오전/오후/저녁 등 분포 | Not Null |
| `privacy_status` | Privacy 상태 | String | `pass`, `suppressed` | Not Null |
| `created_at` | 생성 시각 | Timestamp | insight 생성 시각 | Not Null |

## `gold_ootd_persona_segments` (Business)

> OOTD/persona 기반 segment insight다. 개인 타겟팅이 아니라 집계 segment 설명용이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `segment_key` | 세그먼트 키 | String | persona/ootd segment key | PK 후보 |
| `report_month` | 리포트 월 | String | YYYY-MM | PK 후보 |
| `region_bucket` | 지역 bucket | String | 집계 지역 | PK 후보 |
| `sample_size` | 표본 수 | Integer | 익명 subject 수 | Not Null |
| `style_tag_mix` | 스타일 태그 구성 | JSON | style tag별 비율 | Not Null |
| `plan_type_mix` | 약속 유형 구성 | JSON | 약속 유형별 비율 | Not Null |
| `place_category_mix` | 장소 카테고리 구성 | JSON | 장소 category별 비율 | Not Null |
| `summary` | 세그먼트 요약 | Text | 리포트 표시용 설명 | Nullable |
| `privacy_status` | Privacy 상태 | String | `pass`, `suppressed` | Not Null |
| `created_at` | 생성 시각 | Timestamp | segment 생성 시각 | Not Null |

---

# 6. Report Products / Partner Export

## `report_products` (Business)

> ONMU가 만들 수 있는 리포트 상품 정의다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 리포트 상품 ID | UUID | report product 식별자 | PK |
| `product_key` | 상품 key | Text | `monthly_trend`, `partner_place`, `ootd_persona` 등 | Unique, Not Null |
| `name` | 상품명 | Text | 표시 이름 | Not Null |
| `description` | 설명 | Text | 리포트 목적 | Nullable |
| `data_sources` | 데이터 소스 | JSON | 사용하는 Gold/Silver table 목록 | Not Null |
| `privacy_rules` | Privacy rule | JSON | 최소 표본 수, suppress rule | Not Null |
| `status` | 상태 | Varchar(20) | `draft`, `active`, `paused`, `retired` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 상품 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 상품 수정 시각 | Not Null |

## `partner_accounts` (Business)

> 리포트를 받는 기업/파트너 계정이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 파트너 ID | UUID | partner 식별자 | PK |
| `name` | 파트너명 | Text | 기업/기관명 | Not Null |
| `partner_type` | 파트너 유형 | Varchar(30) | `brand`, `venue`, `agency`, `research` | Not Null |
| `status` | 상태 | Varchar(20) | `active`, `paused`, `terminated` | Not Null |
| `contract_metadata` | 계약 메타데이터 | JSONB | 계약 범위, 제공 가능 리포트 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 계정 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 계정 수정 시각 | Not Null |

## `partner_report_runs` (Business)

> 파트너별 리포트 생성 실행 이력이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 리포트 실행 ID | UUID | report run 식별자 | PK |
| `partner_account_id` | 파트너 ID | UUID | 리포트 수신 파트너 | FK, Not Null |
| `report_product_id` | 리포트 상품 ID | UUID | 생성한 report product | FK, Not Null |
| `report_period_start` | 리포트 시작일 | Date | 집계 시작일 | Not Null |
| `report_period_end` | 리포트 종료일 | Date | 집계 종료일 | Not Null |
| `status` | 생성 상태 | Varchar(20) | `pending`, `running`, `ready`, `failed`, `suppressed` | Not Null |
| `privacy_result` | Privacy 결과 | JSONB | 표본 수/suppress 결과 | Not Null |
| `artifact_uri` | 산출물 URI | Text | PDF/HTML/dashboard 저장 위치 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 실행 생성 시각 | Not Null |
| `completed_at` | 완료 시각 | Timestamptz | 리포트 완료 시각 | Nullable |

## `segment_definitions` (Business)

> 광고/파트너 리포트 segment 정의다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 세그먼트 ID | UUID | segment 식별자 | PK |
| `segment_key` | 세그먼트 key | Text | segment stable key | Unique, Not Null |
| `name` | 세그먼트명 | Text | 표시 이름 | Not Null |
| `definition_rules` | 정의 rule | JSONB | place/ootd/plan feature 조건 | Not Null |
| `min_sample_size` | 최소 표본 수 | Integer | 외부 제공 최소 표본 수 | Not Null |
| `status` | 상태 | Varchar(20) | `draft`, `active`, `retired` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 수정 시각 | Not Null |

## `segment_export_runs` (Business)

> segment insight를 외부 시스템이나 리포트 산출물로 내보낸 이력이다. 개인 식별자 export는 금지한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Export run ID | UUID | export 실행 식별자 | PK |
| `segment_definition_id` | 세그먼트 ID | UUID | export 대상 segment | FK, Not Null |
| `partner_account_id` | 파트너 ID | UUID | 수신 파트너 | FK, Nullable |
| `export_type` | Export 유형 | Varchar(30) | `report`, `dashboard`, `api_snapshot` | Not Null |
| `status` | 상태 | Varchar(20) | `pending`, `completed`, `failed`, `suppressed` | Not Null |
| `sample_size` | 표본 수 | Integer | export 기준 표본 수 | Not Null |
| `privacy_result` | Privacy 결과 | JSONB | threshold/suppression 결과 | Not Null |
| `artifact_uri` | 산출물 URI | Text | 저장 위치 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 실행 생성 시각 | Not Null |
| `completed_at` | 완료 시각 | Timestamptz | 실행 완료 시각 | Nullable |

---

# 7. Data Quality / Governance

## `analytics_quality_checks` (Next-step)

> Bronze/Silver/Gold table의 품질 검사를 정의한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 품질 검사 ID | UUID | quality check 식별자 | PK |
| `check_key` | 검사 key | Text | 검사 stable key | Unique, Not Null |
| `target_layer` | 대상 레이어 | Varchar(20) | `bronze`, `silver`, `gold` | Not Null |
| `target_table` | 대상 테이블 | Text | 검사 대상 table | Not Null |
| `check_type` | 검사 유형 | Varchar(40) | `freshness`, `null_rate`, `volume`, `privacy_threshold` | Not Null |
| `rules` | 검사 rule | JSONB | threshold, column rule 등 | Not Null |
| `enabled` | 활성 여부 | Boolean | 검사 실행 여부 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 검사 정의 생성 시각 | Not Null |

## `analytics_quality_results` (Next-step)

> 품질 검사 실행 결과다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 품질 결과 ID | UUID | result row 식별자 | PK |
| `quality_check_id` | 품질 검사 ID | UUID | 실행한 check | FK, Not Null |
| `run_id` | 실행 ID | Text | ETL/report run id | Not Null |
| `status` | 검사 상태 | Varchar(20) | `pass`, `warn`, `fail` | Not Null |
| `observed_value` | 관측값 | JSONB | 실제 측정값 | Not Null |
| `message` | 메시지 | Text | 검사 결과 설명 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 결과 생성 시각 | Not Null |

## `privacy_suppression_rules` (Next-step)

> 외부 제공 집계에서 숨김 처리할 기준을 관리한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Suppression rule ID | UUID | rule 식별자 | PK |
| `rule_key` | Rule key | Text | rule stable key | Unique, Not Null |
| `metric_scope` | Metric 범위 | Text | 적용 대상 metric/report | Not Null |
| `min_sample_size` | 최소 표본 수 | Integer | 제공 최소 표본 | Not Null |
| `min_distinct_subjects` | 최소 subject 수 | Integer | distinct subject 기준 | Not Null |
| `suppression_mode` | Suppression 방식 | Varchar(30) | `hide_row`, `bucket_other`, `round_value` | Not Null |
| `active` | 활성 여부 | Boolean | rule 활성 여부 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | rule 생성 시각 | Not Null |

---

# 8. 도입 순서

## Phase 1: Core에서 막히지 않게 준비

| 작업 | 설명 |
| --- | --- |
| 동의 이벤트 정리 | core `consent_privacy_settings`, `user_consents`, outbox event를 analytics 확장 가능하게 정리. 구현은 core 데이터사전 PR에서 선반영 |
| Taxonomy 여지 확보 | place category, record tag, OOTD tag, plan type을 core에서 보존 |
| 삭제/철회 이벤트 | 사용자 삭제와 동의 철회가 outbox로 나가도록 설계 |
| Worker metadata | AI worker 결과가 core table을 직접 수정하지 않고 metadata로 남도록 유지 |
| 운영 모니터링 분리 | Prometheus/Grafana는 Spring runtime 운영 메트릭으로 보고 analytics lakehouse 적재 대상에서 제외 |

## Phase 2: Analytics Identity / Bronze

| 작업 | 설명 |
| --- | --- |
| `analytics_subjects` | core 사용자와 익명 subject 분리 |
| Bronze 적재 | outbox 기반 app event snapshot 적재 |
| 품질 검사 | freshness, volume, null rate, privacy threshold 검사 |

## Phase 3: Silver / Gold

| 작업 | 설명 |
| --- | --- |
| 행동 feature | 장소/약속/기록/OOTD 행동 feature 정제 |
| Persona feature | OOTD/persona feature 생성 |
| Gold report | 월간 trend, partner insight, segment 집계 |

## Phase 4: Business Pilot

| 작업 | 설명 |
| --- | --- |
| 파트너 계정 | partner account와 report product 정의 |
| 리포트 산출물 | PDF/HTML/dashboard artifact 생성 |
| Segment export | 개인 식별자 없는 segment insight export |
| Governance | privacy suppression과 partner access audit 운영 |

## 회의 결정 반영 사항

| 주제 | 결정 |
| --- | --- |
| Core와 reporting 경계 | core 앱 기능 구현을 먼저 진행하고, analytics/reporting layer는 next-step 확장으로 분리한다. |
| Analytics 동의 | core에는 현재 동의 상태와 append-only 동의 이력을 둔다. reporting layer 전파는 Phase 2 이후 구현한다. |
| Worker metadata | AI worker 결과는 core table 직접 수정이 아니라 metadata/read model 조합으로 처리한다. |
| 운영 모니터링 | Prometheus/Grafana는 Spring Boot 운영 메트릭 스택으로 분리하고, partner reporting 데이터사전에 포함하지 않는다. |

## 남은 결정 필요 항목

| 주제 | 결정 질문 |
| --- | --- |
| 동의 시점 | 가입 시 analytics opt-in을 받을지, 기록/공유 기능 사용 시 별도 동의를 받을지? |
| 지역 단위 | 리포트에서 허용할 최소 지역 bucket은 어디까지인가? |
| 표본 기준 | 외부 제공 최소 표본 수와 suppression rule을 어떻게 둘 것인가? |
| OOTD/persona | 발표/사업 검증에서 persona feature를 어디까지 보여줄 것인가? |
| Databricks 도입 | 실제 Databricks/Lakehouse를 언제 붙이고, 그 전에는 어떤 lightweight pipeline으로 대체할 것인가? |
| 파트너 리포트 | 첫 partner report product를 장소 트렌드, OOTD/persona, 월간 종합 중 무엇으로 잡을 것인가? |
