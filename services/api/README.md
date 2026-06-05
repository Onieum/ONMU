# 개발용 Node Smoke/Contract Stub API

`services/api/server.mjs`는 최종 백엔드 Main API가 아닙니다. 이 Node 서버는 Windows backend-host, Cloudflare Tunnel, `/healthz`, `/readyz`, CORS, request log, Flutter mock-to-API contract를 빠르게 검증하기 위한 임시 smoke/contract stub입니다.

확정 백엔드 구조는 `Spring Boot Main API + FastAPI Worker`입니다. Flutter 앱은 Spring Boot Main API만 직접 호출하고, FastAPI Worker는 Spring Boot 뒤에서 AI/Data 작업을 처리하는 내부 worker로 둡니다. 제품 도메인 API, 인증/인가, DB transaction, migration, 영구 CRUD 구현 기준은 Spring Boot Main API입니다.

확정된 세부 기준은 다음과 같습니다.

- 첫 OAuth provider는 Naver입니다.
- 인증은 access token + refresh token 방식이며, Flutter는 secure storage에 저장합니다.
- Spring Boot와 FastAPI Worker는 queue/outbox로 연결합니다.
- FastAPI Worker 위치는 `services/workers/ai-data-worker`입니다.
- 투표 생성 canonical API는 `POST /api/v1/groups/{groupId}/votes`입니다.
- 장소 검색 canonical API는 `POST /api/v1/place-search`입니다.

## Node Stub이 검증하는 계약

- `GET /healthz`: Windows backend-host의 HTTP 프로세스 생존 확인
- `GET /readyz`: PostgreSQL, Redis, MinIO 로컬 의존성 연결 확인
- `dev-api.onmu.cloud -> localhost:8080`: Cloudflare Tunnel 경로 확인
- `logs/api-access.log`: request log와 `?client=` / `x-onmu-dev-client` 추적 확인
- dev CORS와 `OPTIONS` preflight: Flutter web/dev 클라이언트 연결 확인
- `/api/v1` contract: Flutter repository를 API repository로 전환하기 전 최소 shape 확인

Spring Boot Main API가 준비되면 위 계약은 Spring Boot로 넘깁니다. Node stub은 그 전까지만 Windows 개발 서버 연결 검증에 사용합니다.

## 현재 제공 범위

기존 smoke endpoint:

- `GET /healthz`
- `GET /readyz`

Flutter PR #61과 `docs/architecture/api-contract-map.md` 기준 contract stub:

- `GET /api/v1/home/summary`
- `GET /api/v1/groups`
- `POST /api/v1/groups`
- `GET /api/v1/groups/{groupId}`
- `GET /api/v1/groups/{groupId}/summary`
- `GET /api/v1/groups/{groupId}/members`
- `GET /api/v1/groups/{groupId}/messages`
- `GET /api/v1/groups/{groupId}/memories`
- `GET /api/v1/groups/{groupId}/memories/{memoryId}`
- `GET /api/v1/groups/{groupId}/votes`
- `POST /api/v1/groups/{groupId}/votes`
- `GET /api/v1/groups/{groupId}/votes/{voteId}`
- `GET /api/v1/groups/{groupId}/votes/{voteId}/voters`
- `GET /api/v1/groups/{groupId}/plans`
- `POST /api/v1/groups/{groupId}/plans`
- `GET /api/v1/groups/{groupId}/plans/{planId}`
- `PATCH /api/v1/groups/{groupId}/plans/{planId}`
- `GET /api/v1/groups/{groupId}/plans/{planId}/itinerary`
- `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates`
- `POST /api/v1/groups/{groupId}/plans/{planId}/place-candidates`
- `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}`
- `POST /api/v1/groups/{groupId}/plans/{planId}/schedule-places`
- `GET /api/v1/groups/{groupId}/plans/{planId}/votes`
- `POST /api/v1/groups/{groupId}/plans/{planId}/votes` (dev compatibility)
- `GET /api/v1/groups/{groupId}/plans/{planId}/votes/{voteId}`
- `GET /api/v1/groups/{groupId}/plans/{planId}/settlement-draft`
- `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft`
- `PATCH /api/v1/groups/{groupId}/plans/{planId}/settlement-draft/items/{itemId}/targets`
- `POST /api/v1/groups/{groupId}/plans/{planId}/settlements/preview`
- `GET /api/v1/groups/{groupId}/plans/{planId}/settlements`
- `POST /api/v1/groups/{groupId}/plans/{planId}/settlements`
- `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}`
- `POST /api/v1/place-search`
- `GET /api/v1/place-search?query=...` (dev compatibility)

