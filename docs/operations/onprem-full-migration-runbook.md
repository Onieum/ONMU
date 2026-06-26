# On-prem full migration runbook

이 문서는 Azure staging primary를 유지하는 백업/수동 fallback이 아니라, Mac 또는 Windows 기반 on-prem 장비를 ONMU의 primary backend로 승격하는 완전 마이그레이션 절차를 정리한다.

이 문서는 준비와 go/no-go 기준을 고정하기 위한 문서다. 실제 DNS 변경, provider console 변경, DB dump/restore, object copy, Azure 중지/삭제는 각 phase의 승인과 실행 기록이 준비된 뒤에만 수행한다.

## 1. 백업 runbook과의 차이

| 구분 | On-prem backup backend | On-prem full migration |
| --- | --- | --- |
| 목적 | Azure staging 장애 분석, 단기 수동 fallback, 리허설 | on-prem 장비를 primary source of truth로 승격 |
| 기본 source of truth | Azure staging | cutover 전 Azure staging, cutover 후 on-prem |
| 공개 route | `backup-api.onmu.cloud` 또는 임시 route 우선 | 최종 API host 또는 앱 build define이 가리키는 primary route |
| write ownership | 원칙적으로 Azure 유지, fallback window에만 제한적 전환 | cutover window부터 on-prem 단일 writer |
| rollback | route를 Azure로 되돌리는 단기 rollback 가능 | on-prem write 수락 이후에는 reverse migration 또는 forward fix 필요 |
| Azure 역할 | primary | cutover 후 standby/read-only/폐기 후보 |

백업 서버 준비, Key Vault down preseed, tile/provider fallback smoke는 [On-prem backup backend runbook](./onprem-backup-backend-runbook.md)을 먼저 통과해야 한다. 이 문서는 그 다음 단계인 primary ownership 이전을 다룬다.

## 2. 마이그레이션 원칙

- `dev`와 `main`에 직접 push하지 않는다.
- 실제 secret value, DB password, OAuth code/state/idToken, token, 사용자 raw row, 사진 URL은 문서/PR/채팅/로그 요약에 출력하지 않는다.
- Azure staging과 on-prem이 동시에 write를 받는 상태를 만들지 않는다.
- 마이그레이션은 `freeze -> copy -> restore -> validate -> route cutover -> mobile/OAuth smoke -> source-of-truth 선언` 순서로만 진행한다.
- OAuth/provider console 변경은 runtime env, mobile build define, DNS/TLS가 같은 phase 안에서 정렬될 때만 수행한다.
- Azure resource 삭제는 마지막 단계다. 처음 cutover 직후에는 Azure를 rollback snapshot/read-only standby로 보존한다.
- Mac과 Windows 모두 후보가 될 수 있지만, 최종 primary 장비는 하나만 지정한다.

## 3. 사전 결정

마이그레이션을 시작하기 전에 아래를 비워두지 않는다.

| 항목 | 결정값 기록 방식 |
| --- | --- |
| Target OS/장비 | Mac 또는 Windows, 장비 식별자는 개인 정보 없이 역할명으로 기록 |
| Target API host | 예: `https://staging-api.onmu.cloud`를 on-prem으로 route 전환하거나 별도 host 사용 |
| Target tile host | 예: `https://backup-tiles.onmu.cloud` 또는 최종 tile host |
| Source freeze window | 시작/종료 시각, 담당자, 사용자 영향 |
| Single writer 전환 방식 | Azure write stop, route switch, app build switch 중 하나 |
| OAuth callback host | Kakao/Naver/Google별 callback host와 mobile deep link |
| Data scope | DB, media, tile, provider cache, outbox/event 처리 범위 |
| Rollback window | route rollback 가능한 마지막 시각 |
| Azure retention | ACA/DB/Blob/Key Vault를 read-only standby로 둘 기간 |

## 4. Phase M0: readiness gate

완전 마이그레이션은 아래 조건을 통과해야 시작한다.

