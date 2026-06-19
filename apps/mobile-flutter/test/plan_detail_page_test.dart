import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/auth/domain/auth_user.dart';
import 'package:onmu_mobile/features/auth/providers/auth_providers.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';
import 'package:onmu_mobile/features/map/model/map_models.dart';
import 'package:onmu_mobile/features/map/repository/route_repository.dart';
import 'package:onmu_mobile/features/map/repository/tile_manifest_repository.dart';
import 'package:onmu_mobile/features/plan/presentation/pages/plan_detail_page.dart';
import 'package:onmu_mobile/features/plan/presentation/pages/plan_itinerary_page.dart';
import 'package:onmu_mobile/features/plan/repository/plan_repository.dart';
import 'package:onmu_mobile/features/plan/view_model/plan_detail_view_model.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';
import 'package:onmu_mobile/shared/models/vote_models.dart';
import 'package:onmu_mobile/shared/widgets/onmu_card.dart';

void main() {
  test('plan date tabs are derived from plan start date', () {
    final tabs = buildPlanDateTabs(
      plan: _testPlan(startsAt: DateTime(2026, 6, 18, 10)),
      dayCount: 3,
    );

    expect(tabs.map((tab) => tab.tabLabel), ['6/18 목', '6/19 금', '6/20 토']);
    expect(tabs[0].headingLabel, '6/18 목 동선');
  });

  testWidgets('plan detail date tabs follow plan start date', (tester) async {
    await tester.pumpWidget(_planDetailTestApp(_PlanDetailTestRepository()));
    await tester.pumpAndSettle();

    expect(find.text('6/18 목'), findsOneWidget);
    expect(find.text('6/7 토'), findsNothing);
  });

  testWidgets('empty memo card uses full plan detail content width', (
    tester,
  ) async {
    await tester.pumpWidget(_planDetailTestApp(_PlanDetailTestRepository()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('아직 적어둔 메모가 없어요.'), 320);
    await tester.pumpAndSettle();

    final memoCard = find
        .ancestor(
          of: find.text('아직 적어둔 메모가 없어요.'),
          matching: find.byType(OnmuCard),
        )
        .first;
    final scrollableWidth = tester.getRect(find.byType(ListView).first).width;

    expect(tester.getRect(memoCard).width, greaterThan(scrollableWidth * 0.85));
  });

  testWidgets('itinerary preview keeps map without visit map label', (
    tester,
  ) async {
    await tester.pumpWidget(_planDetailTestApp(_PlanDetailTestRepository()));
    await tester.pumpAndSettle();

    expect(find.text('일정 타임라인'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('장소 동선').first, 320);
    await tester.pumpAndSettle();

    expect(find.text('좌표 연동 전 미리보기'), findsNothing);
    expect(find.text('장소 동선'), findsWidgets);
    expect(find.text('방문 지도'), findsNothing);
  });

  testWidgets('participant leave action is available only from more menu', (
    tester,
  ) async {
    final repository = _PlanDetailTestRepository(
      currentUserParticipating: true,
    );

    await tester.pumpWidget(_planDetailTestApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('참여자 2명'), findsOneWidget);
    expect(find.byTooltip('참여 멤버 추가'), findsNothing);
    expect(find.text('약속에서 나가기'), findsNothing);

    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();
    expect(find.text('약속 수정하기'), findsOneWidget);
    expect(find.text('약속에서 나가기'), findsOneWidget);
    await tester.tap(find.text('약속에서 나가기'));
    await tester.pumpAndSettle();

    expect(repository.leaveCount, 1);
    expect(find.text('약속에서 나갔어요.'), findsOneWidget);
    expect(find.text('참여자 1명'), findsOneWidget);
  });

  testWidgets('itinerary shows route failure instead of ambiguous ready copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _planItineraryTestApp(
        planRepository: _PlanDetailTestRepository(),
        routeRepository: const _FailingRouteRepository(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('동선을 계산하지 못했어요'), findsOneWidget);
    expect(find.text('동선 준비 중'), findsNothing);
  });

  testWidgets('itinerary shows live route summary and first leg preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      _planItineraryTestApp(
        planRepository: _PlanDetailTestRepository(
          visitPlansByDate: const [
            [
              VisitPlan(
                time: '10:00',
                endTime: '11:00',
                place: '테스트 카페',
                kind: '카페',
                duration: '1시간',
              ),
              VisitPlan(
                time: '11:10',
                endTime: '12:00',
                place: '테스트 식당',
                kind: '음식점',
                duration: '50분',
              ),
            ],
          ],
        ),
        routeRepository: const _SuccessfulRouteRepository(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('10분 · 1.5km · 1구간'), findsOneWidget);
    expect(find.text('테스트 카페 → 테스트 식당 · 10분 · 1.5km'), findsOneWidget);
    expect(find.text('실제 경로 계산 실패'), findsNothing);
    expect(find.text('동선 계산 중'), findsNothing);
  });
}

