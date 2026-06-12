import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/plan/view_model/plan_detail_view_model.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';
import 'package:onmu_mobile/features/group/view_model/group_chat_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_create_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_home_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_list_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/vote_view_model.dart';
import 'package:onmu_mobile/features/home/view_model/home_view_model.dart';
import 'package:onmu_mobile/features/place/repository/place_repository.dart';
import 'package:onmu_mobile/features/place/view_model/place_candidates_view_model.dart';
import 'package:onmu_mobile/features/plan/repository/plan_repository.dart';
import 'package:onmu_mobile/features/settlement/repository/settlement_repository.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';
import 'package:onmu_mobile/shared/models/settlement_models.dart';
import 'package:onmu_mobile/shared/models/vote_models.dart';

import 'support/test_onmu_repositories.dart';

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

  test('홈 ViewModel은 서버에 모임이 없어도 빈 상태를 반환한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_EmptyGroupRepository()),
        planRepositoryProvider.overrideWithValue(_UnusedPlanRepository()),
        settlementRepositoryProvider.overrideWithValue(
          _UnusedSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeViewModelProvider.future);

    expect(state.groupId, isNull);
    expect(state.activePlan, isNull);
    expect(state.upcomingPlans, isEmpty);
    expect(state.settlementId, isNull);
    expect(state.todayPlanCount, 0);
  });

  test('홈 ViewModel은 오늘 날짜 약속 수를 API 결과에서 계산한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_TodayPlansGroupRepository()),
        planRepositoryProvider.overrideWithValue(_TodayPlansPlanRepository()),
        settlementRepositoryProvider.overrideWithValue(
          _UnusedSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeViewModelProvider.future);

    expect(state.todayPlanCount, 2);
  });

  test('홈 ViewModel은 다가오는 약속을 오늘 이후 날짜순으로 정렬한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_UpcomingOrderRepository()),
        planRepositoryProvider.overrideWithValue(
          _UpcomingOrderPlanRepository(),
        ),
        settlementRepositoryProvider.overrideWithValue(
          _UnusedSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeViewModelProvider.future);

    expect(state.upcomingPlans.map((plan) => plan.title), [
      '내일 약속',
      '다음 주 약속',
      '시간 미정 약속',
    ]);
    expect(state.upcomingPlans.any((plan) => plan.title == '지난 약속'), isFalse);
  });

  test('홈 ViewModel은 캘린더 표시용 약속에 지난 약속도 유지한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_UpcomingOrderRepository()),
        planRepositoryProvider.overrideWithValue(
          _UpcomingOrderPlanRepository(),
        ),
        settlementRepositoryProvider.overrideWithValue(
          _UnusedSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeViewModelProvider.future);

    expect(state.calendarPlans.map((plan) => plan.title), [
      '지난 약속',
      '내일 약속',
      '다음 주 약속',
    ]);
  });

  test('홈 ViewModel은 현재 진행 중인 약속이 없으면 activePlan을 비운다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_NoActivePlanRepository()),
        planRepositoryProvider.overrideWithValue(_UnusedPlanRepository()),
        settlementRepositoryProvider.overrideWithValue(
          _UnusedSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeViewModelProvider.future);

    expect(state.activePlan, isNull);
    expect(state.upcomingPlans.map((plan) => plan.title), ['내일 약속']);
  });

  test('온모임 생성 ViewModel은 기존 모임이 없어도 추천 멤버 없이 열린다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_EmptyGroupRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupCreateViewModelProvider.future);

    expect(state.recommendedMemberNames, isEmpty);
  });

  test('온모임 홈 ViewModel은 요청한 groupId 범위의 상태를 만든다', () async {
    final container = createOnmuTestContainer();
    addTearDown(container.dispose);

    final state = await container.read(groupHomeViewModelProvider('2').future);

    expect(state.group.id, 2);
    expect(state.group.name, '퇴근 후 러닝크루');
    expect(state.recentMemories, isNotEmpty);
    expect(state.recentMessage, isNotNull);
  });

  test('온모임 홈 ViewModel은 최근 기록/채팅 실패 시에도 홈을 렌더링한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _FakeGroupRepository(
            throwOnFetchMemories: true,
            throwOnFetchMessages: true,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      groupHomeViewModelProvider('9001').future,
    );

    expect(state.group.id, 9001);
    expect(state.recentMemories, isEmpty);
    expect(state.recentMessage, isNull);
  });

  test('온모임 홈 ViewModel은 미래 약속만 날짜순으로 다가오는 약속에 노출한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_NoActivePlanRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupHomeViewModelProvider('9').future);

    expect(state.upcomingPlan?.title, '내일 약속');
    expect(state.upcomingPlan?.displayStatusLabel, '초안');
  });

  test('약속 상세 ViewModel은 선택 멤버와 날짜별 방문 계획을 분리한다', () async {
    final container = createOnmuTestContainer();
    addTearDown(container.dispose);

    final state = await container.read(
      planDetailViewModelProvider((groupId: '1', planId: '101')).future,
    );

    expect(state.selectedMembers.every((member) => member.selected), isTrue);
    expect(state.visitPlanForDate(0).first.place, '다운타우너 성수');
    expect(state.visitPlanForDate(1).first.place, '협재 해수욕장');
  });

  test('약속 상세 ViewModel은 서버 fallback 참여자를 선택 멤버로 취급하지 않는다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
        planRepositoryProvider.overrideWithValue(
          _FallbackParticipantRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      planDetailViewModelProvider((groupId: '1', planId: '101')).future,
    );

    expect(state.participantArrivals.single.isFallback, isTrue);
    expect(state.selectedMembers, isEmpty);
  });

  test('약속 상세 상태 알리기는 현재 시간이 약속 시간 안일 때만 허용한다', () {
    final basePlan = Plan(
      id: 101,
      title: '진행 시간 검증',
      dateTime: '일정 미정',
      location: '성수동',
      status: '진행중',
      memo: '',
      members: const [],
      timeCandidates: const [],
      visitPlan: const [],
      startsAt: DateTime.parse('2026-06-10T10:00:00+09:00'),
      endsAt: DateTime.parse('2026-06-10T12:00:00+09:00'),
    );
    PlanDetailState detailAt(DateTime currentTime) => PlanDetailState(
      plan: basePlan,
      selectedMembers: const [],
      groupMembers: const [],
      visitPlansByDate: const [],
      participantArrivals: const [],
      currentTime: currentTime,
    );

    expect(
      detailAt(
        DateTime.parse('2026-06-10T11:00:00+09:00'),
      ).canShareArrivalStatus,
      isTrue,
    );
    expect(
      detailAt(
        DateTime.parse('2026-06-10T12:00:00+09:00'),
      ).canShareArrivalStatus,
      isFalse,
    );
    expect(
      detailAt(
        DateTime.parse('2026-06-10T09:59:00+09:00'),
      ).canShareArrivalStatus,
      isFalse,
    );
  });

  test('장소 후보 ViewModel은 후보 좋아요 상태를 repository 데이터와 분리해 관리한다', () async {
    final container = ProviderContainer(
      overrides: [
        placeRepositoryProvider.overrideWithValue(_FakePlaceRepository()),
        planRepositoryProvider.overrideWithValue(_FakePlanRepository()),
      ],
    );
    addTearDown(container.dispose);
    final provider = placeCandidatesViewModelProvider((
      groupId: '1',
      planId: '101',
    ));

    final initial = await container.read(provider.future);
    expect(initial.candidates.single.id, 9901);
    expect(initial.planLocation, '서울시 테스트구');
    expect(initial.isLiked(9901), isFalse);
    expect(initial.favoriteCountFor(9901), 3);

    container.read(provider.notifier).toggleFavorite(9901);

    final updated = container.read(provider).requireValue;
    expect(updated.isLiked(9901), isTrue);
    expect(updated.favoriteCountFor(9901), 4);
  });

  test('투표 상세 ViewModel은 voteId로 투표 카드와 후보를 조회한다', () async {
    final container = createOnmuTestContainer();
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
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
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

  test('채팅 ViewModel은 입장 시 새 메시지 구분선 수를 읽음 동기화와 분리해 보존한다', () async {
    final repository = _FakeGroupRepository(
      initialMessages: const [
        GroupMessage(
          id: 'message-1',
          sender: '민서',
          message: '새 메시지 확인해줘',
          timeLabel: '09:01',
          isMine: false,
        ),
      ],
      initialUnreadCount: 3,
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    final state = await container.read(provider.future);

    expect(repository.markedReadMessages, ['message-1']);
    expect(state.unreadCount, 3);
  });

  test('채팅 ViewModel은 메시지 작성 실패 시 실패 말풍선과 오류를 남긴다', () async {
    final repository = _FakeGroupRepository(throwOnSend: true);
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    final initial = await container.read(provider.future);
    final sent = await container.read(provider.notifier).sendMessage('실패 요청');
    final updated = container.read(provider).requireValue;

    expect(initial.messages, isEmpty);
    expect(sent, isTrue);
    expect(updated.messages.single.message, '실패 요청');
    expect(updated.messages.single.sendStatus, GroupMessageSendStatus.failed);
    expect(updated.sendErrorMessage, '메시지를 보내지 못했어요.');
  });

  test('채팅 ViewModel은 실패한 메시지를 재시도해 서버 응답으로 교체한다', () async {
    final repository = _FakeGroupRepository(
      sendFailuresBeforeSuccess: 1,
      sentMessage: const GroupMessage(
        id: 'server-message-2',
        sender: '나',
        message: '재시도 성공',
        timeLabel: '방금',
        isMine: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    await container.read(provider.notifier).sendMessage('재시도 요청');
    final failed = container.read(provider).requireValue.messages.single;
    final retried = await container
        .read(provider.notifier)
        .retryMessage(failed.id);
    final updated = container.read(provider).requireValue;

    expect(failed.sendStatus, GroupMessageSendStatus.failed);
    expect(retried, isTrue);
    expect(repository.sentMessages, ['재시도 요청', '재시도 요청']);
    expect(updated.messages.single.id, 'server-message-2');
    expect(updated.messages.single.message, '재시도 성공');
    expect(updated.messages.single.sendStatus, GroupMessageSendStatus.sent);
    expect(updated.sendErrorMessage, isNull);
  });

  test('채팅 ViewModel은 realtime 메시지를 추가하고 중복 수신은 건너뛴다', () async {
    final realtime = StreamController<GroupMessage>();
    final repository = _FakeGroupRepository(
      initialMessages: const [
        GroupMessage(
          id: 'message-1',
          cursor: '2026-06-09T05:00:00Z',
          sender: '민서',
          message: '이미 본 메시지',
          timeLabel: '14:00',
          isMine: false,
        ),
      ],
      realtimeMessages: realtime.stream,
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(() async {
      await realtime.close();
      container.dispose();
    });
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    realtime.add(
      const GroupMessage(
        id: 'message-1',
        cursor: '2026-06-09T05:00:00Z',
        sender: '민서',
        message: '이미 본 메시지',
        timeLabel: '14:00',
        isMine: false,
      ),
    );
    realtime.add(
      const GroupMessage(
        id: 'message-2',
        cursor: '2026-06-09T05:01:00Z',
        sender: '지우',
        message: '새로 온 메시지',
        timeLabel: '14:01',
        isMine: false,
      ),
    );
    await pumpEventQueue();

    final updated = container.read(provider).requireValue;
    expect(updated.messages.map((message) => message.id), [
      'message-1',
      'message-2',
    ]);
    expect(repository.markedReadMessages, contains('message-2'));
  });

  test('채팅 ViewModel은 realtime stream 오류가 나도 기존 메시지를 유지한다', () async {
    final realtime = StreamController<GroupMessage>();
    final repository = _FakeGroupRepository(
      initialMessages: const [
        GroupMessage(
          id: 'message-1',
          sender: '민서',
          message: '유지할 메시지',
          timeLabel: '14:00',
          isMine: false,
        ),
      ],
      realtimeMessages: realtime.stream,
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(() async {
      await realtime.close();
      container.dispose();
    });
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    realtime.addError(StateError('stream failed'));
    await pumpEventQueue();

    final updated = container.read(provider).requireValue;
    expect(updated.messages.single.message, '유지할 메시지');
    expect(updated.sendErrorMessage, isNull);
  });

  test('채팅 ViewModel은 timestamp cursor가 없으면 afterCursor를 보내지 않는다', () async {
    final repository = _FakeGroupRepository(
      initialMessages: const [
        GroupMessage(
          id: 'message-id-only',
          sender: '민서',
          message: 'cursor 없는 메시지',
          timeLabel: '14:00',
          isMine: false,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);

    expect(repository.watchedAfterCursors.single, isNull);
  });

  test('채팅 ViewModel dispose는 realtime subscription을 정리한다', () async {
    var canceled = false;
    final realtime = StreamController<GroupMessage>(
      onCancel: () {
        canceled = true;
      },
    );
    final repository = _FakeGroupRepository(realtimeMessages: realtime.stream);
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    container.dispose();
    await pumpEventQueue();

    expect(canceled, isTrue);
    await realtime.close();
  });
}

class _FakeGroupRepository implements GroupRepository {
  _FakeGroupRepository({
    this.sentMessage,
    this.throwOnSend = false,
    this.sendFailuresBeforeSuccess = 0,
    this.throwOnFetchMemories = false,
    this.throwOnFetchMessages = false,
    this.initialMessages = const [],
    this.initialUnreadCount = 0,
    Stream<GroupMessage>? realtimeMessages,
  }) : realtimeMessages =
           realtimeMessages ?? Stream<GroupMessage>.multi((_) {}),
       _remainingSendFailures = sendFailuresBeforeSuccess;

  final GroupMessage? sentMessage;
  final bool throwOnSend;
  final int sendFailuresBeforeSuccess;
  final bool throwOnFetchMemories;
  final bool throwOnFetchMessages;
  final List<GroupMessage> initialMessages;
  final int initialUnreadCount;
  final Stream<GroupMessage> realtimeMessages;
  final sentMessages = <String>[];
  final markedReadMessages = <String?>[];
  final watchedAfterCursors = <String?>[];
  int _remainingSendFailures;

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
  Future<GroupSummary> updateGroup({
    required Object groupId,
    required String name,
    required String description,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupSummary>> fetchGroups() async => [_group];

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async => [];

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async {
    if (throwOnFetchMemories) {
      throw StateError('memories failed');
    }
    return [];
  }

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async => [];

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async {
    if (throwOnFetchMessages) {
      throw StateError('fetch messages failed');
    }
    return initialMessages;
  }

  @override
  Future<GroupMessagePage> fetchMessagePage(
    Object groupId, {
    String? beforeCursor,
    int? limit,
  }) async {
    return GroupMessagePage(
      messages: initialMessages,
      unreadCount: initialUnreadCount,
    );
  }

  @override
  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
  }) async {
    sentMessages.add(message);
    if (throwOnSend || _remainingSendFailures > 0) {
      if (_remainingSendFailures > 0) {
        _remainingSendFailures -= 1;
      }
      throw StateError('send failed');
    }
    return sentMessage ??
        GroupMessage(
          id: 'server-message-${sentMessages.length}',
          sender: '나',
          message: message,
          timeLabel: '방금',
          isMine: true,
        );
  }

  @override
  Future<int> markMessagesRead({
    required Object groupId,
    String? lastReadMessageId,
  }) async {
    markedReadMessages.add(lastReadMessageId);
    return 0;
  }

  @override
  Stream<GroupMessage> watchMessages(Object groupId, {String? afterCursor}) {
    watchedAfterCursors.add(afterCursor);
    return realtimeMessages;
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

class _EmptyGroupRepository implements GroupRepository {
  @override
  Future<GroupSummary> fetchGroup(Object groupId) {
    throw UnimplementedError();
  }

  @override
  Future<GroupSummary> createGroup(GroupCreateInput input) async =>
      GroupSummary(
        id: 1,
        name: input.name,
        description: input.description,
        members: input.memberNames,
        lastMessage: '',
        unreadCount: 0,
        pinnedPlanTitle: '첫 약속 없음',
      );

  @override
  Future<GroupSummary> updateGroup({
    required Object groupId,
    required String name,
    required String description,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupSummary>> fetchGroups() async => [];

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async => null;

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async => [];

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async => [];

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async => [];

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async => [];

  @override
  Future<GroupMessagePage> fetchMessagePage(
    Object groupId, {
    String? beforeCursor,
    int? limit,
  }) async {
    return const GroupMessagePage(messages: []);
  }

  @override
  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
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
    return Stream<GroupMessage>.multi((_) {});
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
  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) {
    throw UnimplementedError();
  }
}

class _TodayPlansGroupRepository extends _EmptyGroupRepository {
  static const _group = GroupSummary(
    id: 7,
    name: '오늘 약속 모임',
    description: '',
    members: [],
    lastMessage: '',
    unreadCount: 0,
    pinnedPlanTitle: '',
  );

  @override
  Future<List<GroupSummary>> fetchGroups() async => const [_group];

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async => _group;

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alreadyEnded = today.add(const Duration(hours: 1));
    final inProgress = now.subtract(const Duration(minutes: 10));
    final laterToday = today.add(const Duration(hours: 23, minutes: 59));
    final tomorrow = today.add(const Duration(days: 1, hours: 9));

    return [
      GroupPlanSummary(
        id: 71,
        title: '종료된 약속',
        dateLabel: '오늘 오전 1:00',
        startsAt: alreadyEnded,
        endsAt: now.subtract(const Duration(seconds: 1)),
        placeName: '성수',
        statusLabel: '예정',
        statusType: '예정',
        memberCount: 1,
        extraMemberCount: 0,
        iconKind: 'coffee',
        isPast: false,
      ),
      GroupPlanSummary(
        id: 72,
        title: '진행 중 약속',
        dateLabel: '오늘 진행 중',
        startsAt: inProgress,
        endsAt: now.add(const Duration(minutes: 50)),
        placeName: '한남',
        statusLabel: '예정',
        statusType: '예정',
        memberCount: 1,
        extraMemberCount: 0,
        iconKind: 'food',
        isPast: false,
      ),
      GroupPlanSummary(
        id: 74,
        title: '오늘 늦은 약속',
        dateLabel: '오늘 오후 11:59',
        startsAt: laterToday,
        endsAt: today.add(const Duration(days: 1, hours: 1)),
        placeName: '성수',
        statusLabel: '예정',
        statusType: '예정',
        memberCount: 1,
        extraMemberCount: 0,
        iconKind: 'coffee',
        isPast: false,
      ),
      GroupPlanSummary(
        id: 73,
        title: '내일 약속',
        dateLabel: '내일 오전 9:00',
        startsAt: tomorrow,
        placeName: '홍대',
        statusLabel: '예정',
        statusType: '예정',
        memberCount: 1,
        extraMemberCount: 0,
        iconKind: 'gallery',
        isPast: false,
      ),
    ];
  }
}

class _TodayPlansPlanRepository implements PlanRepository {
  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return Plan(
      id: int.parse(planId.toString()),
      title: '아침 약속',
      dateTime: '오늘 오전 9:00',
      location: '성수',
      status: '예정',
      memo: '',
      members: const [],
      timeCandidates: const [],
      visitPlan: const [],
    );
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

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async {
    return const [];
  }

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) async {
    return PlanParticipantArrival(
      id: 'current-user',
      displayName: '나',
      participantStatus: 'joined',
      arrivalStatus: status,
      isFallback: false,
    );
  }

  @override
  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }
}

class _UpcomingOrderRepository extends _EmptyGroupRepository {
  static final _now = DateTime.now();
  static final _today = DateTime(_now.year, _now.month, _now.day);
  static const _group = GroupSummary(
    id: 8,
    name: '정렬 테스트 모임',
    description: '',
    members: [],
    lastMessage: '',
    unreadCount: 0,
    pinnedPlanTitle: '',
  );

  @override
  Future<List<GroupSummary>> fetchGroups() async => const [_group];

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async => _group;

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async => [
    GroupPlanSummary(
      id: 82,
      title: '다음 주 약속',
      dateLabel: '다음 주 오후 7:00',
      startsAt: _today.add(const Duration(days: 7, hours: 19)),
      placeName: '성수',
      statusLabel: 'draft',
      statusType: 'draft',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'coffee',
      isPast: false,
    ),
    GroupPlanSummary(
      id: 81,
      title: '내일 약속',
      dateLabel: '내일 오후 2:00',
      startsAt: _today.add(const Duration(days: 1, hours: 14)),
      placeName: '한남',
      statusLabel: 'scheduled',
      statusType: 'scheduled',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'food',
      isPast: false,
    ),
    GroupPlanSummary(
      id: 80,
      title: '지난 약속',
      dateLabel: '어제 오후 2:00',
      startsAt: _today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 14)),
      placeName: '홍대',
      statusLabel: 'completed',
      statusType: 'completed',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'gallery',
      isPast: false,
    ),
    const GroupPlanSummary(
      id: 83,
      title: '시간 미정 약속',
      dateLabel: '일정 미정',
      startsAt: null,
      placeName: '장소 미정',
      statusLabel: 'draft',
      statusType: 'draft',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'coffee',
      isPast: false,
    ),
  ];
}

class _UpcomingOrderPlanRepository extends _TodayPlansPlanRepository {
  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return Plan(
      id: int.parse(planId.toString()),
      title: '내일 약속',
      dateTime: '내일 오후 2:00',
      location: '한남',
      status: 'draft',
      memo: '',
      members: const [],
      timeCandidates: const [],
      visitPlan: const [],
    );
  }
}

class _NoActivePlanRepository extends _EmptyGroupRepository {
  static final _now = DateTime.now();
  static final _today = DateTime(_now.year, _now.month, _now.day);
  static const _group = GroupSummary(
    id: 9,
    name: '진행 중 없음 모임',
    description: '',
    members: [],
    lastMessage: '',
    unreadCount: 0,
    pinnedPlanTitle: '',
  );

  @override
  Future<List<GroupSummary>> fetchGroups() async => const [_group];

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async => _group;

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async =>
      const GroupPinnedPlan(
        id: 90,
        title: '완료된 약속',
        dateLabel: '어제 오후 2:00',
        placeName: '성수',
        statusLabel: 'completed',
        voteSummary: '',
      );

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async => [
    GroupPlanSummary(
      id: 90,
      title: '완료된 약속',
      dateLabel: '어제 오후 2:00',
      startsAt: _today.subtract(const Duration(days: 1, hours: -14)),
      placeName: '성수',
      statusLabel: 'completed',
      statusType: 'completed',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'coffee',
      isPast: true,
    ),
    GroupPlanSummary(
      id: 91,
      title: '내일 약속',
      dateLabel: '내일 오후 2:00',
      startsAt: _today.add(const Duration(days: 1, hours: 14)),
      placeName: '한남',
      statusLabel: 'draft',
      statusType: 'draft',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'food',
      isPast: false,
    ),
  ];
}

class _UnusedPlanRepository implements PlanRepository {
  @override
  Future<Plan> fetchPlan({required Object groupId, required Object planId}) {
    throw StateError('빈 홈 상태에서는 약속 상세를 조회하지 않아야 합니다.');
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

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

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

class _UnusedSettlementRepository implements SettlementRepository {
  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) {
    throw StateError('빈 홈 상태에서는 정산 정보를 조회하지 않아야 합니다.');
  }

  @override
  Future<SettlementSummary> fetchSettlementById({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SettlementSummary> fetchSettlementDraft({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SettlementSummary> previewSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SettlementSummary> createSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) {
    throw UnimplementedError();
  }
}

class _ChatSettlementRepository implements SettlementRepository {
  static const _summary = SettlementSummary(
    id: 301,
    planTitle: '테스트 약속',
    totalAmountLabel: '0원',
    createdDateLabel: '',
    itemCountLabel: '0개',
    finalSummaryLabel: '정산 없음',
    mySummaryLabel: '정산 없음',
    paymentItems: [],
    memberResults: [],
    transfers: [],
    shareMessage: '',
  );

  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) async => _summary;

  @override
  Future<SettlementSummary> fetchSettlementById({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  }) async => _summary;

  @override
  Future<SettlementSummary> fetchSettlementDraft({
    required Object groupId,
    required Object planId,
  }) async => _summary;

  @override
  Future<SettlementSummary> previewSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) async => _summary;

  @override
  Future<SettlementSummary> createSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) async => _summary;
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
    sourceLabel: 'Test API',
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
  }) async => [_candidate];

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

class _FakePlanRepository implements PlanRepository {
  static const _plan = Plan(
    id: 101,
    title: '테스트 약속',
    dateTime: '일정 미정',
    location: '서울시 테스트구',
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
  }) async {
    return _plan;
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

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

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

class _FallbackParticipantRepository implements PlanRepository {
  static const _plan = Plan(
    id: 101,
    title: '참여자 없는 약속',
    dateTime: '일정 미정',
    location: '서울',
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
  }) async {
    return _plan;
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

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async => const [
    PlanParticipantArrival(
      id: 'current-user',
      displayName: '나',
      participantStatus: 'joined',
      arrivalStatus: PlanArrivalStatus.none,
      isFallback: true,
    ),
  ];

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
