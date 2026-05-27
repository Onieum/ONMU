# Architecture Update Skill

## 언제 사용하나

회의 피드백, 기술 스택 변경, Azure/AWS 인프라 결정, 보안 경계 변경을 ONMU 아키텍처 문서와 다이어그램에 반영할 때 사용한다.

## 반드시 먼저 읽을 문서

1. `docs/architecture/current-architecture-diagram.md`
2. `docs/architecture/release-architecture.md`
3. `docs/development/team-ai-tooling.md`
4. `docs/operations/windows-backend-server.md`
5. `AGENTS.md`

## 작업 순서

1. 새 피드백이나 변경 요구를 요약한다.
2. 제품 기능 변경인지, 인프라 변경인지, 보안 변경인지 분류한다.
3. Mermaid 다이어그램을 먼저 수정한다.
4. PNG/SVG 산출물이 필요한 경우 `docs/architecture/assets`에 다시 생성한다.
5. 기술 스택 표와 도메인 경계 표를 함께 갱신한다.
6. 공식 문서 링크가 필요한 기술은 출처를 확인해 추가한다.
7. 로컬 링크와 이미지 경로를 검증한다.

## ONMU 아키텍처 기본 원칙

- Azure는 핵심 운영 영역으로 둔다.
- AWS는 백업, 정적 자산, 보조 자동화, 실험 영역으로 둔다.
- Naver API는 장소/지도 외부 데이터 영역으로 분리한다.
- DB와 Redis는 핵심 API와 같은 클라우드에 둔다.
- 외부 API, AI, Storage, Queue는 보안 경계를 명시한다.

## 완료 기준

- 아키텍처 그림에서 클라이언트, Azure, AWS, Naver, 외부 API, 오픈소스 경계가 구분된다.
- 데이터 소스와 처리 흐름이 설명된다.
- 보안 경계와 secret 관리 기준이 빠지지 않는다.
- 발표용 한 장 요약 문구가 최신 상태다.
