# Azure secret 인벤토리

이 문서는 Azure 전환에 필요한 env var name과 Key Vault secret name을 정리한다. secret 값은 문서, PR, 로그, 채팅에 절대 출력하지 않는다.

## 1. 작성 규칙

- `secret name`은 Key Vault에 저장되는 이름이다.
- `env var`는 Spring/FastAPI/GitHub Actions/container runtime이 읽는 이름이다.
- Flutter에는 공개 client id와 redirect URI만 들어갈 수 있다.
- OAuth client secret, JWT signing secret, DB password, provider secret은 Flutter에 넣지 않는다.
- length나 존재 여부는 smoke 보고에 사용할 수 있지만 값은 출력하지 않는다.

## 2. Core runtime secrets

| Env var | Dev secret name | Staging secret name 후보 | Prod secret name 후보 | 대상 | Flutter 허용 |
| --- | --- | --- | --- | --- | --- |
| `DATABASE_URL` | `dev-database-url` | `staging-database-url` | `prod-database-url` | Spring/Flyway | 아니오 |
| `POSTGRES_PASSWORD` | `dev-postgres-password` | `staging-postgres-password` | `prod-postgres-password` | Spring/Flyway | 아니오 |
| `ONMU_ACCESS_TOKEN_SECRET` | `dev-access-token-secret` | `staging-access-token-secret` | `prod-access-token-secret` | Spring auth | 아니오 |
| `ONMU_AUTH_ISSUER` | config 후보 | config 후보 | config 후보 | Spring auth | 아니오 |
| `ONMU_AUTH_AUDIENCE` | config 후보 | config 후보 | config 후보 | Spring auth | 아니오 |
| `ONMU_ACCESS_TOKEN_TTL` | config 후보 | config 후보 | config 후보 | Spring auth | 아니오 |
| `ONMU_REFRESH_TOKEN_TTL` | config 후보 | config 후보 | config 후보 | Spring auth | 아니오 |
| `REDIS_URL` | `dev-redis-url` | `staging-redis-url` | `prod-redis-url` | Spring/FastAPI | 아니오 |
| `SPRING_DATA_REDIS_URL` | `dev-redis-url` 후보 | `staging-redis-url` | `prod-redis-url` | Spring cache | 아니오 |
| `ONMU_CORS_ORIGINS` | `dev-cors-origins` | `staging-cors-origins` | `prod-cors-origins` | Spring | 아니오 |
| `ONMU_DEV_CORS_ORIGINS` | `dev-cors-origins` fallback | 사용 안 함 후보 | 사용 안 함 후보 | Spring dev fallback | 아니오 |
| `ONMU_ALLOWED_ORIGINS` | config 후보 | config 후보 | config 후보 | `AuthProperties` fallback | 아니오 |

Spring CORS runtime의 1차 env는 현재 `ONMU_CORS_ORIGINS`다. `ONMU_DEV_CORS_ORIGINS`는 dev fallback이며, `ONMU_ALLOWED_ORIGINS`는 `AuthProperties` fallback으로만 남아 있어 혼동하지 않는다.

## 3. Object storage

| Env var | Dev secret name | Staging secret name 후보 | Prod secret name 후보 | 대상 | Flutter 허용 |
| --- | --- | --- | --- | --- | --- |
| `OBJECT_STORAGE_PROVIDER` | config `minio` | config `azure_blob` | config `azure_blob` | Spring plain env | 아니오 |
| `MINIO_ROOT_USER` | `dev-minio-root-user` | 사용 안 함 후보 | 사용 안 함 후보 | Windows dev MinIO | 아니오 |
| `MINIO_ROOT_PASSWORD` | `dev-minio-root-password` | 사용 안 함 후보 | 사용 안 함 후보 | Windows dev MinIO | 아니오 |
| `OBJECT_STORAGE_ENDPOINT` | `dev-object-storage-endpoint` 후보 | `staging-blob-endpoint` 후보 | `prod-blob-endpoint` 후보 | Spring | 아니오 |
| `OBJECT_STORAGE_BUCKET` | `dev-object-storage-bucket` 후보 | `staging-blob-container` 후보 | `prod-blob-container` 후보 | Spring | 아니오 |
| `AZURE_CLIENT_ID` 또는 `OBJECT_STORAGE_MANAGED_IDENTITY_CLIENT_ID` | 사용 안 함 후보 | managed identity client id config | managed identity client id config | Spring Azure Blob provider | 아니오 |
| `AZURE_STORAGE_CONNECTION_STRING` | 사용 안 함 후보 | `staging-storage-connection-string` 후보 | `prod-storage-connection-string` 후보 | migration/tooling | 아니오 |

Azure staging/prod runtime에서는 connection string보다 managed identity/RBAC를 우선한다. `AZURE_CLIENT_ID`는 secret 값이 아니라 user-assigned managed identity 선택용 식별자지만, 보고에는 값 자체를 출력하지 않는다.

