import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../repository/group_repository.dart';

final groupHomeViewModelProvider =
    AsyncNotifierProvider.family<GroupHomeViewModel, GroupHomeState, String>(
      GroupHomeViewModel.new,
    );

class GroupHomeState {
  const GroupHomeState({
    required this.group,
    required this.recentMemories,
    required this.recentMessage,
    this.pinnedPlan,
  });

  final GroupSummary group;
  final GroupPinnedPlan? pinnedPlan;
  final List<GroupMemoryRecord> recentMemories;
  final GroupMessage? recentMessage;
}

class GroupHomeViewModel extends FamilyAsyncNotifier<GroupHomeState, String> {
  @override
  Future<GroupHomeState> build(String arg) async {
    final repository = ref.watch(groupRepositoryProvider);
    final group = await repository.fetchGroup(arg);
    final pinnedPlan = await repository.fetchPinnedPlan(arg);
    final memories = await repository.fetchMemories(arg);
    final messages = await repository.fetchMessages(arg);

    return GroupHomeState(
      group: group,
      pinnedPlan: pinnedPlan,
      recentMemories: List.unmodifiable(memories.take(4)),
      recentMessage: messages.isEmpty ? null : messages.first,
    );
  }
}
