# ONMU 데이터 사전

## 문서 목적

이 문서는 ONMU의 Spring Boot Main API, FastAPI AI/Data Worker가 프로덕션 수준으로 운영되기 위해 필요한 core app 데이터 기준을 회의용으로 정리한다.

현재 `services/api-spring`에는 Sprint 0-1 세로 흐름 검증용 core schema scaffold가 들어와 있다. 하지만 DB 설계 논의는 프론트엔드 화면 흐름처럼 최종 제품 구조를 먼저 펼쳐 놓고, 구현 순서를 나중에 나누는 방식으로 진행한다.

## 설계 기준

- Flutter 앱이 직접 호출하는 공개 API는 Spring Boot Main API가 제공한다.
- Spring Boot Flyway는 core app schema를 소유한다.
- FastAPI Alembic은 `worker_ai` schema만 소유한다.
- FastAPI Worker는 core domain table을 직접 수정하지 않는다.
- 사용자-facing 용어가 `온모임`, `약속`이어도 API와 DB 리소스명은 `groups`, `plans`를 우선한다.
- 첫 친구 추가 구현은 랜덤 사용자 코드 방식으로 시작한다.
- 이후 연락처 동기화, 카카오톡 초대, 공유 링크 초대를 확장할 수 있게 초대 채널을 분리한다.
- 정산은 반드시 약속(`plans`) 하위 도메인으로 둔다.
- 장소 후보와 일정 등록 장소는 분리한다.
- 채팅/알림은 domain action의 side effect를 activity event와 notification으로 받는다.
- 기업용 리포트, 광고 세그먼트, Databricks/Lakehouse는 core production 다음 단계로 분리한다. 자세한 next-step 데이터사전은 [ONMU 데이터 리포팅 넥스트스텝 사전](./ONMU%20데이터%20리포팅%20넥스트스텝%20사전.md)을 따른다.
- Spring Boot 운영 모니터링은 Actuator/Micrometer -> Prometheus -> Grafana 흐름으로 검토하되, 이는 앱 도메인 DB가 아니라 운영 메트릭 저장소로 분리한다.
- 프로덕션 기준에서는 인증, 권한, 감사 로그, rate limit, 멱등성, 데이터 삭제/내보내기 요청을 core domain과 같은 수준으로 설계한다.
- 사용자 입력 원문, 외부 provider token, refresh token 원문, 전화번호 원문, 실제 위치 정밀 좌표는 필요한 경우에도 저장 위치와 보존 기간을 따로 제한한다.
- 모든 외부 연동 결과는 provider 원본과 앱 표시용 read model을 분리한다.
- 대량 이벤트성 테이블은 파티셔닝 또는 보존 정책을 전제로 설계한다.

## 상태 구분

| 상태 | 의미 |
| --- | --- |
| 구현됨 | 현재 Spring/FastAPI migration 또는 scaffold에 존재한다. |
| 다음 구현 | Sprint 0-2에서 API/DB 구현 대상이다. |
| 목표 설계 | 최종 제품 구조에 필요하므로 미리 데이터사전에 둔다. |
| 미래 확장 | core production 이후 외부 초대, 연락처 동기화, reporting/lakehouse에서 확장한다. |

## 목차

1. Core App Schema
2. Auth / User
3. Friend / Invite
4. Group / Plan
5. Place
6. Vote
7. Settlement
8. Record / Media / OOTD
9. Activity / Notification
10. Consent / Privacy
11. Outbox / Worker
12. Production Operations / Governance
13. Physical Database Design
14. 공통 Enum
15. 구현 우선순위

---

# 1. Core App Schema

## Schema — `public`

> Spring Boot Main API가 Flyway로 관리하는 핵심 앱 도메인 schema다.

| 구분 | 내용 |
| --- | --- |
| Migration 소유자 | Spring Boot Main API |
| 구현 위치 | `services/api-spring/src/main/resources/db/migration` |
| 주요 책임 | 사용자, 인증, 친구, 모임, 약속, 장소, 투표, 정산, 기록, 공개 범위, outbox |
| 금지 사항 | FastAPI Worker가 직접 DDL/DML로 core domain table을 수정하지 않는다. |

## Schema — `worker_ai`

> FastAPI AI/Data Worker가 Alembic으로 관리하는 worker 전용 schema다.

| 구분 | 내용 |
| --- | --- |
| Migration 소유자 | FastAPI AI/Data Worker |
| 구현 위치 | `services/workers/ai-data-worker/alembic` |
| 주요 책임 | AI job 상태, prompt 실행 기록, feature extraction 작업 기록 |
| 금지 사항 | core table의 ownership을 가져오거나 사용자-facing 데이터를 직접 수정하지 않는다. |

---

# 2. Auth / User

## `users` (구현됨, 확장 필요)

> ONMU 내부 사용자 원장이다. OAuth provider 식별자와 분리된 내부 UUID를 기준으로 한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 사용자 ID | UUID | ONMU 내부 사용자 식별자 | PK, Not Null |
| `public_id` | 공개 사용자 ID | Text | API 응답과 URL에서 사용할 안정 식별자 | Unique, 다음 구현 |
| `display_name` | 표시 이름 | Text | 앱에서 보이는 사용자 이름 | Not Null |
| `nickname` | 닉네임 | Text | 친구/모임에서 표시할 별칭 | 목표 설계 |
| `profile_image_url` | 프로필 이미지 URL | Text | Blob/CDN에 저장된 프로필 이미지 주소 | 목표 설계 |
| `pixel_character` | 픽셀 캐릭터 JSON | Jsonb | 기본 캐릭터 렌더링에 필요한 성별/피부/머리/눈/의상 선택값 | Not Null, Default `{}` |
| `preference_profile` | 취향 프로필 JSON | Jsonb | 마이페이지 프로필/친구 상세 프로필에 표시할 관심사, 음식/장소/약속 스타일, 지역, 소개 문구 | Not Null, Default `{}` |
| `status_message` | 상태 메시지 | Text | 마이페이지의 짧은 소개 문구 | 목표 설계 |
| `phone_hash` | 전화번호 해시 | Text | 연락처 동기화용 비가역 해시 | 미래 확장, Unique 후보 |
| `email` | 이메일 | Text | OAuth provider가 제공하는 이메일 | Nullable |
| `default_locale` | 기본 언어 | Varchar(10) | 앱 언어/지역 기준 | 기본값 `ko-KR` |
| `time_zone` | 시간대 | Text | 일정/알림 계산 기준 | 기본값 `Asia/Seoul` |
| `status` | 사용자 상태 | Varchar(30) | `active`, `disabled`, `deleted` | Not Null |
| `last_login_at` | 마지막 로그인 시각 | Timestamptz | 최근 인증 성공 시각 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 사용자 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 사용자 수정 시각 | Not Null |
| `deleted_at` | 삭제 시각 | Timestamptz | 탈퇴/삭제 처리 시각 | Nullable |

## `character_profiles` (구현됨)

> 사용자의 기본 픽셀 캐릭터 원장이다. 캐릭터 온보딩에서 최초 생성한 기본 속성만 1대1로 보관하고, OOTD 기록마다 바뀌는 머리/눈/의상 변경분은 `records.payload.characterSnapshot`에 스냅샷으로 저장한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 캐릭터 프로필 ID | UUID | character profile row 식별자 | PK, Not Null |
| `user_id` | 사용자 ID | UUID | 캐릭터를 소유한 사용자 | FK -> `users.id`, Unique, Not Null |
| `gender` | 캐릭터 성별/에셋 그룹 | Varchar(20) | `male`, `female` 중 하나. Flutter 캐릭터 asset path 선택에 필요 | Nullable, `skipped=false`이면 Not Null |
| `skin_tone` | 피부색 | Varchar(30) | 기본 캐릭터 피부색 key | Nullable, `skipped=false`이면 Not Null |
| `hair_style` | 머리 스타일 | Varchar(30) | 기본 캐릭터 머리 스타일 key | Nullable, `skipped=false`이면 Not Null |
| `hair_color` | 머리색 | Varchar(30) | 기본 캐릭터 머리색 key | Nullable, `skipped=false`이면 Not Null |
| `eye_style` | 눈 스타일 | Varchar(30) | 기본 캐릭터 눈 스타일 key | Nullable, `skipped=false`이면 Not Null |
| `eye_color` | 눈 색 | Varchar(30) | 기본 캐릭터 눈 색 key | Nullable, `skipped=false`이면 Not Null |
| `clothes` | 기본 의상 | Varchar(30) | 기본 캐릭터 의상 key | Nullable, `skipped=false`이면 Not Null |
| `skipped` | 온보딩 스킵 여부 | Boolean | 캐릭터 생성을 건너뛴 사용자 표시 | Not Null, 기본값 false |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 기본 캐릭터 수정 시각 | Not Null |

> `skipped=true` row는 캐릭터 속성 없이도 존재할 수 있다. `skipped=false` row는 `gender`, `skin_tone`, `hair_style`, `hair_color`, `eye_style`, `eye_color`, `clothes`가 모두 있어야 한다.
> DB 물리 컬럼과 저장 payload key는 snake_case를 사용한다. Flutter/Dart 모델의 `skinTone`, `hairStyle` 같은 camelCase 이름은 API 계층에서 변환한다.

> 기존 `users.pixel_character`는 현재 API 호환을 위해 남겨 둔다. 새 캐릭터 원장 write/read API를 붙일 때 `character_profiles`를 기준으로 삼고, `users.pixel_character`의 제거 또는 read-through 전략은 별도 migration/PR에서 결정한다.

## `auth_identities` (구현됨)

> OAuth provider 계정과 ONMU 내부 사용자를 연결한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 인증 식별 ID | UUID | provider identity row 식별자 | PK, Not Null |
| `user_id` | 사용자 ID | UUID | `users.id` 참조 | FK, Not Null |
| `provider` | 인증 제공자 | Varchar(30) | `NAVER`, `KAKAO`, `GOOGLE`, `APPLE` | Not Null |
| `provider_subject` | Provider 사용자 ID | Text | provider가 제공하는 고유 subject | Not Null |
| `provider_email` | Provider 이메일 | Text | provider에서 받은 이메일 | Nullable |
| `provider_profile` | Provider 프로필 | JSONB | provider별 raw profile 중 필요한 최소값 | 민감값 제외 |
| `linked_at` | 연결 시각 | Timestamptz | identity 연결 시각 | Not Null |
| `last_verified_at` | 마지막 검증 시각 | Timestamptz | provider token 검증 성공 시각 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |

> UNIQUE: `(provider, provider_subject)`

## `refresh_tokens` (다음 구현)

> 모바일 앱의 access/refresh token 흐름을 관리한다. 실제 token 원문은 저장하지 않고 해시를 저장한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Refresh token ID | UUID | refresh token row 식별자 | PK |
| `user_id` | 사용자 ID | UUID | token 소유 사용자 | FK, Not Null |
| `token_hash` | Token 해시 | Text | refresh token의 해시값 | Not Null, Unique |
| `device_id` | 기기 ID | UUID | 앱 설치/기기 단위 식별자 | Nullable |
| `device_label` | 기기 이름 | Text | iPhone, Android emulator 등 표시용 | Nullable |
| `issued_at` | 발급 시각 | Timestamptz | refresh token 발급 시각 | Not Null |
| `expires_at` | 만료 시각 | Timestamptz | refresh token 만료 시각 | Not Null |
| `rotated_at` | 회전 시각 | Timestamptz | token rotation 완료 시각 | Nullable |
| `revoked_at` | 폐기 시각 | Timestamptz | 로그아웃/탈취 대응 폐기 시각 | Nullable |
| `revoked_reason` | 폐기 사유 | Text | logout, rotation, compromised 등 | Nullable |

## `user_codes` (다음 구현)

> 친구 추가 첫 구현의 핵심 테이블이다. 사용자가 자기 코드를 보여주고, 상대가 입력해 친구 요청을 만든다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 사용자 코드 ID | UUID | 코드 row 식별자 | PK |
| `user_id` | 사용자 ID | UUID | 코드를 소유한 사용자 | FK, Not Null |
| `code` | 사용자 코드 | Varchar(20) | 사람이 입력하기 쉬운 랜덤 코드 | Unique, Not Null |
| `code_format` | 코드 형식 | Varchar(20) | `ALNUM_8`, `ALNUM_10` 등 | Not Null |
| `status` | 코드 상태 | Varchar(20) | `active`, `disabled` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 코드 생성 시각 | Not Null |
| `disabled_at` | 비활성 시각 | Timestamptz | 악용/탈퇴 등으로 비활성화한 시각 | Nullable |

> UNIQUE: `code`
> 회의 결정: 기본 코드는 대문자/숫자 8-10자리, 혼동 문자인 `O`, `0`, `I`, `1`은 제외한다. 사용자 self-service 재발급은 제공하지 않고, 악용/탈퇴/운영 조치가 필요한 경우에만 비활성화한다. 코드 검색은 `rate_limit_counters.bucket_key=friend_code_lookup`으로 분당 5회, 일 30회 수준에서 시작한다.

## `user_devices` (구현됨, 확장 필요)

