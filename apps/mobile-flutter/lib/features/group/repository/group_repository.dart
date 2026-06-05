import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/vote_models.dart';
import '../../../shared/repository/in_memory_onmu_store.dart';

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => MockGroupRepository(ref.watch(inMemoryOnmuStoreProvider)),
);

abstract interface class GroupRepository {
  Future<List<GroupSummary>> fetchGroups();

  Future<GroupSummary> fetchGroup(Object groupId);

  Future<GroupSummary> createGroup(GroupCreateInput input);

  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId);

  Future<List<GroupPlanSummary>> fetchPlans(Object groupId);

  Future<List<GroupMemberProfile>> fetchMembers(Object groupId);

  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId);

  Future<List<GroupMessage>> fetchMessages(Object groupId);

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
