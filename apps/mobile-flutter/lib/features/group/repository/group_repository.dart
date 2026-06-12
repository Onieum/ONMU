import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/group_models.dart';
import '../../../shared/models/vote_models.dart';
import '../../../shared/repository/in_memory_onmu_store.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  if (ref.watch(onmuApiEnabledProvider)) {
    return ApiGroupRepository(ref.watch(onmuApiClientProvider));
  }
  return MockGroupRepository(ref.watch(inMemoryOnmuStoreProvider));
});

abstract interface class GroupRepository {
  Future<List<GroupSummary>> fetchGroups();

  Future<GroupSummary> fetchGroup(Object groupId);

  Future<GroupSummary> createGroup(GroupCreateInput input);

  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId);

  Future<List<GroupPlanSummary>> fetchPlans(Object groupId);

  Future<List<GroupMemberProfile>> fetchMembers(Object groupId);

  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId);

  Future<List<GroupMessage>> fetchMessages(Object groupId);

  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
  });

  Future<List<VoteSummary>> fetchVotes(Object groupId);

  Future<VoteSummary> createVote(VoteCreateInput input);

  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  });

  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  });

  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  });
}

class MockGroupRepository implements GroupRepository {
  MockGroupRepository(this._store);

  final InMemoryOnmuStore _store;

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async {
    return _store.fetchGroup(groupId);
  }

  @override
  Future<GroupSummary> createGroup(GroupCreateInput input) async {
    return _store.createGroup(input);
  }

  @override
  Future<List<GroupSummary>> fetchGroups() async {
    return _store.fetchGroups();
  }

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async {
    return _store.fetchGroupPlans(groupId);
  }

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async {
    return _store.fetchMemories(groupId);
  }

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async {
    return _store.fetchMembers(groupId);
  }

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async {
    return _store.fetchMessages(groupId);
  }

  @override
  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
  }) async {
    return _store.sendMessage(groupId: groupId, message: message);
  }

  @override
  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) async {
    return _store.fetchMemory(groupId: groupId, memoryId: memoryId);
  }

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async {
    return _store.fetchPinnedPlan(groupId);
  }

  @override
  Future<List<VoteSummary>> fetchVotes(Object groupId) async {
    return _store.fetchVotes(groupId);
  }

  @override
  Future<VoteSummary> createVote(VoteCreateInput input) async {
    return _store.createVote(input);
  }

  @override
  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  }) async {
    return _store.fetchVoteCard(groupId: groupId, voteId: voteId);
  }

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) async {
    return _store.fetchVoteVoters(groupId: groupId, voteId: voteId);
  }
}

class ApiGroupRepository implements GroupRepository {
  ApiGroupRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<List<GroupSummary>> fetchGroups() async {
    final groups = await _client.getList('/api/v1/groups');
    return groups.map(_groupSummary).toList(growable: false);
  }

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async {
    final summary = await _client.getObject('/api/v1/groups/$groupId/summary');
    return _groupSummary(OnmuJson.asMap(summary['group']));
  }

  @override
  Future<GroupSummary> createGroup(GroupCreateInput input) async {
    final group = await _client.postObject(
      '/api/v1/groups',
      body: {'name': input.name},
    );
    return _groupSummary(group);
  }

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async {
    final plans = await fetchPlans(groupId);
    if (plans.isEmpty) {
      return null;
    }
    final plan = plans.first;
    return GroupPinnedPlan(
      id: plan.id,
      title: plan.title,
      dateLabel: plan.dateLabel,
      placeName: plan.placeName,
      statusLabel: plan.statusLabel,
      voteSummary: 'Spring API',
    );
  }

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async {
    final plans = await _client.getList('/api/v1/groups/$groupId/plans');
    return plans.map(_groupPlanSummary).toList(growable: false);
  }

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async {
    final group = await fetchGroup(groupId);
    return group.members
        .map(
          (name) => GroupMemberProfile(
            name: name,
            note: 'Spring API에서 불러온 멤버입니다.',
            statusLabel: '참여 중',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async {
    return const [];
  }

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async {
    final response = await _client.getObject(
      '/api/v1/groups/$groupId/chat/messages',
    );
    return OnmuJson.asMapList(
      response['messages'],
    ).map(_groupMessage).toList(growable: false);
  }

  @override
  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
  }) async {
    final response = await _client.postObject(
      '/api/v1/groups/$groupId/chat/messages',
      body: {'message': message},
    );
    return _groupMessage(response);
  }

  @override
  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) async {
    return GroupMemoryRecord(
      id: int.tryParse(memoryId.toString()) ?? 0,
      author: 'ONMU',
      title: '기록 준비 중',
      description: '기록 API가 연결되면 이 영역을 실제 데이터로 전환합니다.',
      dateLabel: '',
      tags: const [],
    );
  }

  @override
  Future<List<VoteSummary>> fetchVotes(Object groupId) async {
    final votes = await _client.getList('/api/v1/groups/$groupId/votes');
    return votes.map(_voteSummary).toList(growable: false);
  }