> 모바일 앱 설치/기기 단위 상태를 관리한다. refresh token, push token, 보안 이벤트를 기기 기준으로 묶기 위한 테이블이다.
> 현재 구현은 push token readiness를 위해 `user_devices`에 provider, token, token hash, last4를 함께 저장한다. 실제 FCM/APNs provider delivery를 켜기 전에는 token 원문 암호화, 별도 `push_tokens` 분리, provider invalidation callback 처리 중 어떤 방식으로 production 보관 정책을 가져갈지 결정해야 한다. Terraform은 PostgreSQL 리소스 경계만 소유하고 이 table DDL은 Spring Flyway가 소유한다.
> `push_token`은 현재 text 컬럼이며 응답과 로그에는 원문을 반환하지 않는다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 기기 ID | UUID | ONMU 내부 기기 식별자 | PK |
| `user_id` | 사용자 ID | UUID | 기기 소유 사용자 | FK, Not Null |
| `device_fingerprint_hash` | 기기 fingerprint 해시 | Text | 앱 설치/기기 특성 기반 해시 | Unique 후보 |
| `platform` | 플랫폼 | Varchar(20) | `ios`, `android`, `web`, `unknown` | Not Null |
| `app_version` | 앱 버전 | Text | 마지막 접속 앱 버전 | Nullable |
| `os_version` | OS 버전 | Text | 마지막 접속 OS 버전 | Nullable |
| `device_label` | 기기 라벨 | Text | 사용자 표시용 기기 이름 | Nullable |
| `last_ip_hash` | 마지막 IP 해시 | Text | 보안 분석용 IP hash | Nullable |
| `last_user_agent` | 마지막 User-Agent | Text | 접속 client 정보 | Nullable |
| `trusted` | 신뢰 기기 여부 | Boolean | 이상 로그인 판단 보조 | 기본값 false |
| `status` | 기기 상태 | Varchar(20) | `active`, `inactive`, `revoked`, `blocked` | Not Null |
| `push_provider` | Push 제공자 | Varchar(30) | `fcm`, `apns`, `dev` | Nullable |
| `push_token` | Push token | Text | provider 발송에 필요한 기기 token. 현재 구현은 text 컬럼이며 응답/로그에 원문 출력 금지. Production 전 암호화 또는 별도 token table 분리 후보 | Nullable |
| `push_token_hash` | Push token 해시 | Text | token 중복/이전 사용자 비활성화 판단용 SHA-256 hash | Nullable |
| `push_token_last4` | Push token 마지막 4자리 | Varchar(8) | 운영 smoke와 응답 확인용 부분 식별자 | Nullable |
| `push_token_updated_at` | Push token 갱신 시각 | Timestamptz | token 등록/갱신 시각 | Nullable |
| `push_token_disabled_at` | Push token 비활성 시각 | Timestamptz | token 비활성화 시각 | Nullable |
| `last_seen_at` | 마지막 접속 시각 | Timestamptz | 마지막 API 요청 시각 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 기기 등록 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 기기 상태 수정 시각 | Not Null |

## `login_attempts` (목표 설계)

> OAuth 로그인, refresh, dev token smoke 등 인증 시도를 기록한다. 원문 token이나 provider secret은 저장하지 않는다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 로그인 시도 ID | UUID | 인증 시도 row 식별자 | PK |
| `user_id` | 사용자 ID | UUID | 식별된 사용자 | FK, Nullable |
| `auth_identity_id` | 인증 identity ID | UUID | provider identity 연결 | FK, Nullable |
| `device_id` | 기기 ID | UUID | 요청 기기 | FK, Nullable |
| `provider` | 인증 제공자 | Varchar(30) | `NAVER`, `KAKAO`, `GOOGLE`, `DEV_TOKEN` | Not Null |
| `attempt_type` | 시도 유형 | Varchar(30) | `oauth_login`, `refresh`, `logout`, `session_check` | Not Null |
| `status` | 결과 상태 | Varchar(20) | `success`, `failed`, `blocked`, `rate_limited` | Not Null |
| `failure_reason` | 실패 사유 | Text | invalid token, expired, provider error 등 | Nullable |
| `ip_hash` | IP 해시 | Text | 보안 분석용 IP hash | Nullable |
| `user_agent` | User-Agent | Text | 요청 client 정보 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 인증 시도 시각 | Not Null |

> 보존 정책: 보안 감사 목적의 단기 보존을 원칙으로 하고, 상세 IP 원문은 저장하지 않는다.

## `user_preferences` (목표 설계)

> 약속/장소/OOTD 추천과 앱 개인화에 쓰는 사용자 선호 원장이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 선호 ID | UUID | preference row 식별자 | PK |
| `user_id` | 사용자 ID | UUID | 선호 사용자 | FK, Not Null |
| `preference_type` | 선호 유형 | Varchar(40) | `place`, `food`, `activity`, `ootd`, `notification` | Not Null |
| `preference_key` | 선호 키 | Text | 카테고리/태그 key | Not Null |
| `preference_value` | 선호 값 | JSONB | 선호 강도, 세부 설정 | Not Null |
| `source` | 수집 경로 | Varchar(30) | `onboarding`, `profile`, `behavior`, `ai` | Not Null |
| `confidence` | 신뢰도 | Numeric(5,4) | 행동 기반 추론 신뢰도 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 선호 수정 시각 | Not Null |

> UNIQUE 후보: `(user_id, preference_type, preference_key)`

## `user_blocks` (목표 설계)

> 친구 요청, 모임 초대, 공유 링크에서 차단 관계를 일관되게 적용한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 차단 ID | UUID | block row 식별자 | PK |
| `blocker_user_id` | 차단한 사용자 ID | UUID | 차단을 건 사용자 | FK, Not Null |
| `blocked_user_id` | 차단된 사용자 ID | UUID | 차단 대상 사용자 | FK, Not Null |
| `reason` | 차단 사유 | Text | 사용자 입력 또는 시스템 사유 | Nullable |
| `source` | 차단 경로 | Varchar(30) | `friend`, `invite`, `report`, `settings` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 차단 시각 | Not Null |
| `deleted_at` | 해제 시각 | Timestamptz | 차단 해제 시각 | Nullable |

> UNIQUE: `(blocker_user_id, blocked_user_id)` where `deleted_at is null`

---

# 3. Friend / Invite

## `friendships` (구현됨)

> 상호 친구 관계 원장이다. 친구 요청이 수락되면 한 row만 생성한다. 두 사용자 ID를 정렬한 canonical pair를 저장해 관계 정합성을 보호한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 친구 관계 ID | UUID | 관계 row 식별자 | PK |
| `user_low_id` | 낮은 정렬 사용자 ID | UUID | canonical pair의 첫 사용자 | FK, Not Null |
| `user_high_id` | 높은 정렬 사용자 ID | UUID | canonical pair의 두 번째 사용자 | FK, Not Null |
| `status` | 관계 상태 | Varchar(20) | `active`, `deleted` | Not Null |
| `source` | 생성 경로 | Varchar(30) | `user_code`, `contact`, `kakao`, `group_invite` | Not Null |
| `accepted_request_id` | 수락된 요청 ID | UUID | 원본 친구 요청 | FK, Nullable |
| `created_at` | 생성 시각 | Timestamptz | 친구 관계 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 상태 수정 시각 | Not Null |
| `deleted_at` | 삭제 시각 | Timestamptz | 친구 삭제 시각 | Nullable |

> UNIQUE: `(user_low_id, user_high_id)`
> CHECK: `user_low_id < user_high_id`
> 회의 결정: 양방향 row 대신 canonical pair 원장을 둔다. 친구 목록 조회는 query/read model에서 양쪽 방향을 풀고, 사용자별 메모/숨김 설정은 `friend_settings`로 분리한다.
> API 구현 메모: 친구 추가 시 요청 방향을 그대로 저장하지 않고 `least(user_a, user_b)` / `greatest(user_a, user_b)` 기준으로 `user_low_id`, `user_high_id`를 정규화한다. 따라서 A→B와 B→A가 중복 row로 들어가지 않는다.

## `friend_settings` (구현됨)

> 친구 관계에 대한 사용자별 표시 설정이다. 관계 원장은 `friendships`가 소유하고, 각 사용자가 상대를 어떻게 표시할지는 별도 row로 관리한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 친구 설정 ID | UUID | 설정 row 식별자 | PK |
| `friendship_id` | 친구 관계 ID | UUID | canonical friendship 참조 | FK, Not Null |
| `user_id` | 설정 소유 사용자 ID | UUID | 이 설정을 적용받는 사용자 | FK, Not Null |
| `friend_user_id` | 상대 사용자 ID | UUID | 표시 대상 친구 | FK, Not Null |
| `display_alias` | 표시 별칭 | Text | 사용자가 붙인 친구 별칭 | Nullable |
| `memo` | 친구 메모 | Text | 사용자가 붙인 개인 메모 | Nullable |
| `hidden` | 숨김 여부 | Boolean | 친구 목록에서 숨김 | Not Null |
| `is_favorite` | 즐겨찾기 여부 | Boolean | 마이페이지 즐겨찾는 친구 표시 여부 | Not Null, Default false |
| `created_at` | 생성 시각 | Timestamptz | 설정 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 설정 수정 시각 | Not Null |

> UNIQUE: `(friendship_id, user_id)`
> 한 친구 관계가 수락되면 두 사용자의 기본 설정 row를 생성한다. 설정 row의 불일치는 관계 원장 정합성에 영향을 주지 않는다. `memo`, `display_alias`, `hidden`, `is_favorite`는 모두 설정 소유자인 `user_id` 기준 개인 값이다.
> API 구현 메모: 친구 상세 프로필 조회 `GET /api/v1/users/me/friends/{friendUserId}/profile`은 `friend_settings`와 `friendships`로 active 관계를 확인한 뒤 상대 사용자의 `users.preference_profile`과 `users.pixel_character`를 반환한다. 이때 `friend_settings.memo`는 조회자 개인 메모로 친구의 공개 취향 프로필을 대체하지 않는다.

## `friend_requests` (다음 구현)

> 사용자 코드 입력, 연락처 추천, 카카오 초대에서 시작되는 친구 요청 상태를 관리한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 친구 요청 ID | UUID | 요청 row 식별자 | PK |
| `requester_user_id` | 요청자 ID | UUID | 친구 요청을 보낸 사용자 | FK, Not Null |
| `target_user_id` | 대상자 ID | UUID | 친구 요청을 받은 사용자 | FK, Not Null |
| `request_code` | 입력 코드 | Text | 사용자가 입력한 코드 snapshot | Nullable |
| `source` | 요청 경로 | Varchar(30) | `user_code`, `contact`, `kakao`, `link` | Not Null |
| `message` | 요청 메시지 | Text | 친구 요청에 포함한 짧은 문구 | Nullable |
| `status` | 요청 상태 | Varchar(20) | `pending`, `accepted`, `rejected`, `canceled`, `expired` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 요청 생성 시각 | Not Null |
| `responded_at` | 응답 시각 | Timestamptz | 수락/거절 시각 | Nullable |
| `expires_at` | 만료 시각 | Timestamptz | 미응답 요청 만료 시각 | Nullable |

## `contact_imports` (미래 확장)

> 연락처 동기화 기능이 들어올 때 원문 연락처를 저장하지 않고 해시/동의/매칭 상태만 저장한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 연락처 import ID | UUID | import 작업 식별자 | PK |
| `user_id` | 사용자 ID | UUID | import를 실행한 사용자 | FK, Not Null |
| `phone_hash` | 전화번호 해시 | Text | 전화번호 정규화 후 해시 | Not Null |
| `matched_user_id` | 매칭 사용자 ID | UUID | ONMU 사용자로 매칭된 대상 | FK, Nullable |
| `match_status` | 매칭 상태 | Varchar(20) | `matched`, `not_found`, `blocked`, `pending` | Not Null |
| `consent_snapshot_id` | 동의 snapshot ID | UUID | 연락처 접근 동의 기록 | FK 후보 |
| `created_at` | 생성 시각 | Timestamptz | import 시각 | Not Null |

## `external_invites` (목표 설계)

> 카카오톡 초대하기, 공유 링크, SMS 등 외부 초대 채널을 통합한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 외부 초대 ID | UUID | 초대 row 식별자 | PK |
| `inviter_user_id` | 초대한 사용자 ID | UUID | 초대를 만든 사용자 | FK, Not Null |
| `target_user_id` | 대상 사용자 ID | UUID | 가입 후 매칭된 사용자 | FK, Nullable |
| `group_id` | 모임 ID | UUID | 모임 초대인 경우 연결 | FK, Nullable |
| `plan_id` | 약속 ID | UUID | 약속 초대인 경우 연결 | FK, Nullable |
| `channel` | 초대 채널 | Varchar(30) | `kakao`, `contact`, `sms`, `link` | Not Null |
| `invite_token_hash` | 초대 토큰 해시 | Text | 공유 링크 token의 해시 | Unique 후보 |
| `status` | 초대 상태 | Varchar(20) | `created`, `opened`, `accepted`, `expired`, `revoked` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 초대 생성 시각 | Not Null |
| `opened_at` | 열람 시각 | Timestamptz | 링크/초대 열람 시각 | Nullable |
| `accepted_at` | 수락 시각 | Timestamptz | 초대 수락 시각 | Nullable |
| `expires_at` | 만료 시각 | Timestamptz | 초대 만료 시각 | Nullable |

---

# 4. Group / Plan

## `groups` (구현됨, 확장 필요)

> 온모임의 상위 공간이다. 사람, 채팅, 투표, 기록, 약속이 이 공간 안에서 묶인다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 모임 ID | UUID | 내부 group 식별자 | PK |
| `public_id` | 공개 모임 ID | Text | API contract용 안정 ID | Unique, 구현됨 |
| `name` | 모임 이름 | Text | 사용자에게 보이는 온모임 이름 | Not Null |
| `description` | 모임 설명 | Text | 모임 홈 소개 문구 | 목표 설계 |
| `owner_user_id` | 소유자 ID | UUID | 모임 생성자 또는 관리자 | FK |
| `cover_image_url` | 커버 이미지 URL | Text | 모임 홈 커버 이미지 | Nullable |
| `status` | 모임 상태 | Varchar(20) | `active`, `archived`, `deleted` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 모임 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 모임 수정 시각 | Not Null |
| `deleted_at` | 삭제 시각 | Timestamptz | 모임 삭제 시각 | Nullable |

