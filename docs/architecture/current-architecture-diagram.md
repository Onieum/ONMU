# ONMU 현재 아키텍처 다이어그램과 기술 스택 권장안

## 1. 문서 목적

이 문서는 현재 ONMU의 제품 방향과 대표 피드백을 기준으로, 발표와 개발 계획에 바로 사용할 수 있는 아키텍처 그림과 기술 스택 선택 기준을 정리한다.

핵심 포지션은 다음과 같이 잡는다.

> ONMU는 카카오톡, 지도 앱, 캘린더, 사진첩, 정산 앱에 흩어진 약속 경험을 하나의 흐름으로 묶는 약속 큐레이션 및 라이프로그 플랫폼이다.

초기 구현은 Flutter 모바일 앱을 중심으로 진행하고, 백엔드는 로컬 Docker 환경에서 시작하되 Azure 운영 환경으로 옮길 수 있는 구조를 전제로 둔다.

## 2. 다이어그램 관리 방식

현재 저장소에서는 이 문서의 Mermaid 블록을 다이어그램 원본으로 관리한다. 발표 자료나 Notion에 이미지가 필요할 때만 Mermaid를 PNG/SVG로 렌더링해서 별도 산출물로 만든다.

이미지 파일은 저장소의 필수 소스가 아니다. 다이어그램을 수정할 때는 아래 Mermaid 블록을 먼저 고치고, 필요한 경우에만 렌더링 산출물을 생성한다.

## 3. 현재 기준 전체 아키텍처

```mermaid
flowchart LR
    user["사용자"] --> mobile["Flutter 모바일 앱"]
    user --> web["브랜드 웹"]

    subgraph client["클라이언트 경계"]
        mobile
        web
    end

    mobile --> edge["Azure Front Door 또는 Application Gateway WAF"]
    web --> edge

    subgraph azureEdge["Azure 보안/진입 경계"]
        edge --> apim["Azure API Management"]
        apim --> ingress["AKS Ingress 또는 Container Apps Ingress"]
    end

    subgraph app["애플리케이션 서비스 경계"]
        ingress --> mainApi["Spring Boot Main API"]
        ingress --> realtime["Realtime Gateway"]
        mainApi --> worker["FastAPI AI/Data Worker"]
    end

    subgraph data["데이터/상태 경계"]
        mainApi --> postgres["Azure Database for PostgreSQL Flexible Server + PostGIS"]
        mainApi --> redis["Azure Cache for Redis"]
        mainApi --> blob["Azure Blob Storage"]
        realtime --> redis
        mainApi --> bus["Azure Service Bus 또는 Event Hubs"]
        bus --> worker
        worker --> search["Azure AI Search 또는 PostgreSQL 검색"]
    end

    subgraph ai["AI/추천 경계"]
        worker --> openai["Azure OpenAI"]
        search --> worker
    end

    subgraph external["외부 API 경계"]
        mainApi --> naver["Naver Maps/Place API"]
        worker --> publicInfo["휴무/공지/리뷰 외부 정보"]
        mobile --> share["카카오톡/인스타그램 공유"]
    end

    subgraph ops["운영/보안 경계"]
        github["GitHub Actions"] --> registry["Container Registry"]
        registry --> ingress
        terraform["Terraform"] --> azureInfra["Azure 리소스"]
        keyvault["Azure Key Vault"] --> mainApi
        keyvault --> worker
        monitor["Azure Monitor + Application Insights"] --> mainApi
        monitor --> worker
        monitor --> realtime
    end
```

이 그림에서 발표자가 반드시 설명해야 하는 경계는 네 가지다.

| 경계 | 설명 |
| --- | --- |
| 클라이언트 경계 | 사용자가 직접 만나는 영역이다. 핵심 제품은 Flutter 앱이고, 웹은 브랜드/프로젝트 소개만 담당한다. |
| Azure 보안/진입 경계 | 외부 요청이 처음 들어오는 곳이다. WAF, API 정책, 인증 검증, rate limit을 이 계층에서 설명한다. |
| 애플리케이션 서비스 경계 | Spring Boot는 트랜잭션과 도메인 계약, FastAPI는 추천/분석/AI 작업, Realtime Gateway는 실시간 상태를 맡는다. |
| 외부 API 경계 | 네이버 지도/장소, 공유 채널, 외부 공지 정보는 내부 데이터가 아니므로 호출, 캐시, 장애 대응 정책을 따로 둔다. |