| Gate | Go 기준 | No-Go 기준 |
| --- | --- | --- |
| PR 상태 | migration 문서와 runbook이 `dev` 기준 최신 | 문서가 stale, PR conflict, CI 실패 |
| Target runtime | `/healthz`, `/readyz`, no-token `/users/me` 401 | local-only도 불안정 |
| DB restore | `pg_restore` exit/go-no-go 기준 통과 | non-zero 원인 미분류, Flyway/extension/schema 실패 |
| Media/tile restore | object count/checksum/status와 tile Range smoke 통과 | raw URL/credential 의존, tile blank |
| Provider preseed | OAuth/place/route provider env presence 확인 | Key Vault 장애 시 값을 가져올 수 없음 |
| Actual OAuth | target route에서 iOS/Android 로그인 완료 | 웹 callback까지만 확인 |
| Rollback plan | route, DB, object, write ownership rollback point 기록 | rollback owner/time/target 불명확 |

## 5. Phase M1: target primary 장비 확정

Mac과 Windows 중 하나를 최종 primary 장비로 정한다. 다른 장비는 secondary rehearsal 또는 cold standby로만 둔다.

공통 기준:

- Java 21
- Docker 또는 외부 Postgres/Redis/MinIO 대체 구성
- 고정 전원/네트워크
- 자동 재시작 수단
  - macOS: `launchd`
  - Windows: Task Scheduler 또는 Windows Service wrapper
- 로컬 로그 보존 위치
- OS 업데이트/재부팅 window
- local secret store와 파일 권한

기록할 값:

- OS와 runtime 방식
- Spring commit hash와 image/tag
- DB/Redis/Object endpoint host type
- public route 방식
- log path

기록하지 않을 값:

- secret value
- DB connection string value
- object storage credential
- tunnel token

## 6. Phase M2: local secret source of truth 전환

완전 마이그레이션 이후에는 Azure Key Vault가 primary secret source가 아니다. 단, secret 값은 여전히 문서화하지 않는다.

권장 구조:

| 항목 | 기준 |
| --- | --- |
| local env file | repo 밖 경로, macOS/Linux `600`, Windows 사용자 ACL |
| OS secret store | 가능하면 Keychain 또는 Windows Credential Manager 병행 |
| wrapper script | repo 밖 경로, secret value echo 금지 |
| rotation note | secret name, rotation date, 담당자만 기록 |
| Flutter define | 공개 client id/base URL만 포함, client secret/JWT signing secret 금지 |

필수 env name:

- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_PASSWORD`
- `SPRING_DATA_REDIS_URL`
- `ONMU_ACCESS_TOKEN_SECRET`
- `OBJECT_STORAGE_ENDPOINT`
- `OBJECT_STORAGE_BUCKET`
- `KAKAO_REST_API_KEY`
- `KAKAO_CLIENT_SECRET`
- `KAKAO_OAUTH_REDIRECT_URI`
- `KAKAO_OAUTH_MOBILE_CALLBACK_URI`
- `NAVER_OAUTH_CLIENT_ID`
- `NAVER_OAUTH_CLIENT_SECRET`
- `NAVER_OAUTH_REDIRECT_URI`
- `NAVER_OAUTH_MOBILE_CALLBACK_URI`
- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`
- `NAVER_SEARCH_CLIENT_ID`
- `NAVER_SEARCH_CLIENT_SECRET`
- `OPENROUTESERVICE_API_KEY`

## 7. Phase M3: source freeze와 single writer 전환

Source freeze 전에는 Azure staging이 source of truth다. Freeze 이후부터 on-prem restore와 validation이 끝날 때까지 새 write를 받지 않는다.

Freeze 방식 후보:

| 방식 | 기준 |
| --- | --- |
| 앱 점검 window | 사용자 접근을 잠시 막을 수 있을 때 |
| Azure API read-only mode | runtime flag가 있거나 ingress/proxy에서 write method를 막을 수 있을 때 |
| Route cutover first | target이 이미 검증됐고 짧은 freeze만 필요한 때 |

금지:

- Azure와 on-prem이 동시에 채팅/정산/기록 write를 받는 상태
- source freeze 없이 DB dump를 떠서 그대로 primary로 승격
- freeze 이후 Azure에서 발생한 write를 누락하고 on-prem을 primary로 선언

기록할 값:

