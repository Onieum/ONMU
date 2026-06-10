# ONMU Record / OOTD / Media / Worker (Spring Boot 구현 문서)

기준 문서: `ONMU 데이터 사전 37a5e2e83ef480e886e3fce07dc20e78.md`  
범위: `/records` 화면, OOTD AI 파이프라인, 미디어 저장(저장/썸네일), 공개 범위/동의 UI 연동

---

## 1) 구현 범위 요약

아래는 담당 범위를 “현재 코드 기준 + 실제 해야 할 일”로 나눈 것입니다.

### 현재 구현된 것 (완전하지 않음)
- `POST /api/v1/groups/{groupId}/plans/{planId}/records`
- `GET /api/v1/users/me/records/recent`
- `GET /api/v1/records/{recordId}`
- `POST /api/v1/media/upload` (실제 업로드가 아니라 랜덤 placeholder URL 반환)
- `POST /api/v1/internal/callbacks/ootd` (코어 테이블 반영)
- outbox 이벤트 생성은 `outbox_events` insert까지만

### 반드시 추가/보완할 것
- 실제 media 업로드 객체 저장소 연동(MinIO/Blob)
- 기록 업로드/상세 화면에 맞춘 read model 정합성
- AI 분석 요청/응답의 안정적인 outbox/job 처리
- worker 실패 fallback(직접 입력 기반) 지원
- 공개 범위/동의값 조회/저장 API
- 동의 미동의에 따른 AI 호출 가드
- 카메라/갤러리 업로드를 record 생성과 연결하는 2단계 업로드 플로우

---

## 2) 구현 전제(데이터사전 + 현재 테이블/도메인 매핑)

### `records`
- 데이터사전 목표: `record_type`, `body`, `recorded_at`, `payload`, `visibility` 등
- 현재 엔티티는 `title`, `summary`, `mood_tags`, `visibility`, `payload` 중심
- 즉시 대응: `record_type`, `body`, `recorded_at`를 추가하여 read/write 모델 분리(요청/응답 분리)

### `record_media`
- 목표 스키마(사전): storage provider / bucket / object_key / content_type / size_bytes
- 현재 스키마(구현): `storage_key`, `public_url`, 폭/높이, 길이, `media_type`, `payload`
- 즉시 대응: 기존 컬럼 유지 + 최소 확장(`storage_provider`, `bucket`, `content_type`, `size_bytes`) 또는 `payload`에 메타 보강

### `character_profiles`
- 기본 캐릭터 원장: 캐릭터 온보딩에서 최초 생성한 `gender`, `skin_tone`, `hair_style`, `hair_color`, `eye_style`, `eye_color`, `clothes`, `skipped`를 사용자 1대1 row로 저장
- `skipped=true` row는 속성 없이 존재할 수 있고, `skipped=false` row는 렌더링에 필요한 기본 속성을 모두 가져야 함
- OOTD 기록 생성 시 바뀐 머리/눈/의상은 기본 캐릭터를 덮어쓰지 않고 `records.payload.characterSnapshot`에 해당 카드의 최종 스냅샷으로 저장
- DB 물리 컬럼과 `records.payload.characterSnapshot` key는 snake_case를 사용하고, Flutter camelCase 모델 이름은 API 계층에서 변환
- 기존 `users.pixel_character`는 현재 `/api/v1/users/me` 응답 호환을 위해 남겨 두고, 신규 캐릭터 원장 API를 붙일 때 정리 전략을 별도 결정

### `ootd_features`
- 현재 `features` json + `feature_source`를 바로 저장하고 있음
- worker 결과 수용에는 적합하나, `ai_job_run_id`/신뢰도/원본 model meta가 없음
- 즉시 대응: `ai_job_run_id`, `model_ref`, `raw_metadata`, `result_version` 보완

### `outbox_events`
- 현재 `status`는 기본 `no_consumer`만 쓰고 있음
- 목표: `pending → published → processing → completed/failed` 상태 전환 + 재시도 로그
- `outbox_publish_attempts`/`worker_dead_letters`를 함께 사용해 실패 추적

### 동의/공개
- `consent_privacy_settings`, `user_consents`는 migration에 반영되어 있으나 Spring 도메인 미구현
- `record` 및 `/api/v1/records/*` 응답에서 `visibility`를 반드시 검증해야 함

