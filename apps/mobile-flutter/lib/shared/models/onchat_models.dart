class OnChatGroup {
  const OnChatGroup({
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

class OnChatPinnedMeetup {
  const OnChatPinnedMeetup({
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

class OnChatMessage {
  const OnChatMessage({
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

class OnChatMemoryRecord {
  const OnChatMemoryRecord({
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

const demoOnChatGroups = [
  OnChatGroup(
    id: 'friends',
    name: '성수 토요일 멤버',
    description: '디저트, 산책, OOTD 기록을 같이 남기는 온챗',
    members: ['민서', '지훈', '하린', '나'],
    lastMessage: '카페 문라이트 쪽이 제일 편해 보여!',
    unreadCount: 3,
    pinnedMeetupTitle: '토요일 오후 성수 모임',
  ),
  OnChatGroup(
    id: 'office',
    name: '퇴근 후 전시팀',
    description: '전시 보고 저녁까지 이어지는 약속방',
    members: ['서윤', '도윤', '나'],
    lastMessage: '정산은 내가 먼저 올려둘게.',
    unreadCount: 0,
    pinnedMeetupTitle: '목요일 한남 전시',
  ),
];

const demoPinnedMeetup = OnChatPinnedMeetup(
  id: 'demo',
  title: '토요일 오후 성수 모임',
  dateLabel: '6월 6일 토요일 15:00',
  placeName: '카페 문라이트 후보 1순위',
  statusLabel: '장소 투표 진행 중',
  voteSummary: '카페 문라이트 3표 · 파스타룸 소소 1표',
);

const demoOnChatMessages = [
  OnChatMessage(
    sender: '민서',
    message: '이번엔 너무 시끄럽지 않은 곳이면 좋겠어.',
    timeLabel: '14:12',
    isMine: false,
  ),
  OnChatMessage(
    sender: '나',
    message: '그럼 조용한 카페 후보 위주로 다시 볼게.',
    timeLabel: '14:13',
    isMine: true,
  ),
  OnChatMessage(
    sender: '하린',
    message: '사진도 남기고 싶어서 밝은 자리면 더 좋아.',
    timeLabel: '14:14',
    isMine: false,
  ),
  OnChatMessage(
    sender: 'ONMU',
    message: '카페 문라이트가 취향 96%, 이동 평균 18분으로 가장 잘 맞아요.',
    timeLabel: '14:15',
    isMine: false,
  ),
];

const demoOnChatMemories = [
  OnChatMemoryRecord(
    title: '성수 카페 룩',
    description: '보라 니트와 데님을 입고 남긴 토요일 기록',
    dateLabel: '지난 모임',
    tags: ['OOTD', '카페', '친구'],
  ),
  OnChatMemoryRecord(
    title: '서울숲 산책',
    description: '날씨가 좋아서 예정에 없던 산책까지 이어졌어요.',
    dateLabel: '4월 20일',
    tags: ['산책', '사진', '봄'],
  ),
];
