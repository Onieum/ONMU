class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.lastMessage,
    required this.unreadCount,
    required this.pinnedPlanTitle,
  });

  final int id;
  final String name;
  final String description;
  final List<String> members;
  final String lastMessage;
  final int unreadCount;
  final String pinnedPlanTitle;
}

class GroupPinnedPlan {
  const GroupPinnedPlan({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.placeName,
    required this.statusLabel,
    required this.voteSummary,
  });

  final int id;
  final String title;
  final String dateLabel;
  final String placeName;
  final String statusLabel;
  final String voteSummary;
}

class GroupPlanSummary {
  const GroupPlanSummary({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.placeName,
    required this.statusLabel,
    required this.statusType,
    required this.memberCount,
    required this.extraMemberCount,
    required this.iconKind,
    required this.isPast,
  });

  final int id;
  final String title;
  final String dateLabel;
  final String placeName;
  final String statusLabel;
  final String statusType;
  final int memberCount;
  final int extraMemberCount;
  final String iconKind;
  final bool isPast;
}

class GroupMessage {
  const GroupMessage({
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

class GroupMemoryRecord {
  const GroupMemoryRecord({
    required this.id,
    required this.author,
    required this.title,
    required this.description,
    required this.dateLabel,
    required this.tags,
  });

  final int id;
  final String author;
  final String title;
  final String description;
  final String dateLabel;
  final List<String> tags;
}

class VoteCard {
  const VoteCard({
    required this.title,
    required this.summary,
    required this.statusLabel,
    required this.actionLabel,
  });

  final String title;
  final String summary;
  final String statusLabel;
  final String actionLabel;
}

class GroupMemberProfile {
  const GroupMemberProfile({
    required this.name,
    required this.note,
    required this.statusLabel,
    this.invited = false,
  });

  final String name;
  final String note;
  final String statusLabel;
  final bool invited;
}

const mockGroups = [
  GroupSummary(
    id: 1,
    name: '대학 동기 여행단',
    description: '우리, 또 하나의 추억을 만들자',
    members: ['지민', '민수', '소연', '현우', '준호', '혜진', '나', '지훈'],
    lastMessage: '제주도 준비물 체크리스트를 고정해뒀어요.',
    unreadCount: 3,
    pinnedPlanTitle: '제주도 여행 D-7',
  ),
  GroupSummary(
    id: 2,
    name: '퇴근 후 러닝크루',
    description: '여의도 한강공원에서 뛰고 기록을 남겨요',
    members: ['서윤', '도윤', '나', '하린', '민재'],
    lastMessage: '오늘은 19:30 출발로 맞춰둘게.',
    unreadCount: 1,
    pinnedPlanTitle: '금요일 러닝 D-2',
  ),
  GroupSummary(
    id: 3,
    name: '보드게임 모임',
    description: '홍대 보드게임카페 후보를 투표 중이에요',
    members: ['민서', '지훈', '나', '하린', '도윤', '서윤'],
    lastMessage: '온무식당 쪽으로 저녁 먼저 먹고 갈까?',
    unreadCount: 2,
    pinnedPlanTitle: '일요일 보드게임 D-4',
  ),
];

const mockPinnedPlan = GroupPinnedPlan(
  id: 101,
  title: '제주도 여행',
  dateLabel: '6.7(토) - 6.9(월)',
  placeName: '제주도 일대',
  statusLabel: 'D-12',
  voteSummary: '4명 참여',
);

const mockGroupPlans = [
  GroupPlanSummary(
    id: 101,
    title: '제주도 여행',
    dateLabel: '6.7 (금) - 6.9 (일)',
    placeName: '제주도 일대',
    statusLabel: 'D-12',
    statusType: '진행중',
    memberCount: 6,
    extraMemberCount: 2,
    iconKind: 'water',
    isPast: false,
  ),
  GroupPlanSummary(
    id: 102,
    title: '한남 카페 투어',
    dateLabel: '6.5 (수) 오후 2:00',
    placeName: '한남동 일대',
    statusLabel: 'D-2',
    statusType: '예정',
    memberCount: 5,
    extraMemberCount: 1,
    iconKind: 'coffee',
    isPast: false,
  ),
  GroupPlanSummary(
    id: 104,
    title: '홍대 전시회 구경',
    dateLabel: '6.12 (수) 오후 2:00',
    placeName: '홍대 일대',
    statusLabel: 'D-4',
    statusType: '예정',
    memberCount: 3,
    extraMemberCount: 0,
    iconKind: 'gallery',
    isPast: false,
  ),
  GroupPlanSummary(
    id: 105,
    title: '성수 디저트 모임',
    dateLabel: '6.17 (월) 오후 7:00',
    placeName: '성수동',
    statusLabel: 'D-17',
    statusType: '예정',
    memberCount: 3,
    extraMemberCount: 0,
    iconKind: 'coffee',
    isPast: false,
  ),
  GroupPlanSummary(
    id: 103,
    title: '한강 피크닉',
    dateLabel: '5.10 (금) 오후 1:00',
    placeName: '여의도 한강공원',
    statusLabel: '완료',
    statusType: '완료',
    memberCount: 4,
    extraMemberCount: 0,
    iconKind: 'park',
    isPast: true,
  ),
];

const mockGroupMemberProfiles = [
  GroupMemberProfile(name: '지연', note: '여행 가이드 준비 중이에요', statusLabel: '참여 중'),
  GroupMemberProfile(name: '민수', note: '맛집 리스트 정리 중!', statusLabel: '참여 중'),
  GroupMemberProfile(name: '하린', note: '렌터카 비교해봤어요', statusLabel: '참여 중'),
  GroupMemberProfile(name: '현우', note: '숙소 후보 찾아보는 중', statusLabel: '참여 중'),
  GroupMemberProfile(name: '소연', note: '카페 투어 코스 짜는 중', statusLabel: '참여 중'),
  GroupMemberProfile(
    name: '재훈',
    note: '사진 스팟 모아두었어요',
    statusLabel: '초대됨',
    invited: true,
  ),
  GroupMemberProfile(
    name: '은지',
    note: '함께하고 싶어요!',
    statusLabel: '초대됨',
    invited: true,
  ),
  GroupMemberProfile(
    name: '태호',
    note: '이번엔 꼭 참석할게요!',
    statusLabel: '초대됨',
    invited: true,
  ),
];

const mockGroupMessages = [
  GroupMessage(
    sender: '지민',
    message: '다들 안녕! 드디어 다음 주에 제주도네 날씨도 좋아 보이더라구.',
    timeLabel: '오전 9:21',
    isMine: false,
  ),
  GroupMessage(
    sender: '나',
    message: '기대된다아 ㅎㅎ',
    timeLabel: '오전 9:22',
    isMine: true,
  ),
  GroupMessage(
    sender: '현우',
    message: '항공권 모바일 체크인 했어! 좌석도 다 같이 앉도록 해봤음 ㅎㅎ',
    timeLabel: '오전 9:24',
    isMine: false,
  ),
  GroupMessage(
    sender: 'ONMU',
    message: '장소 후보가 3개 모였어요. 필요하면 투표를 만들어 함께 정해요.',
    timeLabel: '오전 9:25',
    isMine: false,
  ),
];

const mockVoteCard = VoteCard(
  title: '제주도 여행 장소 투표',
  summary: '카페 오션뷰, 흑돼지 맛집 돈사돈, 협재 해수욕장 후보를 비교 중이에요.',
  statusLabel: '수동 투표 · 진행 중',
  actionLabel: '투표 보기',
);

const mockGroupMemories = [
  GroupMemoryRecord(
    id: 1001,
    author: '지연',
    title: '성수동 카페',
    description: '분위기 좋은 카페 발견! 디저트도 너무 맛있었어요.',
    dateLabel: '2024.05.24',
    tags: ['카페', '사진', '디저트'],
  ),
  GroupMemoryRecord(
    id: 1002,
    author: '민수',
    title: '제주 바다',
    description: '바다 색이 진짜 예뻤던 날.',
    dateLabel: '2024.05.16',
    tags: ['여행', '사진', '바다'],
  ),
  GroupMemoryRecord(
    id: 1003,
    author: '하린',
    title: '전시회 다녀왔어요',
    description: '조용히 둘러보기 좋았던 전시.',
    dateLabel: '2024.05.10',
    tags: ['기타', '기록', '전시'],
  ),
  GroupMemoryRecord(
    id: 1004,
    author: '현우',
    title: '한강 피크닉',
    description: '다음에도 같이 가자!',
    dateLabel: '2024.05.10',
    tags: ['여행', '사진', '피크닉'],
  ),
];
