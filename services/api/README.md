# 메인 API

API는 다음 도메인의 transaction boundary를 담당합니다.

- identity
- profile
- social
- meetup
- place
- decision
- memory
- settlement
- privacy
- share
- notification
- audit

첫 구현은 modular monolith로 시작할 수 있습니다. 다만 나중에 필요할 때 서비스를 분리할 수 있도록 module boundary는 릴리스 아키텍처의 도메인 경계와 맞춰야 합니다.

첫 세로 prototype에 필요한 endpoint:

- `POST /profiles/me/preferences`
- `POST /meetups`
- `POST /meetups/{meetupId}/participants`
- `GET /meetups/{meetupId}`
- `GET /meetups/{meetupId}/place-candidates`
- `POST /meetups/{meetupId}/place-candidates`
- `POST /meetups/{meetupId}/decision`
- `POST /meetups/{meetupId}/memories`
- `POST /meetups/{meetupId}/settlements`
- `GET /meetups/{meetupId}/settlements`
- `GET /healthz`
- `GET /readyz`

현재 Windows backend-host smoke test용으로 `server.mjs`가 `/healthz`와 `/readyz`를 제공합니다.

```powershell
npm run host:windows
npm run api:dev
```

개인 로컬 테스트는 `.env.example`의 임시값을 복사해서 쓸 수 있습니다. 공유 Windows dev 서버는 실제 DB 비밀번호와 외부 API key를 `.env`에 두지 않고 Azure Key Vault에서 읽어 시작합니다.

```powershell
npm run host:windows:keyvault
npm run api:dev:keyvault
```

Cloudflare Tunnel은 이 API/gateway만 `dev-api.onmu.cloud`로 노출하고, DB/Redis/MinIO 포트는 외부에 열지 않습니다. DB 점검은 `db-dev.onmu.cloud` Cloudflare Access TCP와 개인별 DB 계정으로 제한합니다.
