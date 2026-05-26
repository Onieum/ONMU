# 워커 서비스

워커 서비스는 메인 API를 막지 않아야 하는 비동기 작업을 처리합니다.

| 워커 | 책임 |
| --- | --- |
| `recommendation` | 취향 매칭, 그룹 점수, 후보 설명 |
| `place-risk` | 영업시간 충돌, 임시 휴무 리스크, 오래된 API 데이터 |
| `route-departure` | Directions API, ETA, 출발 알림 |
| `photo-memory` | 사진 metadata와 기억 카드 보조 |
| `notification` | push 준비, 재시도, 전송 기록 |

워커는 idempotent해야 하며 안전하게 재시도할 수 있어야 합니다.