## `group_members` (다음 구현)

> 모임 참여자와 권한을 관리한다. 친구 관계와 독립적으로 존재한다. 초기 초대 생성은 친구 기반으로 제한하되, 모임 안에는 나와 직접 친구가 아닌 멤버도 존재할 수 있다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 모임 멤버 ID | UUID | row 식별자 | PK |
| `group_id` | 모임 ID | UUID | 소속 모임 | FK, Not Null |
| `user_id` | 사용자 ID | UUID | 참여 사용자 | FK, Not Null |
| `role` | 모임 역할 | Varchar(20) | `owner`, `admin`, `member` | Not Null |
| `display_name_override` | 모임 내 표시 이름 | Text | 모임 안에서만 쓰는 별칭 | Nullable |
| `status` | 멤버 상태 | Varchar(20) | `active`, `invited`, `left`, `removed` | Not Null |
| `joined_at` | 참여 시각 | Timestamptz | 모임 참여 시각 | Nullable |
| `left_at` | 나간 시각 | Timestamptz | 모임 나가기/제거 시각 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |

> UNIQUE: `(group_id, user_id)`
> 회의 결정: 직접 친구가 아니어도 같은 모임의 멤버가 될 수 있다. 다만 초기 구현에서는 초대 생성 대상을 친구로 제한하고, 링크/카카오 초대와 비친구 직접 초대는 미래 확장으로 둔다.

## `group_invites` (목표 설계)

> 모임 단위 초대 상태를 관리한다. 초기 구현은 친구 초대를 기준으로 하고, 링크 초대와 카카오 공유는 같은 테이블에서 확장한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 모임 초대 ID | UUID | 초대 row 식별자 | PK |
| `group_id` | 모임 ID | UUID | 초대 대상 모임 | FK, Not Null |
| `inviter_user_id` | 초대한 사용자 ID | UUID | 초대 생성자 | FK, Not Null |
| `invitee_user_id` | 초대받은 사용자 ID | UUID | 가입/친구 상태인 초대 대상 | FK, Nullable |
| `external_invite_id` | 외부 초대 ID | UUID | 링크/카카오 초대 연결 | FK, Nullable |
| `status` | 초대 상태 | Varchar(20) | `pending`, `accepted`, `declined`, `expired`, `revoked` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 초대 생성 시각 | Not Null |
| `responded_at` | 응답 시각 | Timestamptz | 수락/거절 시각 | Nullable |
| `expires_at` | 만료 시각 | Timestamptz | 초대 만료 시각 | Nullable |

## `plans` (구현됨, 확장 필요)

> 온모임 안에서 만들어지는 약속 단위다. 장소, 투표, 정산, 기록의 기준이 된다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 약속 ID | UUID | 내부 plan 식별자 | PK |
| `public_id` | 공개 약속 ID | Text | API contract용 안정 ID | Unique, 구현됨 |
| `group_id` | 모임 ID | UUID | 약속이 속한 모임 | FK, Not Null |
| `title` | 약속 제목 | Text | 약속 이름 | Not Null |
| `description` | 약속 설명 | Text | 약속 메모/설명 | 목표 설계 |
| `starts_at` | 시작 시각 | Timestamptz | 약속 시작 시각 | Nullable |
| `ends_at` | 종료 시각 | Timestamptz | 약속 종료 시각 | Nullable |
| `location_label` | 대표 장소명 | Text | 약속 카드에 보이는 대표 장소 | Nullable |
| `status` | 약속 상태 | Varchar(30) | `draft`, `confirmed`, `completed`, `canceled` | Not Null |
| `visibility` | 공개 범위 | Varchar(30) | `participants`, `group`, `private` | 목표 설계 |
| `created_by_user_id` | 생성자 ID | UUID | 약속 생성 사용자 | FK |
| `created_at` | 생성 시각 | Timestamptz | 약속 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 약속 수정 시각 | Not Null |
| `canceled_at` | 취소 시각 | Timestamptz | 약속 취소 시각 | Nullable |

## `plan_participants` (다음 구현)

> 약속 참여자를 관리한다. 모임 멤버 전체가 항상 약속 참여자인 것은 아니다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 약속 참여자 ID | UUID | row 식별자 | PK |
| `plan_id` | 약속 ID | UUID | 참여 약속 | FK, Not Null |
| `user_id` | 사용자 ID | UUID | 참여 사용자 | FK, Not Null |
| `group_member_id` | 모임 멤버 ID | UUID | 모임 멤버 row 연결 | FK, Nullable |
| `status` | 참여 상태 | Varchar(20) | `invited`, `accepted`, `declined`, `tentative`, `removed` | Not Null |
| `role` | 약속 역할 | Varchar(20) | `host`, `participant` | Not Null |
| `joined_at` | 참여 확정 시각 | Timestamptz | 참여 수락 시각 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |

> UNIQUE: `(plan_id, user_id)`

## `plan_time_candidates` (목표 설계)

> 약속 만들기 과정에서 여러 시간 후보를 모으고 투표/추천할 때 사용한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 시간 후보 ID | UUID | row 식별자 | PK |
| `plan_id` | 약속 ID | UUID | 연결 약속 | FK, Not Null |
| `starts_at` | 후보 시작 시각 | Timestamptz | 후보 시작 시간 | Not Null |
| `ends_at` | 후보 종료 시각 | Timestamptz | 후보 종료 시간 | Nullable |
| `status` | 후보 상태 | Varchar(20) | `candidate`, `selected`, `rejected` | Not Null |
| `recommended` | 추천 여부 | Boolean | 시스템 추천 후보 여부 | 기본값 false |
| `created_by_user_id` | 생성자 ID | UUID | 후보를 추가한 사용자 | FK |
| `created_at` | 생성 시각 | Timestamptz | 후보 생성 시각 | Not Null |

## `plan_availability_responses` (목표 설계)

> 약속 시간 후보에 대한 사용자별 가능 여부를 저장한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 가능 시간 응답 ID | UUID | row 식별자 | PK |
| `plan_id` | 약속 ID | UUID | 연결 약속 | FK, Not Null |
| `time_candidate_id` | 시간 후보 ID | UUID | 연결 시간 후보 | FK, Not Null |
| `user_id` | 사용자 ID | UUID | 응답 사용자 | FK, Not Null |
| `availability` | 가능 여부 | Varchar(20) | `available`, `maybe`, `unavailable` | Not Null |
| `note` | 응답 메모 | Text | 늦게 도착, 먼저 퇴장 등 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 응답 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 응답 수정 시각 | Not Null |

> UNIQUE: `(time_candidate_id, user_id)`

## `plan_checklists` (목표 설계)

> 준비물, 예약, 입금 확인처럼 약속 전 협업 체크리스트를 관리한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 체크리스트 ID | UUID | checklist row 식별자 | PK |
| `plan_id` | 약속 ID | UUID | 연결 약속 | FK, Not Null |
| `title` | 체크리스트 제목 | Text | 준비물, 예약 확인 등 | Not Null |
| `created_by_user_id` | 생성자 ID | UUID | 체크리스트 생성 사용자 | FK |
| `status` | 상태 | Varchar(20) | `active`, `archived` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 수정 시각 | Not Null |

## `plan_checklist_items` (목표 설계)

> 체크리스트의 개별 항목이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 체크 항목 ID | UUID | item row 식별자 | PK |
| `checklist_id` | 체크리스트 ID | UUID | 연결 체크리스트 | FK, Not Null |
| `assignee_user_id` | 담당자 ID | UUID | 담당 사용자 | FK, Nullable |
| `title` | 항목 제목 | Text | 준비물/할 일 제목 | Not Null |
| `status` | 항목 상태 | Varchar(20) | `open`, `done`, `canceled` | Not Null |
| `due_at` | 마감 시각 | Timestamptz | 항목 마감 시각 | Nullable |
| `done_at` | 완료 시각 | Timestamptz | 완료 시각 | Nullable |
| `sort_order` | 정렬 순서 | Integer | 화면 표시 순서 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 생성 시각 | Not Null |

## `plan_status_events` (목표 설계)

> 약속 상태 변경 이력을 append-only로 저장한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 상태 이벤트 ID | UUID | event row 식별자 | PK |
| `plan_id` | 약속 ID | UUID | 연결 약속 | FK, Not Null |
| `actor_user_id` | 행위자 ID | UUID | 상태를 변경한 사용자 | FK, Nullable |
| `from_status` | 이전 상태 | Varchar(30) | 변경 전 상태 | Nullable |
| `to_status` | 이후 상태 | Varchar(30) | 변경 후 상태 | Not Null |
| `reason` | 변경 사유 | Text | 취소/완료 사유 등 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 이벤트 발생 시각 | Not Null |

---

# 5. Place

## `external_places` (목표 설계)

> Naver Maps/Place API 등 외부 장소 원본을 내부 후보와 분리해 캐시한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 외부 장소 ID | UUID | 내부 캐시 row 식별자 | PK |
| `public_id` | 공개 외부 장소 ID | Text | API contract용 안정 ID | Unique |
| `provider` | 제공자 | Varchar(30) | `NAVER`, `KAKAO`, `GOOGLE`, `MANUAL`, `AI_EXTRACT`, `CRAWLER` | Not Null |
| `provider_place_id` | Provider 장소 ID | Text | 외부 API의 장소 ID | Nullable |
| `name` | 장소명 | Text | 장소 이름 | Not Null |
| `category` | 카테고리 | Text | 음식점, 카페 등 | Nullable |
| `address` | 주소 | Text | 지번/도로명 주소 | Nullable |
| `road_address` | 도로명 주소 | Text | 도로명 주소 | Nullable |
| `latitude` | 위도 | Numeric(10,7) | 지도 표시/거리 계산 | Nullable |
| `longitude` | 경도 | Numeric(10,7) | 지도 표시/거리 계산 | Nullable |
| `phone_label` | 전화번호 라벨 | Text | 앱 표시용 전화번호 문자열 | Nullable |
| `homepage_url` | 대표 홈페이지 URL | Text | 외부 장소의 대표 홈페이지 | Nullable |
| `link_summary` | 링크 요약 캐시 | JSONB | API 응답에서 빠르게 사용할 링크 read model | Not Null, Default `[]` |
| `provider_payload` | Provider 요약 payload | JSONB | 외부 응답 중 장소 캐시에 필요한 최소 정보 | Not Null, 민감값 제외 |
| `created_at` | 생성 시각 | Timestamptz | 내부 캐시 row 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 내부 캐시 row 수정 시각 | Not Null |

> UNIQUE 후보: `(provider, provider_place_id)`
> `link_summary`는 앱/API 표시용 캐시이며 canonical 원장은 `external_place_links`다. `instagram`, `reservation`, `menu`, `blog`, `homepage`, `naver_place`, `kakao_place` 같은 링크 요약만 담고 secret/token/개인정보는 저장하지 않는다.

예시:

```json
[
  {
    "type": "instagram",
    "url": "https://example.test/onmu-place-instagram",
    "label": "인스타그램",
    "status": "active",
    "source": "provider"
  },
  {
    "type": "reservation",
    "provider": "catchtable",
    "url": "https://example.test/onmu-place-reservation",
    "label": "예약"
  }
]
```

## `external_place_links` (다음 구현)

> 장소별 외부 링크 canonical 원장이다. 링크 중복 제거, 상태 관리, 검증 시각, 만료, 표시 순서를 구조화해 관리한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 외부 장소 링크 ID | UUID | 링크 row 식별자 | PK |
| `external_place_id` | 외부 장소 ID | UUID | 연결 외부 장소 | FK, Not Null |
| `link_type` | 링크 유형 | Varchar(40) | `homepage`, `instagram`, `baemin`, `catchtable`, `menu`, `blog`, `naver_place`, `kakao_place`, `reservation`, `other` | Not Null |
| `url` | 원본 URL | Text | 앱/서버가 참조할 외부 링크 | Not Null |
| `normalized_url` | 정규화 URL | Text | 중복 제거용 정규화 링크 | Nullable |
| `label` | 표시 라벨 | Text | 앱에서 보이는 링크 라벨 | Nullable |
| `provider` | 링크 제공자 | Varchar(30) | `NAVER`, `KAKAO`, `GOOGLE`, `MANUAL`, `AI_EXTRACT`, `CRAWLER` | Nullable |
| `source_type` | 링크 출처 유형 | Varchar(30) | `provider`, `manual`, `crawler`, `ai_extract` | Not Null |
| `status` | 링크 상태 | Varchar(20) | `active`, `inactive`, `broken`, `hidden` | Not Null |
| `display_order` | 표시 순서 | Integer | 같은 장소 안에서 링크 노출 순서 | Not Null |
| `confidence` | 신뢰도 | Numeric(5,4) | AI/크롤러 추출 링크 신뢰도 | Nullable, 0~1 |
| `fetched_at` | 수집 시각 | Timestamptz | Provider/크롤러 수집 시각 | Nullable |
| `verified_at` | 검증 시각 | Timestamptz | 링크가 마지막으로 확인된 시각 | Nullable |
| `expires_at` | 만료 시각 | Timestamptz | 재검증 또는 숨김 판단 기준 | Nullable |
| `metadata` | 보조 metadata | JSONB | provider별 동적 링크 세부 정보 | Not Null, Default `{}` |
| `created_at` | 생성 시각 | Timestamptz | 링크 row 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 링크 row 수정 시각 | Not Null |

역할 분리:

- `external_places.link_summary`: 앱/API 응답에서 빠르게 사용할 표시용 캐시/read model.
- `external_place_links`: 중복 제거, 검증, 상태, 만료, 표시 순서를 관리하는 canonical 링크 원장.
- `place_source_snapshots`: provider 원본 응답, 크롤러 원본, AI 추출 이력을 저장하는 source history.

