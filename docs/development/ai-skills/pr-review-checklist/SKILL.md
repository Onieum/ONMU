# PR Review Checklist Skill

## 언제 사용하나

ONMU Pull Request를 리뷰하거나, PR을 만들기 전에 자체 점검할 때 사용한다.

## 반드시 먼저 읽을 문서

1. `docs/development/git-workflow.md`
2. `.github/pull_request_template.md`
3. `.github/copilot-instructions.md`
4. `AGENTS.md`

## 리뷰 우선순위

1. 버그와 데이터 손상 가능성
2. 보안/secret/개인정보 노출
3. 아키텍처 경계 위반
4. 디자인 시스템 위반
5. 테스트 누락
6. 문서 누락

## Flutter PR 확인 항목

- 색상, 간격, typography가 디자인 시스템을 따른다.
- 공통 컴포넌트를 재사용한다.
- 화면 상태와 서버 상태가 분리되어 있다.
- iPhone 17 계열 세로 화면에서 overflow가 없다.
- `flutter analyze`와 관련 test 결과가 PR에 적혀 있다.

## 백엔드 PR 확인 항목

- API 계약이 문서나 OpenAPI와 맞다.
- 트랜잭션 경계가 명확하다.
- migration이 안전하다.
- 외부 API 실패 시 fallback 또는 에러 처리가 있다.
- 민감 데이터가 로그에 남지 않는다.

## 인프라 PR 확인 항목

- secret이 코드나 문서에 없다.
- Azure/AWS 리소스 이름과 환경 구분이 명확하다.
- 비용이 커질 수 있는 리소스는 설명이 있다.
- 삭제/교체 위험이 있는 변경은 별도 경고가 있다.

## 리뷰 출력 형식

문제가 있으면 심각도 순으로 작성한다.

```text
## Findings

- [P1] 파일:라인 - 문제 요약
  설명과 수정 제안

## Questions

- 확인이 필요한 질문

## Summary

- 전체 판단
```

문제가 없으면 "주요 문제 없음"이라고 명확히 쓰고, 남은 테스트 공백만 짧게 남긴다.
