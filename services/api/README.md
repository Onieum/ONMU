# 메인 API

API는 다음 도메인의 transaction boundary를 담당합니다.

- identity
- profile
- social
- meetup
- place
- decision
- memory
- notification

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
- `GET /healthz`
- `GET /readyz`
