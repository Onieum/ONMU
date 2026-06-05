# 메인 API

API는 identity, profile, social, group, plan, place, decision, memory, settlement, privacy, share, notification, audit 도메인의 transaction boundary를 담당합니다.

현재 `server.mjs`는 Windows dev 서버와 Flutter mock-to-API 전환을 위한 Node 기반 contract stub입니다. 최종 Main API 스택은 아직 확정하지 않았고, 문서의 임시 추천안은 Spring Boot Main API + FastAPI Worker입니다.

## 현재 제공 범위

기존 smoke endpoint:

- `GET /healthz`
- `GET /readyz`

Flutter PR #61 기준 contract stub:

- `GET /api/v1/home/summary`
- `GET /api/v1/groups`
- `POST /api/v1/groups`
- `GET /api/v1/groups/{groupId}`
- `GET /api/v1/groups/{groupId}/summary`
- `GET /api/v1/groups/{groupId}/members`
- `GET /api/v1/groups/{groupId}/messages`
- `GET /api/v1/groups/{groupId}/memories`
- `GET /api/v1/groups/{groupId}/memories/{memoryId}`
- `GET /api/v1/groups/{groupId}/plans`
- `POST /api/v1/groups/{groupId}/plans`
- `GET /api/v1/groups/{groupId}/plans/{planId}`
- `PATCH /api/v1/groups/{groupId}/plans/{planId}`
- `GET /api/v1/groups/{groupId}/plans/{planId}/itinerary`
- `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates`
- `GET /api/v1/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}`
- `GET /api/v1/groups/{groupId}/plans/{planId}/place-risks`
- `GET /api/v1/groups/{groupId}/plans/{planId}/place-vote-result`
- `GET /api/v1/groups/{groupId}/plans/{planId}/votes`
- `POST /api/v1/groups/{groupId}/plans/{planId}/votes`
- `GET /api/v1/groups/{groupId}/plans/{planId}/votes/{voteId}`
- `GET /api/v1/groups/{groupId}/votes`
- `GET /api/v1/groups/{groupId}/votes/{voteId}`
- `GET /api/v1/groups/{groupId}/votes/{voteId}/voters`
- `GET /api/v1/groups/{groupId}/plans/{planId}/settlements`
- `GET /api/v1/groups/{groupId}/plans/{planId}/settlements/{settlementId}`
- `GET /api/v1/place-search?query=...`

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

Cloudflare Tunnel은 이 API/gateway만 `dev-api.onmu.cloud`로 노출하고, DB/Redis/MinIO 포트는 외부에 열지 않습니다. DB 점검은 별도 Cloudflare Access TCP와 개인별 DB 계정으로 제한합니다.

## 검증

```powershell
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
curl http://localhost:8080/api/v1/home/summary
curl http://localhost:8080/api/v1/groups
curl http://localhost:8080/api/v1/groups/1/plans/101
curl http://localhost:8080/api/v1/groups/1/plans/101/place-candidates
curl http://localhost:8080/api/v1/groups/1/votes/501
curl http://localhost:8080/api/v1/groups/1/plans/101/settlements
```

요청 로그:

```powershell
Get-Content logs\api-access.log -Tail 20
```

## 주의

- 이 서버는 contract stub입니다. PostgreSQL 테이블, migration, 영구 CRUD는 아직 구현하지 않습니다.
- 응답 필드는 Flutter model과 맞춘 camelCase JSON입니다.
- POST/PATCH 결과는 서버 프로세스 메모리에만 반영됩니다.
- secret, API key, credential은 `.env`, 문서, PR 본문에 남기지 않습니다.
