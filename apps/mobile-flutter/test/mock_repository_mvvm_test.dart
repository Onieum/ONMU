import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/plan/view_model/plan_detail_view_model.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';
import 'package:onmu_mobile/features/group/view_model/group_chat_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_home_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_list_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/vote_view_model.dart';
import 'package:onmu_mobile/features/place/repository/place_repository.dart';
import 'package:onmu_mobile/features/place/view_model/place_candidates_view_model.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';
import 'package:onmu_mobile/shared/models/vote_models.dart';

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

  test('투표 상세 ViewModel은 voteId로 투표 카드와 후보를 조회한다', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(
      voteDetailViewModelProvider((groupId: '1', voteId: '501')).future,
    );

    expect(state.vote.title, '제주도 여행 장소 투표');
    expect(state.candidates.first.name, '온무식당');
    expect(state.votersFor(201), contains('민서'));
  });

  test('채팅 ViewModel은 메시지 작성 성공 시 서버 응답을 상태에 반영한다', () async {
    final repository = _FakeGroupRepository(
      sentMessage: const GroupMessage(
        sender: '나',
        message: '서버 응답 메시지',
        timeLabel: '방금',
        isMine: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    final initial = await container.read(provider.future);
    final sent = await container
        .read(provider.notifier)
        .sendMessage('  전송 요청  ');
    final updated = container.read(provider).requireValue;

    expect(initial.messages, isEmpty);
    expect(sent, isTrue);
    expect(repository.sentMessages, ['전송 요청']);
    expect(updated.messages.single.message, '서버 응답 메시지');
    expect(updated.sendErrorMessage, isNull);
  });

  test('채팅 ViewModel은 메시지 작성 실패 시 기존 상태를 보존하고 오류를 남긴다', () async {
    final repository = _FakeGroupRepository(throwOnSend: true);
    final container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    final initial = await container.read(provider.future);
    final sent = await container.read(provider.notifier).sendMessage('실패 요청');
    final updated = container.read(provider).requireValue;

    expect(initial.messages, isEmpty);
    expect(sent, isFalse);
    expect(updated.messages, isEmpty);
    expect(updated.sendErrorMessage, '메시지를 보내지 못했어요.');
  });
}

class _FakeGroupRepository implements GroupRepository {
  _FakeGroupRepository({this.sentMessage, this.throwOnSend = false});

  final GroupMessage? sentMessage;
  final bool throwOnSend;
  final sentMessages = <String>[];

  static final _group = GroupSummary(
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
  Future<GroupSummary> createGroup(GroupCreateInput input) async =>
      GroupSummary(
        id: 9002,
        name: input.name,
        description: input.description,
        members: input.memberNames,
        lastMessage: '생성됨',
        unreadCount: 0,
        pinnedPlanTitle: '첫 약속 없음',
      );

  @override
  Future<List<GroupSummary>> fetchGroups() async => [_group];

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async => [];

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async => [];

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async => [];

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async => [];

  @override
  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
  }) async {
    if (throwOnSend) {
      throw StateError('send failed');
    }
    sentMessages.add(message);
    return sentMessage ??
        GroupMessage(
          sender: '나',
          message: message,
          timeLabel: '방금',
          isMine: true,
        );
  }

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
  Future<List<VoteSummary>> fetchVotes(Object groupId) async => [];

  @override
  Future<VoteSummary> createVote(VoteCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  }) async => const VoteCard(
    title: '테스트 투표',
    summary: '테스트 후보',
    statusLabel: '진행 중',
    actionLabel: '투표 보기',
  );

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) {
    throw UnimplementedError();
  }
}

class _FakePlaceRepository implements PlaceRepository {
  static final _candidate = PlaceCandidate(
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
  }) async => [_candidate];

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
  }) async => [];

  @override
  Future<PlaceVoteResult> fetchVoteResult({
    required Object groupId,
    required Object planId,
  }) async => PlaceVoteResult(
    title: '테스트 투표',
    selectedPlaceName: '목업 카페',
    voters: ['지우'],
    note: '테스트 결과',
  );
}