- freeze 시작/종료 시각
- 허용된 HTTP method
- source active connection count
- source write 차단 방식
- rollback 가능 시각

## 8. Phase M4: DB migration

DB 이전은 [Azure 데이터 이전 runbook](./azure-data-migration-runbook.md)의 PostgreSQL 기준을 따른다. Target이 Azure가 아니라 on-prem이어도 Flyway, PostGIS, schema/index, row count 판정은 동일하다.

실행 기준:

1. source snapshot 또는 logical dump를 생성한다.
2. target Postgres/PostGIS를 준비한다.
3. target DB에 restore한다.
4. `pg_restore` exit code와 stderr를 분류한다.
5. PostGIS extension, Flyway, 핵심 table/index/constraint를 확인한다.
6. source/target row count를 비교한다.
7. Spring target runtime을 target DB에 연결한다.

Go/No-Go:

| 항목 | Go 기준 |
| --- | --- |
| `pg_restore` | `0` 또는 분류된 warning만 존재 |
| PostGIS | extension presence 확인 |
| Flyway | 최신 migration success |
| 핵심 schema | users/groups/plans/chat/settlement/record/media/place table presence |
| 핵심 count | source/target 차이 설명 가능 |
| API readiness | target `/readyz` 200 |

## 9. Phase M5: object storage와 tile migration

Media와 tile은 분리해서 이전한다.

Media:

- private media bucket/object prefix를 target object store로 복사한다.
- object count, sample size/checksum, API read status만 기록한다.
- raw user media URL이나 파일명은 보고하지 않는다.

Tile:

- `manifest.json`
- MapLibre style JSON
- PMTiles object
- Range header
- CORS/header
- Android/iOS map 화면

Tile host가 바뀌면 Flutter `ONMU_TILE_MANIFEST_URL` 또는 DNS/route가 같이 정렬되어야 한다.

## 10. Phase M6: public route와 TLS

완전 마이그레이션에서는 임시 `backup-api`가 아니라 최종 primary host를 정한다.

선택지:

| 방식 | 기준 |
| --- | --- |
| 기존 `staging-api.onmu.cloud`를 on-prem으로 전환 | 앱 재빌드를 줄이고 provider callback host 변경을 줄이고 싶을 때 |
| 신규 `api.onmu.cloud` 또는 다른 host | staging과 production 의미를 분리하고 싶을 때 |
| 임시 host 후 앱 재빌드 | provider console과 앱 배포를 함께 바꿀 수 있을 때 |

Cutover 전 확인:

- DNS TTL
- TLS 인증서 발급/갱신 방식
- health check path
- rollback target
- access log 위치
- rate limit/WAF 대체 여부

## 11. Phase M7: OAuth/provider console 정렬

Provider callback host가 바뀌면 아래 네 곳이 같은 값으로 정렬되어야 한다.

| 위치 | 확인 |
| --- | --- |
| Provider console | Kakao/Naver redirect/callback allowlist |
| Spring env | redirect URI, mobile callback URI |
| Flutter public define | API base URL, provider public client id/redirect URI |
| Mobile deep link | `io.onieum.onmu://oauth/<provider>/callback` 유지 |

Google은 웹 OAuth redirect보다 Android package/SHA-1, iOS bundle id/reversed client id, Spring audience 검증을 함께 본다.

기록할 값:

- provider name
- callback host/path
- mobile callback scheme/path
- provider error parameter 존재 여부
- HTTP status/path

기록하지 않을 값:

- actual code/state/idToken
- raw provider response
- client secret
- 사용자 계정 정보

## 12. Phase M8: mobile build와 distribution

API host 또는 tile manifest host가 바뀌면 앱 build define과 배포 경로를 함께 결정한다.

| 항목 | 기준 |
| --- | --- |
| `ONMU_API_BASE_URL` | 최종 on-prem primary API host |
| `ONMU_TILE_MANIFEST_URL` | 최종 tile manifest host |
| OAuth public values | provider public client id와 redirect URI만 |
| 금지 | JWT signing secret, OAuth client secret, object credential |