## 4. 제품 데이터 흐름

```mermaid
flowchart TD
    profile["사용자 프로필/취향 입력"] --> api["Spring Boot Main API"]
    meetup["약속 생성/참여자 초대"] --> api
    place["장소 검색/후보 추가"] --> api
    ootd["사진/OOTD/기록 입력"] --> api
    settlement["모임 비용/정산 입력"] --> api
    privacy["공개 범위 설정"] --> api

    api --> tx["도메인 트랜잭션 처리"]
    tx --> db["PostgreSQL/PostGIS"]
    tx --> event["Outbox 이벤트 발행"]

    place --> naver["Naver Place API"]
    naver --> cache["장소 후보 캐시"]
    cache --> db

    event --> bus["Service Bus 또는 Event Hubs"]
    bus --> worker["FastAPI Worker"]

    worker --> recommend["참여자 취향 병합/장소 점수화"]
    worker --> risk["휴무일/브레이크타임/비선호 키워드 경고"]
    worker --> aiRecord["OOTD/기록 설명 생성"]

    recommend --> openai["Azure OpenAI"]
    aiRecord --> openai
    risk --> db

    ootd --> blob["Blob Storage"]
    settlement --> settlementTable["정산 상태 테이블"]
    privacy --> acl["공개 범위/권한 테이블"]

    db --> memory["모임 기록/라이프로그"]
    settlementTable --> memory
    acl --> share["공유 카드/참여자 공개/나만 보기"]
```

제품 흐름에서 중요한 점은 감성 기능과 실용 기능을 같은 기록 흐름에 묶는 것이다.

| 데이터 | 저장/처리 위치 | 제품 의미 |
| --- | --- | --- |
| 프로필/취향 | PostgreSQL, 추천 워커 | 개인화 장소 추천의 근거 |
| 약속/참여자 | PostgreSQL, Redis, Realtime Gateway | 실시간 협업과 상태 공유 |
| 장소/외부 API | Naver API, PostGIS, 캐시 | 장소 후보, 거리, 영업 정보, 리스크 판단 |
| 사진/OOTD | Blob Storage, FastAPI Worker | 기록, 공유, 재방문 유도 |
| 정산/비용 | PostgreSQL 트랜잭션 | 실용성 보강, 모임 완료 흐름 |
| 공개 범위 | 권한 테이블, API 정책 | 개인정보 보호와 공유 정책 |

## 5. 로컬 개발에서 Azure 운영까지

```mermaid
flowchart LR
    local["로컬 개발자 PC"] --> compose["Docker Compose"]
    compose --> localApi["Spring Boot / FastAPI / Redis / PostgreSQL / MinIO"]

    localApi --> devServer["Windows 개발 서버"]
    devServer --> tunnel["Cloudflare Tunnel 또는 제한된 방화벽 포트"]

    devServer --> staging["Azure Staging"]
    staging --> prod["Azure Production"]

    subgraph stagingBox["Azure Staging 후보"]
        aca["Azure Container Apps"]
        pgStaging["PostgreSQL Flexible Server"]
        redisStaging["Redis"]
        blobStaging["Blob Storage"]
    end

    subgraph prodBox["Azure Production 후보"]
        aks["AKS"]
        pgProd["PostgreSQL HA + PostGIS"]
        redisProd["Redis"]
        blobProd["Blob Storage + CDN"]
        monitorProd["Azure Monitor"]
    end

    staging --> aca
    prod --> aks
```

현재 팀 상황에서는 `로컬 Docker Compose -> Windows 개발 서버 -> Azure Staging -> Azure Production` 순서가 현실적이다.

단, 운영 플랫폼은 두 가지 선택지가 있다.

| 선택지 | 장점 | 단점 | 추천 상황 |
| --- | --- | --- | --- |
| Azure Container Apps | Kubernetes 운영 부담이 적고, 컨테이너 배포와 스케일링이 빠르다. | Kubernetes 자체 역량을 보여주기는 약하다. | 빠른 staging, 팀 속도 우선, 운영 복잡도 절감 |
| AKS | 실제 Kubernetes 운영 역량, 네트워크/보안/관측성 설계를 보여주기 좋다. | 클러스터 운영, Ingress, Secret, 노드 비용 관리가 어렵다. | 최종 발표에서 인프라 역량을 강하게 보여주고 싶을 때 |

