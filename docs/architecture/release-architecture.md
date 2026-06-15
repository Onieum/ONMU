# ONMU 릴리스 아키텍처

## 원칙

ONMU는 처음부터 실제 서비스 릴리스를 전제로 설계합니다. 구현은 애자일하게 작게 나누어 진행하지만, 목표 아키텍처는 운영 가능한 제품 수준을 기준으로 둡니다. Flutter 앱, API, 실시간 게이트웨이, 워커, 관리형 데이터 서비스, AKS, 관측성, CI/CD를 초기 설계에 포함합니다.

발표용 다이어그램과 기술 스택 기준은 [현재 아키텍처 다이어그램과 기술 스택 결정안](./current-architecture-diagram.md)을 기준으로 함께 관리합니다. Flutter 구조는 [Flutter 프론트 아키텍처](./frontend-architecture.md), API 계약은 [API Contract Map](./api-contract-map.md), Auth/User/Profile 경계는 [ONMU Auth/User/Profile 아키텍처](./auth-user-profile-architecture.md), 홈/약속/투표 경계는 [ONMU 홈 / 약속 / 투표 아키텍처](./home-plans-vote-architecture.md), 채팅/ChatActivity 목표 구조는 [ONMU 채팅 및 ChatActivity 아키텍처](./chat-activity-architecture.md), Place/Search/Route/Map 경계는 [ONMU Place / Search / Route / Map 아키텍처](./place-search-route-map-architecture.md), 백엔드 확정안은 [백엔드 결정 원본과 기술스택](./backend-stack-options.md)을 함께 봅니다.

Azure/Terraform 전환을 준비할 때는 [Current-to-target 아키텍처 인덱스](./current-to-target-index.md)에서 도메인별 목표 구조를 먼저 확인하고, 운영 절차는 [Azure Terraform 전환 운영 가이드](../operations/azure-terraform-migration.md), secret 경계는 [Azure secret 인벤토리](../operations/azure-secret-inventory.md), 배포 검증은 [Azure smoke checklist](../operations/azure-smoke-checklist.md)를 기준으로 봅니다.

## 제품 표면

| 표면 | 역할 |
| --- | --- |
| Flutter 모바일 앱 | iOS와 Android의 핵심 제품 경험 |
| 브랜드 웹 | 정적 브랜드/프로젝트 소개 |
| Spring Boot Main API | 도메인 트랜잭션, full social OAuth, 권한, 공개 API 계약 |
| 실시간 게이트웨이 | WebSocket 방 상태와 fan-out |
| FastAPI Worker | 추천 설명, 장소 선택 보조, 경로/출발, 사진 기록, 알림 보조 작업 |
| ChatActivity | 채팅 메시지와 투표/정산/약속 변경 카드 |
| Notification | 약속, 투표, 정산, 기록 이벤트 알림 |

## 첫 연결 흐름

```text
스플래시
  -> 소셜 로그인
  -> 취향 선택
  -> 캐릭터 설정
  -> 홈
  -> 온모임
  -> 약속 생성/상세
  -> 장소 후보/일정 등록
  -> 채팅/투표/정산/기록
```

## 목표 플랫폼

```text
Flutter 앱
  -> API Gateway / Ingress
  -> Spring Boot Main API
  -> 실시간 게이트웨이
  -> PostgreSQL + PostGIS
  -> Redis
  -> 검색 서비스
  -> 이벤트 버스
  -> FastAPI Worker
  -> 오브젝트 스토리지 + CDN
  -> 관측성
```

## 도메인 경계

| 도메인 | 책임 |
| --- | --- |
| Identity | 사용자, 인증 제공자, 기기 토큰 |
| Profile | 취향 태그, 가능 시간, 저장 장소 |
| Social | 친구 관계와 초대 |
| Meetup | 약속, 참여자, 일정 후보 |
| Place | 장소, 후보, 외부 API 캐시, 선택 보조 정보 |
| Decision | 투표, 선택된 장소/일정, 결정 로그 |
| Realtime | presence와 참여자 실시간 상태 |
| Recommendation | 후보 설명, 취향 기반 선택 보조 |
| Memory | 기억 카드, 사진, 스티커 |
| ChatActivity | 일반 메시지, 투표 카드, 정산 카드, 약속 변경 알림 |
| Settlement | 약속 단위 결제 항목, 대상자, 미리보기, 최종 송금 요약, 정산 완료 여부 |
| Privacy | 기록 공개 범위, 항목별 공개 여부, 외부 공유 정책 |
| Share | 카카오톡 공유 카드, 인스타그램 저장 이미지, 공유 링크 |
| Notification | push 요청과 전송 결과 |
| Audit | outbox 이벤트, 감사 로그 |

## 전달 단계

1. Flutter route와 화면 흐름을 운영 route 기준으로 정리합니다.
2. Spring Boot Main API와 FastAPI Worker의 API/Event 계약을 고정합니다.
3. API contract와 mock-to-repository 전환 기준을 만듭니다.
4. full social OAuth와 사용자 session을 연결합니다.
5. 홈, 온모임, 약속, 장소, 정산, 채팅, 알림 read model을 연결합니다.
6. 실시간 협업과 notification side effect를 강화합니다.
7. 릴리스 품질과 관측성을 강화합니다.