`metadata`에는 provider별 동적 정보만 저장하며 secret/token/개인정보를 넣지 않는다. 중복 방지는 `(external_place_id, normalized_url)` partial unique와 `(external_place_id, link_type, url)` unique를 우선한다.

## `place_candidates` (구현됨, 확장 필요)

> 약속 단위 후보 pool이다. 후보는 일정에 등록될 수도 있고, 투표 대상이 될 수도 있다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 장소 후보 ID | UUID | 내부 후보 식별자 | PK |
| `public_id` | 공개 후보 ID | Text | API contract용 안정 ID | Unique, 구현됨 |
| `group_id` | 모임 ID | UUID | 후보가 속한 모임 | FK, Not Null |
| `plan_id` | 약속 ID | UUID | 후보가 속한 약속 | FK, Not Null |
| `external_place_id` | 외부 장소 ID | UUID | 외부 장소 캐시 연결 | FK, Nullable |
| `name` | 장소명 | Text | 후보 장소 이름 | Not Null |
| `category` | 카테고리 | Text | 카페, 한식 등 | Nullable |
| `address` | 주소 | Text | 사용자에게 보이는 주소 | Nullable |
| `summary` | 후보 요약 | Text | 후보 카드에 보이는 한 줄 설명 | 목표 설계 |
| `added_by_user_id` | 추가자 ID | UUID | 후보를 추가한 사용자 | FK |
| `status` | 후보 상태 | Varchar(20) | `candidate`, `selected`, `archived`, `removed` | Not Null |
| `payload` | 보조 payload | JSONB | 태그, 선호 메모, 표시용 보조 정보 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 후보 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 후보 수정 시각 | 목표 설계 |

## `place_candidate_reactions` (목표 설계)

> 후보 리스트의 하트/선호 표시를 저장한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 후보 반응 ID | UUID | row 식별자 | PK |
| `place_candidate_id` | 장소 후보 ID | UUID | 반응 대상 후보 | FK, Not Null |
| `user_id` | 사용자 ID | UUID | 반응 사용자 | FK, Not Null |
| `reaction_type` | 반응 유형 | Varchar(20) | `heart`, `like`, `avoid` | Not Null |
| `note` | 선호 메모 | Text | 후보에 대한 짧은 메모 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 반응 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 반응 수정 시각 | Nullable |

> UNIQUE: `(place_candidate_id, user_id, reaction_type)`

## `schedule_places` (구현됨, 확장 필요)

> 특정 약속의 일정/동선에 등록된 장소다. 후보와 달리 시간과 순서를 가진다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 일정 장소 ID | UUID | 내부 일정 장소 식별자 | PK |
| `public_id` | 공개 일정 장소 ID | Text | API contract용 안정 ID | Unique, 구현됨 |
| `group_id` | 모임 ID | UUID | 연결 모임 | FK, Not Null |
| `plan_id` | 약속 ID | UUID | 연결 약속 | FK, Not Null |
| `place_candidate_id` | 장소 후보 ID | UUID | 후보에서 일정 등록한 경우 연결 | FK, Nullable |
| `external_place_id` | 외부 장소 ID | UUID | 검색 결과에서 바로 등록한 경우 연결 | FK, Nullable |
| `name` | 장소명 | Text | 일정에 보이는 장소 이름 | Not Null |
| `starts_at` | 시작 시각 | Timestamptz | 방문 시작 시각 | Nullable |
| `ends_at` | 종료 시각 | Timestamptz | 방문 종료 시각 | Nullable |
| `sort_order` | 정렬 순서 | Integer | 동선 카드 표시 순서 | Not Null |
| `memo` | 장소 메모 | Text | 일정 장소별 메모 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 일정 장소 생성 시각 | Not Null |

## `place_search_logs` (목표 설계)

> 장소 검색 품질, 캐시, 장애 대응을 위한 검색 요청 로그다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 검색 로그 ID | UUID | row 식별자 | PK |
| `user_id` | 사용자 ID | UUID | 검색 사용자 | FK, Nullable |
| `group_id` | 모임 ID | UUID | 검색 맥락 모임 | FK, Nullable |
| `plan_id` | 약속 ID | UUID | 검색 맥락 약속 | FK, Nullable |
| `query` | 검색어 | Text | 사용자가 입력한 검색어 | Not Null |
| `bounds` | 지도 범위 | JSONB | 지도 bounds, 중심 좌표, zoom | Nullable |
| `filters` | 검색 필터 | JSONB | 카테고리, 시간, 인원, 취향 필터 | Nullable |
| `provider` | 제공자 | Varchar(30) | `NAVER`, `CACHE`, `MANUAL` | Not Null |
| `result_count` | 결과 수 | Integer | 반환된 후보 수 | Not Null |
| `latency_ms` | 지연 시간 | Integer | 외부 API/검색 응답 시간 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 검색 시각 | Not Null |

## `place_opening_hours` (목표 설계)

> 외부 장소 영업시간을 구조화해 저장한다. 원본 텍스트는 snapshot에 두고, 앱 판단용 값은 여기서 계산한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 영업시간 ID | UUID | row 식별자 | PK |
| `external_place_id` | 외부 장소 ID | UUID | 연결 장소 | FK, Not Null |
| `day_of_week` | 요일 | Smallint | 0=일요일, 6=토요일 | Not Null |
| `opens_at_local` | 오픈 시간 | Time | 현지 오픈 시간 | Nullable |
| `closes_at_local` | 마감 시간 | Time | 현지 마감 시간 | Nullable |
| `last_order_at_local` | 라스트오더 시간 | Time | 라스트오더 시간 | Nullable |
| `closed` | 휴무 여부 | Boolean | 해당 요일 휴무 여부 | Not Null |
| `source` | 출처 | Varchar(30) | `provider`, `manual`, `ai_extract` | Not Null |
| `confidence` | 신뢰도 | Numeric(5,4) | AI/외부 정보 신뢰도 | Nullable |
| `valid_from` | 유효 시작일 | Date | 영업시간 유효 시작일 | Nullable |
| `valid_to` | 유효 종료일 | Date | 영업시간 유효 종료일 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |

## `place_source_snapshots` (목표 설계)

> 외부 장소 API 응답, 공지/휴무 정보, 수동 확인 결과를 이력으로 저장한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 장소 snapshot ID | UUID | snapshot row 식별자 | PK |
| `external_place_id` | 외부 장소 ID | UUID | 연결 장소 | FK, Not Null |
| `source_type` | 출처 유형 | Varchar(30) | `naver_api`, `manual`, `notice`, `ai_extract` | Not Null |
| `source_url` | 출처 URL | Text | 공지/외부 페이지 URL | Nullable |
| `payload` | Snapshot payload | JSONB | 응답/수집 결과 중 필요한 값 | Not Null |
| `fetched_at` | 수집 시각 | Timestamptz | 외부 조회 시각 | Not Null |
| `expires_at` | 만료 시각 | Timestamptz | 재수집 기준 | Nullable |

> 개인정보와 무관한 장소 정보라도 source payload는 무제한 저장하지 않고 만료/압축 정책을 둔다.

---

# 6. Vote

## `votes` (구현됨, 확장 필요)

> 모임 단위 자체 생성 리소스다. 일반 투표부터 장소/일정/정산/준비물 투표까지 연결 대상을 가진다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 투표 ID | UUID | 내부 vote 식별자 | PK |
| `public_id` | 공개 투표 ID | Text | API contract용 안정 ID | Unique, 구현됨 |
| `group_id` | 모임 ID | UUID | 투표가 속한 모임 | FK, Not Null |
| `target_type` | 대상 유형 | Varchar(30) | `GROUP`, `PLAN`, `PLACE_CANDIDATE`, `SETTLEMENT` | Nullable |
| `target_id` | 대상 ID | Text | 대상 리소스의 public/internal ID | Nullable |
| `vote_type` | 투표 유형 | Varchar(30) | `PLACE`, `TIME`, `SETTLEMENT`, `GENERAL`, `CHECKLIST` | Not Null |
| `title` | 투표 제목 | Text | 투표 카드 제목 | Not Null |
| `description` | 투표 설명 | Text | 투표 상세 설명 | 목표 설계 |
| `status` | 투표 상태 | Varchar(20) | `open`, `closed`, `canceled` | Not Null |
| `deadline_at` | 마감 시각 | Timestamptz | 투표 마감 시각 | Nullable |
| `created_by_user_id` | 생성자 ID | UUID | 투표 생성 사용자 | FK |
| `payload` | 보조 payload | JSONB | dev scaffold와 표시용 옵션 snapshot | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 투표 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 투표 수정 시각 | Not Null |
| `closed_at` | 종료 시각 | Timestamptz | 투표 종료 시각 | Nullable |

## `vote_options` (다음 구현)

> 투표 선택지다. 현재 scaffold의 `payload.options`를 정규화한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 투표 옵션 ID | UUID | 선택지 row 식별자 | PK |
| `vote_id` | 투표 ID | UUID | 연결 투표 | FK, Not Null |
| `place_candidate_id` | 장소 후보 ID | UUID | 장소 투표 선택지 연결 | FK, Nullable |
| `label` | 선택지 라벨 | Text | 사용자에게 보이는 선택지명 | Not Null |
| `description` | 선택지 설명 | Text | 부가 설명 | Nullable |
| `sort_order` | 정렬 순서 | Integer | 표시 순서 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 선택지 생성 시각 | Not Null |

## `vote_responses` (다음 구현)

> 사용자별 투표 응답이다. 복수 선택 여부는 vote 설정 또는 payload에서 결정한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 투표 응답 ID | UUID | 응답 row 식별자 | PK |
| `vote_id` | 투표 ID | UUID | 연결 투표 | FK, Not Null |
| `vote_option_id` | 투표 옵션 ID | UUID | 선택한 옵션 | FK, Not Null |
| `user_id` | 사용자 ID | UUID | 응답 사용자 | FK, Not Null |
| `comment` | 응답 코멘트 | Text | 선택 사유/메모 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 응답 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 응답 수정 시각 | Nullable |

> UNIQUE 후보: `(vote_id, vote_option_id, user_id)`
> 단일 선택 투표는 application constraint로 사용자당 하나만 허용한다.

---

# 7. Settlement

## `settlement_drafts` (구현됨, 확장 필요)

> 정산 생성 전 편집 상태다. 약속 단위로 하나의 draft를 우선한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 정산 Draft ID | UUID | 내부 draft 식별자 | PK |
| `public_id` | 공개 Draft ID | Text | API contract용 안정 ID | Unique, 구현됨 |
| `group_id` | 모임 ID | UUID | 연결 모임 | FK, Not Null |
| `plan_id` | 약속 ID | UUID | 연결 약속 | FK, Not Null |
| `status` | Draft 상태 | Varchar(20) | `editing`, `previewed`, `submitted`, `discarded` | 목표 설계 |
| `payload` | Draft payload | JSONB | scaffold 단계의 항목/대상자 snapshot | Not Null |
| `created_by_user_id` | 생성자 ID | UUID | draft 생성 사용자 | FK |
| `created_at` | 생성 시각 | Timestamptz | draft 생성 시각 | 목표 설계 |
| `updated_at` | 수정 시각 | Timestamptz | draft 수정 시각 | Not Null |

> UNIQUE 후보: `(plan_id, status)`에서 active draft 1개를 application constraint로 관리한다.

## `settlement_items` (다음 구현)

> 정산 결제 항목이다. 현재 `settlement_drafts.payload.items`를 정규화한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 정산 항목 ID | UUID | 항목 row 식별자 | PK |
| `settlement_draft_id` | Draft ID | UUID | 편집 중인 draft | FK, Nullable |
| `settlement_id` | 정산 ID | UUID | 최종 정산 연결 | FK, Nullable |
| `title` | 항목명 | Text | 식사, 카페, 숙소 등 | Not Null |
| `amount` | 결제 금액 | Numeric(12,2) | 항목 총액 | Not Null |
| `currency` | 통화 | Varchar(3) | `KRW` 등 | Not Null |
| `split_type` | 분할 방식 | Varchar(20) | `equal`, `custom` | Not Null |
| `paid_at` | 결제 시각 | Timestamptz | 실제 결제 시각 | Nullable |
| `memo` | 항목 메모 | Text | 영수증/설명 | Nullable |
| `sort_order` | 정렬 순서 | Integer | 정산 화면 표시 순서 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 항목 생성 시각 | Not Null |

## `settlement_item_payers` (다음 구현)

> 한 항목을 여러 명이 나누어 결제한 경우까지 지원한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 결제자 row ID | UUID | row 식별자 | PK |
| `settlement_item_id` | 정산 항목 ID | UUID | 연결 항목 | FK, Not Null |
| `user_id` | 결제자 ID | UUID | 돈을 낸 사용자 | FK, Not Null |
| `paid_amount` | 결제 금액 | Numeric(12,2) | 해당 사용자가 낸 금액 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |

## `settlement_item_targets` (다음 구현)

> 항목별 정산 대상자와 부담액을 저장한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 정산 대상 row ID | UUID | row 식별자 | PK |
| `settlement_item_id` | 정산 항목 ID | UUID | 연결 항목 | FK, Not Null |
| `user_id` | 대상자 ID | UUID | 비용을 부담하는 사용자 | FK, Not Null |
| `target_amount` | 부담 금액 | Numeric(12,2) | 개별 금액 모드에서의 금액 | Nullable |
| `included` | 대상 포함 여부 | Boolean | 대상자 선택 여부 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |

## `settlements` (구현됨, 확장 필요)

