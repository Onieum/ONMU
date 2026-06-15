# ONMU Records/Memories/Media/OOTD 아키텍처

## 목적

이 문서는 ONMU의 기록 탭, 하루 일과, OOTD, 미디어 업로드, 기록 상세/수정/삭제 영역의 Current-to-Target Architecture 기준이다. 현재 repo의 Spring Boot Main API, Flutter record repository/UI, Flyway 데이터 사전을 기준으로 현재 구현과 Azure/Terraform 목표 구조를 분리한다.

## 제품 원칙

- 기록의 원장은 `records`이고, 사진/이미지 파일은 DB가 아니라 object storage에 둔다.
- `record_media`는 기록과 storage object의 연결 정보를 보관한다.
- 하루 일과는 `type=DAILY`, OOTD는 `type=OOTD`로 저장한다.
- 다이어리 UI 복원에 필요한 theme, mood, weather, timeline, 사진별 comment는 `records.payload` JSON에 보존한다.
- OOTD 캐릭터 변경분은 기본 캐릭터를 수정하지 않고 `records.payload.characterSnapshot`에 저장한다.
- Flutter 앱은 Spring Boot Main API만 호출한다. Blob/MinIO, FastAPI Worker, DB는 직접 호출하지 않는다.
- 이미지 업로드는 먼저 `POST /api/v1/media/upload`로 storage URL을 만들고, 이후 memory create/update에 URL을 연결한다.

## Current Implementation

### Spring Boot Main API

현재 repo 기준 구현 파일은 다음과 같다.

| 역할 | 파일 |
| --- | --- |
| 기록/메모리 controller | `services/api-spring/src/main/java/com/onmu/api/web/MemoryController.java` |
| legacy/record controller | `services/api-spring/src/main/java/com/onmu/api/web/RecordController.java` |
| 기록 service | `services/api-spring/src/main/java/com/onmu/api/service/RecordService.java` |
| 미디어 controller | `services/api-spring/src/main/java/com/onmu/api/web/MediaController.java` |
| 미디어 service | `services/api-spring/src/main/java/com/onmu/api/service/MediaService.java` |
| entity/repository | `RecordEntity.java`, `RecordRepository.java`, `RecordMediaEntity.java`, `RecordMediaRepository.java`, `RecordTagEntity.java`, `RecordTagRepository.java` |
| DTO | `CreateMemoryRequest.java`, `CreateRecordRequest.java`, `MemoryResponse.java`, `RecordMediaInput.java`, `UploadMediaResponse.java` |
| 테스트 | `RecordServiceTests.java`, `MediaServiceTests.java`, `MediaControllerTests.java` |

현재 route는 다음 계약을 제공한다.

| 기능 | Method / Path | 비고 |
| --- | --- | --- |
| 내 기록 목록 | `GET /api/v1/memories` | 기록 탭 월간/전체 read model |
| 기록 생성 | `POST /api/v1/memories` | DAILY/OOTD 공통 생성 |
| 기록 상세 | `GET /api/v1/memories/{memoryId}` | memory detail/edit 진입 |
| 기록 전체 수정 | `PUT /api/v1/memories/{memoryId}` | full replace 성격 |
| 기록 부분 수정 | `PATCH /api/v1/memories/{memoryId}` | Flutter Web 수정 저장 우선 경로 |
| 기록 삭제 | `DELETE /api/v1/memories/{memoryId}` | soft delete target |
| 그룹 기록 목록 | `GET /api/v1/groups/{groupId}/memories` | group detail read model |
| 그룹 기록 생성 | `POST /api/v1/groups/{groupId}/memories` | group scoped create |
| 미디어 업로드 | `POST /api/v1/media/upload` | multipart upload |
| 미디어 public proxy | `GET /api/v1/media/public` | storage key/public URL 표시 |
| presigned URL 후보 | `POST /api/v1/uploads/presigned-url` | target 확장 hook |

### Flutter client

현재 Flutter 구현 경계는 다음과 같다.