ONMU는 포트폴리오 관점에서 AKS를 목표 아키텍처에 남겨두되, 첫 배포 검증은 Azure Container Apps로 낮게 시작하는 전략이 좋다.

## 6. 대표 피드백 반영용 기술 스택 권장안

| 영역 | 1차 권장 스택 | 이유 | 도입 시점 |
| --- | --- | --- | --- |
| 모바일 앱 | Flutter, go_router, Riverpod, Dio, freezed/json_serializable | iOS/Android를 한 코드베이스로 만들고, 화면/상태/API 모델을 분리하기 좋다. | 즉시 |
| 프로토타입 | FlutterFlow | 스토리보드와 화면 이동 검증에 빠르다. 단, 최종 앱은 Flutter 코드 품질 기준으로 관리한다. | 즉시 |
| 브랜드 웹 | 정적 웹, Azure Static Web Apps 또는 Vercel | 제품 소개/팀 소개만 담당하므로 복잡한 웹앱이 필요 없다. | 발표 전 |
| 메인 API | Spring Boot 3, Java 21, Spring Security, JPA/Querydsl, Flyway | 약속, 참여자, 정산, 공개 범위 같은 트랜잭션 도메인에 적합하다. | Sprint 1 |
| AI/Data Worker | FastAPI, Pydantic, Python worker | 장소 점수화, OOTD 분석, 추천 설명 생성처럼 비동기/AI 작업을 분리하기 좋다. | Sprint 2 |
| 실시간 상태 | Spring WebSocket 또는 별도 Realtime Gateway, Redis pub/sub | 출발/도착/지각/미확인 상태를 빠르게 fan-out한다. | Sprint 2 |
| API 경계 | Azure API Management | 모바일 앱과 백엔드 사이에서 인증, rate limit, API 정책을 설명하기 좋다. | Staging |
| WAF/Edge | Azure Front Door WAF 또는 Application Gateway WAF | 외부 요청의 첫 보안 경계를 명확히 보여준다. | Staging |
| 컨테이너 운영 | 로컬 Docker Compose, Staging은 Container Apps, Production 목표는 AKS | 개발 속도와 포트폴리오 아키텍처를 둘 다 챙긴다. | Sprint 0부터 |
| 관계형 DB | Azure Database for PostgreSQL Flexible Server, PostGIS | 약속, 장소, 위치 거리 계산, 정산, 권한 데이터를 한 모델로 관리하기 좋다. | Sprint 0부터 |
| 캐시 | Redis | 장소 API 캐시, 실시간 presence, 짧은 TTL 상태에 적합하다. | Sprint 1 |
| 파일 저장 | Azure Blob Storage, 로컬 MinIO | 사진/OOTD/공유 카드 같은 비정형 미디어를 DB에서 분리한다. | Sprint 1 |
| 검색/RAG | 초기에는 PostgreSQL 검색, 확장 시 Azure AI Search | 처음부터 검색 엔진을 크게 가져가지 않고, 발표용 AI/RAG 확장성을 보여줄 수 있다. | Sprint 2 이후 |
| 이벤트/큐 | Azure Service Bus, 필요 시 Event Hubs Kafka endpoint | 일반 업무 이벤트는 Service Bus가 단순하고, Kafka 호환/스트리밍 강조가 필요하면 Event Hubs를 붙인다. | Sprint 2 이후 |
| AI | Azure OpenAI | 추천 설명, 기록 문장 생성, OOTD 분석 결과 요약에 사용한다. 앱에서 직접 호출하지 않고 worker 뒤에 둔다. | Sprint 2 이후 |
| 인증 | Microsoft Entra External ID 또는 Firebase Auth 추상화 | Azure 발표 관점은 Entra External ID가 좋고, 한국형 소셜 로그인은 provider 추상화로 확장한다. | Sprint 1 |
| 비밀값 | Azure Key Vault, Managed Identity | 외부 API 키와 DB 비밀번호를 코드/GitHub/Jira에 남기지 않는다. | Staging |
| 관측성 | Azure Monitor, Application Insights, OpenTelemetry | Spring/FastAPI/Realtime의 요청 흐름을 trace로 묶어 보여준다. | Sprint 1부터 |
| IaC/CI | Terraform, GitHub Actions, Dependabot | 로컬에서 Azure로 옮기는 과정을 반복 가능하게 만들고, 공개 저장소 운영 기준을 세운다. | Sprint 0부터 |

