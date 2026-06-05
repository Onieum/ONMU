import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => const MockGroupRepository(),
);

abstract interface class GroupRepository {
  Future<List<GroupSummary>> fetchGroups();

  Future<GroupSummary> fetchGroup(Object groupId);

  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId);

  Future<List<GroupPlanSummary>> fetchPlans(Object groupId);

  Future<List<GroupMemberProfile>> fetchMembers(Object groupId);

  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId);

  Future<List<GroupMessage>> fetchMessages(Object groupId);

  Future<VoteCard> fetchVoteCard(Object groupId);

  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  });
}

class MockGroupRepository implements GroupRepository {
  const MockGroupRepository();

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async {
    return mockGroups.firstWhere(
      (group) => group.id.toString() == groupId.toString(),
      orElse: () => mockGroups.first,
    );
  }

  @override
  Future<List<GroupSummary>> fetchGroups() async {
    return List.unmodifiable(mockGroups);
  }

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async {
    return List.unmodifiable(mockGroupPlans);
  }

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async {
    return List.unmodifiable(mockGroupMemories);
  }

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async {
    return List.unmodifiable(mockGroupMemberProfiles);
  }

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async {
    return List.unmodifiable(mockGroupMessages);
  }

  @override
  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) async {
    return mockGroupMemories.firstWhere(
      (memory) => memory.id.toString() == memoryId.toString(),
      orElse: () => mockGroupMemories.first,
    );
  }

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async {
    return mockPinnedPlan;
  }

  @override
  Future<VoteCard> fetchVoteCard(Object groupId) async {
    return mockVoteCard;
  }
}