> 최종 생성된 정산 결과다. 약속 단위로 저장하고 채팅/알림에 공유된다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 정산 ID | UUID | 내부 정산 식별자 | PK |
| `public_id` | 공개 정산 ID | Text | API contract용 안정 ID | Unique, 구현됨 |
| `group_id` | 모임 ID | UUID | 연결 모임 | FK, Not Null |
| `plan_id` | 약속 ID | UUID | 연결 약속 | FK, Not Null |
| `status` | 정산 상태 | Varchar(20) | `created`, `shared`, `completed`, `canceled` | 목표 설계 |
| `total_amount` | 총 정산 금액 | Numeric(12,2) | 최종 항목 합계 | 다음 구현 |
| `currency` | 통화 | Varchar(3) | `KRW` 등 | 다음 구현 |
| `payload` | 결과 payload | JSONB | scaffold 단계 결과 snapshot | Not Null |
| `created_by_user_id` | 생성자 ID | UUID | 정산 생성 사용자 | FK |
| `created_at` | 생성 시각 | Timestamptz | 정산 생성 시각 | Not Null |
| `completed_at` | 완료 시각 | Timestamptz | 정산 완료 처리 시각 | Nullable |

## `settlement_transfers` (다음 구현)

> 최종 정산 결과의 송금 요약이다. 실제 결제/송금 연동은 별도 범위다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 송금 요약 ID | UUID | row 식별자 | PK |
| `settlement_id` | 정산 ID | UUID | 연결 정산 | FK, Not Null |
| `from_user_id` | 보내는 사용자 ID | UUID | 돈을 보내야 하는 사용자 | FK, Not Null |
| `to_user_id` | 받는 사용자 ID | UUID | 돈을 받아야 하는 사용자 | FK, Not Null |
| `amount` | 송금 금액 | Numeric(12,2) | 송금 요약 금액 | Not Null |
| `status` | 송금 상태 | Varchar(20) | `pending`, `confirmed`, `waived` | Not Null |
| `confirmed_at` | 확인 시각 | Timestamptz | 송금 완료 확인 시각 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |

## `settlement_receipts` (목표 설계)

> 정산 항목에 연결된 영수증/증빙 이미지와 OCR/수동 검증 상태를 관리한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 영수증 ID | UUID | receipt row 식별자 | PK |
| `settlement_item_id` | 정산 항목 ID | UUID | 연결 정산 항목 | FK, Not Null |
| `media_id` | 미디어 ID | UUID | 영수증 이미지 media | FK, Nullable |
| `uploaded_by_user_id` | 업로드 사용자 ID | UUID | 증빙 업로드 사용자 | FK, Not Null |
| `ocr_status` | OCR 상태 | Varchar(20) | `pending`, `completed`, `failed`, `skipped` | Not Null |
| `ocr_result` | OCR 결과 | JSONB | 금액/날짜/상호명 추출 결과 | Not Null |
| `verification_status` | 검증 상태 | Varchar(20) | `unverified`, `matched`, `mismatch`, `manual_confirmed` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 업로드 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 상태 수정 시각 | Not Null |

## `settlement_confirmations` (목표 설계)

> 사용자별 정산 확인, 이의 제기, 송금 완료 표시를 관리한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 정산 확인 ID | UUID | confirmation row 식별자 | PK |
| `settlement_id` | 정산 ID | UUID | 연결 정산 | FK, Not Null |
| `user_id` | 사용자 ID | UUID | 확인 대상 사용자 | FK, Not Null |
| `confirmation_type` | 확인 유형 | Varchar(30) | `viewed`, `agreed`, `paid`, `disputed` | Not Null |
| `comment` | 코멘트 | Text | 이의 제기/확인 메모 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 확인 이벤트 시각 | Not Null |

> UNIQUE 후보: `(settlement_id, user_id, confirmation_type)`

---

# 8. Record / Media / OOTD

## `records` (구현됨, 확장 필요)

> 약속/모임 기록의 원장이다. 하루 기록, OOTD, 사진 메모를 통합한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 기록 ID | UUID | 내부 기록 식별자 | PK |
| `public_id` | 공개 기록 ID | Text | API/URL용 안정 ID | 다음 구현 |
| `group_id` | 모임 ID | UUID | 모임 기록인 경우 연결 | FK, Nullable |
| `plan_id` | 약속 ID | UUID | 약속 기록인 경우 연결 | FK, Nullable |
| `author_user_id` | 작성자 ID | UUID | 기록 작성 사용자 | FK |
| `record_type` | 기록 유형 | Varchar(30) | `daily`, `ootd`, `photo`, `memo` | 목표 설계 |
| `title` | 기록 제목 | Text | 기록 카드 제목 | Not Null |
| `body` | 기록 본문 | Text | 사용자가 작성한 메모/일기 | 목표 설계 |
| `visibility` | 공개 범위 | Varchar(30) | `private`, `participants`, `group` | Not Null |
| `recorded_at` | 기록 기준 시각 | Timestamptz | 실제 기록 날짜/시간 | 목표 설계 |
| `payload` | 보조 payload | JSONB | OOTD/감정/날씨/태그/캐릭터 snapshot | Not Null |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | row 수정 시각 | 목표 설계 |
| `deleted_at` | 삭제 시각 | Timestamptz | 기록 삭제 시각 | Nullable |

OOTD 기록의 캐릭터 변경분은 `character_profiles`를 직접 덮어쓰지 않고, 해당 카드 생성 시점의 최종 결과만 `records.payload.characterSnapshot`에 남긴다.

```json
{
  "body": "스포티한 바람막이와 반바지",
  "recordType": "OOTD",
  "recordedAt": "2026-06-10T11:45:00Z",
  "characterSnapshot": {
    "gender": "female",
    "skin_tone": "type_warm",
    "eye_style": "round",
    "hair_style": "short_curly",
    "hair_color": "ash_brown",
    "eye_color": "hazel",
    "clothes": "none"
  }
}
```

## `record_media` (다음 구현)

> 기록에 첨부된 사진/이미지/공유 카드 원본이다. 실제 파일은 Blob/MinIO에 둔다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 미디어 ID | UUID | media row 식별자 | PK |
| `record_id` | 기록 ID | UUID | 연결 기록 | FK, Not Null |
| `media_type` | 미디어 유형 | Varchar(30) | `image`, `video`, `share_card`, `thumbnail` | Not Null |
| `storage_provider` | 저장소 제공자 | Varchar(30) | `minio`, `azure_blob` | Not Null |
| `bucket` | 버킷/컨테이너 | Text | 저장 위치 bucket/container | Not Null |
| `object_key` | Object key | Text | 파일 object key | Not Null |
| `public_url` | 접근 URL | Text | CDN 또는 signed URL. 공개 링크 의미로 사용하지 않음 | Nullable |
| `content_type` | MIME type | Text | `image/jpeg` 등 | Nullable |
| `size_bytes` | 파일 크기 | Bigint | 파일 크기 | Nullable |
| `width` | 이미지 너비 | Integer | 이미지 pixel width | Nullable |
| `height` | 이미지 높이 | Integer | 이미지 pixel height | Nullable |
| `metadata` | 미디어 메타데이터 | JSONB | EXIF 제거 후 필요한 최소 정보 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |

## `record_tags` (목표 설계)

> 기록 검색, 회고, analytics taxonomy 연결을 위한 tag 테이블이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 기록 태그 ID | UUID | row 식별자 | PK |
| `record_id` | 기록 ID | UUID | 연결 기록 | FK, Not Null |
| `tag` | 태그 | Text | `카페투어`, `데이트룩`, `여행` 등 | Not Null |
| `tag_type` | 태그 유형 | Varchar(30) | `user`, `ai`, `system`, `ootd` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 태그 생성 시각 | Not Null |

## `ootd_features` (목표 설계)

> OOTD 기록에서 추출한 스타일 feature다. 개인 기록과 AI worker 결과를 연결한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | OOTD feature ID | UUID | row 식별자 | PK |
| `record_id` | 기록 ID | UUID | OOTD 기록 연결 | FK, Not Null |
| `weather` | 날씨 | Varchar(30) | `sunny`, `cloudy`, `rainy` 등 | Nullable |
| `mood` | 감정 | Varchar(30) | `happy`, `calm`, `excited` 등 | Nullable |
| `style_tags` | 스타일 태그 | JSONB | AI/사용자 스타일 태그 배열 | Not Null |
| `brand_tags` | 브랜드/의류 태그 | JSONB | 상의/하의/신발 등 구조화 태그 | Not Null |
| `color_palette` | 색상 팔레트 | JSONB | 대표 색상 feature | Nullable |
| `ai_job_run_id` | AI job ID | UUID | feature extraction job 연결 | worker_ai 참조값 |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |

## `share_cards` (목표 설계)

> 외부 공유용 이미지 카드 결과다. 기록 공개 범위와 분리된 export 산출물이며, 초기 구현은 이미지 저장/공유를 기준으로 한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 공유 카드 ID | UUID | row 식별자 | PK |
| `record_id` | 기록 ID | UUID | 연결 기록 | FK, Nullable |
| `plan_id` | 약속 ID | UUID | 약속 공유 카드 연결 | FK, Nullable |
| `settlement_id` | 정산 ID | UUID | 정산 공유 카드 연결 | FK, Nullable |
| `card_type` | 카드 유형 | Varchar(30) | `record`, `ootd`, `settlement`, `invite` | Not Null |
| `image_media_id` | 이미지 미디어 ID | UUID | 생성된 카드 이미지 | FK, Nullable |
| `share_url` | 공유 URL | Text | 미래 링크 공유 확장용 URL. 초기 구현에서는 사용하지 않음 | Nullable |
| `status` | 생성 상태 | Varchar(20) | `pending`, `ready`, `failed`, `expired` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 카드 생성 시각 | Not Null |
| `expires_at` | 만료 시각 | Timestamptz | 공유 링크 만료 시각 | Nullable |

## `record_comments` (목표 설계)

> 기록 상세 화면의 댓글이다. 기록 공개 범위와 댓글 작성 권한을 함께 검증한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 댓글 ID | UUID | comment row 식별자 | PK |
| `record_id` | 기록 ID | UUID | 댓글 대상 기록 | FK, Not Null |
| `author_user_id` | 작성자 ID | UUID | 댓글 작성자 | FK, Not Null |
| `parent_comment_id` | 상위 댓글 ID | UUID | 대댓글인 경우 연결 | FK, Nullable |
| `body` | 댓글 본문 | Text | 댓글 내용 | Not Null |
| `status` | 댓글 상태 | Varchar(20) | `active`, `deleted`, `hidden` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 댓글 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 댓글 수정 시각 | Nullable |
| `deleted_at` | 삭제 시각 | Timestamptz | 댓글 삭제 시각 | Nullable |

## `record_reactions` (목표 설계)

> 기록 카드의 좋아요/공감 반응이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 기록 반응 ID | UUID | reaction row 식별자 | PK |
| `record_id` | 기록 ID | UUID | 반응 대상 기록 | FK, Not Null |
| `user_id` | 사용자 ID | UUID | 반응 사용자 | FK, Not Null |
| `reaction_type` | 반응 유형 | Varchar(20) | `like`, `heart`, `smile` 등 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 반응 생성 시각 | Not Null |

> UNIQUE: `(record_id, user_id, reaction_type)`

## `media_processing_jobs` (목표 설계)

> 이미지 썸네일 생성, EXIF 제거, 안전성 검사, 공유 카드 렌더링 같은 미디어 후처리를 추적한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 미디어 처리 job ID | UUID | job row 식별자 | PK |
| `media_id` | 미디어 ID | UUID | 처리 대상 media | FK, Not Null |
| `job_type` | Job 유형 | Varchar(40) | `thumbnail`, `exif_strip`, `moderation`, `share_card` | Not Null |
| `status` | Job 상태 | Varchar(20) | `pending`, `processing`, `completed`, `failed`, `skipped` | Not Null |
| `result_media_id` | 결과 미디어 ID | UUID | 생성된 thumbnail/card media | FK, Nullable |
| `metadata` | 처리 메타데이터 | JSONB | 처리 결과, 오류, 크기 정보 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | job 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | job 수정 시각 | Not Null |

---


## 하루 일과 다이어리 payload 계약 메모

하루 일과 기록 기능은 새 테이블을 추가하지 않고 기존 `records`, `record_media`, `record_tags`를 사용한다. 사진 원본 URL은 `record_media.public_url`에 저장하고, 사진별 코멘트/다이어리 구성 정보는 `records.payload` JSON에 보존한다.

기록 삭제는 물리 삭제가 아니라 `records.deleted_at`을 채우는 soft delete로 처리한다. 목록/상세 조회는 `deleted_at IS NULL` 조건을 기준으로 한다.

`record_media.public_url`은 API 서버 기준 상대 URL일 수 있으므로, Flutter Web에서는 표시 직전에 API base URL을 붙여 absolute URL로 사용한다.

`records.payload`의 DAILY 기록 확장 필드는 다음과 같다.

| JSON key | 설명 |
| --- | --- |
| `recordType` | `DAILY` 또는 `OOTD` |
| `body` | 하루 전체 메모 |
| `mood` | 사용자가 선택한 기분 라벨 |
| `weather` | 사용자가 선택한 날씨 라벨 |
| `brands.recordType` | Flutter 화면 분기용 `daily`/`ootd` |
| `brands.theme` | 다이어리 결과 테마, 예: `diary`, `clean` |
| `brands.crew` | OOTD/크루 포함 여부, 예: `included`, `userOnly` |
| `timeline[]` | 결과 화면 재구성용 사진/메모 순서 |
| `timeline[].imageUrl` | 해당 사진 카드에 표시할 `record_media.public_url` |

OOTD 기록이 없는 하루 일과는 크루 단계와 결과 화면의 캐릭터/WITH 블록을 건너뛴다. OOTD가 있는 경우에만 다이어리 중간 캐릭터 블록 및 하단 WITH/MOOD/WEATHER 캐릭터 영역을 표시한다.