## 4. OAuth secrets and public defines

| Env var | Dev secret name | Staging secret name 후보 | Prod secret name 후보 | 대상 | Flutter 허용 |
| --- | --- | --- | --- | --- | --- |
| `KAKAO_REST_API_KEY` | `dev-kakao-rest-api-key` | `staging-kakao-rest-api-key` | `prod-kakao-rest-api-key` | Spring/Flutter public define | 예 |
| `KAKAO_CLIENT_SECRET` | `dev-kakao-client-secret` | `staging-kakao-client-secret` | `prod-kakao-client-secret` | Spring | 아니오 |
| `KAKAO_OAUTH_REDIRECT_URI` | env/config | `staging-kakao-oauth-redirect-uri` | `prod-kakao-oauth-redirect-uri` | Spring/Flutter public define | 공개 URI만 예 |
| `KAKAO_OAUTH_MOBILE_CALLBACK_URI` | env/config | `staging-kakao-oauth-mobile-callback-uri` | `prod-kakao-oauth-mobile-callback-uri` | Spring callback deep link | 예 |
| `NAVER_OAUTH_CLIENT_ID` | `dev-naver-oauth-client-id` | `staging-naver-oauth-client-id` | `prod-naver-oauth-client-id` | Spring/Flutter public define | 예 |
| `NAVER_OAUTH_CLIENT_SECRET` | `dev-naver-oauth-client-secret` | `staging-naver-oauth-client-secret` | `prod-naver-oauth-client-secret` | Spring | 아니오 |
| `NAVER_OAUTH_REDIRECT_URI` | env/config | `staging-naver-oauth-redirect-uri` | `prod-naver-oauth-redirect-uri` | Flutter public define, Spring parity env | 공개 URI만 예 |
| `NAVER_OAUTH_MOBILE_CALLBACK_URI` | env/config | `staging-naver-oauth-mobile-callback-uri` | `prod-naver-oauth-mobile-callback-uri` | Spring callback deep link | 예 |
| `GOOGLE_OAUTH_CLIENT_ID` | `dev-google-oauth-client-id` | `staging-google-oauth-client-id` | `prod-google-oauth-client-id` | Spring/Flutter public define | 예 |
| `GOOGLE_SERVER_CLIENT_ID` | `dev-google-server-client-id` | `staging-google-server-client-id` | `prod-google-server-client-id` | Spring/Flutter public define | 예 |
| `GOOGLE_CLIENT_ID` | `dev-google-oauth-client-id` | `staging-google-oauth-client-id` | `prod-google-oauth-client-id` | Flutter public define | 예 |
| `GOOGLE_IOS_CLIENT_ID` | generated from `GOOGLE_CLIENT_ID` | generated from `GOOGLE_CLIENT_ID` | generated from `GOOGLE_CLIENT_ID` | iOS generated xcconfig | 예 |
| `GOOGLE_IOS_SERVER_CLIENT_ID` | generated from `GOOGLE_SERVER_CLIENT_ID` | generated from `GOOGLE_SERVER_CLIENT_ID` | generated from `GOOGLE_SERVER_CLIENT_ID` | iOS generated xcconfig | 예 |
| `GOOGLE_IOS_REVERSED_CLIENT_ID` | generated from `GOOGLE_CLIENT_ID` | generated from `GOOGLE_CLIENT_ID` | generated from `GOOGLE_CLIENT_ID` | iOS URL scheme | 예 |

Provider console의 redirect/callback 설정은 환경별 host와 모바일 URL scheme을 맞춘다. 실제 code/state/idToken 값은 smoke 보고에 포함하지 않는다.
현재 public define 생성 스크립트는 별도 `GOOGLE_ANDROID_CLIENT_ID` Key Vault secret을 직접 읽지 않는다. 플랫폼별 client id secret을 분리하려면 Flutter/Spring 코드, define 생성 스크립트, Spring audience 검증 문서를 함께 갱신한다.

## 5. Place/Search/Route provider secrets

| Env var | Dev secret name | Staging secret name 후보 | Prod secret name 후보 | 대상 | Flutter 허용 |
| --- | --- | --- | --- | --- | --- |
| `NAVER_SEARCH_CLIENT_ID` | `dev-naver-search-client-id` | `staging-naver-search-client-id` | `prod-naver-search-client-id` | Spring place-search | 아니오 |
| `NAVER_SEARCH_CLIENT_SECRET` | `dev-naver-search-client-secret` | `staging-naver-search-client-secret` | `prod-naver-search-client-secret` | Spring place-search | 아니오 |
| `OPENROUTESERVICE_API_KEY` | `dev-openrouteservice-api-key` | `staging-openrouteservice-api-key` | `prod-openrouteservice-api-key` | Spring route | 아니오 |

Kakao Local API 사용 여부는 provider 권한/심사 상태를 별도 runbook으로 관리한다.

## 6. Notification/push 후보

