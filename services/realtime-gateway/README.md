# Realtime Gateway

The realtime gateway handles WebSocket connections and room fan-out.

First prototype events:

| Event | Direction | Purpose |
| --- | --- | --- |
| `room.joined` | server -> client | A participant joined the meetup room |
| `participant.status.updated` | server -> client | Departed, arrived, late, unknown |
| `candidate.created` | server -> client | A place candidate was added |
| `candidate.updated` | server -> client | Candidate score/status changed |
| `decision.updated` | server -> client | Place or schedule decision changed |

Rules:

- Persist important state through the API before broadcasting.
- Use Redis for fan-out and short-lived room state.
- Clients must reconnect and resync room state after disconnect.