# 9. Activity / Notification

## `chat_activity_events` (구현됨, 확장 필요)

> 온모임 채팅 화면의 메시지, 시스템 카드, 투표 카드, 정산 카드, 약속 변경 알림을 하나의 activity stream으로 관리한다.
> 현재 Spring 구현은 `event_type`과 `payload`를 기준으로 메시지와 카드 snapshot을 저장한다. `activity_type`, `body`, `target_type`, `target_id`, `deleted_at` 같은 분리 컬럼은 목표 설계 후보이며 아직 물리 schema에는 없다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Activity ID | UUID | activity row 식별자 | PK |
| `group_id` | 모임 ID | UUID | activity가 속한 모임 | FK, Nullable, 구현상 메시지는 모임 기준으로 사용 |
| `plan_id` | 약속 ID | UUID | 약속 관련 activity 연결 | FK, Nullable |
| `actor_user_id` | 행위자 ID | UUID | 메시지/행동을 만든 사용자 | FK, Nullable |
| `event_type` | 이벤트 유형 | Varchar(60) | `chat.message`, `system.message`, `vote.created`, `settlement.created` 등 | Not Null |
| `payload` | 표시 payload | JSONB | 메시지 본문, sender snapshot, attachment metadata, 카드 표시용 snapshot | Not Null, Default `{}` |
| `created_at` | 생성 시각 | Timestamptz | activity 생성 시각 | Not Null |

현재 `chat.message` payload는 `senderName`, `message`, `attachments`, `messageType`, `source`를 포함할 수 있다. 이미지 첨부는 media upload 이후 `type=image`, `storageKey`, `publicUrl`, `contentType`, `fileName`, `width`, `height` metadata로 연결한다. `chat_activity_events`는 채팅 화면의 시간축 원장이며, 약속/투표/정산 같은 도메인의 최종 source of truth는 각 도메인 테이블에 둔다.

## `chat_read_states` (구현됨)

> 사용자별 모임 채팅 읽음 상태 projection이다. unread count 계산은 마지막 읽은 activity 시각 이후의 다른 사용자 메시지를 기준으로 한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 읽음 상태 ID | UUID | read state row 식별자 | PK |
| `group_id` | 모임 ID | UUID | 읽음 상태가 속한 모임 | FK -> `groups.id`, Not Null, On Delete Cascade |
| `user_id` | 사용자 ID | UUID | 읽음 상태 소유 사용자 | FK -> `users.id`, Not Null, On Delete Cascade |
| `last_read_event_id` | 마지막 읽은 Activity ID | UUID | 마지막으로 읽은 `chat_activity_events.id` | FK -> `chat_activity_events.id`, Nullable, On Delete Set Null |
| `last_read_at` | 마지막 읽은 Activity 시각 | Timestamptz | unread count 기준 시각. event가 없으면 mark-read 시각 | Not Null |
| `updated_at` | 갱신 시각 | Timestamptz | read state row 갱신 시각 | Not Null |

> UNIQUE: `(group_id, user_id)`
> INDEX: `(user_id, group_id)`

읽음 상태는 메시지별 상세 읽음 표시가 아니라 모임/사용자별 last read cursor를 관리한다. 메시지별 읽은 사람 목록 UI가 필요해지면 별도 projection 또는 event 기반 집계를 추가한다.

## `notifications` (구현됨, 확장 필요)

> 사용자별 알림 inbox다. push notification은 후속 side effect로 분리한다.
> 현재 Spring API와 Flutter 알림 화면이 사용하는 source of truth다. 실제 FCM/APNs provider delivery 성공 여부와 무관하게 사용자가 앱 안에서 보는 알림 원장으로 유지한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 알림 ID | UUID | 알림 row 식별자 | PK |
| `user_id` | 수신자 ID | UUID | 알림을 받는 사용자 | FK, Not Null |
| `group_id` | 모임 ID | UUID | 관련 모임 | FK, Nullable |
| `plan_id` | 약속 ID | UUID | 관련 약속 | FK, Nullable |
| `notification_type` | 알림 유형 | Varchar(60) | `chat_message`, `plan`, `vote`, `settlement`, `record`, `friend` 등 | Not Null |
| `title` | 알림 제목 | Text | 알림 카드 제목 | Not Null |
| `body` | 알림 본문 | Text | 알림 카드 본문 | Nullable |
| `payload` | 이동/표시 payload | JSONB | groupId, messageId, senderUserId, chatActivityEventId 같은 최소 metadata | Not Null, Default `{}` |
| `status` | 알림 상태 | Varchar(30) | `queued`, `read` 등 | Not Null, Default `queued` |
| `read_at` | 읽은 시각 | Timestamptz | 사용자가 읽은 시각 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 알림 생성 시각 | Not Null |

채팅 메시지 작성 시 작성자를 제외한 active/joined 모임 멤버와 owner를 대상으로 `chat_message` notification을 생성할 수 있다. 실제 FCM/APNs 발송은 아직 켜지지 않았고, `notification.requested` outbox와 dev-safe delivery abstraction으로 분리한다.
Provider delivery로 이어질 `notification.requested` outbox payload는 `notificationId`를 포함해야 한다. 또는 `aggregate_type=notification`, `aggregate_id=<notifications.id>` 조합으로 원본 notification을 찾을 수 있어야 한다. `settlement` 같은 도메인 aggregate만 담긴 알림 요청은 현재 delivery service에서 원본 notification을 찾지 못해 dev-safe skip 처리될 수 있으므로, 실제 provider delivery 전 payload 규칙을 통일한다.

## `notification_deliveries` (구현됨, 확장 필요)

> 알림 발송 시도와 결과를 저장한다. 현재 dev slice는 실제 FCM/APNs 발송 없이 `provider=dev`, `status=skipped_dev`로 추적 row를 남긴다.
> 이 table은 provider 발송 projection이며 inbox 원장이 아니다. `provider=dev`, `status=skipped_dev`는 발송 성공이 아니라 provider delivery 비활성 상태를 추적하는 dev-safe 결과다. 실제 provider delivery 대상 `notification.requested` 이벤트는 `notificationId`로 `notifications.id`에 연결되어야 하며, dev-safe row를 실제 FCM/APNs 발송 성공으로 해석하지 않는다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 발송 ID | UUID | 발송 row 식별자 | PK |
| `notification_id` | 알림 ID | UUID | 원본 알림 | FK, Not Null |
| `channel` | 발송 채널 | Varchar(30) | `push`, `email`, `kakao`, `sms` | Not Null |
| `provider` | 제공자 | Varchar(30) | `dev`, FCM, APNs 등 | Nullable |
| `status` | 발송 상태 | Varchar(20) | `pending`, `sent`, `failed`, `skipped_dev` | Not Null |
| `provider_message_id` | Provider 메시지 ID | Text | 외부 발송 ID | Nullable |
| `error_message` | 오류 메시지 | Text | 실패/skip 이유 | Nullable |
| `attempted_at` | 시도 시각 | Timestamptz | 발송 시도 시각 | Not Null |
| `delivered_at` | 발송 시각 | Timestamptz | 발송 성공 시각 | Nullable |

## `push_tokens` (미래 분리 후보)

> 현재 push token readiness는 `user_devices`에 구현한다. 별도 token lifecycle, 암호화 저장, provider별 무효화 callback이 필요해지면 이 테이블로 분리할 수 있다. token 원문은 필요 최소 범위에서만 저장하고 로그에는 남기지 않는다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Push token ID | UUID | push token row 식별자 | PK |
| `user_id` | 사용자 ID | UUID | token 소유 사용자 | FK, Not Null |
| `device_id` | 기기 ID | UUID | 연결 기기 | FK, Nullable |
| `provider` | Push 제공자 | Varchar(20) | `fcm`, `apns` | Not Null |
| `token_hash` | Token 해시 | Text | token 중복/폐기 판단용 해시 | Unique 후보 |
| `token_ciphertext` | Token 암호문 | Text | 발송에 필요한 token 암호화 값 | Not Null |
| `status` | Token 상태 | Varchar(20) | `active`, `invalid`, `revoked` | Not Null |
| `last_used_at` | 마지막 사용 시각 | Timestamptz | 마지막 발송 시각 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | token 등록 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 상태 수정 시각 | Not Null |

## `notification_preferences` (구현됨, 확장 필요)

> 사용자별 알림 수신 설정이다.
> 현재 Spring service는 기본 type `chat_message`, `plan_reminder`, `vote_created`, `settlement_requested`, `record_created`와 channel `in_app`, `push`를 allowlist로 사용한다. email, kakao, sms, marketing channel은 target 확장이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 알림 설정 ID | UUID | preference row 식별자 | PK |
| `user_id` | 사용자 ID | UUID | 설정 사용자 | FK, Not Null |
| `notification_type` | 알림 유형 | Varchar(60) | `chat_message`, `plan`, `vote`, `settlement`, `record`, `friend`, `marketing` | Not Null |
| `channel` | 채널 | Varchar(30) | `in_app`, `push`, `email`, `kakao` | Not Null |
| `enabled` | 수신 여부 | Boolean | 해당 알림 수신 여부 | Not Null |
| `quiet_hours` | 방해금지 시간 | JSONB | 시작/종료 시간, 요일 | Nullable |
| `updated_at` | 수정 시각 | Timestamptz | 설정 수정 시각 | Not Null |

> UNIQUE: `(user_id, notification_type, channel)`

---

# 10. Consent / Privacy

## `consent_privacy_settings` (구현됨, 확장 필요)

> 사용자별 개인정보, analytics 활용, 공개 범위 기본값의 현재 상태를 관리한다. 변경 이력은 append-only `user_consents`에 남긴다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 설정 ID | UUID | privacy setting row 식별자 | PK |
| `user_id` | 사용자 ID | UUID | 설정 대상 사용자 | FK, Not Null |
| `analytics_opt_in` | Analytics 동의 여부 | Boolean | 비식별 분석/리포팅 활용 동의 | Not Null |
| `contact_sync_opt_in` | 연락처 동기화 동의 여부 | Boolean | 연락처 접근/매칭 동의 | 다음 구현 |
| `marketing_opt_in` | 마케팅 수신 동의 | Boolean | 마케팅/광고 알림 동의 | 목표 설계 |
| `default_record_visibility` | 기본 기록 공개 범위 | Varchar(30) | `private`, `participants`, `group` | 목표 설계 |
| `payload` | 추가 설정 payload | JSONB | 설정 확장을 위한 payload | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 설정 수정 시각 | Not Null |

## `privacy_policy_snapshots` (목표 설계)

> 동의가 어떤 약관/정책 버전에 대해 이루어졌는지 남긴다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 정책 snapshot ID | UUID | 정책 버전 row 식별자 | PK |
| `policy_type` | 정책 유형 | Varchar(40) | `terms`, `privacy`, `analytics`, `contact_sync` | Not Null |
| `version` | 정책 버전 | Varchar(30) | `2026-06-08` 등 | Not Null |
| `title` | 정책 제목 | Text | 사용자에게 보인 제목 | Not Null |
| `body_hash` | 본문 해시 | Text | 정책 본문 checksum | Not Null |
| `effective_at` | 적용 시작 시각 | Timestamptz | 정책 적용 시각 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | row 생성 시각 | Not Null |

## `user_consents` (목표 설계)

> 사용자별 동의 이력을 append-only로 관리한다. Analytics/reporting layer로 넘길 수 있는 동의/철회 이벤트의 core 원장이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 사용자 동의 ID | UUID | 동의 row 식별자 | PK |
| `user_id` | 사용자 ID | UUID | 동의 사용자 | FK, Not Null |
| `policy_snapshot_id` | 정책 snapshot ID | UUID | 동의한 정책 버전 | FK, Not Null |
| `consent_status` | 동의 상태 | Varchar(20) | `granted`, `withdrawn` | Not Null |
| `source` | 동의 경로 | Varchar(30) | `signup`, `settings`, `contact_sync` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 동의/철회 시각 | Not Null |

> 회의 결정: core 구현 단계에서 현재 동의 상태와 동의 변경 이력까지 설계한다. 다만 `analytics_subjects`, Bronze/Silver/Gold 적재 같은 reporting layer 전파 구현은 next-step 데이터사전 범위로 분리한다.

## `data_subject_requests` (목표 설계)

> 사용자 데이터 열람, 내보내기, 삭제, 동의 철회 요청을 추적한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 정보주체 요청 ID | UUID | request row 식별자 | PK |
| `user_id` | 사용자 ID | UUID | 요청 사용자 | FK, Not Null |
| `request_type` | 요청 유형 | Varchar(30) | `export`, `delete`, `withdraw_consent`, `rectify` | Not Null |
| `status` | 요청 상태 | Varchar(30) | `received`, `processing`, `completed`, `rejected`, `canceled` | Not Null |
| `requested_payload` | 요청 payload | JSONB | 사용자가 요청한 범위 | Not Null |
| `result_payload` | 결과 payload | JSONB | 완료 결과/내보내기 파일 참조 | Nullable |
| `requested_at` | 요청 시각 | Timestamptz | 요청 접수 시각 | Not Null |
| `completed_at` | 완료 시각 | Timestamptz | 요청 완료 시각 | Nullable |
| `expires_at` | 결과 만료 시각 | Timestamptz | export 파일 만료 시각 | Nullable |

## `data_retention_policies` (목표 설계)

