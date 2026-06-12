import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/group_models.dart';
import '../../../shared/models/vote_models.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return ApiGroupRepository(ref.watch(onmuApiClientProvider));
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
      voteSummary: '',
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
          (name) =>
              GroupMemberProfile(name: name, note: '', statusLabel: '참여 중'),
        )
        .toList(growable: false);
  }

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async {
    final memories = await _client.getList('/api/v1/groups/$groupId/memories');
    return memories.map(_groupMemoryRecord).toList(growable: false);
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
    final memory = await _client.getObject(
      '/api/v1/groups/$groupId/memories/$memoryId',
    );
    return _groupMemoryRecord(memory);
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
      description: OnmuJson.readString(json, 'description'),
      members: members,
      lastMessage: OnmuJson.readString(json, 'lastMessage'),
      unreadCount: OnmuJson.readInt(json, 'unreadCount'),
      pinnedPlanTitle: OnmuJson.readString(json, 'pinnedPlanTitle', '약속 준비 중'),
    );
  }

  GroupPlanSummary _groupPlanSummary(Map<String, dynamic> json) {
    return GroupPlanSummary(
      id: OnmuJson.readInt(json, 'id'),
      title: OnmuJson.readString(json, 'title', '약속'),
      dateLabel: OnmuJson.readString(json, 'dateLabel', '일정 미정'),
      startsAt: DateTime.tryParse(OnmuJson.readString(json, 'startsAt')),
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

  GroupMemoryRecord _groupMemoryRecord(Map<String, dynamic> json) {
    final apiId = _memoryApiId(json);
    final memo = OnmuJson.readString(
      json,
      'memo',
      OnmuJson.readString(
        json,
        'summary',
        OnmuJson.readString(json, 'description'),
      ),
    );
    final author = OnmuJson.readString(
      json,
      'authorName',
      OnmuJson.readString(json, 'author', 'ONMU'),
    );

    return GroupMemoryRecord(
      id: _memoryLegacyId(apiId, json),
      apiId: apiId,
      author: author,
      title: OnmuJson.readString(json, 'title', '기록'),
      description: memo,
      dateLabel: _memoryDateLabel(
        OnmuJson.readString(
          json,
          'date',
          OnmuJson.readString(json, 'createdAt'),
        ),
      ),
      tags: OnmuJson.stringList(json['tags']),
      imageUrls: _absoluteMediaUrls(json['imageUrls']),
    );
  }

  String _memoryApiId(Map<String, dynamic> json) {
    final publicId = OnmuJson.readString(json, 'publicId');
    if (publicId.isNotEmpty) {
      return publicId;
    }
    return OnmuJson.readString(json, 'id');
  }

  int _memoryLegacyId(String apiId, Map<String, dynamic> json) {
    final numericId = OnmuJson.readInt(json, 'id', -1);
    if (numericId >= 0) {
      return numericId;
    }
    final match = RegExp(r'(\d+)$').firstMatch(apiId);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  List<String> _absoluteMediaUrls(Object? value) {
    return OnmuJson.stringList(value)
        .map(_absoluteMediaUrl)
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }

  String _absoluteMediaUrl(String url) {
    if (url.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) {
      return url;
    }
    final baseUri = Uri.tryParse(_client.baseUrl);
    if (baseUri == null || _client.baseUrl.isEmpty) {
      return url;
    }
    return baseUri.resolve(url).toString();
  }

  String _memoryDateLabel(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    final local = parsed.toLocal();
    return '${local.year}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.day.toString().padLeft(2, '0')}';
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
      participants: const [],
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