기존 앱이 `staging-api.onmu.cloud`를 기본으로 보고 있고 이 host 자체를 on-prem으로 route 전환한다면 앱 재빌드를 줄일 수 있다. 반대로 host를 `api.onmu.cloud`로 바꾸면 iOS/Android 재빌드와 실제 OAuth smoke가 필수다.

## 13. Phase M9: cutover smoke

최종 route cutover 직후 아래를 status/path/count 중심으로 확인한다.

| 영역 | 기준 |
| --- | --- |
| API | `/healthz` 200, `/readyz` 200, no-token `/users/me` 401 |
| OAuth | iOS/Android 실제 provider 로그인, 앱 복귀, 세션 유지 |
| User/Profile | `/api/v1/users/me` 200, field presence |
| Groups/Plans | 목록/상세/생성/참여 status |
| Chat | 목록, 전송, 재조회, 읽음, SSE/polling status |
| Media/Record | upload/read/delete status, object presence |
| Map/Search/Route | provider count, coordinate count, route provider live 여부 |
| Notification | unread/list/preferences/push-token readiness |
| Tile | manifest/style 200, PMTiles Range 206, 모바일 지도 blank 없음 |

Smoke 실패 시 먼저 route, runtime, DB, object, provider, mobile build define 중 어느 축인지 분리한다.

## 14. Phase M10: source-of-truth 선언

아래가 모두 통과하면 on-prem을 primary로 선언한다.

- on-prem route가 사용자 앱의 기본 API host다.
- on-prem DB가 write source of truth다.
- Azure API는 stopped, read-only, 또는 standby로 격하됐다.
- freeze 이후 발생한 write가 on-prem에만 존재한다.
- OAuth provider callback이 target route와 맞다.
- tile/media object read가 target에서 된다.
- rollback window와 rollback 한계가 공지됐다.

선언 후에는 Azure staging에 새 write를 허용하지 않는다. Azure로 돌아가야 하면 단순 route rollback이 아니라 on-prem에서 Azure로 reverse migration 또는 forward migration이 필요하다.

## 15. Phase M11: Azure retention과 decommission

Cutover 직후 Azure를 즉시 삭제하지 않는다.

| 기간 | Azure 역할 |
| --- | --- |
| T+0 ~ T+24h | rollback snapshot/read-only standby |
| T+24h ~ T+7d | 비용과 보존 필요성 검토, DB/blob snapshot 유지 |
| T+7d 이후 | 팀 합의 후 중지/삭제 후보 |

삭제 전 확인:

- on-prem backup/snapshot 존재
- object storage copy 검증 완료
- provider console이 Azure callback을 더 이상 필요로 하지 않음
- App Insights/Log Analytics에서 필요한 장애 분석 로그 export 완료
- Key Vault secret rotation 또는 폐기 계획 존재

## 16. Rollback과 reverse migration

Rollback은 시점에 따라 다르다.

| 시점 | 가능한 조치 |
| --- | --- |
| freeze 전 | Azure primary 유지 |
| restore 검증 전 | target 폐기 후 재시도 |
| route cutover 직후, write 수락 전 | route를 Azure로 되돌림 |
| on-prem write 수락 후 | on-prem -> Azure reverse migration 또는 forward fix |

on-prem write 수락 후에는 Azure DB가 더 이상 최신 원장이 아니다. 이때 Azure로 돌아가려면 on-prem DB/object/outbox 기준으로 새 dump/copy를 만들고 Azure target에 적용해야 한다.

## 17. 보고 템플릿

```markdown
## Migration Window
- source freeze start:
- source freeze end:
- target primary host:
- target commit:
- rollback deadline:

## Data
- DB restore status:
- table count:
- Flyway latest:
- media object count:
- tile object count:

## Runtime
- healthz:
- readyz:
- no-token users/me:
- authenticated users/me:

## OAuth/Mobile
- Kakao:
- Naver:
- Google:
- iOS smoke:
- Android smoke:

## Domain Smoke
- chat:
- media:
- map/search/route:
- notification:

## Decision
- Go/No-Go:
- primary source of truth:
- Azure retention:
- next owner:
```

보고에는 secret value, token, OAuth code/state/idToken, 사용자 raw value, media raw URL을 넣지 않는다.