> 테이블/도메인별 보존 기간과 삭제 방식을 운영 기준으로 관리한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 보존 정책 ID | UUID | policy row 식별자 | PK |
| `domain` | 도메인 | Varchar(40) | `auth`, `record`, `media`, `analytics`, `audit` | Not Null |
| `table_name` | 테이블명 | Text | 적용 대상 table | Not Null |
| `retention_days` | 보존 일수 | Integer | 보존 기간 | Not Null |
| `deletion_mode` | 삭제 방식 | Varchar(30) | `soft_delete`, `hard_delete`, `anonymize`, `archive` | Not Null |
| `legal_hold_supported` | 법적 보존 지원 여부 | Boolean | legal hold 가능 여부 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 정책 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 정책 수정 시각 | Not Null |

---

# 11. Outbox / Worker

## `outbox_events` (구현됨)

> Spring Boot domain transaction과 함께 기록되는 이벤트 원장이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Outbox event ID | UUID | 이벤트 row 식별자 | PK |
| `event_type` | 이벤트 유형 | Text | `plan.created`, `vote.created` 등 | Not Null |
| `aggregate_type` | Aggregate 유형 | Text | `PLAN`, `VOTE`, `SETTLEMENT` 등 | Not Null |
| `aggregate_id` | Aggregate ID | UUID | 대상 aggregate 내부 ID | Nullable |
| `payload` | 이벤트 payload | JSONB | worker/notification용 최소 metadata | Not Null |
| `status` | 이벤트 상태 | Text | `pending`, `published`, `processing`, `completed`, `failed`, `no_consumer`, `skipped_dev` | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 이벤트 생성 시각 | Not Null |
| `published_at` | 발행 시각 | Timestamptz | queue로 넘긴 시각 | Nullable |
| `locked_at` | lock 시각 | Timestamptz | worker/publisher가 잡은 시각 | Nullable |
| `retry_count` | 재시도 횟수 | Integer | 실패 후 재시도 횟수 | Not Null |
| `last_error` | 마지막 오류 | Text | 마지막 처리 오류 메시지 | Nullable |

## `worker_ai.ai_job_runs` (구현됨)

> AI/Data worker 작업 실행 단위다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | AI job run ID | UUID | worker job 식별자 | PK |
| `outbox_event_id` | Outbox event ID | UUID | 원본 outbox 이벤트 ID | Nullable |
| `job_type` | Job 유형 | Text | `place_explanation`, `record_summary`, `ootd_feature` 등 | Not Null |
| `status` | Job 상태 | Text | `pending`, `processing`, `completed`, `failed`, `skipped` | Not Null |
| `input_metadata` | 입력 메타데이터 | JSONB | core table ID, prompt input 요약 | Not Null |
| `result_metadata` | 결과 메타데이터 | JSONB | 생성 결과, fallback 여부, 비용 요약 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | job 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | job 상태 수정 시각 | Not Null |

> 회의 결정: FastAPI AI Worker는 Spring core domain table을 직접 수정하지 않는다. Worker는 `input_metadata`, `result_metadata`, job 상태를 남기고, Spring API가 필요한 경우 core read model과 worker metadata를 조합한다.

## `worker_ai.prompt_runs` (구현됨)

> AI 모델 prompt 실행 기록이다. prompt 원문과 민감 데이터 저장은 최소화한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Prompt run ID | UUID | prompt 실행 row 식별자 | PK |
| `ai_job_run_id` | AI job run ID | UUID | 연결 job | FK 후보 |
| `prompt_kind` | Prompt 유형 | Text | `place_reason`, `ootd_summary`, `record_caption` | Not Null |
| `model_name` | 모델명 | Text | 사용한 모델 alias | Nullable |
| `status` | 실행 상태 | Text | `pending`, `completed`, `failed`, `fallback` | Not Null |
| `metadata` | 실행 메타데이터 | JSONB | token, latency, redaction 상태 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 실행 시각 | Not Null |

## `worker_ai.feature_extraction_jobs` (구현됨)

> OOTD/persona/place feature 추출 작업 기록이다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Feature job ID | UUID | feature job 식별자 | PK |
| `subject_ref` | 대상 참조 | Text | `record:<id>`, `place_candidate:<id>` 형식 | Not Null |
| `feature_kind` | Feature 유형 | Text | `ootd_style`, `place_preference`, `persona_seed` | Not Null |
| `status` | Job 상태 | Text | `pending`, `completed`, `failed` | Not Null |
| `metadata` | Feature metadata | JSONB | 추출 결과/버전/품질 메타데이터 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | job 생성 시각 | Not Null |

## `outbox_publish_attempts` (목표 설계)

> outbox event를 queue/bus로 넘기려는 시도와 실패를 이력으로 남긴다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 발행 시도 ID | UUID | attempt row 식별자 | PK |
| `outbox_event_id` | Outbox event ID | UUID | 원본 이벤트 | FK, Not Null |
| `publisher_instance_id` | Publisher instance ID | Text | 발행 프로세스 식별자 | Nullable |
| `attempt_number` | 시도 번호 | Integer | 몇 번째 발행 시도인지 | Not Null |
| `status` | 시도 상태 | Varchar(20) | `success`, `failed`, `skipped` | Not Null |
| `error_code` | 오류 코드 | Text | 실패 코드 | Nullable |
| `error_message` | 오류 메시지 | Text | 민감값 제거 후 오류 요약 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 시도 시각 | Not Null |

## `worker_dead_letters` (목표 설계)

> 재시도 한도를 넘은 worker job 또는 복구가 필요한 이벤트를 관리한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Dead letter ID | UUID | dead letter row 식별자 | PK |
| `outbox_event_id` | Outbox event ID | UUID | 원본 outbox event | FK, Nullable |
| `ai_job_run_id` | AI job run ID | UUID | 원본 worker job | FK, Nullable |
| `dead_letter_type` | Dead letter 유형 | Varchar(40) | `publish_failed`, `worker_failed`, `invalid_payload` | Not Null |
| `status` | 처리 상태 | Varchar(20) | `open`, `replayed`, `ignored`, `resolved` | Not Null |
| `payload_snapshot` | Payload snapshot | JSONB | 민감값 제거 후 실패 payload | Not Null |
| `last_error` | 마지막 오류 | Text | 실패 원인 요약 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | dead letter 생성 시각 | Not Null |
| `resolved_at` | 해결 시각 | Timestamptz | 재처리/무시 완료 시각 | Nullable |

---

# 12. Production Operations / Governance

## `idempotency_keys` (목표 설계)

> 모바일 재시도, 네트워크 불안정, 중복 제출로 인한 중복 생성/정산/투표를 방지한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 멱등성 ID | UUID | row 식별자 | PK |
| `user_id` | 사용자 ID | UUID | 요청 사용자 | FK, Nullable |
| `idempotency_key` | 멱등성 key | Text | client가 보낸 idempotency key | Not Null |
| `request_method` | HTTP method | Varchar(10) | POST, PATCH 등 | Not Null |
| `request_path` | 요청 path | Text | API path | Not Null |
| `request_hash` | 요청 hash | Text | body/header 주요값 hash | Not Null |
| `response_status` | 응답 status | Integer | 최초 처리 응답 status | Nullable |
| `response_body_hash` | 응답 body hash | Text | 재응답 검증용 hash | Nullable |
| `locked_at` | lock 시각 | Timestamptz | 처리 중 lock 시각 | Nullable |
| `expires_at` | 만료 시각 | Timestamptz | key 보존 만료 시각 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 최초 요청 시각 | Not Null |

> UNIQUE: `(user_id, idempotency_key)` 또는 `(idempotency_key)`
> 적용 대상: group/plan/vote/settlement/record 생성, media upload confirm, invite accept.

## `api_access_logs` (목표 설계)

> Node stub의 `logs/api-access.log` parity를 Spring runtime에서 맞추기 위한 요청 추적 테이블 또는 로그 스키마다. 고속 path에서는 DB 직접 기록보다 Application Insights/Log Analytics sink를 우선한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | API 로그 ID | UUID | 요청 로그 식별자 | PK |
| `request_id` | 요청 ID | Text | trace/correlation id | Not Null |
| `dev_client` | Dev client | Text | `client=` 또는 `x-onmu-dev-client` 값 | Nullable |
| `user_id` | 사용자 ID | UUID | 인증된 사용자 | FK, Nullable |
| `method` | HTTP method | Varchar(10) | GET, POST 등 | Not Null |
| `path` | 요청 path | Text | query 중 민감값 제외 | Not Null |
| `status_code` | 응답 status | Integer | HTTP status code | Not Null |
| `latency_ms` | 지연 시간 | Integer | 처리 시간 | Not Null |
| `ip_hash` | IP 해시 | Text | 원문 IP 대신 hash | Nullable |
| `user_agent` | User-Agent | Text | client 정보 | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 요청 완료 시각 | Not Null |

> 파티셔닝 후보: 월별 range partition.
> 보존 정책: dev/staging은 짧게, production은 운영/보안 기준에 맞춰 별도 정의.

## Observability 저장소 경계 (목표 설계)

> Spring Boot 운영 모니터링은 앱 도메인 DB에 테이블을 추가하는 방식이 아니라, Actuator/Micrometer 메트릭을 Prometheus가 수집하고 Grafana가 시각화하는 방식으로 검토한다.

| 항목 | 기준 |
| --- | --- |
| Spring 노출 | `/actuator/prometheus` 같은 Actuator endpoint를 통해 Micrometer/Prometheus format 메트릭 노출 |
| 수집 | Prometheus scrape job이 Spring runtime을 주기적으로 수집 |
| 시각화 | Grafana가 Prometheus datasource를 사용해 CPU, JVM, HTTP latency, error rate, readiness 상태를 dashboard화 |
| DB 경계 | Prometheus time-series data는 PostgreSQL core app schema에 저장하지 않는다. |
| 보안 | actuator endpoint는 public API와 분리하고, dev/prod 노출 범위와 인증을 별도로 통제한다. |
| 데이터사전 영향 | `api_access_logs`, `audit_logs`, `security_events`는 도메인/보안 추적용이고, Prometheus/Grafana는 운영 메트릭용으로 분리한다. |

## `audit_logs` (목표 설계)

> 권한, 개인정보, 정산, 삭제 요청처럼 감사가 필요한 변경을 append-only로 기록한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 감사 로그 ID | UUID | audit row 식별자 | PK |
| `actor_user_id` | 행위자 ID | UUID | 변경을 수행한 사용자 | FK, Nullable |
| `actor_type` | 행위자 유형 | Varchar(30) | `user`, `admin`, `system`, `worker` | Not Null |
| `action` | 행위 | Varchar(80) | `group.member.removed`, `privacy.updated` 등 | Not Null |
| `target_type` | 대상 유형 | Varchar(40) | `USER`, `GROUP`, `PLAN`, `SETTLEMENT` 등 | Not Null |
| `target_id` | 대상 ID | UUID | 대상 리소스 ID | Nullable |
| `before_snapshot` | 변경 전 snapshot | JSONB | 민감값 제거 후 변경 전 값 | Nullable |
| `after_snapshot` | 변경 후 snapshot | JSONB | 민감값 제거 후 변경 후 값 | Nullable |
| `reason` | 사유 | Text | 관리자/시스템 변경 사유 | Nullable |
| `request_id` | 요청 ID | Text | API trace id | Nullable |
| `created_at` | 생성 시각 | Timestamptz | 감사 이벤트 시각 | Not Null |

> 변경 불가능성을 높이기 위해 application에서 update/delete를 금지하고 append-only로 관리한다.

## `security_events` (목표 설계)

> 이상 로그인, rate limit, 차단, token 탈취 의심 등 보안 이벤트를 관리한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | 보안 이벤트 ID | UUID | security event 식별자 | PK |
| `user_id` | 사용자 ID | UUID | 관련 사용자 | FK, Nullable |
| `device_id` | 기기 ID | UUID | 관련 기기 | FK, Nullable |
| `event_type` | 이벤트 유형 | Varchar(60) | `login_failed`, `token_reuse`, `rate_limited`, `blocked_user_code_lookup` | Not Null |
| `severity` | 심각도 | Varchar(20) | `info`, `warning`, `critical` | Not Null |
| `ip_hash` | IP 해시 | Text | 원문 IP 대신 hash | Nullable |
| `metadata` | 메타데이터 | JSONB | 민감값 제거 후 상세 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 이벤트 발생 시각 | Not Null |

## `rate_limit_counters` (목표 설계)

> 사용자 코드 검색, 로그인 시도, 초대 생성, 외부 장소 검색 같은 abuse-sensitive API를 제한한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Rate limit ID | UUID | counter row 식별자 | PK |
| `scope_type` | 범위 유형 | Varchar(30) | `user`, `ip_hash`, `device`, `anonymous` | Not Null |
| `scope_key` | 범위 key | Text | 사용자 ID, IP hash, device ID 등 | Not Null |
| `bucket_key` | Bucket key | Text | `friend_code_lookup`, `oauth_login` 등 | Not Null |
| `window_start_at` | window 시작 시각 | Timestamptz | rate limit window 시작 | Not Null |
| `window_seconds` | window 초 | Integer | window 길이 | Not Null |
| `request_count` | 요청 수 | Integer | window 안의 요청 수 | Not Null |
| `blocked_until` | 차단 종료 시각 | Timestamptz | 초과 시 차단 종료 시각 | Nullable |
| `updated_at` | 수정 시각 | Timestamptz | counter 갱신 시각 | Not Null |

> Redis counter를 우선 사용하되, abuse 분석과 장기 차단은 DB snapshot을 둔다.

## `feature_flags` (목표 설계)

> API mode, Spring runtime 전환, 친구 코드, 연락처 동기화, AI 기능 등 점진적 rollout에 사용한다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Feature flag ID | UUID | flag row 식별자 | PK |
| `flag_key` | Flag key | Text | 기능 플래그 key | Unique, Not Null |
| `description` | 설명 | Text | 플래그 목적 | Nullable |
| `enabled` | 활성 여부 | Boolean | 전체 기본 활성 여부 | Not Null |
| `rollout_rules` | Rollout rule | JSONB | 사용자/환경/비율 rule | Not Null |
| `created_by_user_id` | 생성자 ID | UUID | 플래그 생성자 | FK, Nullable |
| `created_at` | 생성 시각 | Timestamptz | 생성 시각 | Not Null |
| `updated_at` | 수정 시각 | Timestamptz | 수정 시각 | Not Null |

