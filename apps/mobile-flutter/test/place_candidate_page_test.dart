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

    expect(find.text('아직 장소 후보 리스트가 비어있어요!'), findsOneWidget);
    expect(find.text('후보를 추가하면 이 공간에 카드로 정리돼요.'), findsOneWidget);

    final voteButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '투표 만들기'),
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
}

Widget _candidatePageApp({required PlaceRepository placeRepository}) {
  return ProviderScope(
    overrides: [
      placeRepositoryProvider.overrideWithValue(placeRepository),
      planRepositoryProvider.overrideWithValue(
        const _CandidatePlanRepository(),
      ),
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
    String note = '',
  }) async => SchedulePlace(
    id: '701',
    groupId: groupId.toString(),
    planId: planId.toString(),
    candidateId: candidateId.toString(),
    name: name,
    note: note,
    sortOrder: 1,
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
  const _CandidatePlanRepository();

  static const _plan = Plan(
    id: 101,
    title: '장소 후보 테스트',
    dateTime: '일정 미정',
    location: '성수동',
    status: 'draft',
    memo: '',
    members: [],
    timeCandidates: [],
    visitPlan: [],
  );

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async => _plan;

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