| 역할 | 파일 |
| --- | --- |
| 기록 달력/바텀시트 | `apps/mobile-flutter/lib/features/ootd/ootd_list_page.dart` |
| 하루 일과 작성/결과 | `apps/mobile-flutter/lib/features/ootd/presentation/pages/daily_record_screen.dart` |
| 하루 일과 수정 | `apps/mobile-flutter/lib/features/ootd/presentation/pages/daily_record_edit_screen.dart` |
| OOTD 작성 | `apps/mobile-flutter/lib/features/ootd/presentation/pages/ootd_record_screen.dart` |
| 기록 repository | `apps/mobile-flutter/lib/features/ootd/repository/record_repository.dart` |
| record model | `apps/mobile-flutter/lib/shared/models/ootd_model.dart` |
| 기록 상세 화면 | `apps/mobile-flutter/lib/features/memory/presentation/pages/memory_detail_page.dart` |
| API client | `apps/mobile-flutter/lib/core/api/onmu_api_client.dart`, `onmu_media_url.dart` |
| route | `apps/mobile-flutter/lib/core/routing/route_paths.dart`, `app_router.dart` |

Route 기준은 `/records`, `/records/new/daily`, `/records/new/ootd`, `/records/{recordId}`, `/records/edit/{recordId}`, `/records/{recordId}/template-diary`다.

### Data model and Flyway

| 테이블 | Flyway | 역할 |
| --- | --- | --- |
| `records` | `V1__core_schema_scaffold.sql`, `V4__core_schema_data_dictionary.sql`, seed `V5`, `V9` | DAILY/OOTD/photo/memo 통합 기록 원장 |
| `record_media` | `V4__core_schema_data_dictionary.sql`, seed `V5`, `V9`, `V12__connect_seed_record_media_minio.sql` | 기록 첨부 미디어 metadata와 storage key/public URL |
| `record_tags` | `V4__core_schema_data_dictionary.sql`, seed `V5` | hashtag/mood/category tag 연결 |
| `ootd_features` | `V4__core_schema_data_dictionary.sql` | OOTD/persona feature 확장 후보 |
| `outbox_events` | `V4__core_schema_data_dictionary.sql` | record/media 후처리 이벤트 후보 |

`records.deleted_at`은 soft delete 기준이다. 목록/상세 조회는 `deleted_at IS NULL`을 기준으로 해야 한다.

## API Contract

기록 생성 요청 예시:

```json
{
  "type": "DAILY",
  "title": "Daily record 2026-06-17",
  "memo": "오늘의 소중한 순간을 기록했어요.",
  "date": "2026-06-17",
  "tags": ["#하루기록", "#찐인데"],
  "visibility": "PRIVATE",
  "imageUrls": [
    "/api/v1/media/public?key=dev/media/records/rec_123/image-1.jpg"
  ],
  "payload": {
    "brands": {
      "recordType": "daily",
      "theme": "diary",
      "crew": "userOnly"
    },
    "mood": "평온",
    "weather": "맑음",
    "timeline": [
      {
        "category": "daily",
        "imageUrl": "/api/v1/media/public?key=dev/media/records/rec_123/image-1.jpg",
        "description": "카페에서 쉬었다."
      }
    ]
  }
}
```

미디어 업로드 응답 예시:

```json
{
  "storageKey": "dev/media/records/rec_123/image-1.jpg",
  "publicUrl": "/api/v1/media/public?key=dev/media/records/rec_123/image-1.jpg"
}
```

OOTD character snapshot 예시:

```json
{
  "type": "OOTD",
  "payload": {
    "brands": {
      "recordType": "ootd"
    },
    "characterSnapshot": {
      "hairStyleIndex": 1,
      "hairColorIndex": 2,
      "eyeColorIndex": 0,
      "topIndex": 3,
      "bottomIndex": 1
    }
  }
}
```

## Event / Outbox / Side Effect Model

Current:

- `POST/PATCH/DELETE /api/v1/memories`는 Spring transaction 안에서 `records`, `record_media`, `record_tags`를 갱신한다.
- `POST /api/v1/media/upload`는 파일을 storage에 먼저 올리고 URL을 반환한다.
- Flutter는 upload 결과의 `publicUrl`을 memory payload와 `imageUrls[]`에 연결한다.