Widget _planDetailTestApp(_PlanDetailTestRepository repository) {
  return ProviderScope(
    overrides: [
      authUserProvider.overrideWith(
        (ref) => const AuthUser(
          id: 'user-me',
          publicId: 'user-me',
          provider: 'NAVER',
          nickname: '나',
          onboardingStatus: 'COMPLETED',
        ),
      ),
      groupRepositoryProvider.overrideWithValue(_PlanDetailGroupRepository()),
      planRepositoryProvider.overrideWithValue(repository),
      routeRepositoryProvider.overrideWithValue(
        const _SuccessfulRouteRepository(),
      ),
      tileManifestRepositoryProvider.overrideWithValue(
        const _FailingTileManifestRepository(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const PlanDetailPage(groupId: '1', planId: '101'),
    ),
  );
}

Widget _planItineraryTestApp({
  required _PlanDetailTestRepository planRepository,
  required RouteRepository routeRepository,
}) {
  return ProviderScope(
    overrides: [
      planRepositoryProvider.overrideWithValue(planRepository),
      routeRepositoryProvider.overrideWithValue(routeRepository),
      tileManifestRepositoryProvider.overrideWithValue(
        const _FailingTileManifestRepository(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const PlanItineraryPage(groupId: '1', planId: '101'),
    ),
  );
}

class _PlanDetailTestRepository implements PlanRepository {
  _PlanDetailTestRepository({
    bool currentUserParticipating = false,
    List<List<VisitPlan>>? visitPlansByDate,
  }) : _visitPlansByDate =
           visitPlansByDate ??
           const [
             [
               VisitPlan(
                 time: '10:00',
                 endTime: '11:00',
                 place: '테스트 카페',
                 kind: '카페',
                 duration: '1시간',
               ),
             ],
           ],
       _currentParticipant = currentUserParticipating
           ? const PlanParticipantArrival(
               id: 'participant-me',
               userId: 'user-me',
               nickname: '나',
               participantStatus: 'joined',
               arrivalStatus: PlanArrivalStatus.none,
               isFallback: false,
             )
           : null;

  var joinCount = 0;
  var leaveCount = 0;
  PlanParticipantArrival? _currentParticipant;
  final List<List<VisitPlan>> _visitPlansByDate;

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return _testPlan(startsAt: DateTime(2026, 6, 18, 10));
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async {
    return _visitPlansByDate;
  }

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async {
    final participant = _currentParticipant;
    return participant == null ? const [] : [participant];
  }

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) async {
    joinCount += 1;
    _currentParticipant = PlanParticipantArrival(
      id: 'participant-me',
      userId: 'user-me',
      nickname: '나',
      participantStatus: 'joined',
      arrivalStatus: status,
      isFallback: false,
    );
    return _currentParticipant!;
  }

  @override
  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  }) async {
    leaveCount += 1;
    _currentParticipant = const PlanParticipantArrival(
      id: 'participant-me',
      userId: 'user-me',
      nickname: '나',
      participantStatus: 'left',
      arrivalStatus: PlanArrivalStatus.none,
      isFallback: false,
    );
    return _currentParticipant!;
  }

  @override
  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  }) async {
    _currentParticipant = PlanParticipantArrival(
      id: userId,
      userId: userId,
      nickname: userId,
      participantStatus: 'joined',
      arrivalStatus: PlanArrivalStatus.none,
      isFallback: false,
    );
    return _currentParticipant!;
  }

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
}

