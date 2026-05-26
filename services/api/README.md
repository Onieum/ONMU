# Main API

The API owns transaction boundaries for:

- identity
- profile
- social
- meetup
- place
- decision
- memory
- notification

The first implementation can be a modular monolith, but module boundaries must match the release architecture so that services can be split later if needed.

Required endpoints from the first vertical prototype:

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
