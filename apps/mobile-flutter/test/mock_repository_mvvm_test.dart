import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/plan/view_model/plan_detail_view_model.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';
import 'package:onmu_mobile/features/group/view_model/group_home_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_list_view_model.dart';
import 'package:onmu_mobile/features/place/repository/place_repository.dart';
import 'package:onmu_mobile/features/place/view_model/place_candidates_view_model.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';

void main() {
  test('온모임 목록 ViewModel은 repository override 데이터를 그대로 노출한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupListViewModelProvider.future);

    expect(state.groups, hasLength(1));
    expect(state.groups.single.id, 9001);
    expect(state.groupCount, 1);
  });

  test('온모임 홈 ViewModel은 요청한 groupId 범위의 상태를 만든다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(groupHomeViewModelProvider('2').future);

    expect(state.group.id, 2);
    expect(state.group.name, '퇴근 후 러닝크루');
    expect(state.recentMemories, isNotEmpty);
    expect(state.recentMessage, isNotNull);
  });

  test('약속 상세 ViewModel은 선택 멤버와 날짜별 방문 계획을 분리한다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(
      planDetailViewModelProvider((groupId: '1', planId: '101')).future,
    );

    expect(state.selectedMembers.every((member) => member.selected), isTrue);
    expect(state.visitPlanForDate(0).first.place, '다운타우너 성수');
    expect(state.visitPlanForDate(1).first.place, '협재 해수욕장');
  });

  test('장소 후보 ViewModel은 후보 좋아요 상태를 repository 데이터와 분리해 관리한다', () async {
    final container = ProviderContainer(
      overrides: [
        placeRepositoryProvider.overrideWithValue(_FakePlaceRepository()),
      ],
    );
    addTearDown(container.dispose);
    final provider = placeCandidatesViewModelProvider((
      groupId: '1',
      planId: '101',
    ));

    final initial = await container.read(provider.future);
    expect(initial.candidates.single.id, 9901);
    expect(initial.isLiked(9901), isFalse);
    expect(initial.favoriteCountFor(9901), 3);

    container.read(provider.notifier).toggleFavorite(9901);

    final updated = container.read(provider).requireValue;
    expect(updated.isLiked(9901), isTrue);
    expect(updated.favoriteCountFor(9901), 4);
  });
}

class _FakeGroupRepository implements GroupRepository {
  static const _group = GroupSummary(
    id: 9001,
    name: 'Spring API 전환 모임',
    description: 'repository 교체만으로 서버 데이터를 읽는 구조',
    members: ['지우', '민수'],
    lastMessage: '서버 DTO 연결 준비 완료',
    unreadCount: 0,
    pinnedPlanTitle: 'API 계약 점검',
  );

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async => _group;

  @override
  Future<List<GroupSummary>> fetchGroups() async => const [_group];

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async => const [];

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async =>
      const [];

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async =>
      const [];

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async => const [];

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async => null;

  @override
  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VoteCard> fetchVoteCard(Object groupId) {
    throw UnimplementedError();
  }
}

class _FakePlaceRepository implements PlaceRepository {
  static const _candidate = PlaceCandidate(
    id: 9901,
    name: '목업 카페',
    category: '카페',
    summary: 'repository 테스트 후보',
    score: 90,
    matchPercent: 86,
    distanceLabel: '도보 3분',
    travelTimeLabel: '도보 3분',
    priceLabel: '1인 10,000원대',
    isOpen: true,
    address: '서울시 테스트구',
    openingLabel: '오늘 10:00-20:00',
    sourceLabel: 'Mock API',
    riskLabel: '안정',
    riskTone: 'none',
    memberFits: [],
    tags: ['조용한'],
    reasons: ['테스트하기 좋아요.'],
    risks: ['운영 리스크 없음'],
  );

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async => const [_candidate];

  @override
  Future<PlaceCandidate> fetchCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  }) async => _candidate;

  @override
  Future<List<PlaceRisk>> fetchRisks({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<PlaceVoteResult> fetchVoteResult({
    required Object groupId,
    required Object planId,
  }) async => const PlaceVoteResult(
    title: '테스트 투표',
    selectedPlaceName: '목업 카페',
    voters: ['지우'],
    note: '테스트 결과',
  );
}