Target 후보:

| 이벤트 | 발생 시점 | 소비자 |
| --- | --- | --- |
| `record.created` | DAILY/OOTD 생성 | notification/read model worker 후보 |
| `record.updated` | 기록 수정 | cache/read model refresh 후보 |
| `record.deleted` | soft delete | media cleanup worker 후보 |
| `media.thumbnail.requested` | image upload 또는 record create | FastAPI/Media worker 후보 |
| `ai.summary.requested` | 기록 설명/추천 생성 필요 시 | FastAPI AI/Data Worker |

미디어 파일 삭제는 DB transaction과 object storage operation의 원자성이 다르므로, target에서는 soft delete 후 cleanup job/outbox로 정리하는 방식을 우선한다.

## Target Architecture

```mermaid
flowchart LR
  Flutter["Flutter Records UI"] --> API["Spring Boot Main API"]
  API --> PG["PostgreSQL records / record_media / record_tags"]
  API --> Blob["Azure Blob Storage target"]
  API --> Outbox["outbox_events"]
  Outbox --> Bus["Azure Service Bus"]
  Bus --> Worker["FastAPI AI/Media Worker"]
  API --> Monitor["Application Insights / Log Analytics"]
```

- 확정: records/memories public API는 Spring Boot `/api/v1`가 소유한다.
- 확정: core record schema는 Spring Flyway가 소유한다.
- 확정: Flutter는 미디어 storage에 직접 write하지 않는다.
- 후보: local/dev MinIO 경계는 target Azure Blob Storage로 전환한다.
- 후보: thumbnail, AI diary summary, OOTD/persona extraction은 FastAPI Worker가 소비한다.
- 미결정: presigned direct upload를 사용할지, Spring multipart proxy를 유지할지 결정 필요.

## Current-to-Target Delta

| 구분 | Current | Target | Delta |
| --- | --- | --- | --- |
| 기록 저장 | Spring `/memories` + payload JSON | 동일 + payload schema version | `payload.schemaVersion` 추가 후보 |
| 사진 업로드 | Spring multipart, MinIO/local object storage | Azure Blob + managed identity 또는 SAS | storage abstraction/env 정리 필요 |
| 이미지 표시 | `publicUrl` 상대 경로 가능 | absolute media URL normalization | Flutter `ONMU_API_BASE_URL` 기준 정규화 유지 |
| 삭제 | `DELETE /memories/{id}` soft delete target | soft delete + media cleanup outbox | cleanup worker 필요 |
| 수정 | Flutter Web은 `PATCH` 우선 | CORS policy에 PATCH/DELETE 고정 | APIM/ingress CORS Terraform 필요 |
| OOTD | character snapshot payload | AI/OOTD feature extraction 확장 | worker job/event 필요 |

## Terraform Resource Implications

Terraform이 소유해야 할 리소스 후보:

- Azure Blob Storage account, container, lifecycle policy
- Azure Database for PostgreSQL Flexible Server, diagnostic settings
- Azure Key Vault, Managed Identity, app settings Key Vault reference
- Azure API Management 또는 ingress CORS policy for `GET,POST,PUT,PATCH,DELETE,OPTIONS`
- Azure Service Bus queue/topic for media/AI job events
- Azure Monitor Application Insights, Log Analytics, alerts for 4xx/5xx/upload failure

Terraform이 소유하지 않는 것:

- `records`, `record_media`, `record_tags`, `outbox_events` DDL: Spring Flyway 소유
- `worker_ai` schema: FastAPI Alembic 소유
- media upload transaction, record payload validation: Spring runtime 소유
- Flutter layout/theme/assets: Flutter app repository 소유
- CI/CD run execution: GitHub Actions 소유

## Secret / Key Vault / Managed Identity Boundary

secret 값은 문서에 기록하지 않는다. 이름과 경계만 관리한다.