## 7. 기술 스택별 사용 방식

이 섹션은 발표 중 "그 기술을 어디에 쓰나요?"라는 질문에 답하기 위한 기준이다. 기술 이름을 나열하지 말고, ONMU의 어떤 문제를 해결하는지와 어느 데이터가 지나가는지를 함께 설명한다.

### 7.1 클라이언트와 화면

| 기술 | ONMU에서 쓰는 위치 | 처리하는 것 | 선택 이유 |
| --- | --- | --- | --- |
| Flutter | iOS/Android 모바일 앱 | 약속 생성, 장소 선택, 실시간 상태, OOTD, 기록, 마이 페이지 | 핵심 서비스가 모바일 네이티브 중심이고 한 코드베이스로 양쪽 앱을 만들 수 있다. |
| go_router | Flutter 라우팅 | 온보딩, 캐릭터 생성, 약속 생성, 기록 상세, 마이 페이지 이동 | URL/route 기반으로 화면 흐름을 명확히 관리한다. |
| Riverpod | Flutter 상태 관리 | 로그인 상태, 캐릭터 draft, 약속 draft, 장소 후보, 정산 상태 | 화면 상태와 API 상태를 분리해 테스트하기 쉽다. |
| Dio | Flutter API client | REST API 요청, 인증 토큰 첨부, 에러 처리 | interceptor로 인증/재시도/로그 마스킹을 관리하기 좋다. |
| FlutterFlow | 초기 프로토타입 | 스토리보드 화면 연결, 사용자 흐름 검증 | 실제 개발 전 화면 흐름을 빠르게 검증한다. 최종 앱은 Flutter 코드 기준으로 정리한다. |

### 7.2 백엔드 API와 도메인

| 기술 | ONMU에서 쓰는 위치 | 처리하는 것 | 선택 이유 |
| --- | --- | --- | --- |
| Spring Boot | Main API | 사용자, 약속, 참여자, 장소 후보, 정산, 공개 범위, 기록 저장 | 트랜잭션이 중요한 도메인 로직을 안정적으로 처리한다. |
| Spring Security | Main API 인증/인가 | 로그인 사용자 식별, role/permission, API 보호 | 공개/비공개 기록, 참여자 전용 데이터 같은 권한 판단이 필요하다. |
| JPA/Querydsl | Main API 데이터 접근 | 약속 목록, 장소 후보, 기록 조회, 정산 상태 조회 | 일반 CRUD와 조건 검색을 타입 안정성 있게 관리한다. |
| Flyway | DB migration | 테이블 생성/변경 이력 | 팀원이 같은 DB 스키마로 개발하고, staging/prod 배포 때 변경을 추적한다. |
| FastAPI | AI/Data Worker | 장소 점수화, OOTD 분석, 추천 설명, 비동기 데이터 처리 | Python AI/데이터 라이브러리와 붙이기 쉽고, Spring API와 역할을 분리할 수 있다. |

Spring Boot와 FastAPI를 나누는 기준은 단순하다. 사용자 요청에 즉시 일관성 있게 처리되어야 하는 것은 Spring Boot가 맡고, 시간이 걸리거나 AI/분석 성격이 강한 작업은 FastAPI Worker로 넘긴다.

### 7.3 데이터 저장소

| 기술 | ONMU에서 쓰는 위치 | 처리하는 것 | 선택 이유 |
| --- | --- | --- | --- |
| PostgreSQL | 메인 관계형 DB | 사용자, 약속, 참여자, 장소 후보, 기록, 정산, 공개 범위 | 서비스의 핵심 정합성을 지키는 중심 저장소다. |
| PostGIS | PostgreSQL 확장 | 장소 좌표, 거리 계산, 반경 검색, 근처 후보 조회 | 장소 추천과 지도 기반 필터링에 필요하다. |
| Redis | 캐시/짧은 상태 저장 | 장소 API 응답 캐시, 참여자 presence, 실시간 방 상태, rate limit 보조 | 빠르게 변하거나 짧게 보관할 상태를 DB에 계속 쓰지 않게 한다. |
| Azure Blob Storage | 운영 파일 저장소 | OOTD 사진, 기록 이미지, 공유 카드 이미지, 캐릭터 결과 이미지 | 큰 바이너리 파일을 DB와 분리하고 CDN 연동이 쉽다. |
| MinIO | 로컬 개발용 오브젝트 스토리지 | Blob Storage와 같은 방식의 사진/이미지 저장 mock | 로컬 Docker에서 Azure Blob과 유사한 개발 경험을 제공한다. |

