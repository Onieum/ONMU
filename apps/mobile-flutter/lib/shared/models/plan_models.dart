class PlanMember {
  const PlanMember({
    required this.name,
    required this.message,
    required this.badge,
    required this.selected,
  });

  final String name;
  final String message;
  final String badge;
  final bool selected;
}

class TimeCandidate {
  const TimeCandidate({
    required this.time,
    required this.range,
    required this.status,
    required this.description,
    required this.countLabel,
    required this.recommended,
  });

  final String time;
  final String range;
  final String status;
  final String description;
  final String countLabel;
  final bool recommended;
}

class VisitPlan {
  const VisitPlan({
    required this.time,
    required this.endTime,
    required this.place,
    required this.kind,
    required this.duration,
  });

  final String time;
  final String endTime;
  final String place;
  final String kind;
  final String duration;
}

class Plan {
  const Plan({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.status,
    required this.memo,
    required this.members,
    required this.timeCandidates,
    required this.visitPlan,
  });

  final int id;
  final String title;
  final String dateTime;
  final String location;
  final String status;
  final String memo;
  final List<PlanMember> members;
  final List<TimeCandidate> timeCandidates;
  final List<VisitPlan> visitPlan;
}

const mockPlanMembers = [
  PlanMember(
    name: '연우',
    message: '가고싶다 했어요!',
    badge: '방문지 제안',
    selected: false,
  ),
  PlanMember(name: '지영', message: '카페 투어 좋아해요', badge: '선택됨', selected: true),
  PlanMember(
    name: '민수',
    message: '이번엔 내가 추천할게!',
    badge: '시간 제안',
    selected: true,
  ),
  PlanMember(
    name: '준호',
    message: '매운 음식은 피하고 싶어요',
    badge: '초대',
    selected: false,
  ),
  PlanMember(name: '하린', message: '좋아요 좋아요', badge: '선택됨', selected: true),
  PlanMember(
    name: '서준',
    message: '이번엔 시간이 될지...',
    badge: '초대',
    selected: false,
  ),
];

const mockPlanTimeCandidates = [
  TimeCandidate(
    time: '12:00',
    range: '~ 14:00',
    status: '모두 가능',
    description: '점심부터 여유롭게 시작할 수 있어요.',
    countLabel: '4/4',
    recommended: false,
  ),
  TimeCandidate(
    time: '13:00',
    range: '~ 15:00',
    status: '모두 가능',
    description: '가장 많은 친구들이 가능한 시간이에요!',
    countLabel: '4/4',
    recommended: true,
  ),
  TimeCandidate(
    time: '15:00',
    range: '~ 17:00',
    status: '일부만 가능',
    description: '2명의 친구가 일정이 있어요.',
    countLabel: '2/4',
    recommended: false,
  ),
  TimeCandidate(
    time: '18:00',
    range: '~ 20:00',
    status: '보통 어려워요',
    description: '3명의 친구가 일정이 있어요.',
    countLabel: '1/4',
    recommended: false,
  ),
];

const mockPlanDetail = Plan(
  id: 101,
  title: '주말 나들이',
  dateTime: '5월 26일 (일) · 오후 1:00 ~ 8:00',
  location: '성수동 일대',
  status: '이행 전',
  memo: '편한 복장으로 오기! 돗자리 챙기면 좋을 것 같아요.',
  members: mockPlanMembers,
  timeCandidates: mockPlanTimeCandidates,
  visitPlan: [
    VisitPlan(
      time: '13:00',
      endTime: '14:30',
      place: '다운타우너 성수',
      kind: '카페',
      duration: '1시간 30분',
    ),
    VisitPlan(
      time: '14:45',
      endTime: '16:15',
      place: '연무장길 카페거리',
      kind: '카페',
      duration: '1시간 30분',
    ),
    VisitPlan(
      time: '16:30',
      endTime: '17:30',
      place: '성수연방',
      kind: '음식점',
      duration: '1시간',
    ),
    VisitPlan(
      time: '17:40',
      endTime: '19:00',
      place: '서울숲 산책',
      kind: '볼거리',
      duration: '1시간 20분',
    ),
  ],
);
