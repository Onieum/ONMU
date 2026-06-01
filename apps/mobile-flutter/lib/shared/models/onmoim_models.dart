class OnMoimGroup {
  const OnMoimGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.lastMessage,
    required this.unreadCount,
    required this.pinnedMeetupTitle,
  });

  final String id;
  final String name;
  final String description;
  final List<String> members;
  final String lastMessage;
  final int unreadCount;
  final String pinnedMeetupTitle;
}

class OnMoimPinnedMeetup {
  const OnMoimPinnedMeetup({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.placeName,
    required this.statusLabel,
    required this.voteSummary,
  });

  final String id;
  final String title;
  final String dateLabel;
  final String placeName;
  final String statusLabel;
  final String voteSummary;
}

class OnMoimMessage {
  const OnMoimMessage({
    required this.sender,
    required this.message,
    required this.timeLabel,
    required this.isMine,
  });

  final String sender;
  final String message;
  final String timeLabel;
  final bool isMine;
}

class OnMoimMemoryRecord {
  const OnMoimMemoryRecord({
    required this.title,
    required this.description,
    required this.dateLabel,
    required this.tags,
  });

  final String title;
  final String description;
  final String dateLabel;
  final List<String> tags;
}

const demoOnMoimGroups = [
  OnMoimGroup(
    id: 'friends',
    name: '대학 동기 여행단',
    description: '우리, 또 하나의 추억을 만들자',
    members: ['지민', '민수', '소연', '현우', '준호', '혜진', '나', '지훈'],
    lastMessage: '제주도 준비물 체크리스트를 고정해뒀어요.',
    unreadCount: 3,
    pinnedMeetupTitle: '제주도 여행 D-7',
  ),
  OnMoimGroup(
    id: 'office',
    name: '퇴근 후 러닝크루',
    description: '여의도 한강공원에서 뛰고 기록을 남겨요',
    members: ['서윤', '도윤', '나', '하린', '민재'],
    lastMessage: '오늘은 19:30 출발로 맞춰둘게.',
    unreadCount: 1,
    pinnedMeetupTitle: '금요일 러닝 D-2',
  ),
  OnMoimGroup(
    id: 'board',
    name: '보드게임 모임',
    description: '홍대 보드게임카페 후보를 투표 중이에요',
    members: ['민서', '지훈', '나', '하린', '도윤', '서윤'],
    lastMessage: '온무식당 쪽으로 저녁 먼저 먹고 갈까?',
    unreadCount: 2,
    pinnedMeetupTitle: '일요일 보드게임 D-4',
  ),
];

const demoPinnedMeetup = OnMoimPinnedMeetup(
  id: 'demo',
  title: '제주도 여행',
  dateLabel: '6.7(토) - 6.9(월)',
  placeName: '부산 해운대 출발',
  statusLabel: '장소 투표 진행 중',
  voteSummary: '온무식당 5표 · 무드카페 3표 · 하루정원 1표',
);

const demoOnMoimMessages = [
  OnMoimMessage(
    sender: '지민',
    message: '다들 안녕! 드디어 다음 주에 제주도네 날씨도 좋아 보이더라구.',
    timeLabel: '오전 9:21',
    isMine: false,
  ),
  OnMoimMessage(
    sender: '나',
    message: '기대된다아 ㅎㅎ',
    timeLabel: '오전 9:22',
    isMine: true,
  ),
  OnMoimMessage(
    sender: '현우',
    message: '항공권 모바일 체크인 했어! 좌석도 다 같이 앉도록 해봤음 ㅎㅎ',
    timeLabel: '오전 9:24',
    isMine: false,
  ),
  OnMoimMessage(
    sender: 'ONMU',
    message: '장소 투표 마감이 D-1이에요. 최종 장소를 확정해보세요.',
    timeLabel: '오전 9:25',
    isMine: false,
  ),
];

const demoOnMoimMemories = [
  OnMoimMemoryRecord(
    title: '협재 해수욕장',
    description: '진짜 바다 색이 미쳤다...',
    dateLabel: '제주 여행',
    tags: ['사진', '바다', '친구'],
  ),
  OnMoimMemoryRecord(
    title: '석양 맛집 인정!',
    description: '분위기 최고였던 카페 기록',
    dateLabel: '지난 모임',
    tags: ['사진', '카페', '기록'],
  ),
  OnMoimMemoryRecord(
    title: '흑돼지 맛집',
    description: '목살이 진짜 부드러웠어요.',
    dateLabel: '저녁 기록',
    tags: ['음식', '맛집', '공유'],
  ),
  OnMoimMemoryRecord(
    title: '이런 여행 너무 즐거웠어',
    description: '다음엔 어디로 갈까?',
    dateLabel: 'Day 2',
    tags: ['기록', '친구', '추억'],
  ),
];