## `admin_actions` (목표 설계)

> 관리자나 운영자가 사용자/모임/기록/정산을 조정한 경우 별도 이력을 남긴다.

| 필드명(물리) | 필드명(논리) | 데이터 타입 | 설명 | 제약사항 |
| --- | --- | --- | --- | --- |
| `id` | Admin action ID | UUID | action row 식별자 | PK |
| `admin_user_id` | 관리자 사용자 ID | UUID | 수행 관리자 | FK, Not Null |
| `action` | 조치 | Varchar(80) | `user.disable`, `record.hide`, `invite.revoke` 등 | Not Null |
| `target_type` | 대상 유형 | Varchar(40) | 조치 대상 리소스 유형 | Not Null |
| `target_id` | 대상 ID | UUID | 조치 대상 리소스 ID | Nullable |
| `reason` | 조치 사유 | Text | 관리자 입력 사유 | Not Null |
| `metadata` | 메타데이터 | JSONB | 민감값 제거 후 상세 | Not Null |
| `created_at` | 생성 시각 | Timestamptz | 조치 시각 | Not Null |

---

# 13. Physical Database Design

## ID 전략

| 항목 | 기준 |
| --- | --- |
| 내부 PK | UUID. PostgreSQL `pgcrypto`의 `gen_random_uuid()` 사용을 기본으로 한다. |
| Public ID | Flutter/URL/API 안정성을 위해 주요 리소스에 `public_id`를 둔다. |
| 외부 Provider ID | `provider`, `provider_*_id` 조합으로 관리하고 내부 PK와 섞지 않는다. |
| 사용자 코드 | 친구 추가용 `user_codes.code`는 public ID가 아니라 검색 가능한 초대 코드다. abuse 방지를 위해 rate limit을 반드시 둔다. |

## 공통 컬럼 규칙

| 컬럼 | 기준 |
| --- | --- |
| `created_at` | 모든 core table에 둔다. |
| `updated_at` | 수정 가능한 entity table에 둔다. |
| `deleted_at` | soft delete가 필요한 사용자-facing table에 둔다. |
| `status` | enum성 문자열을 두되, 초기에는 DB enum보다 varchar + check constraint를 우선한다. |
| `payload` / `metadata` | scaffold와 확장성에 사용하되, 장기적으로 query가 필요한 값은 정규화한다. |

## 인덱스 기준

| 범위 | 필수 인덱스 |
| --- | --- |
| 멤버십 | `group_members(group_id, user_id)`, `plan_participants(plan_id, user_id)` |
| 목록 조회 | `plans(group_id, starts_at)`, `records(user_id, created_at)`, `notifications(user_id, created_at)` |
| 상태 조회 | `outbox_events(status, created_at)`, `ai_job_runs(status, created_at)` |
| 친구 코드 | `user_codes(code)` unique, `friend_requests(target_user_id, status, created_at)` |
| 친구 관계 | `friendships(user_low_id, user_high_id)` unique, `friend_settings(friendship_id, user_id)` unique, `friend_settings(user_id)`, `friend_settings(friend_user_id)` |
| 정산 | `settlement_items(settlement_id)`, `settlement_transfers(settlement_id, from_user_id)` |
| 장소 | `place_candidates(plan_id, created_at)`, `external_places(provider, provider_place_id)`, `external_place_links(external_place_id, status, display_order)`, `external_place_links(link_type, status)`, `external_place_links(provider, source_type)` |

## 파티셔닝 후보

| 테이블 | 기준 |
| --- | --- |
| `api_access_logs` | 월별 range partition |
| `audit_logs` | 월별 range partition |
| `security_events` | 월별 range partition |
| `outbox_events` | 상태/생성일 기준 partition 또는 archive |
| `notifications` | 사용자별 최근 조회 + 오래된 데이터 archive |
| Reporting next-step tables | [ONMU 데이터 리포팅 넥스트스텝 사전](./ONMU%20데이터%20리포팅%20넥스트스텝%20사전.md)에서 별도 관리 |

## 트랜잭션 경계

| 흐름 | 트랜잭션 기준 |
| --- | --- |
| 모임 생성 | `groups`, `group_members`, `chat_activity_events`, `outbox_events`를 같은 transaction에서 처리 |
| 약속 생성 | `plans`, `plan_participants`, `chat_activity_events`, `outbox_events`를 같은 transaction에서 처리 |
| 투표 생성 | `votes`, `vote_options`, `chat_activity_events`, `outbox_events`를 같은 transaction에서 처리 |
| 정산 생성 | `settlements`, `settlement_items`, `settlement_transfers`, `chat_activity_events`, `notifications`, `outbox_events`를 같은 transaction에서 처리 |
| 기록 생성 | `records`, `record_media`, `record_tags`, `outbox_events`를 같은 transaction에서 처리하되 파일 업로드는 confirm 단계로 분리 |

## 보안/개인정보 저장 기준

| 데이터 | 저장 기준 |
| --- | --- |
| Refresh token | 원문 저장 금지. `token_hash`만 저장하고 rotation 이력 관리 |
| Push token | 현재 `user_devices.push_token`은 readiness 단계의 text 저장이다. 실제 provider 발송이 필요하면 암호문 저장 또는 `push_tokens` 분리, 로그 출력 금지 |
| 전화번호 | 원문 저장 금지. 동기화는 정규화 후 hash 중심 |
| 위치 | 장소 좌표는 장소 정보로 관리하되, 사용자 실시간 위치는 별도 동의와 짧은 TTL 기준 |
| Provider profile | 필요한 최소 field만 저장. provider token 원문 저장 금지 |
| AI prompt/input | 민감 원문 최소화, prompt run metadata에는 redaction 상태를 남김 |

## 삭제/탈퇴 기준

| 범위 | 기준 |
| --- | --- |
| 사용자 탈퇴 | `users.status=deleted`, PII 제거, 친구/초대 관계 비활성화 |
| 기록 삭제 | 사용자-facing record/media는 soft delete 후 storage object 삭제 job 수행 |
| 정산 | 법적/분쟁 가능성이 있는 경우 soft delete 대신 접근 제한과 보존 정책을 적용 |
| Analytics next-step | core에서 삭제/철회 이벤트를 발행하고, 별도 reporting layer가 해당 이벤트를 반영 |

## 운영 검증 기준

| 검증 | 기준 |
| --- | --- |
| Migration | Flyway/Alembic이 각 소유 schema만 변경하는지 확인 |
| Seed data | 실제 사용자 데이터 금지, dev seed는 public ID와 synthetic 값만 사용 |
| Secret scan | `.env`, token, provider secret, DB password가 문서/로그/PR에 없는지 확인 |
| Access log parity | Node stub의 `client=` 추적을 Spring runtime에서도 동등하게 확인 |
| Fresh DB smoke | 기존 팀 dev volume 삭제 없이 별도 DB/포트로 smoke |

---

# 14. 공통 Enum

## 사용자/친구

| Enum | 값 |
| --- | --- |
| `user_status` | `active`, `disabled`, `deleted` |
| `auth_provider` | `NAVER`, `KAKAO`, `GOOGLE`, `APPLE` |
| `friend_status` | `active`, `hidden`, `blocked`, `deleted` |
| `friend_request_status` | `pending`, `accepted`, `rejected`, `canceled`, `expired` |
| `invite_channel` | `user_code`, `contact`, `kakao`, `sms`, `link` |

## 모임/약속

| Enum | 값 |
| --- | --- |
| `group_status` | `active`, `archived`, `deleted` |
| `group_member_role` | `owner`, `admin`, `member` |
| `group_member_status` | `active`, `invited`, `left`, `removed` |
| `plan_status` | `draft`, `confirmed`, `completed`, `canceled` |
| `participant_status` | `invited`, `accepted`, `declined`, `tentative`, `removed` |

## 장소/투표/정산

| Enum | 값 |
| --- | --- |
| `place_candidate_status` | `candidate`, `selected`, `archived`, `removed` |
| `external_place_link_type` | `homepage`, `instagram`, `baemin`, `catchtable`, `menu`, `blog`, `naver_place`, `kakao_place`, `reservation`, `other` |
| `external_place_link_source_type` | `provider`, `manual`, `crawler`, `ai_extract` |
| `external_place_link_status` | `active`, `inactive`, `broken`, `hidden` |
| `vote_type` | `PLACE`, `TIME`, `SETTLEMENT`, `GENERAL`, `CHECKLIST` |
| `vote_status` | `open`, `closed`, `canceled` |
| `settlement_status` | `created`, `shared`, `completed`, `canceled` |
| `settlement_split_type` | `equal`, `custom` |

## 기록/알림/Worker

| Enum | 값 |
| --- | --- |
| `record_type` | `daily`, `ootd`, `photo`, `memo` |
| `visibility` | `private`, `participants`, `group` |
| `chat_event_type` | `chat.message`, `system.message`, `plan.created`, `vote.created`, `settlement.created`, `record.created` |
| `notification_type` | `chat_message`, `plan`, `vote`, `settlement`, `record`, `friend` |
| `outbox_status` | `pending`, `published`, `processing`, `completed`, `failed`, `no_consumer`, `skipped_dev` |
| `worker_job_status` | `pending`, `processing`, `completed`, `failed`, `skipped` |

---

# 15. 구현 우선순위

## Sprint 0-1: Spring API 실제 연결 기준

| 우선순위 | 테이블 | 이유 |
| --- | --- | --- |
| 1 | `users`, `auth_identities`, `refresh_tokens`, `user_codes`, `character_profiles` | 로그인, 세션 유지, 친구 코드 기반 추가, 캐릭터 온보딩의 시작점 |
| 2 | `friend_requests`, `friendships`, `friend_settings` | 랜덤 사용자 코드 방식의 첫 친구 추가 구현과 canonical pair 관계 원장 |
| 3 | `groups`, `group_members`, `group_invites` | 온모임 목록/홈/멤버/초대 API 기준 |
| 4 | `plans`, `plan_participants` | 약속 생성/상세/참여자 API 기준 |
| 5 | `place_candidates`, `schedule_places`, `external_places`, `external_place_links` | 후보 추가, 일정 등록, 외부 장소 링크 표시 흐름 |
| 6 | `votes`, `vote_options`, `vote_responses` | 장소/일반 투표 정규화 |
| 7 | `settlement_drafts`, `settlement_items`, `settlement_item_targets`, `settlements`, `settlement_transfers` | 정산 만들기와 결과 공유 |

## Sprint 1-2: 기록/알림/Worker 연결

| 우선순위 | 테이블 | 이유 |
| --- | --- | --- |
| 1 | `records`, `record_media`, `record_tags` | 기록/OOTD 화면의 실제 DB 연결 |
| 2 | `chat_activity_events`, `notifications` | 채팅 카드와 홈 알림을 domain action과 연결 |
| 3 | `outbox_events` 상태 전환, `worker_ai.ai_job_runs` | AI/Data worker job 추적 |
| 4 | `ootd_features`, `share_cards` | OOTD/persona feature와 공유 카드 |

## MVP 이후: 확장

| 범위 | 테이블 |
| --- | --- |
| 연락처 동기화 | `contact_imports`, `user_consents` |
| 카카오/링크 초대 | `external_invites` |
| Push 발송 추적 | `notification_deliveries` |
| 외부 링크 공유 | `share_cards.share_url`, 별도 public link 정책 테이블 |
| 기업용 리포트 | 별도 문서 [ONMU 데이터 리포팅 넥스트스텝 사전](./ONMU%20데이터%20리포팅%20넥스트스텝%20사전.md)에서 관리 |

## 회의 결정 반영 사항

| 주제 | 결정 |
| --- | --- |
| 사용자 코드 | 8-10자리 랜덤 코드로 시작하고 self-service 재발급은 제공하지 않는다. 검색 rate limit은 분당 5회, 일 30회 수준으로 시작한다. |
| 친구 관계 | 양방향 row 대신 canonical pair `friendships`를 사용하고, 사용자별 메모/숨김은 `friend_settings`로 분리한다. |
| 그룹 멤버 | 모임 멤버십은 친구 관계와 독립적으로 허용한다. 초기 초대 생성은 친구 기반으로 제한하고, 링크/카카오 초대는 미래 확장으로 둔다. |
| 기록 공개 범위 | core visibility는 `private`, `participants`, `group`만 둔다. 초기 기본값은 `group`으로 두고, 약속 참여자 제한이 필요한 화면에서 `participants`를 사용한다. |
| 캐릭터 저장 | 기본 캐릭터 원장은 `character_profiles` 1대1 row로 저장하고, OOTD 카드별 변경분은 `records.payload.characterSnapshot`에 스냅샷으로 저장한다. |
| Public share | `public_share`를 core visibility enum에서 제거한다. 외부 공유는 이미지 export/share card로 분리하고, 링크 공유는 별도 미래 확장으로 둔다. |
| Worker 결과 | FastAPI Worker는 core table을 직접 수정하지 않는다. Worker metadata를 남기고 Spring read model/API에서 조합한다. |
| Analytics 동의 | core에는 현재 동의 상태와 append-only 동의 이력을 둔다. reporting layer 전파는 next-step 데이터사전에서 별도 설계/구현한다. |
| Spring 모니터링 | Actuator/Micrometer -> Prometheus -> Grafana 흐름은 운영 메트릭 저장소로 분리하며 core PostgreSQL 도메인 테이블에 넣지 않는다. |