Redis는 영구 데이터의 원본이 아니다. ONMU에서 원본은 PostgreSQL과 Blob Storage이고, Redis는 빠른 조회와 실시간 상태 보조에만 사용한다.

### 7.4 이벤트와 비동기 처리

| 기술 | ONMU에서 쓰는 위치 | 처리하는 것 | 선택 이유 |
| --- | --- | --- | --- |
| Outbox Pattern | Spring Boot 내부 | 약속 생성, 장소 후보 추가, 기록 생성 후 이벤트 발행 예약 | DB 저장과 이벤트 발행 사이의 유실을 줄인다. |
| Azure Service Bus | 기본 비동기 큐 | 추천 작업 요청, 알림 요청, 이미지 분석 요청, 정산 완료 후 기록 갱신 | 일반 업무 이벤트에는 큐/토픽 모델이 단순하고 안정적이다. |
| Kafka/Event Hubs | 확장 이벤트 스트림 | 실시간 행동 로그, 추천 학습용 이벤트, 대량 상태 이벤트 | Kafka 역량을 보여주거나 스트리밍 분석이 필요할 때 확장한다. |
| GitHub Actions scheduled job | 가벼운 배치 | 문서 링크 점검, 의존성 점검, 간단한 health check | 별도 배치 플랫폼 없이 반복 검증을 자동화한다. |

초기에는 Kafka를 바로 운영하지 않는다. 발표에서는 `Service Bus로 업무 이벤트를 안정적으로 처리하고, 대량 이벤트/스트리밍 분석이 필요해지면 Event Hubs의 Kafka 호환 endpoint로 확장한다`고 설명한다.

### 7.5 실시간 협업

| 기술 | ONMU에서 쓰는 위치 | 처리하는 것 | 선택 이유 |
| --- | --- | --- | --- |
| WebSocket | Realtime Gateway | 출발, 도착, 지각, 미확인, 투표 상태 fan-out | 약속 방 참여자에게 상태 변화를 즉시 보여준다. |
| Redis pub/sub | Realtime Gateway 내부 | 여러 서버 인스턴스 간 방 이벤트 전달 | 서버가 여러 개로 늘어도 같은 방 참여자에게 이벤트를 보낼 수 있다. |
| Redis TTL key | Presence 상태 | 접속 중, 마지막 확인 시간, 임시 typing/active 상태 | 자동 만료가 필요한 짧은 상태에 적합하다. |

실시간 상태는 DB에 전부 저장하지 않는다. 최종 기록에 필요한 이벤트만 PostgreSQL에 남기고, 화면 표시용 임시 상태는 Redis에 둔다.

### 7.6 검색, 추천, AI

| 기술 | ONMU에서 쓰는 위치 | 처리하는 것 | 선택 이유 |
| --- | --- | --- | --- |
| PostgreSQL Full Text/Search | 초기 검색 | 장소명, 태그, 기록 제목, 메모 검색 | 초기에는 별도 검색 엔진 없이 단순하게 시작한다. |
| Azure AI Search | 확장 검색/RAG | 기록 검색, 취향 기반 후보 검색, AI 답변 근거 검색 | 발표용 AI/RAG 확장성과 운영형 검색 구조를 보여줄 수 있다. |
| Azure OpenAI | AI 기능 | 추천 설명 생성, OOTD/기록 문장 생성, 장소 선택 이유 요약 | 단순 점수보다 사용자가 납득할 수 있는 설명을 만든다. |
| FastAPI Worker | AI 호출 중간 계층 | prompt 구성, 결과 검증, fallback, 비용 제어 | 모바일 앱이나 Spring API가 AI 모델을 직접 호출하지 않게 한다. |