| Env var | Dev secret name 후보 | Staging secret name 후보 | Prod secret name 후보 | 대상 | Flutter 허용 |
| --- | --- | --- | --- | --- | --- |
| `ONMU_FCM_SERVICE_ACCOUNT_JSON` | `dev-fcm-service-account-json` 후보 | `staging-fcm-service-account-json` | `prod-fcm-service-account-json` | Notification provider | 아니오 |
| `ONMU_APNS_PRIVATE_KEY` | `dev-apns-private-key` 후보 | `staging-apns-private-key` | `prod-apns-private-key` | Notification provider | 아니오 |
| `ONMU_APNS_KEY_ID` | `dev-apns-key-id` 후보 | `staging-apns-key-id` | `prod-apns-key-id` | Notification provider | 아니오 |
| `ONMU_APNS_TEAM_ID` | `dev-apns-team-id` 후보 | `staging-apns-team-id` | `prod-apns-team-id` | Notification provider | 아니오 |
| `ONMU_APNS_BUNDLE_ID` | config 후보 | `staging-apns-bundle-id` 후보 | `prod-apns-bundle-id` 후보 | Notification provider | 공개 식별자는 가능하나 Flutter push secret과 함께 전달 금지 |
| `ONMU_PUSH_DELIVERY_ENABLED` | config 후보 | config 후보 | config 후보 | Notification provider flag | 아니오 |
| `ONMU_PUSH_PROVIDER_MODE` | config 후보 | config 후보 | config 후보 | Notification provider mode | 아니오 |

현재 dev-safe delivery는 실제 FCM/APNs 발송을 켜지 않는 기준으로 검증한다.

## 7. Observability 후보

| Env var | Dev secret name 후보 | Staging secret name 후보 | Prod secret name 후보 | 대상 | Flutter 허용 |
| --- | --- | --- | --- | --- | --- |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | `dev-appinsights-connection-string` 후보 | `staging-appinsights-connection-string` | `prod-appinsights-connection-string` | Spring/FastAPI | 아니오 |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | config 후보 | config 후보 | config 후보 | Spring/FastAPI | 아니오 |

## 8. OOTD AI generation 후보

| Env var | Dev secret name 후보 | Staging secret name 후보 | Prod secret name 후보 | 대상 | Flutter 허용 |
| --- | --- | --- | --- | --- | --- |
| `ONMU_OOTD_GENERATION_PROVIDER` | config `mock` | config `mock` 또는 `azure_ml` | config 후보 | FastAPI worker plain env | 아니오 |
| `ONMU_HF_TOKEN` | `dev-hf-token` 후보 | `staging-hf-token` | `prod-hf-token` | FastAPI worker | 아니오 |
| `ONMU_OOTD_MODEL_ID` | `dev-ootd-model-id` 후보 | `staging-ootd-model-id` | `prod-ootd-model-id` | FastAPI worker | 아니오 |
| `ONMU_OOTD_MODEL_REVISION` | `dev-ootd-model-revision` 후보 | `staging-ootd-model-revision` | `prod-ootd-model-revision` | FastAPI worker | 아니오 |
| `ONMU_AZUREML_ENDPOINT_URL` | `dev-azureml-endpoint-url` 후보 | `staging-azureml-endpoint-url` | `prod-azureml-endpoint-url` | FastAPI worker | 아니오 |
| `ONMU_AZUREML_ENDPOINT_KEY` | `dev-azureml-endpoint-key` 후보 | `staging-azureml-endpoint-key` | `prod-azureml-endpoint-key` | FastAPI worker | 아니오 |
| `ONMU_VISION_MODEL_DEPLOYMENT` | config 후보 | config 후보 | config 후보 | FastAPI worker plain env 후보 | 아니오 |
| `ONMU_VISION_API_KEY` | `dev-vision-api-key` 후보 | `staging-vision-api-key` | `prod-vision-api-key` | FastAPI worker | 아니오 |

OOTD AI generation 값은 Flutter에 넣지 않는다. Flutter는 Spring `/api/v1/ootd/avatar-generations`와 job polling API만 호출한다. Worker, Hugging Face, Azure ML, Vision endpoint, Blob private object key는 Flutter가 직접 호출하지 않는다.

`ONMU_OOTD_MODEL_ID`, `ONMU_OOTD_MODEL_REVISION`은 secret 값은 아니지만 Key Vault secret name으로 관리한다. FLUX.1-Kontext-dev는 non-commercial license이므로, production 또는 상업 배포 단계에서 모델 교체가 필요할 수 있기 때문이다. `ONMU_VISION_MODEL_DEPLOYMENT`는 현재 plain env 후보로 둔다.

## 9. Smoke 보고 허용 항목

허용한다.

- env var name
- Key Vault secret name
- present 여부
- length
- secret updated time의 존재 여부
- process start time이 secret update 이후인지 여부

금지한다.

- secret 값
- Authorization header 값
- raw request/response body
- OAuth code/state/idToken 값
- 사용자 개인정보 실제 값
