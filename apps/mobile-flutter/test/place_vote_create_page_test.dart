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

    final addButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '장소 후보 리스트에서 추가'),
    );
    expect(addButton.onPressed, isNull);

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '투표 만들기'),
    );
    expect(createButton.onPressed, isNull);
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
  Future<List<PlaceCandidate>> searchPlaces({
    required Object groupId,
    required Object planId,
    required String query,
    String? category,
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
}
