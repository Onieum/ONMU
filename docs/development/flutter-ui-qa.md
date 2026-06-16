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

## Android smoke 환경 기준

Windows Android emulator에서 Flutter debug APK를 빌드할 때는 Android Studio JBR 21을 우선 사용한다. JDK 25가 먼저 잡히면 Gradle/Flutter build 중 `can't find system classes` 또는 `Unable to find package java.lang in platform classes` 계열 오류가 날 수 있다.

권장 PowerShell 설정 예시:

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
java -version
```

채팅이나 검색 입력 자동화를 수행할 때는 emulator 입력기를 영문 입력 상태로 맞춘다. 한글 입력기가 활성화되어 있으면 ASCII 자동 입력이 한글 자모처럼 변환되어, 메시지 내용 검증과 screenshot 판독이 흔들릴 수 있다. 메시지 내용 자체보다 전송 흐름을 검증할 때도 입력기 상태를 보고서에 남긴다.
