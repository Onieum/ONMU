# Mock to API Migration

## 목적

Flutter 화면이 mock data에 직접 묶여 있는 상태에서 실제 API로 이동할 때의 단계와 책임을 정리한다.

## 원칙

- View에서 mock list를 직접 import하지 않는다.
- 화면별 read model을 먼저 정의한다.
- mock repository와 API repository가 같은 contract를 구현한다.
- API 전환 전 widget test는 mock repository로 유지한다.

## 전환 단계

| 단계 | 작업 |
| --- | --- |
| 1 | 현재 mock model과 화면 사용 위치를 찾는다. |
| 2 | 화면 단위 read model을 정의한다. |
| 3 | repository interface를 만든다. |
| 4 | 기존 mock data를 mock repository로 옮긴다. |
| 5 | ViewModel이 repository를 통해 상태를 만든다. |
| 6 | API DTO mapper를 추가한다. |
| 7 | provider override로 mock/API repository를 바꿀 수 있게 한다. |

## 우선 전환 대상

1. Home summary
2. Group list/detail
3. Plan list/detail
4. Place candidate/search
5. Settlement draft/preview/result
6. Chat activity
7. Notification

## 검증

- repository 단위 테스트
- mapper 단위 테스트
- 주요 route widget test
- API contract fixture 테스트
