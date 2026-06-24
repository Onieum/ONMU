import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/place/presentation/pages/place_vote_create_page.dart';
import 'package:onmu_mobile/features/place/repository/place_repository.dart';
import 'package:onmu_mobile/features/plan/repository/plan_repository.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';

void main() {
  testWidgets('투표 만들기는 플랜 컨텍스트를 쓰고 빈 후보 리스트에서는 비활성화된다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placeRepositoryProvider.overrideWithValue(
            const _EmptyPlaceRepository(),
          ),
          planRepositoryProvider.overrideWithValue(
            const _CandidatePlanRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceVoteCreatePage(groupId: '1', planId: '101'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('성수동'), findsOneWidget);
    expect(find.text('장소 후보 테스트 장소 투표'), findsOneWidget);
    expect(find.text('제주도 여행 장소 투표'), findsNothing);
    expect(find.text('투표에 올릴 장소 후보 리스트가 비어있어요.'), findsOneWidget);
    expect(find.text('장소 후보 리스트에서 추가'), findsNothing);

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '투표로 정하기'),
    );
    expect(createButton.onPressed, isNull);
  });

  testWidgets('투표 만들기는 추천 후보를 기본 선택하고 바로 만들 수 있게 한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placeRepositoryProvider.overrideWithValue(
            const _CandidatePlaceRepository(),
          ),
          planRepositoryProvider.overrideWithValue(
            const _CandidatePlanRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceVoteCreatePage(groupId: '1', planId: '101'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('추천 기준으로 2개 후보를 미리 담아뒀어요. 필요하면 후보를 조정하세요.'),
      findsOneWidget,
    );
    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '선택한 2개로 투표 만들기'),
    );
    expect(createButton.onPressed, isNotNull);

    await tester.tap(find.text('비우기'));
    await tester.pumpAndSettle();

    final disabledButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '투표로 정하기'),
    );
    expect(disabledButton.onPressed, isNull);
  });
}

class _EmptyPlaceRepository implements PlaceRepository {
  const _EmptyPlaceRepository();

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<PlaceCandidate> fetchCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  }) {
    throw UnimplementedError();
  }

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
  }) {
    throw UnimplementedError();
  }

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

class _CandidatePlaceRepository extends _EmptyPlaceRepository {
  const _CandidatePlaceRepository();

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async => const [_cafeCandidate, _restaurantCandidate];
}

class _CandidatePlanRepository implements PlanRepository {
  const _CandidatePlanRepository();

  static const _plan = Plan(
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
  summary: '조용히 이야기하기 좋은 카페',
  score: 80,
  matchPercent: 92,
  distanceLabel: '약 300m',
  travelTimeLabel: '도보 5분',
  priceLabel: '',
  isOpen: true,
  address: '서울 성동구 테스트로 1',
  openingLabel: '',
  sourceLabel: '',
  riskLabel: '',
  riskTone: 'none',
  memberFits: [],
  tags: ['카페'],
  reasons: ['대화하기 좋아요'],
  risks: [],
  heartCount: 2,
);

const _restaurantCandidate = PlaceCandidate(
  id: 2,
  name: '온무식당',
  category: '식당',
  summary: '식사하기 좋은 곳',
  score: 75,
  matchPercent: 88,
  distanceLabel: '약 500m',
  travelTimeLabel: '도보 8분',
  priceLabel: '',
  isOpen: true,
  address: '서울 성동구 맛길 2',
  openingLabel: '',
  sourceLabel: '',
  riskLabel: '',
  riskTone: 'none',
  memberFits: [],
  tags: ['한식'],
  reasons: ['같이 먹기 좋아요'],
  risks: [],
  heartCount: 1,
);