Azure OpenAI는 의사결정을 대신하는 도구가 아니라 설명과 보조 판단을 만드는 계층으로 둔다. 장소 후보 점수 자체는 취향, 거리, 시간, 휴무, 정산/모임 유형 같은 구조화 데이터와 함께 계산한다.

### 7.7 외부 API

| 기술 | ONMU에서 쓰는 위치 | 처리하는 것 | 선택 이유 |
| --- | --- | --- | --- |
| Naver Maps/Place API | 장소 도메인 | 장소 검색, 좌표, 카테고리, 주소, 지도 표시용 데이터 | 국내 장소 데이터와 사용자 친숙도가 높다. |
| 외부 공지/휴무 정보 | 장소 리스크 판단 | 휴무일, 브레이크타임, 공지성 정보 | 장소 선택 실패를 줄이기 위한 보조 데이터다. |
| Kakao/Instagram 공유 | Share 도메인 | 공유 카드, 이미지 저장, 외부 공유 | 기록/라이프로그의 확산과 재방문을 유도한다. |

외부 API 응답은 그대로 믿지 않고, 캐시 시간과 출처를 함께 저장한다. 장애가 나면 최근 캐시 또는 수동 입력으로 fallback한다.

### 7.8 보안과 운영

| 기술 | ONMU에서 쓰는 위치 | 처리하는 것 | 선택 이유 |
| --- | --- | --- | --- |
| Azure Front Door WAF 또는 Application Gateway WAF | 외부 진입 경계 | 웹 공격 차단, TLS, routing | 인터넷에서 들어오는 요청의 첫 방어선이다. |
| Azure API Management | API 정책 계층 | rate limit, 인증 검증, API versioning, 외부 노출 제어 | 모바일 앱과 백엔드 사이의 정책을 한 곳에서 관리한다. |
| Azure Key Vault | 비밀값 저장 | DB 비밀번호, Naver API key, Azure OpenAI key, JWT secret | 비밀값을 코드, GitHub, Jira, Notion에 남기지 않는다. |
| Managed Identity | Azure 리소스 간 인증 | 앱이 Key Vault, Storage 등에 접근 | 비밀번호 없는 리소스 접근을 목표로 한다. |
| Azure Monitor/Application Insights | 관측성 | API latency, error rate, trace, dependency call, worker 실패 | 발표에서 운영 가능한 서비스라는 근거가 된다. |
| OpenTelemetry | 서비스 간 trace | Flutter 요청에서 API, worker, DB까지 흐름 추적 | 장애 원인을 서비스 경계별로 찾기 쉽다. |

보안 설명의 핵심은 `민감 데이터는 DB/Storage에 분리 저장하고, 접근은 인증/인가/API 정책/Key Vault로 통제한다`는 것이다.

### 7.9 배포와 인프라

| 기술 | ONMU에서 쓰는 위치 | 처리하는 것 | 선택 이유 |
| --- | --- | --- | --- |
| Docker Compose | 로컬 개발 | Spring Boot, FastAPI, PostgreSQL, Redis, MinIO 실행 | 팀원 개발 환경을 맞추고 Windows 개발 서버로 옮기기 쉽다. |
| Azure Container Apps | Staging 후보 | 컨테이너 API/Worker 배포 | AKS보다 운영 부담이 낮아 빠른 검증에 좋다. |
| AKS | Production 목표 아키텍처 | 서비스, Ingress, Secret, autoscale, observability | 최종 발표에서 Kubernetes 운영 설계를 보여줄 수 있다. |
| Terraform | IaC | Azure 리소스 생성, 네트워크, DB, Storage, monitoring | 로컬에서 클라우드로 옮길 때 환경을 반복 가능하게 만든다. |
| GitHub Actions | CI/CD | lint, test, build, Docker image, deploy, PR check | Jira/GitHub workflow와 연결해 협업 기준을 만든다. |
| Dependabot | 의존성 관리 | GitHub Actions, npm, Flutter pub, Gradle/Maven 업데이트 | public 저장소에서 보안 업데이트를 놓치지 않는다. |

개발 순서는 `Docker Compose로 로컬 통합 -> Windows 개발 서버로 팀 테스트 -> Container Apps staging -> AKS 목표 구조`가 가장 현실적이다.

## 8. 기능 피드백을 아키텍처에 반영하는 방법

