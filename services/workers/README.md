# Worker Services

Worker services handle asynchronous work that should not block Spring Boot Main API requests.

The confirmed first worker is `services/workers/ai-data-worker`.

| Worker | Status | Responsibility |
| --- | --- | --- |
| `ai-data-worker` | Scaffold | AI/Data jobs behind Spring Boot: place explanation, recommendation helper data, record/OOTD summary, worker job metadata |
| `notification-worker` | Future only | Push and notification retries after MVP scope is clearer |
| `media-worker` | Future only | Media thumbnails and heavier image processing after MVP scope is clearer |

Workers are internal services. Flutter must not call them directly. Spring Boot writes domain events and worker requests to `outbox_events`; workers consume through queue/outbox and write only to their owned schema.

Current PR scope only records the worker boundary and ownership. Future analytics/reporting work stays in the architecture roadmap until the core product flow is ready.