`POST /api/v1/groups/{groupId}/plans/{planId}/votes`와 `GET /api/v1/place-search?query=...`는 기존 mock/화면 전환 검증을 위한 임시 호환 route입니다. 운영 API의 canonical 계약은 [API Contract Map](../../docs/architecture/api-contract-map.md)의 `POST /api/v1/groups/{groupId}/votes`, `POST /api/v1/place-search`를 따릅니다.

Seed ID는 Flutter `InMemoryOnmuStore`와 맞춰 `groupId=1`, `planId=101`, `voteId=501`을 기본 검증값으로 사용합니다. 없는 ID는 mock store처럼 첫 번째 seed로 fallback합니다.

## 실행

개인 로컬 테스트:

```powershell
npm run host:windows
npm run api:dev
```

공유 Windows dev 서버:

```powershell
npm run host:windows:keyvault
npm run api:dev:keyvault
npm run tunnel:cloudflare
```

Cloudflare Tunnel은 Node stub 또는 이후 Spring Boot Main API의 HTTP gateway만 `dev-api.onmu.cloud`로 노출합니다. DB/Redis/MinIO 포트는 외부에 열지 않습니다. DB 점검은 별도 Cloudflare Access TCP와 개인별 DB 계정으로 제한합니다.

## 검증

```powershell
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
curl http://localhost:8080/api/v1/home/summary
curl http://localhost:8080/api/v1/groups
curl http://localhost:8080/api/v1/groups/1/plans/101
curl http://localhost:8080/api/v1/groups/1/plans/101/place-candidates
$placeSearchBody = Join-Path $env:TEMP "onmu-place-search.json"
[System.IO.File]::WriteAllText($placeSearchBody, '{"query":"cafe","planId":"101"}', [System.Text.UTF8Encoding]::new($false))
curl.exe -X POST http://localhost:8080/api/v1/place-search -H "Content-Type: application/json" --data-binary "@$placeSearchBody"
$voteBody = Join-Path $env:TEMP "onmu-vote.json"
[System.IO.File]::WriteAllText($voteBody, '{"voteType":"PLACE","targetType":"PLAN","targetId":"101","title":"place vote","options":["cafe","restaurant"]}', [System.Text.UTF8Encoding]::new($false))
curl.exe -X POST http://localhost:8080/api/v1/groups/1/votes -H "Content-Type: application/json" --data-binary "@$voteBody"
$candidateBody = Join-Path $env:TEMP "onmu-place-candidate.json"
[System.IO.File]::WriteAllText($candidateBody, '{"name":"new place","category":"cafe"}', [System.Text.UTF8Encoding]::new($false))
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/place-candidates -H "Content-Type: application/json" --data-binary "@$candidateBody"
$previewBody = Join-Path $env:TEMP "onmu-settlement-preview.json"
[System.IO.File]::WriteAllText($previewBody, '{}', [System.Text.UTF8Encoding]::new($false))
curl.exe -X POST http://localhost:8080/api/v1/groups/1/plans/101/settlements/preview -H "Content-Type: application/json" --data-binary "@$previewBody"
```

요청 로그:

```powershell
curl "https://dev-api.onmu.cloud/api/v1/home/summary?client=team-check"
Get-Content logs\api-access.log -Tail 20
```

## 주의

- 이 서버는 Windows backend-host 검증용 contract stub입니다.
- PostgreSQL 테이블, migration, 인증/인가, 영구 CRUD는 Spring Boot Main API에서 구현합니다.
- POST/PATCH 결과는 서버 프로세스 메모리에만 반영됩니다.
- 장소 후보 stub은 하트/선호 참고, 후보 추가, 일정 등록, 투표 생성 흐름을 위한 최소 데이터만 제공합니다.
- secret, API key, credential은 `.env`, 문서, PR 본문에 남기지 않습니다.