Plan _testPlan({DateTime? startsAt}) {
  return Plan(
    id: 101,
    title: '테스트 약속',
    dateTime: '일정 미정',
    location: '성수동',
    status: '예정',
    memo: '',
    members: const [
      PlanMember(name: '지우', message: '', badge: '참여 중', selected: true),
    ],
    timeCandidates: const [],
    visitPlan: const [
      VisitPlan(
        time: '10:00',
        endTime: '11:00',
        place: '테스트 카페',
        kind: '카페',
        duration: '1시간',
      ),
    ],
    startsAt: startsAt,
  );
}

class _PlanDetailGroupRepository implements GroupRepository {
  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async {
    return const [
      GroupMemberProfile(name: '나', note: '현재 사용자', statusLabel: '참여 중'),
      GroupMemberProfile(name: '지우', note: '모임 멤버', statusLabel: '참여 중'),
    ];
  }

  @override
  Future<GroupMemberProfile> addMember({
    required Object groupId,
    required String userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GroupSummary> createGroup(GroupCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<VoteSummary> createVote(VoteCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<GroupSummary> fetchGroup(Object groupId) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupSummary>> fetchGroups() {
    throw UnimplementedError();
  }

  @override
  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) {
    throw UnimplementedError();
  }

  @override
  Future<GroupMessagePage> fetchMessagePage(
    Object groupId, {
    String? beforeCursor,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
    List<GroupMessageAttachment> attachments = const [],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> markMessagesRead({
    required Object groupId,
    String? lastReadMessageId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<GroupMessage> watchMessages(Object groupId, {String? afterCursor}) {
    throw UnimplementedError();
  }

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) {
    throw UnimplementedError();
  }

  @override
  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VoteCard> submitVote({
    required Object groupId,
    required Object voteId,
    required Object optionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<VoteSummary>> fetchVotes(
    Object groupId, {
    String? targetType,
    Object? targetId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GroupSummary> updateGroup({
    required Object groupId,
    required String name,
    required String description,
  }) {
    throw UnimplementedError();
  }
}

class _FailingRouteRepository implements RouteRepository {
  const _FailingRouteRepository();

  @override
  Future<RouteRecommendation> recommend({
    required Object groupId,
    required Object planId,
    required String travelMode,
  }) {
    throw StateError('route failed');
  }
}

class _SuccessfulRouteRepository implements RouteRepository {
  const _SuccessfulRouteRepository();

  @override
  Future<RouteRecommendation> recommend({
    required Object groupId,
    required Object planId,
    required String travelMode,
  }) async {
    return RouteRecommendation.fromJson({
      'provider': 'openrouteservice',
      'travelMode': travelMode,
      'liveProvider': true,
      'distanceMeters': 1500,
      'durationSeconds': 600,
      'stops': [
        {
          'id': 'stop-1',
          'name': '테스트 카페',
          'lat': 37.5665,
          'lng': 126.9780,
          'order': 1,
        },
        {
          'id': 'stop-2',
          'name': '테스트 식당',
          'lat': 37.5651,
          'lng': 126.9895,
          'order': 2,
        },
      ],
      'geometry': [
        [126.9780, 37.5665],
        [126.9895, 37.5651],
      ],
      'legs': [
        {
          'order': 1,
          'fromStopId': 'stop-1',
          'toStopId': 'stop-2',
          'fromName': '테스트 카페',
          'toName': '테스트 식당',
          'distanceMeters': 1500,
          'durationSeconds': 600,
        },
      ],
    });
  }
}

class _FailingTileManifestRepository implements TileManifestRepository {
  const _FailingTileManifestRepository();

  @override
  Future<TileManifest> fetchManifest() {
    throw StateError('manifest failed');
  }
}
