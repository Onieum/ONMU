import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../core/api/onmu_media_url.dart';
import '../../../shared/models/group_models.dart';
import '../../../shared/models/preference_profile.dart';
import '../../../shared/utils/onmu_display_name.dart';
import '../../../shared/models/vote_models.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return ApiGroupRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class GroupRepository {
  Future<List<GroupSummary>> fetchGroups();

  Future<GroupSummary> fetchGroup(Object groupId);

  Future<GroupSummary> createGroup(GroupCreateInput input);

  Future<GroupSummary> updateGroup({
    required Object groupId,
    required String name,
    required String description,
  });

  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId);

  Future<List<GroupPlanSummary>> fetchPlans(Object groupId);

  Future<List<GroupMemberProfile>> fetchMembers(Object groupId);

  Future<List<GroupMemberProfile>> fetchPlanParticipantCandidates({
    required Object groupId,
    required List<String> userIds,
  });

  Future<GroupMemberProfile> addMember({
    required Object groupId,
    required String userId,
  });

  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId);

  Future<List<GroupMessage>> fetchMessages(Object groupId);

  Future<GroupMessagePage> fetchMessagePage(
    Object groupId, {
    String? beforeCursor,
    int? limit,
  });

  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
    List<GroupMessageAttachment> attachments = const [],
  });

  Future<int> markMessagesRead({
    required Object groupId,
    String? lastReadMessageId,
  });

  Stream<GroupMessage> watchMessages(Object groupId, {String? afterCursor});

  Future<List<VoteSummary>> fetchVotes(
    Object groupId, {
    String? targetType,
    Object? targetId,
  });

  Future<VoteSummary> createVote(VoteCreateInput input);

  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  });

  Future<VoteCard> submitVote({
    required Object groupId,
    required Object voteId,
    required Object optionId,
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
    final group = await _client.getObject('/api/v1/groups/$groupId');
    return _groupSummary(group);
  }

  @override
  Future<GroupSummary> createGroup(GroupCreateInput input) async {
    final group = await _client.postObject(
      '/api/v1/groups',
      body: {
        'name': input.name.trim(),
        'description': input.description.trim(),
        'memberNames': input.memberNames,
      },
    );
    return _groupSummary(group);
  }

  @override
  Future<GroupSummary> updateGroup({
    required Object groupId,
    required String name,
    required String description,
  }) async {
    final group = await _client.patchObject(
      '/api/v1/groups/$groupId',
      body: {'name': name.trim(), 'description': description.trim()},
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
    final members = await _client.getList('/api/v1/groups/$groupId/members');
    return members.map(_groupMemberProfile).toList(growable: false);
  }

  @override
  Future<List<GroupMemberProfile>> fetchPlanParticipantCandidates({
    required Object groupId,
    required List<String> userIds,
  }) async {
    final normalizedUserIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedUserIds.isEmpty) {
      return const [];
    }
    final query = normalizedUserIds
        .map((id) => 'userIds=${Uri.encodeQueryComponent(id)}')
        .join('&');
    final path = Uri(
      path: '/api/v1/groups/$groupId/plans/participant-candidates',
      query: query,
    ).toString();
    final members = await _client.getList(path);
    return members.map(_groupMemberProfile).toList(growable: false);
  }

  @override
  Future<GroupMemberProfile> addMember({
    required Object groupId,
    required String userId,
  }) async {
    final member = await _client.postObject(
      '/api/v1/groups/$groupId/members',
      body: {'userId': userId.trim()},
    );
    return _groupMemberProfile(member);
  }

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async {
    final memories = await _client.getList('/api/v1/groups/$groupId/memories');
    return memories.map(_groupMemoryRecord).toList(growable: false);
  }

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async {
    return (await fetchMessagePage(groupId)).messages;
  }

  @override
  Future<GroupMessagePage> fetchMessagePage(
    Object groupId, {
    String? beforeCursor,
    int? limit,
  }) async {
    final queryParameters = <String, String>{};
    if (beforeCursor != null && beforeCursor.trim().isNotEmpty) {
      queryParameters['beforeCursor'] = beforeCursor.trim();
    }
    if (limit != null) {
      queryParameters['limit'] = limit.toString();
    }
    final path = Uri(
      path: '/api/v1/groups/$groupId/chat/messages',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
    final response = await _client.getObject(path);
    return _groupMessagePage(response);
  }

  @override
  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
    List<GroupMessageAttachment> attachments = const [],
  }) async {
    final response = await _client.postObject(
      '/api/v1/groups/$groupId/chat/messages',
      body: {
        'message': message,
        if (attachments.isNotEmpty)
          'attachments': attachments
              .map((attachment) => attachment.toApiJson())
              .toList(growable: false),
      },
    );
    return _groupMessage(response);
  }

  @override
  Future<int> markMessagesRead({
    required Object groupId,
    String? lastReadMessageId,
  }) async {
    final body = <String, Object?>{};
    if (lastReadMessageId != null && lastReadMessageId.trim().isNotEmpty) {
      body['lastReadMessageId'] = lastReadMessageId.trim();
    }
    final response = await _client.putObject(
      '/api/v1/groups/$groupId/chat/read-state',
      body: body,
    );
    return OnmuJson.readInt(response, 'unreadCount');
  }

  @override
  Stream<GroupMessage> watchMessages(
    Object groupId, {
    String? afterCursor,
  }) async* {
    final queryParameters = <String, String>{};
    if (afterCursor != null && afterCursor.trim().isNotEmpty) {
      queryParameters['afterCursor'] = afterCursor.trim();
    }
    final path = Uri(
      path: '/api/v1/groups/$groupId/chat/events',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
    final lines = await _client.getLineStream(path);
    await for (final json in const GroupChatSseDecoder().decode(lines)) {
      yield _groupMessage(json);
    }
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
  Future<List<VoteSummary>> fetchVotes(
    Object groupId, {
    String? targetType,
    Object? targetId,
  }) async {
    final queryParameters = <String, String>{};
    if (targetType != null && targetType.trim().isNotEmpty) {
      queryParameters['targetType'] = targetType.trim();
    }
    if (targetId != null && targetId.toString().trim().isNotEmpty) {
      queryParameters['targetId'] = targetId.toString().trim();
    }
    final path = Uri(
      path: '/api/v1/groups/$groupId/votes',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
    final votes = await _client.getList(path);
    return votes.map(_voteSummary).toList(growable: false);
  }

  @override
  Future<VoteSummary> createVote(VoteCreateInput input) async {
    final deadlineAt = _deadlineAtFor(input);
    final vote = await _client.postObject(
      '/api/v1/groups/${input.groupId}/votes',
      body: {
        'voteType': 'PLACE',
        'targetType': 'PLAN',
        'targetId': input.planId.toString(),
        'title': input.title,
        'options': input.candidateNames,
        if (deadlineAt != null)
          'deadlineAt': deadlineAt.toUtc().toIso8601String(),
        if (input.placeCandidateIds.isNotEmpty)
          'placeCandidateIds': input.placeCandidateIds,
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
    return _voteCard(vote);
  }

  @override
  Future<VoteCard> submitVote({
    required Object groupId,
    required Object voteId,
    required Object optionId,
  }) async {
    final vote = await _client.postObject(
      '/api/v1/groups/$groupId/votes/$voteId/responses/me',
      body: {'optionId': optionId.toString()},
    );
    return _voteCard(vote);
  }

  VoteCard _voteCard(Map<String, dynamic> vote) {
    final optionSummaries = _voteOptionSummaries(vote);
    final options = optionSummaries.map((option) => option.label).toList();
    return VoteCard(
      title: OnmuJson.readString(vote, 'title', '투표'),
      summary: options.isEmpty ? '등록된 투표 후보가 없어요' : options.join(', '),
      statusLabel: OnmuJson.readString(
        vote,
        'status',
        OnmuJson.readBool(vote, 'closed') ? 'closed' : 'open',
      ),
      actionLabel: '투표 보기',
      participantCount: OnmuJson.readInt(vote, 'participantCount'),
      targetType: OnmuJson.readString(vote, 'targetType'),
      targetId: OnmuJson.readString(vote, 'targetId'),
      options: optionSummaries,
      myOptionId: _myVoteOptionId(vote, optionSummaries),
      deadlineAt: _voteDeadlineAt(vote),
    );
  }

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) async {
    final vote = await _client.getObject(
      '/api/v1/groups/$groupId/votes/$voteId',
    );
    return _voteVotersByCandidateId(vote);
  }

  GroupSummary _groupSummary(Map<String, dynamic> json) {
    final members = OnmuJson.stringList(json['members']);
    final memberAvatars = _groupSummaryMemberAvatars(json, members);
    return GroupSummary(
      id: OnmuJson.readInt(json, 'id'),
      name: OnmuJson.readString(json, 'name', 'ONMU 모임'),
      description: OnmuJson.readString(json, 'description'),
      members: members,
      memberAvatars: memberAvatars,
      lastMessage: OnmuJson.readString(json, 'lastMessage'),
      unreadCount: OnmuJson.readInt(json, 'unreadCount'),
      pinnedPlanTitle: OnmuJson.readString(json, 'pinnedPlanTitle'),
    );
  }

  List<GroupPlanMemberAvatar> _groupSummaryMemberAvatars(
    Map<String, dynamic> json,
    List<String> fallbackNames,
  ) {
    final profiles = OnmuJson.asMapList(json['memberProfiles']);
    if (profiles.isNotEmpty) {
      return profiles
          .map(
            (profile) => GroupPlanMemberAvatar(
              name: OnmuJson.readString(profile, 'name', '참여자'),
              profileImageUrl: _profileImageUrl(profile),
            ),
          )
          .toList(growable: false);
    }
    return fallbackNames
        .map((name) => GroupPlanMemberAvatar(name: name))
        .toList(growable: false);
  }

  GroupPlanSummary _groupPlanSummary(Map<String, dynamic> json) {
    final memberAvatars = _groupPlanMemberAvatars(json);
    return GroupPlanSummary(
      id: OnmuJson.readInt(json, 'id'),
      title: OnmuJson.readString(json, 'title', '약속'),
      dateLabel: OnmuJson.readString(json, 'dateLabel', '일정 미정'),
      startsAt: DateTime.tryParse(OnmuJson.readString(json, 'startsAt')),
      endsAt: DateTime.tryParse(OnmuJson.readString(json, 'endsAt')),
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
      memberAvatars: memberAvatars,
      thumbnailImageUrl: _planThumbnailImageUrl(json),
    );
  }

  String _planThumbnailImageUrl(Map<String, dynamic> json) {
    for (final key in const [
      'thumbnailImageUrl',
      'placeImageUrl',
      'primaryImageUrl',
      'imageUrl',
      'photoUrl',
    ]) {
      final resolved = _absoluteMediaUrl(OnmuJson.readString(json, key));
      if (resolved.isNotEmpty) {
        return resolved;
      }
    }

    for (final key in const ['imageUrls', 'placeImageUrls', 'photoUrls']) {
      final urls = _absoluteMediaUrls(json[key]);
      if (urls.isNotEmpty) {
        return urls.first;
      }
    }

    final place = OnmuJson.asMap(json['place']);
    if (place.isNotEmpty) {
      return _planThumbnailImageUrl(place);
    }

    return '';
  }

  List<GroupPlanMemberAvatar> _groupPlanMemberAvatars(
    Map<String, dynamic> json,
  ) {
    final members = OnmuJson.asMapList(json['members']);
    final rawMembers = members.isNotEmpty
        ? members
        : OnmuJson.asMapList(json['participants']);
    return rawMembers
        .map((member) {
          final name = resolveOnmuDisplayName([
            OnmuJson.readString(member, 'name'),
            OnmuJson.readString(member, 'displayName'),
            OnmuJson.readString(member, 'nickname'),
          ], fallback: '참여자');
          return GroupPlanMemberAvatar(
            name: name,
            profileImageUrl: _profileImageUrl(member),
          );
        })
        .toList(growable: false);
  }

  GroupMessagePage _groupMessagePage(Map<String, dynamic> json) {
    return GroupMessagePage(
      messages: OnmuJson.asMapList(
        json['messages'],
      ).map(_groupMessage).toList(growable: false),
      nextCursor: OnmuJson.readString(json, 'nextCursor').trim().isEmpty
          ? null
          : OnmuJson.readString(json, 'nextCursor').trim(),
      hasMore: OnmuJson.readBool(json, 'hasMore'),
      unreadCount: OnmuJson.readInt(json, 'unreadCount'),
    );
  }

  GroupMessage _groupMessage(Map<String, dynamic> json) {
    final createdAt = OnmuJson.readString(json, 'createdAt');
    final localTimeLabel = _messageTimeLabel(createdAt);
    return GroupMessage(
      id: OnmuJson.readString(json, 'id'),
      cursor: OnmuJson.readString(json, 'cursor'),
      sender: resolveOnmuDisplayName([
        OnmuJson.readString(json, 'senderName'),
        OnmuJson.readString(json, 'sender'),
      ], fallback: 'ONMU'),
      message: _messageText(json),
      timeLabel: localTimeLabel.isEmpty
          ? OnmuJson.readString(json, 'timeLabel')
          : localTimeLabel,
      messageType: OnmuJson.readString(
        json,
        'messageType',
        OnmuJson.readString(json, 'cardType'),
      ),
      cardType: OnmuJson.readString(json, 'cardType'),
      targetType: OnmuJson.readString(json, 'targetType'),
      targetId: OnmuJson.readString(json, 'targetId'),
      planId: OnmuJson.readString(json, 'planId'),
      voteId: OnmuJson.readString(json, 'voteId'),
      settlementId: OnmuJson.readString(json, 'settlementId'),
      isMine: OnmuJson.readBool(json, 'isMine'),
      senderProfileImageUrl: _profileImageUrl(json, 'senderProfileImageUrl'),
      attachments: _messageAttachments(json['attachments']),
      sendStatus: GroupMessageSendStatus.fromApi(
        OnmuJson.readString(json, 'sendStatus', 'sent'),
      ),
    );
  }

  String _messageTimeLabel(String value) {
    if (value.isEmpty) {
      return '';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return '';
    }
    final local = parsed.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _messageText(Map<String, dynamic> json) {
    if (json.containsKey('message')) {
      return json['message']?.toString() ?? '';
    }
    return OnmuJson.readString(json, 'content', '새 활동이 있어요.');
  }

  GroupMemberProfile _groupMemberProfile(Map<String, dynamic> json) {
    return GroupMemberProfile(
      userId: OnmuJson.readString(json, 'userId'),
      name: resolveOnmuDisplayName([
        OnmuJson.readString(json, 'name'),
        OnmuJson.readString(json, 'displayName'),
        OnmuJson.readString(json, 'nickname'),
      ], fallback: '멤버'),
      note: OnmuJson.readString(json, 'note'),
      statusLabel: OnmuJson.readString(json, 'statusLabel', '참여 중'),
      invited: OnmuJson.readBool(json, 'invited'),
      profileImageUrl: _profileImageUrl(json),
      preferenceProfile: _preferenceProfile(json),
    );
  }

  PreferenceProfile? _preferenceProfile(Map<String, dynamic> json) {
    final preferenceJson = OnmuJson.asMap(json['preferenceProfile']);
    return preferenceJson.isEmpty
        ? null
        : PreferenceProfile.fromJson(preferenceJson);
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
      authorProfileImageUrl: _profileImageUrl(json, 'authorProfileImageUrl'),
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

  List<GroupMessageAttachment> _messageAttachments(Object? value) {
    return OnmuJson.asMapList(value)
        .map(_messageAttachment)
        .whereType<GroupMessageAttachment>()
        .toList(growable: false);
  }

  GroupMessageAttachment? _messageAttachment(Map<String, dynamic> json) {
    final type = OnmuJson.readString(json, 'type').toLowerCase();
    if (type != 'image') {
      return null;
    }
    final publicUrl = _absoluteMediaUrl(OnmuJson.readString(json, 'publicUrl'));
    final storageKey = OnmuJson.readString(json, 'storageKey');
    if (publicUrl.isEmpty && storageKey.isEmpty) {
      return null;
    }
    return GroupMessageAttachment(
      type: 'image',
      publicUrl: publicUrl,
      storageKey: storageKey,
      contentType: OnmuJson.readString(json, 'contentType'),
      fileName: OnmuJson.readString(json, 'fileName'),
      width: _positiveInt(json, 'width'),
      height: _positiveInt(json, 'height'),
    );
  }

  int? _positiveInt(Map<String, dynamic> json, String key) {
    final value = OnmuJson.readInt(json, key);
    return value > 0 ? value : null;
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

  String _profileImageUrl(
    Map<String, dynamic> json, [
    String primaryKey = 'profileImageUrl',
  ]) {
    final url = OnmuJson.readString(
      json,
      primaryKey,
      OnmuJson.readString(
        json,
        'profileImageUrl',
        OnmuJson.readString(
          json,
          'profilePhotoUrl',
          OnmuJson.readString(json, 'avatarUrl'),
        ),
      ),
    );
    return resolveOnmuMediaUrl(url, baseUrl: _client.baseUrl);
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
    final optionSummaries = _voteOptionSummaries(json);
    final options = optionSummaries.map((option) => option.label).toList();
    final deadlineAt = _voteDeadlineAt(json);
    final closed = _voteClosed(json, deadlineAt);
    final targetId = OnmuJson.readString(json, 'targetId');
    final myOptionId = _myVoteOptionId(json, optionSummaries);
    final participantAvatars = _voteParticipantAvatars(json);
    final participants = participantAvatars.isNotEmpty
        ? participantAvatars
              .map((avatar) => avatar.name)
              .toList(growable: false)
        : OnmuJson.stringList(json['participants']);
    return VoteSummary(
      id: OnmuJson.readInt(json, 'id'),
      title: OnmuJson.readString(json, 'title', '투표'),
      statusLabel: closed ? '마감' : '진행 중',
      description: options.join(', '),
      planLabel: targetId.isEmpty ? '모임 투표' : '약속 $targetId',
      planMeta: OnmuJson.readString(json, 'voteType', 'PLACE'),
      participants: participants,
      participantAvatars: participantAvatars,
      participantCount: OnmuJson.readInt(json, 'participantCount'),
      options: optionSummaries,
      closed: closed,
      joinedByMe: OnmuJson.readBool(json, 'joinedByMe', myOptionId.isNotEmpty),
      actionLabel: closed ? '결과 보기' : '투표 확인하기',
      targetType: OnmuJson.readString(json, 'targetType'),
      targetId: targetId,
      deadlineAt: deadlineAt,
    );
  }

  bool _voteClosed(Map<String, dynamic> json, DateTime? deadlineAt) {
    final status = OnmuJson.readString(json, 'status').trim().toLowerCase();
    final normalized = status.replaceAll(RegExp(r'[\s_-]'), '');
    if (OnmuJson.readBool(json, 'closed') ||
        normalized == 'closed' ||
        normalized == 'close' ||
        normalized == 'completed' ||
        normalized == 'complete' ||
        normalized == 'done') {
      return true;
    }
    final deadline = deadlineAt?.toLocal();
    return deadline != null && !DateTime.now().toLocal().isBefore(deadline);
  }

  DateTime? _voteDeadlineAt(Map<String, dynamic> json) {
    for (final key in const ['deadlineAt', 'deadline', 'expiresAt', 'dueAt']) {
      final parsed = DateTime.tryParse(OnmuJson.readString(json, key));
      if (parsed != null) {
        return parsed;
      }
    }
    final deadlineDate = OnmuJson.readString(json, 'deadlineDate');
    final deadlineTime = OnmuJson.readString(json, 'deadlineTime');
    if (deadlineDate.isEmpty || deadlineTime.isEmpty) {
      return null;
    }
    return _parseDeadline(deadlineDate, deadlineTime);
  }

  DateTime? _deadlineAtFor(VoteCreateInput input) {
    return _parseDeadline(input.deadlineDate, input.deadlineTime);
  }

  DateTime? _parseDeadline(String date, String time) {
    final normalizedDate = date.trim();
    final normalizedTime = time.trim();
    if (normalizedDate.isEmpty || normalizedTime.isEmpty) {
      return null;
    }
    return DateTime.tryParse('$normalizedDate $normalizedTime') ??
        DateTime.tryParse('${normalizedDate}T$normalizedTime');
  }

  List<VoteParticipantAvatar> _voteParticipantAvatars(
    Map<String, dynamic> json,
  ) {
    final profileMaps = OnmuJson.asMapList(json['participantProfiles']);
    final source = profileMaps.isNotEmpty ? profileMaps : json['participants'];
    if (source is! List) {
      return const [];
    }

    return source
        .map((participant) {
          if (participant is Map) {
            final map = Map<String, dynamic>.from(participant);
            final name = resolveOnmuDisplayName([
              OnmuJson.readString(map, 'nickname'),
              OnmuJson.readString(map, 'name'),
            ], fallback: '');
            if (name.trim().isEmpty) {
              return null;
            }
            return VoteParticipantAvatar(
              name: name.trim(),
              profileImageUrl: _profileImageUrl(map),
            );
          }
          final name = participant.toString().trim();
          if (name.isEmpty) {
            return null;
          }
          return VoteParticipantAvatar(name: name);
        })
        .whereType<VoteParticipantAvatar>()
        .toList(growable: false);
  }

  List<VoteOptionSummary> _voteOptionSummaries(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List) {
      return const [];
    }
    return rawOptions
        .map((option) {
          if (option is Map) {
            final map = Map<String, dynamic>.from(option);
            final label =
                map['label']?.toString() ??
                map['name']?.toString() ??
                map['candidateName']?.toString() ??
                '';
            if (label.isEmpty) {
              return null;
            }
            return VoteOptionSummary(
              id: OnmuJson.readString(map, 'id'),
              label: label,
              countLabel: OnmuJson.readString(map, 'countLabel', '0표'),
              progress: _progress(map['progress']),
              targetType: OnmuJson.readString(map, 'targetType'),
              targetId: OnmuJson.readString(map, 'targetId'),
              candidateId: OnmuJson.readString(map, 'candidateId'),
              responseCount: OnmuJson.readInt(map, 'responseCount'),
              selectedByMe: OnmuJson.readBool(map, 'selectedByMe'),
            );
          }
          final label = option.toString();
          if (label.isEmpty) {
            return null;
          }
          return VoteOptionSummary(label: label, countLabel: '0표', progress: 0);
        })
        .whereType<VoteOptionSummary>()
        .toList(growable: false);
  }

  double _progress(Object? value) {
    if (value is num) {
      return value.toDouble().clamp(0, 1).toDouble();
    }
    return double.tryParse(value?.toString() ?? '')?.clamp(0, 1).toDouble() ??
        0;
  }

  Map<int, List<String>> _voteVotersByCandidateId(Map<String, dynamic> json) {
    final fromProjection = _votersByCandidateMap(json['votersByCandidateId']);
    if (fromProjection.isNotEmpty) {
      return fromProjection;
    }

    final voters = <int, List<String>>{};
    for (final option in OnmuJson.asMapList(json['options'])) {
      final candidateId = _candidateIdFromVoteOption(option);
      if (candidateId == 0) {
        continue;
      }
      final names = _voterNames(option['voters'])
          .ifEmpty(() => _voterNames(option['voterNames']))
          .ifEmpty(() => _voterNames(option['respondents']));
      if (names.isNotEmpty) {
        voters[candidateId] = names;
      }
    }
    return Map.unmodifiable(voters);
  }

  Map<int, List<String>> _votersByCandidateMap(Object? raw) {
    if (raw is! Map) {
      return const {};
    }
    final result = <int, List<String>>{};
    for (final entry in raw.entries) {
      final candidateId = int.tryParse(entry.key.toString()) ?? 0;
      if (candidateId == 0) {
        continue;
      }
      final names = _voterNames(entry.value);
      if (names.isNotEmpty) {
        result[candidateId] = names;
      }
    }
    return Map.unmodifiable(result);
  }

  List<String> _voterNames(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .map((voter) {
          if (voter is Map) {
            final map = Map<String, dynamic>.from(voter);
            return resolveOnmuDisplayName([
              OnmuJson.readString(map, 'nickname'),
              OnmuJson.readString(map, 'displayName'),
              OnmuJson.readString(map, 'name'),
            ], fallback: '');
          }
          return voter.toString();
        })
        .where((name) => name.trim().isNotEmpty)
        .map((name) => name.trim())
        .toList(growable: false);
  }

  int _candidateIdFromVoteOption(Map<String, dynamic> option) {
    final candidateId = int.tryParse(
      OnmuJson.readString(option, 'candidateId'),
    );
    if (candidateId != null && candidateId != 0) {
      return candidateId;
    }
    if (OnmuJson.readString(option, 'targetType').toUpperCase() ==
        'PLACE_CANDIDATE') {
      return int.tryParse(OnmuJson.readString(option, 'targetId')) ?? 0;
    }
    return 0;
  }

  String _myVoteOptionId(
    Map<String, dynamic> json,
    List<VoteOptionSummary> options,
  ) {
    final explicit = OnmuJson.readString(
      json,
      'myOptionId',
      OnmuJson.readString(json, 'selectedOptionId'),
    );
    if (explicit.isNotEmpty) {
      return explicit;
    }
    for (final option in options) {
      if (option.selectedByMe && option.id.trim().isNotEmpty) {
        return option.id.trim();
      }
    }
    return '';
  }
}

extension _ListFallback<T> on List<T> {
  List<T> ifEmpty(List<T> Function() fallback) {
    return isEmpty ? fallback() : this;
  }
}

class GroupChatSseDecoder {
  const GroupChatSseDecoder();

  Stream<Map<String, dynamic>> decode(Stream<String> lines) async* {
    final dataLines = <String>[];
    await for (final line in lines) {
      if (line.isEmpty) {
        final decoded = _decodeData(dataLines);
        dataLines.clear();
        if (decoded != null) {
          yield decoded;
        }
        continue;
      }
      if (line.startsWith(':')) {
        continue;
      }
      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }

    final decoded = _decodeData(dataLines);
    if (decoded != null) {
      yield decoded;
    }
  }

  Map<String, dynamic>? _decodeData(List<String> dataLines) {
    if (dataLines.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(dataLines.join('\n'));
      return OnmuJson.asMap(decoded);
    } catch (_) {
      return null;
    }
  }
}
