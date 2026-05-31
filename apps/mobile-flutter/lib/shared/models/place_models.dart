class PlaceCandidate {
  const PlaceCandidate({
    required this.id,
    required this.name,
    required this.category,
    required this.summary,
    required this.score,
    required this.matchPercent,
    required this.distanceLabel,
    required this.travelTimeLabel,
    required this.priceLabel,
    required this.isOpen,
    required this.tags,
    required this.reasons,
    required this.risks,
  });

  final String id;
  final String name;
  final String category;
  final String summary;
  final double score;
  final int matchPercent;
  final String distanceLabel;
  final String travelTimeLabel;
  final String priceLabel;
  final bool isOpen;
  final List<String> tags;
  final List<String> reasons;
  final List<String> risks;
}

class PlaceVoteResult {
  const PlaceVoteResult({
    required this.title,
    required this.selectedPlaceName,
    required this.voters,
    required this.note,
  });

  final String title;
  final String selectedPlaceName;
  final List<String> voters;
  final String note;
}

class PlaceRisk {
  const PlaceRisk({
    required this.title,
    required this.description,
    required this.level,
    required this.actionLabel,
  });

  final String title;
  final String description;
  final PlaceRiskLevel level;
  final String actionLabel;
}

enum PlaceRiskLevel { notice, warning, blocker }

const demoPlaceCandidates = [
  PlaceCandidate(
    id: 'cafe-moon',
    name: '카페 문라이트',
    category: '디저트 카페',
    summary: '조용한 좌석과 넓은 테이블이 있어 네 명이 오래 이야기하기 좋아요.',
    score: 4.8,
    matchPercent: 96,
    distanceLabel: '성수역 도보 6분',
    travelTimeLabel: '평균 18분',
    priceLabel: '1인 12,000원대',
    isOpen: true,
    tags: ['조용함', '디저트', '사진 잘 나옴'],
    reasons: ['민서의 조용한 카페 취향과 맞아요.', '지훈이 싫어하는 매운 메뉴가 없어요.', '브레이크타임 없이 운영해요.'],
    risks: ['주말 3시 이후 웨이팅 가능'],
  ),
  PlaceCandidate(
    id: 'pasta-room',
    name: '파스타룸 소소',
    category: '이탈리안',
    summary: '예약 가능한 테이블과 쉬운 동선이 장점인 캐주얼 식당이에요.',
    score: 4.5,
    matchPercent: 89,
    distanceLabel: '뚝섬역 도보 4분',
    travelTimeLabel: '평균 21분',
    priceLabel: '1인 18,000원대',
    isOpen: true,
    tags: ['예약 가능', '파스타', '역 근처'],
    reasons: ['참여자 이동 시간이 고르게 분산돼요.', '채식 옵션이 있어요.', '예약 링크를 바로 공유할 수 있어요.'],
    risks: ['라스트오더 20:30'],
  ),
  PlaceCandidate(
    id: 'garden-table',
    name: '가든 테이블',
    category: '브런치',
    summary: '분위기는 좋지만 일부 비선호 키워드가 겹쳐 확인이 필요해요.',
    score: 4.1,
    matchPercent: 78,
    distanceLabel: '서울숲 도보 9분',
    travelTimeLabel: '평균 27분',
    priceLabel: '1인 22,000원대',
    isOpen: false,
    tags: ['브런치', '테라스', '감성'],
    reasons: ['사진 기록과 잘 어울리는 공간이에요.', 'OOTD 기록 장소로 쓰기 좋아요.', '근처 산책 코스가 있어요.'],
    risks: ['월요일 휴무', '견과류 메뉴 많음'],
  ),
];

const demoPlaceVoteResult = PlaceVoteResult(
  title: '온챗 투표 결과',
  selectedPlaceName: '카페 문라이트',
  voters: ['민서', '지훈', '하린'],
  note: '온챗에서 3명이 조용한 카페에 투표했어요. 후보 상단에 이어서 보여줍니다.',
);

const demoPlaceRisks = [
  PlaceRisk(
    title: '가든 테이블 월요일 휴무',
    description: '후보 중 한 곳이 약속 후보일에 쉬어요. 다른 날짜나 후보를 먼저 보는 게 좋아요.',
    level: PlaceRiskLevel.blocker,
    actionLabel: '후보에서 낮추기',
  ),
  PlaceRisk(
    title: '카페 문라이트 웨이팅 가능',
    description: '주말 오후 3시 이후 대기 가능성이 있어요. 예약 가능 여부를 확인해보세요.',
    level: PlaceRiskLevel.warning,
    actionLabel: '예약 확인',
  ),
  PlaceRisk(
    title: '견과류 메뉴 확인 필요',
    description: '참여자 비선호 키워드와 일부 메뉴가 겹쳐 주문 전 확인이 필요해요.',
    level: PlaceRiskLevel.notice,
    actionLabel: '메뉴 보기',
  ),
];

PlaceCandidate findPlaceCandidate(String id) {
  return demoPlaceCandidates.firstWhere(
    (candidate) => candidate.id == id,
    orElse: () => demoPlaceCandidates.first,
  );
}