  @override
  Future<VoteSummary> createVote(VoteCreateInput input) async {
    final vote = await _client.postObject(
      '/api/v1/groups/${input.groupId}/votes',
      body: {
        'voteType': 'PLACE',
        'targetType': 'PLAN',
        'targetId': input.planId.toString(),
        'title': input.title,
        'options': input.candidateNames,
      },
    );
    return _voteSummary(vote);
  }

  @override
  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  }) async {
    final vote = await _client.getObject(
      '/api/v1/groups/$groupId/votes/$voteId',
    );
    final options = _optionLabels(vote);
    return VoteCard(
      title: OnmuJson.readString(vote, 'title', '투표'),
      summary: options.isEmpty ? '투표 후보를 불러왔어요.' : options.join(', '),
      statusLabel: OnmuJson.readString(vote, 'status', 'open'),
      actionLabel: '투표 보기',
    );
  }

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) async {
    return const {};
  }

  GroupSummary _groupSummary(Map<String, dynamic> json) {
    final members = OnmuJson.stringList(json['members']);
    return GroupSummary(
      id: OnmuJson.readInt(json, 'id'),
      name: OnmuJson.readString(json, 'name', 'ONMU 모임'),
      description: OnmuJson.readString(json, 'description', 'Spring API 모임'),
      members: members.isEmpty ? const ['ONMU Dev User'] : members,
      lastMessage: OnmuJson.readString(json, 'lastMessage', 'Spring API 연결됨'),
      unreadCount: OnmuJson.readInt(json, 'unreadCount'),
      pinnedPlanTitle: OnmuJson.readString(json, 'pinnedPlanTitle', '약속 준비 중'),
    );
  }

  GroupPlanSummary _groupPlanSummary(Map<String, dynamic> json) {
    return GroupPlanSummary(
      id: OnmuJson.readInt(json, 'id'),
      title: OnmuJson.readString(json, 'title', '약속'),
      dateLabel: OnmuJson.readString(json, 'dateLabel', '일정 미정'),
      placeName: OnmuJson.readString(json, 'placeName', '장소 미정'),
      statusLabel: OnmuJson.readString(
        json,
        'statusLabel',
        OnmuJson.readString(json, 'status', '예정'),
      ),
      statusType: OnmuJson.readString(json, 'status', '예정'),
      memberCount: OnmuJson.readInt(json, 'memberCount', 1),
      extraMemberCount: OnmuJson.readInt(json, 'extraMemberCount'),
      iconKind: OnmuJson.readString(json, 'iconKind', 'coffee'),
      isPast: OnmuJson.readBool(json, 'isPast'),
    );
  }

  GroupMessage _groupMessage(Map<String, dynamic> json) {
    return GroupMessage(
      sender: OnmuJson.readString(
        json,
        'senderName',
        OnmuJson.readString(json, 'sender', 'ONMU'),
      ),
      message: OnmuJson.readString(
        json,
        'message',
        OnmuJson.readString(json, 'content', '새 활동이 있어요.'),
      ),
      timeLabel: OnmuJson.readString(
        json,
        'timeLabel',
        _messageTimeLabel(OnmuJson.readString(json, 'createdAt')),
      ),
      isMine: OnmuJson.readBool(json, 'isMine'),
    );
  }

  String _messageTimeLabel(String value) {
    if (value.isEmpty) {
      return '';
    }
    final match = RegExp(r'T(\d{2}):(\d{2})').firstMatch(value);
    if (match == null) {
      return '';
    }
    return '${match.group(1)}:${match.group(2)}';
  }

  VoteSummary _voteSummary(Map<String, dynamic> json) {
    final options = _optionLabels(json);
    final closed = OnmuJson.readBool(json, 'closed');
    return VoteSummary(
      id: OnmuJson.readInt(json, 'id'),
      title: OnmuJson.readString(json, 'title', '투표'),
      statusLabel: closed ? '마감' : '진행 중',
      description: options.isEmpty ? '투표 후보 준비 중' : options.join(', '),
      planLabel: OnmuJson.readString(json, 'targetId').isEmpty
          ? '모임 투표'
          : "약속 ${OnmuJson.readString(json, 'targetId')}",
      planMeta: OnmuJson.readString(json, 'voteType', 'PLACE'),
      participants: const ['ONMU Dev User'],
      options: options
          .map(
            (label) =>
                VoteOptionSummary(label: label, countLabel: '0표', progress: 0),
          )
          .toList(growable: false),
      closed: closed,
      joinedByMe: false,
      actionLabel: closed ? '결과 보기' : '투표 확인하기',
    );
  }

  List<String> _optionLabels(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    if (rawOptions is List) {
      return rawOptions
          .map((option) {
            if (option is Map) {
              return option['label']?.toString() ??
                  option['name']?.toString() ??
                  '';
            }
            return option.toString();
          })
          .where((label) => label.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}
