# 실시간 게이트웨이

실시간 게이트웨이는 WebSocket 연결과 약속 방 fan-out을 담당합니다.

첫 prototype event:

| Event | 방향 | 목적 |
| --- | --- | --- |
| `room.joined` | server -> client | 참여자가 약속 방에 join |
| `participant.status.updated` | server -> client | 출발, 도착, 지각, 알 수 없음 상태 변경 |
| `candidate.created` | server -> client | 장소 후보 추가 |
| `candidate.updated` | server -> client | 후보 점수 또는 상태 변경 |
| `decision.updated` | server -> client | 장소 또는 일정 결정 변경 |

규칙:

- broadcast 전에 중요한 상태를 API를 통해 먼저 저장합니다.
- fan-out과 짧게 유지되는 방 상태에는 Redis를 사용합니다.
- client는 연결이 끊긴 뒤 reconnect와 방 상태 resync를 수행해야 합니다.