---

## 3) API 설계(백엔드 기준)

### A. 기록 목록/상세

#### `GET /api/v1/users/me/records/recent`
- 요청: `?groupId`, `?planId`, `?type(ootd|photo|memo|daily)`, `?visibility`, `?q`, `?cursor`, `?limit`
- 응답:
```json
{
  "records": [
    {
      "id": "rec_xxx",
      "title": "오늘의 옷차림",
      "summary": "간단 메모",
      "body": "본문",
      "visibility": "participants",
      "groupId": "grp_..",
      "planId": "plan_..",
      "recordType": "ootd",
      "recordedAt": "2026-06-09T20:00:00+09:00",
      "tags": ["#캐주얼"],
      "imageUrls": ["https://.../full.jpg"],
      "media": [
        {"id":"m1","mediaType":"image","storageKey":"records/...","publicUrl":"https://...","width":1200,"height":900}
      ]
    }
  ],
  "nextCursor": "..."
}
```

#### `GET /api/v1/records/{recordId}`
- 상세 응답에 분석 결과/태그/미디어/공개범위 정책 정보를 포함

#### `POST /api/v1/groups/{groupId}/plans/{planId}/records`
- 요청:
```json
{
  "title": "...",
  "summary": "...",
  "recordType": "OOTD|PHOTO|MEMO|DAILY",
  "body": "...",
  "visibility": "participants|group|private",
  "media": [{ "mediaId":"...", "storageKey":"...", "sortOrder":0 }],
  "moodTags": ["#캐주얼"],
  "characterSnapshot": {
    "gender": "female",
    "skin_tone": "type_warm",
    "hair_style": "short_curly",
    "hair_color": "ash_brown",
    "eye_style": "round",
    "eye_color": "hazel",
    "clothes": "none"
  }
}
```
- 처리:
  - 트랜잭션 1: record + record_media + record_tags 저장
  - OOTD인 경우: 기본 캐릭터는 `character_profiles`에서 읽고, 카드별 변경분을 합성한 최종 결과를 `records.payload.characterSnapshot`에 저장
  - 트랜잭션 1 마지막: outbox에 `record.created` + `ai.summary.requested`(OOTD인 경우)
  - 기록 생성 즉시 응답/혹은 업로드 미리 완료 플래그 방식 선택

### B. 미디어 (카메라/갤러리)

#### 현재 API 유지
- `POST /api/v1/media/upload`(multipart `file`)
  - 최소 목표: 기존 시그니처 유지

#### 권장 확장(권장)
- `POST /api/v1/media/upload/init`
  - pre-signed URL 방식 도입 시점
- `POST /api/v1/media/upload/complete`
  - 업로드 완료 등록(크기/해시/원본/썸네일 플래그)
- `GET /api/v1/media/{storageKey}/thumbnail`
  - 썸네일 URL/생성 상태 조회

#### 저장소 정책(권장)
- MinIO endpoint: `http://127.0.0.1:9000`
- bucket: `records`
- prefix: `records/{userId}/raw/`, `records/{userId}/thumb/`
- 권한: 업로드 후 presigned URL 또는 서버사이드 업로드 중 하나 고정

### C. OOTD AI / Worker

#### 이벤트 연결
- `record.created`(기록 생성)
- `ai.summary.requested`(record.created와 동일 tx)
- worker는 **`ai_job_runs` / `feature_extraction_jobs`** 추적 저장 후 분석

#### 작업 흐름
1. Spring에서 요청을 `outbox_events.status=pending`으로 insert
2. Worker publisher(또는 Poller)가 이벤트를 `published`로 변경 후 소비 처리
3. FastAPI worker: record 조회 또는 payload 기반으로 이미지 fetch 후 HF inference
4. 성공 시 Spring callback
   - `POST /api/v1/internal/callbacks/ootd`  
5. 실패 시
   - `failed` 기록 + `retry_count` 증가 + dead-letter 등록
   - 클라이언트는 manual input 모드로 전환하여 저장 가능

#### Callback 요청/응답 예시
```json
{
  "recordId": "rec_xxx",
  "source": "huggingface",
  "features": {
    "styles": ["casual", "minimal"],
    "colors": ["black", "white"],
    "brands": ["CROCS"]
  },
  "tags": ["#캐주얼","#뉴트럴"],
  "imageUrl": "https://.../processed.jpg"
}
```

