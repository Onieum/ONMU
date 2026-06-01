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
    required this.address,
    required this.openingLabel,
    required this.sourceLabel,
    required this.riskLabel,
    required this.riskTone,
    required this.memberFits,
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
  final String address;
  final String openingLabel;
  final String sourceLabel;
  final String riskLabel;
  final String riskTone;
  final List<MemberFit> memberFits;
  final List<String> tags;
  final List<String> reasons;
  final List<String> risks;
}

class MemberFit {
  const MemberFit({
    required this.label,
    required this.score,
    required this.note,
  });

  final String label;
  final int score;
  final String note;
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
    required this.evidence,
  });

  final String title;
  final String description;
  final PlaceRiskLevel level;
  final String actionLabel;
  final String evidence;
}

enum PlaceRiskLevel { notice, warning, blocker }

const demoPlaceCandidates = [
  PlaceCandidate(
    id: 'onmu-diner',
    name: '온무식당',
    category: '한식',
    summary: '영업중 · 브레이크타임 없음',
    score: 92,
    matchPercent: 88,
    distanceLabel: '홍대입구역 도보 7분',
    travelTimeLabel: '도보 7분',
    priceLabel: '1인 16,000원대',
    isOpen: true,
    address: '서울 마포구 와우산로 24',
    openingLabel: '오늘 11:30-21:00 · LO 20:30',
    sourceLabel: 'Kakao Places · 2시간 전 동기화',
    riskLabel: '안정',
    riskTone: 'none',
    memberFits: [
      MemberFit(label: 'A', score: 95, note: '조용한, 담백한'),
      MemberFit(label: 'B', score: 88, note: '한식, 웨이팅 짧음'),
      MemberFit(label: 'C', score: 91, note: '단체 가능'),
      MemberFit(label: 'D', score: 76, note: '매운 메뉴 적음'),
    ],
    tags: ['조용한', '한식', '단체가능'],
    reasons: [
      '평균 점수와 운영 안정성이 가장 높아요.',
      '약속 시간과 영업시간 충돌이 없어요.',
      '참여자 네 명 모두 76점 이상이에요.',
    ],
    risks: ['운영 리스크 없음'],
  ),
  PlaceCandidate(
    id: 'mood-cafe',
    name: '무드카페',
    category: '카페',
    summary: '라스트오더 19:30 임박',
    score: 84,
    matchPercent: 82,
    distanceLabel: '합정역 도보 5분',
    travelTimeLabel: '도보 5분',
    priceLabel: '1인 12,000원대',
    isOpen: true,
    address: '서울 마포구 독막로 17',
    openingLabel: '오늘 12:00-20:00 · LO 19:30',
    sourceLabel: 'Naver Places · 12일 전 동기화',
    riskLabel: '주의',
    riskTone: 'medium',
    memberFits: [
      MemberFit(label: 'A', score: 82, note: '디저트'),
      MemberFit(label: 'B', score: 91, note: '역 가까움'),
      MemberFit(label: 'C', score: 77, note: '뷰 좋은'),
      MemberFit(label: 'D', score: 70, note: '웨이팅 있음'),
    ],
    tags: ['디저트', '뷰좋은', '웨이팅'],
    reasons: [
      '합정역에서 가장 가까워요.',
      '디저트 취향 멤버에게 잘 맞아요.',
      '라스트오더까지 여유가 짧아 확인이 필요해요.',
    ],
    risks: ['라스트오더 충돌 가능성', '운영시간 정보 오래됨'],
  ),
  PlaceCandidate(
    id: 'daily-garden',
    name: '하루정원',
    category: '카페',
    summary: '마지막 동기화 12일 전',
    score: 79,
    matchPercent: 74,
    distanceLabel: '홍대입구역 도보 11분',
    travelTimeLabel: '도보 11분',
    priceLabel: '1인 14,000원대',
    isOpen: false,
    address: '서울 마포구 양화로 8',
    openingLabel: '영업시간 확인 필요',
    sourceLabel: 'Google Places · 12일 전 동기화',
    riskLabel: '확인필요',
    riskTone: 'unknown',
    memberFits: [
      MemberFit(label: 'A', score: 78, note: '디저트'),
      MemberFit(label: 'B', score: 73, note: '조용한'),
      MemberFit(label: 'C', score: 70, note: '사진맛집'),
      MemberFit(label: 'D', score: 66, note: '확인 필요'),
    ],
    tags: ['확인 필요', '뷰좋은', '디저트'],
    reasons: [
      '사진 기록과 잘 어울리는 공간이에요.',
      '디저트 선택지는 많지만 정보가 오래됐어요.',
      '방문 전 직접 확인이 필요해요.',
    ],
    risks: ['운영시간 정보 오래됨', '휴무일 가능성'],
  ),
];

const demoPlaceVoteResult = PlaceVoteResult(
  title: '온모임 투표 결과',
  selectedPlaceName: '온무식당',
  voters: ['민서', '지훈', '하린'],
  note: '온모임에서 3명이 안정적인 한식 장소에 투표했어요. 후보 상단에 이어서 보여줍니다.',
);

const demoPlaceRisks = [
  PlaceRisk(
    title: '라스트오더 충돌 가능성',
    description: '예상 도착 19:20, 라스트오더 19:30이라 여유 시간이 10분뿐이에요.',
    level: PlaceRiskLevel.blocker,
    actionLabel: '그래도 후보 추가',
    evidence: '지도 API · 2026.05.19 갱신',
  ),
  PlaceRisk(
    title: '운영시간 정보 오래됨',
    description: '마지막 동기화 12일 전이라 방문 전 직접 확인을 권장합니다.',
    level: PlaceRiskLevel.warning,
    actionLabel: '전화 확인',
    evidence: '장소 공지 링크 있음 · 신뢰도 0.72',
  ),
  PlaceRisk(
    title: '비선호 키워드 확인',
    description: '참여자 비선호 키워드인 견과류 메뉴가 일부 리뷰에 반복 등장했어요.',
    level: PlaceRiskLevel.notice,
    actionLabel: '메뉴 보기',
    evidence: '사용자 리뷰 · 최근 30일',
  ),
];

PlaceCandidate findPlaceCandidate(String id) {
  return demoPlaceCandidates.firstWhere(
    (candidate) => candidate.id == id,
    orElse: () => demoPlaceCandidates.first,
  );
}
