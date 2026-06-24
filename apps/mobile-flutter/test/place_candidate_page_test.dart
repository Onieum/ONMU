import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/place/presentation/pages/place_candidate_page.dart';
import 'package:onmu_mobile/features/place/presentation/widgets/place_candidate_card.dart';
import 'package:onmu_mobile/features/place/repository/place_repository.dart';
import 'package:onmu_mobile/features/plan/repository/plan_repository.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';

void main() {
  testWidgets('장소 후보 리스트는 플랜 위치만 보여주고 카테고리 칩으로 필터링된다', (tester) async {
    await tester.pumpWidget(
      _candidatePageApp(
        placeRepository: const _StaticPlaceRepository([
          _cafeCandidate,
          _restaurantCandidate,
          _exhibitCandidate,
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('성수동'), findsOneWidget);
    expect(find.text('제주도 여행'), findsNothing);
    expect(find.text('제주도 일대'), findsNothing);
    expect(find.text('무드카페'), findsOneWidget);
    expect(find.text('온무식당'), findsOneWidget);

    await tester.tap(find.text('카페'));
    await tester.pumpAndSettle();
    expect(find.text('무드카페'), findsOneWidget);
    expect(find.text('온무식당'), findsNothing);

    await tester.tap(find.text('식사'));
    await tester.pumpAndSettle();
    expect(find.text('온무식당'), findsOneWidget);
    expect(find.text('무드카페'), findsNothing);

    await tester.tap(find.text('관광'));
    await tester.pumpAndSettle();
    expect(find.text('빛 전시관'), findsOneWidget);
    expect(find.text('온무식당'), findsNothing);
  });

  testWidgets('장소 후보 리스트가 비어 있으면 안내 카드와 비활성 투표 버튼을 보여준다', (tester) async {
    await tester.pumpWidget(
      _candidatePageApp(placeRepository: const _StaticPlaceRepository([])),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 만날 장소 후보가 없어요'), findsOneWidget);
    expect(find.text('검색으로 후보를 담으면 이곳에서 비교하고 투표할 수 있어요.'), findsOneWidget);

    final voteButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '투표로 정하기'),
    );
    expect(voteButton.onPressed, isNull);
  });

  testWidgets('장소 후보 선호 문구는 memberFit label을 사용한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: MemberPreferenceList(candidate: _memberFitCandidate),
        ),
      ),
    );

    expect(find.text('도윤님이 좋아하는 장소입니다 · 조용한 대화 공간을 선호해요'), findsOneWidget);
    expect(find.textContaining('민서님'), findsNothing);
  });

  testWidgets('장소 일정 등록은 약속 기간 날짜만 버튼으로 선택한다', (tester) async {
    final planStart = _futureDateAt(daysFromNow: 3, hour: 10);
    final planEnd = planStart.add(const Duration(days: 2, hours: 2));

    await tester.pumpWidget(
      _candidatePageApp(
        placeRepository: const _StaticPlaceRepository([_cafeCandidate]),
        planRepository: _CandidatePlanRepository(
          plan: _CandidatePlanRepository.defaultPlan.copyWith(
            startsAt: planStart,
            endsAt: planEnd,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '이 장소로 일정 만들기'));
    await tester.pumpAndSettle();

    expect(find.text(_dateButtonLabel(planStart)), findsOneWidget);
    expect(
      find.text(_dateButtonLabel(planStart.add(const Duration(days: 1)))),
      findsOneWidget,
    );
    expect(find.text(_dateButtonLabel(planEnd)), findsOneWidget);
    expect(
      find.text(_dateButtonLabel(planEnd.add(const Duration(days: 1)))),
      findsNothing,
    );
    expect(find.text('방문 시작 시간'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('방문 종료 시간'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('방문 종료 시간'), findsOneWidget);
  });
}

Widget _candidatePageApp({
  required PlaceRepository placeRepository,
  PlanRepository planRepository = const _CandidatePlanRepository(),
}) {
  return ProviderScope(
    overrides: [
      placeRepositoryProvider.overrideWithValue(placeRepository),
      planRepositoryProvider.overrideWithValue(planRepository),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const PlaceCandidatePage(groupId: '1', planId: '101'),
    ),
  );
}

class _StaticPlaceRepository implements PlaceRepository {
  const _StaticPlaceRepository(this._candidates);

  final List<PlaceCandidate> _candidates;

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async => _candidates;

  @override
  Future<PlaceCandidate> fetchCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  }) async => _candidates.first;

  @override
  Future<PlaceCandidate> createCandidate({
    required Object groupId,
    required Object planId,
    required PlaceCandidate candidate,
  }) async => candidate;

  @override
  Future<SchedulePlace> createSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required String name,
    DateTime? startsAt,
    DateTime? endsAt,
    String note = '',
  }) async => SchedulePlace(
    id: '701',
    groupId: groupId.toString(),
    planId: planId.toString(),
    candidateId: candidateId.toString(),
    name: name,
    startsAt: startsAt,
    endsAt: endsAt,
    note: note,
    sortOrder: 1,
  );

  @override
  Future<SchedulePlace> updateSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
    DateTime? startsAt,
    DateTime? endsAt,
    String note = '',
  }) async => SchedulePlace(
    id: schedulePlaceId.toString(),
    groupId: groupId.toString(),
    planId: planId.toString(),
    candidateId: '',
    name: '수정 장소',
    startsAt: startsAt,
    endsAt: endsAt,
    note: note,
    sortOrder: 1,
  );

  @override
  Future<PlaceCandidate> setCandidateHeart({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required bool hearted,
  }) async => _candidates.first.copyWith(
    heartedByMe: hearted,
    heartCount: hearted ? 1 : 0,
  );

  @override
  Future<void> deleteSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
  }) async {}

  @override
  Future<List<PlaceCandidate>> searchPlaces({
    required Object groupId,
    required Object planId,
    required String query,
    String? category,
    double? lat,
    double? lng,
    int? radius,
  }) async => const [];

  @override
  Future<List<PlaceRisk>> fetchRisks({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<PlaceVoteResult> fetchVoteResult({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }
}

class _CandidatePlanRepository implements PlanRepository {
  const _CandidatePlanRepository({this.plan = defaultPlan});

  static const defaultPlan = Plan(
    id: 101,
    title: '장소 후보 테스트',
    dateTime: '일정 미정',
    location: '성수동',
    status: 'scheduled',
    memo: '',
    members: [],
    timeCandidates: [],
    visitPlan: [],
  );

  final Plan plan;

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async => plan;

  @override
  Future<Plan> createPlan(PlanCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}

const _cafeCandidate = PlaceCandidate(
  id: 1,
  name: '무드카페',
  category: '카페',
  summary: '조용한 카페',
  score: 0,
  matchPercent: 0,
  distanceLabel: '',
  travelTimeLabel: '도보 8분',
  priceLabel: '',
  isOpen: true,
  address: '',
  openingLabel: '',
  sourceLabel: '',
  riskLabel: '',
  riskTone: 'none',
  memberFits: [],
  tags: ['디저트'],
  reasons: [],
  risks: [],
);

const _restaurantCandidate = PlaceCandidate(
  id: 2,
  name: '온무식당',
  category: '식당',
  summary: '같이 먹기 좋은 식당',
  score: 0,
  matchPercent: 0,
  distanceLabel: '',
  travelTimeLabel: '도보 12분',
  priceLabel: '',
  isOpen: true,
  address: '',
  openingLabel: '',
  sourceLabel: '',
  riskLabel: '',
  riskTone: 'none',
  memberFits: [],
  tags: ['한식'],
  reasons: [],
  risks: [],
);

const _exhibitCandidate = PlaceCandidate(
  id: 3,
  name: '빛 전시관',
  category: '전시',
  summary: '가볍게 둘러보기 좋은 전시',
  score: 0,
  matchPercent: 0,
  distanceLabel: '',
  travelTimeLabel: '지하철 15분',
  priceLabel: '',
  isOpen: true,
  address: '',
  openingLabel: '',
  sourceLabel: '',
  riskLabel: '',
  riskTone: 'none',
  memberFits: [],
  tags: ['관광'],
  reasons: [],
  risks: [],
);

const _memberFitCandidate = PlaceCandidate(
  id: 4,
  name: '선호 테스트 장소',
  category: '카페',
  summary: '멤버 선호 문구 테스트',
  score: 0,
  matchPercent: 0,
  distanceLabel: '',
  travelTimeLabel: '',
  priceLabel: '',
  isOpen: true,
  address: '',
  openingLabel: '',
  sourceLabel: '',
  riskLabel: '',
  riskTone: 'none',
  memberFits: [MemberFit(label: '도윤', score: 94, note: '조용한 대화 공간을 선호해요')],
  tags: [],
  reasons: [],
  risks: [],
);

DateTime _futureDateAt({required int daysFromNow, required int hour}) {
  final now = DateTime.now();
  final date = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(Duration(days: daysFromNow));
  return DateTime(date.year, date.month, date.day, hour);
}

String _dateButtonLabel(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.month}/${local.day} ${_weekdayLabel(local)}';
}

String _weekdayLabel(DateTime dateTime) {
  return switch (dateTime.weekday) {
    DateTime.monday => '월',
    DateTime.tuesday => '화',
    DateTime.wednesday => '수',
    DateTime.thursday => '목',
    DateTime.friday => '금',
    DateTime.saturday => '토',
    DateTime.sunday => '일',
    _ => '',
  };
}

extension on Plan {
  Plan copyWith({DateTime? startsAt, DateTime? endsAt}) {
    return Plan(
      id: id,
      title: title,
      dateTime: dateTime,
      location: location,
      status: status,
      memo: memo,
      members: members,
      timeCandidates: timeCandidates,
      visitPlan: visitPlan,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
    );
  }
}
