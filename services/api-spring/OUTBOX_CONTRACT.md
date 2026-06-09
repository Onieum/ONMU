# Outbox Contract

Spring Boot Main API owns `outbox_events`. FastAPI Worker consumes AI/Data events through queue/outbox and writes only to `worker_ai` tables.

## Event Types

| Event type | Producer | Consumer |
| --- | --- | --- |
| `group.created` | Spring Boot Main API | future notification/realtime |
| `group.updated` | Spring Boot Main API | future notification/realtime |
| `group.member_left` | Spring Boot Main API | future notification/realtime |
| `plan.created` | Spring Boot Main API | future notification/realtime |
| `place_candidate.created` | Spring Boot Main API | FastAPI ai-data-worker |
| `vote.created` | Spring Boot Main API | future notification/realtime |
| `settlement.created` | Spring Boot Main API | future notification/realtime |
| `record.created` | Spring Boot Main API | FastAPI ai-data-worker |
| `ai.summary.requested` | Spring Boot Main API | FastAPI ai-data-worker |

## Status Values

| Status | Meaning |
| --- | --- |
| `pending` | Event is stored and ready to publish. |
| `published` | Event was handed to queue. |
| `processing` | Worker claimed the job. |
| `completed` | Worker result was stored. |
| `failed` | Worker failed and retry policy applies. |
| `no_consumer` | No worker exists for this event in the current dev stage. |
| `skipped_dev` | Event is intentionally skipped in local/dev smoke. |

## Payload Rules

- Do not store provider tokens, API keys, raw credentials, or unnecessary personal data.
- Prefer aggregate ids and compact metadata.
- For analytics future use, keep consent and privacy flags explicit.
- FastAPI Worker may store derived result metadata in `worker_ai`, but must not mutate core tables directly.

## Group Event Payloads

| Event type | Aggregate type | Payload |
| --- | --- | --- |
| `group.created` | `group` | `groupId`, `name`, `ownerUserId` |
| `group.updated` | `group` | `groupId`, `name`, `description` |
| `group.member_left` | `group` | `groupId`, `userId` |