| 이름 | 사용처 | Key Vault secret name |
| --- | --- | --- |
| `DATABASE_URL` | Spring records DB connection | `database-url` 계열 환경별 secret |
| `POSTGRES_PASSWORD` | Spring DB password | `postgres-password` 계열 환경별 secret |
| `ONMU_ACCESS_TOKEN_SECRET` | dev JWT 검증/발급 | `dev-access-token-secret`, `int-access-token-secret` |
| `ONMU_CORS_ORIGINS` 또는 환경별 CORS env | Flutter Web origin 허용 | 환경별 앱 설정 또는 Key Vault 참조 |
| `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` | local/dev MinIO compatibility | `minio-root-user`, `minio-root-password` |
| Azure Blob credential 후보 | target media storage | Managed Identity 우선, 불가 시 storage credential secret |

Flutter 앱에는 storage credential, DB credential, Key Vault secret을 넣지 않는다.

## Observability and Smoke Test

Current smoke 후보:

- `GET /healthz`, `GET /readyz`
- `OPTIONS /api/v1/memories` with Origin `http://127.0.0.1:5173`, method `POST/PATCH/DELETE`
- `POST /api/v1/media/upload` small image upload
- `POST /api/v1/memories` DAILY create
- `PATCH /api/v1/memories/{memoryId}` update
- `DELETE /api/v1/memories/{memoryId}` soft delete
- `GET /api/v1/memories`에서 deleted record 제외 확인

Target metrics:

- memory create/update/delete success/failure count
- media upload size rejection count
- media upload latency p95
- storage dependency failure count
- `record_not_found`, `media_upload_failed`, `authentication_required`, `token_expired` error dashboard
- CORS preflight failure count by origin/method

## Migration Risks

- dev server에 API PR이 merge/deploy되지 않으면 Flutter local code가 `PATCH`/`DELETE`/new payload를 호출해도 404/405/502처럼 보일 수 있다.
- 이미지 URL이 relative public URL이면 Flutter Web에서 dev server origin으로 잘못 붙을 수 있다.
- 큰 이미지 업로드는 dev API 제한에 걸릴 수 있어 client resize/compress 정책이 필요하다.
- `records.payload` JSON schema를 화면 UI와 함께 변경하면 이전 seed/기록이 깨질 수 있다.
- media object는 DB transaction과 원자적으로 삭제되지 않으므로 orphan object cleanup이 필요하다.
- OOTD가 없는 DAILY 기록은 character/WITH block을 표시하지 않아야 한다.

## Decision Log

| 상태 | 결정 |
| --- | --- |
| 확정 | Flutter는 Spring Boot Main API만 직접 호출한다. |
| 확정 | 하루 일과는 `type=DAILY`, OOTD는 `type=OOTD`로 구분한다. |
| 확정 | 사진은 upload 후 `publicUrl`을 record payload와 `record_media`에 연결한다. |
| 확정 | OOTD별 캐릭터 변경은 `records.payload.characterSnapshot`에 저장한다. |
| 확정 | 기록 삭제는 `records.deleted_at` 기준 soft delete로 처리한다. |
| 후보 | media thumbnail/AI summary는 outbox + FastAPI Worker로 확장한다. |
| 미결정 | direct-to-Blob presigned upload를 도입할지 Spring multipart proxy를 유지할지 결정 필요. |

## Roadmap

1. `records.payload.schemaVersion`을 도입해 기존 seed/기록과 새 다이어리 UI를 구분한다.
2. Flutter image picker 결과를 client resize/compress 후 upload하도록 정리한다.
3. `PATCH/DELETE /memories/{id}` dev/staging smoke를 CI/CD에 추가한다.
4. media upload를 Azure Blob Storage abstraction으로 교체한다.
5. `record.created`, `media.thumbnail.requested`, `ai.summary.requested` outbox event를 worker와 연결한다.
6. 기록 export image/share card는 외부 공개 링크가 아니라 client export 또는 share card domain으로 분리한다.

## Non-goals

- 실제 AI 이미지 생성/스타일 추천 prompt 구현
- Flutter에서 Blob/MinIO 직접 업로드
- Databricks/reporting layer 구현
- 공개 링크 기반 share page 구현
- 온모임/약속 장소 확정 로직 구현