| 피드백 | 아키텍처 반영 |
| --- | --- |
| 모임통장/N분의 1 정산 | `Settlement` 도메인 추가, 비용 입력/분담금/입금 상태를 PostgreSQL 트랜잭션으로 관리 |
| 공개/비공개/공유 범위 | `Privacy` 또는 `VisibilityPolicy` 테이블 추가, API 응답마다 권한 필터 적용 |
| 기존 앱과의 차별점 | 카카오톡/지도/캘린더/사진첩/정산 앱에 흩어진 흐름을 하나의 이벤트 흐름으로 설명 |
| Azure 중심 아키텍처 | API Management, Key Vault, Azure Monitor, Azure OpenAI, Azure Database for PostgreSQL을 중심에 배치 |
| 외부 API 경계 | Naver API와 공유 채널은 외부 영역으로 분리하고, 캐시/장애/fallback 정책을 명시 |
| 보안 경계 | WAF, 인증, API 정책, 비밀값 관리, private network, 로그 마스킹을 별도 계층으로 표시 |

## 9. 지금 바로 추가하면 좋은 도메인

현재 도메인 경계에 아래 세 가지를 추가하면 피드백 반영력이 좋아진다.

| 도메인 | 책임 |
| --- | --- |
| Settlement | 모임 총비용, 참여자별 분담금, 입금 상태, 정산 완료 여부 |
| Privacy | 기록 공개 범위, 항목별 공개 여부, 외부 공유 정책 |
| Share | 카카오톡 공유 카드, 인스타그램 저장 이미지, 공유 링크 |

초기 구현 범위는 작게 잡는다.

1. 모임별 총비용 입력
2. 참여자별 N분의 1 자동 계산
3. 참여자별 정산 상태 체크
4. 기록 상세 화면에 정산 요약 표시
5. 기록 공개 범위 `나만 보기`, `참여자만 보기`, `외부 공유용 이미지`부터 지원

## 10. 발표용 한 장 요약 문구

발표에서는 기술을 나열하기보다 아래 흐름으로 설명한다.

```text
Flutter 앱에서 약속과 취향, 장소 후보, 사진, 정산 정보를 입력한다.
Spring Boot API가 도메인 트랜잭션과 권한을 처리하고,
PostgreSQL/PostGIS가 약속/장소/정산/공개 범위를 저장한다.
FastAPI Worker는 Azure OpenAI와 장소 데이터를 활용해 추천과 기록 설명을 생성한다.
Azure API Management, WAF, Key Vault, Monitor가 보안과 운영 경계를 담당한다.
Naver Place API와 공유 채널은 외부 API 경계로 분리한다.
```

## 11. 아직 결정해야 할 것

| 결정 항목 | 추천 기본값 | 나중에 바꿀 수 있는 대안 |
| --- | --- | --- |
| 운영 컴퓨트 | Staging은 Container Apps, Production 목표는 AKS | 비용/운영 부담이 크면 Production도 Container Apps |
| 인증 제공자 | Entra External ID를 기준으로 설계하고 provider 추상화 | Firebase Auth, Kakao/Naver OAuth 직접 연동 |
| 검색 엔진 | PostgreSQL 검색으로 시작 | Azure AI Search, OpenSearch |
| 이벤트 브로커 | Service Bus로 시작 | Kafka 호환성이 필요하면 Event Hubs |
| 정산 범위 | 기록형 정산 상태 관리 | 실제 결제/송금 연동은 Toss Payments/PortOne 등 별도 검토 |

## 12. 공식 참고 문서

- [Azure Container Apps documentation](https://learn.microsoft.com/azure/container-apps/services)
- [What is Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/what-is-aks)
- [Azure API Management authentication and authorization](https://learn.microsoft.com/en-us/azure/api-management/authentication-authorization-overview)
- [Azure Database for PostgreSQL Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-deploy-on-azure-free-account)
- [Azure Event Hubs](https://learn.microsoft.com/en-ca/azure/event-hubs/event-hubs-about)
- [Azure Service Bus](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview)
- [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/)
- [Azure Monitor Application Insights with OpenTelemetry](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry)
- [Azure AI Search vector search](https://learn.microsoft.com/en-us/azure/search/vector-search-overview)
- [Azure OpenAI in Azure AI Foundry Models](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
- [Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-overview)
- [Microsoft Entra External ID](https://learn.microsoft.com/en-us/entra/external-id/external-identities-overview)
