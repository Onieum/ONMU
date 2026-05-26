# Worker Services

Worker services process async jobs that should not block the main API.

| Worker | Responsibility |
| --- | --- |
| `recommendation` | Taste matching, group score, candidate explanation |
| `place-risk` | Opening-hours conflict, temporary closure risk, stale API data |
| `route-departure` | Directions API, ETA, departure alert |
| `photo-memory` | Photo metadata and memory card assistance |
| `notification` | Push preparation, retry, delivery logging |

Workers should be idempotent and safe to retry.