### D. 공개 범위 / 동의
- 새 API 제안
  - `GET /api/v1/me/consent/privacy`
  - `PATCH /api/v1/me/consent/privacy`
  - `GET /api/v1/me/consents/{type}`
  - `POST /api/v1/records/{recordId}/visibility`
- 기본 규칙
  - AI 분석은 `consent_privacy_settings.analytics_opt_in=true` 또는 해당 타입 동의가 있어야 실행
  - 동의 없으면 `analysisStatus=disabled_by_consent`로 저장 후 기록 생성은 진행

---

## 4) 서비스 내부 구현 포인트

### RecordService
- 현재 `currentUser()`를 첫 유저 반환 스텁에서 실제 인증 principal로 교체
- 요청 검증:
  - `recordType` whitelist
  - visibility/visibility-policy 유효성
  - 그룹/약속 권한 검사(작성자 권한)
- Outbox 생성은 한 트랜잭션 안에서 처리하고, 이벤트 payload는 필요한 최소 필드만 포함

### MediaService
- 현재 placeholder URL 반환 제거
- 업로드 서비스:
  1) 파일 검증 (크기/타입)
  2) object key 생성
  3) storage 업로드
  4) media row 생성을 위한 key/public URL/metadata 반환
- 썸네일 정책: OOTD는 기본 썸네일 생성 여부 결정 플래그

### OOTD 분석
- `record.created`에서 바로 `ai.summary.requested` 발행(기록 타입이 `ootd` 또는 `photo`이고 동의 있을 때만)
- callback 처리 시 태그 중복 제거, 최신 분석만 유지

---

## 5) 구현 순서(추천)

1. **데이터 정합화**: `record_type/body/recorded_at`, `media` metadata 필드 보강(최소 1일차)
2. **미디어 저장소 실제 연결**: upload + complete 플로우, media key 추적(2~3일차)
3. **기록 API read model 강화**: 최근/상세에서 tags/media/features/visibility 일관되게 구성(2일차)
4. **outbox 상태/퍼블리셔**: status transition + retry 로그(3일차)
5. **worker + AI 연결**: HF API 호출/재시도/dead-letter(4일차)
6. **fallback**: 분석 실패 시 직접 입력 모드 저장 및 안내(1일차)
7. **동의 API + 공개 범위 검증**: 필수 가드 + UI 바인딩(2일차)

---

## 6) 테스트 기준

- 단위 테스트
  - RecordService: 공개 범위, 생성 검증, outbox payload key 검사
  - MediaService: 업로드 실패/성공 path
  - OOTD callback: 중복 태그/중복 이미지 URL 교체 정책
- 통합 테스트
  - `/api/v1/groups/{groupId}/plans/{planId}/records` + `record.created`/`ai.summary.requested` 이벤트 생성
  - `/api/v1/media/upload` 업로드 후 기록 생성 연결
  - consent=false일 때 AI 분석 미실행 보장
  - `/records/{id}`에서 visibility 미일치 차단

---

## 7) 바로 시작할 수 있는 TODO 체크리스트

- [ ] `media` upload: spring에서 MinIO 업로드 및 `storage_key` 실제값 저장
- [ ] `RecordService`: record 생성시 `record_type/body/recorded_at` 반영 + outbox 이벤트 확장
- [ ] `OutboxService`: 상태 변경 API + publish/claim 시퀀스
- [ ] `ai-data-worker`: `record.created`/`ai.summary.requested` 소비기 구현
- [ ] HuggingFace 클라이언트 + timeout/retry + 실패 처리
- [ ] callback idempotency: 같은 `recordId+imageHash` 중복 처리 방지
- [ ] `consent_privacy_settings` 조회/수정 API
- [ ] `records` 공개 범위 기반 필터 + 공개 share 카드 정책
- [ ] 수동 입력 fallback API (AI 실패시에도 기록은 완성 상태 유지)

---

## 참고

- 이 문서는 `ONMU 데이터 사전 37a5e2e83ef480e886e3fce07dc20e78.md`(데이터사전),  
  `ONMU/services/api-spring/OUTBOX_CONTRACT.md`, `ONMU/services/api-spring/src/main/java` 현구조를 기준으로 작성했습니다.
