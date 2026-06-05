# Flutter UI QA 체크리스트

## 기준 viewport

최근 화면 검수 기준은 iPhone 17 크기 `402 x 874`이다.

| 항목 | 값 |
| --- | --- |
| width | 402 |
| height | 874 |
| device scale factor | 1 |

## 반복 확인 화면

```text
/home
/home/upcoming-plans
/home/notifications
/groups
/groups/friends
/groups/friends/chat
/groups/friends/memories
/groups/friends/plans/demo
/groups/friends/plans/demo/place-candidates
/groups/friends/plans/demo/place-search
/groups/friends/plans/demo/settlements/new
/groups/friends/plans/demo/settlements/lunch-split
/records
/my
```

## 레이아웃 체크

- 마스킹 테이프, 배지, chip이 삐뚤어져 보이지 않는가?
- 텍스트가 카드 밖으로 넘치지 않는가?
- 하단바와 FAB가 겹치지 않는가?
- bottom sheet를 확장/축소할 수 있는가?
- 뒤로가기 버튼이 필요한 상세 화면에 존재하는가?
- 8px spacing 기준에서 요소가 어색하게 붙어 있지 않은가?

## 디자인 체크

- 기본 배경은 흰색인가?
- 하단바는 과하게 진한 배경이 아닌가?
- 코랄/핑크 포인트가 일관적인가?
- 장소/정산처럼 정보 중심 화면에서 장식이 정보를 방해하지 않는가?
- 기록 화면은 스크랩북 감성이 있으면서도 카드가 정렬되어 있는가?

## 테스트 연결

- route smoke는 widget test로 먼저 확인한다.
- 시각 깨짐은 browser screenshot smoke 또는 golden test로 보강한다.
- UI QA에서 반복 발견된 깨짐은 재현 route와 viewport를 문서에 남긴다.
