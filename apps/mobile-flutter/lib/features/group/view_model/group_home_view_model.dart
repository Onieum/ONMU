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
    required this.upcomingPlan,
    required this.recentMemories,
    required this.recentMessage,
  });

  final GroupSummary group;
  final GroupPlanSummary? upcomingPlan;
  final List<GroupMemoryRecord> recentMemories;
  final GroupMessage? recentMessage;
}

class GroupHomeViewModel extends AsyncNotifier<GroupHomeState> {
  GroupHomeViewModel(this.groupId);

  final String groupId;

  @override
  Future<GroupHomeState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final group = await repository.fetchGroup(groupId);
    final plans = await repository.fetchPlans(groupId);
    final memories = await _optionalList(
      () => repository.fetchMemories(groupId),
    );
    final messages = await _optionalList(
      () => repository.fetchMessages(groupId),
    );

    return GroupHomeState(
      group: group,
      upcomingPlan: _nearestUpcomingPlan(plans),
      recentMemories: List.unmodifiable(memories.take(4)),
      recentMessage: messages.isEmpty ? null : messages.first,
    );
  }

  Future<List<T>> _optionalList<T>(Future<List<T>> Function() load) async {
    try {
      return await load();
    } catch (_) {
      return const [];
    }
  }

  GroupPlanSummary? _nearestUpcomingPlan(List<GroupPlanSummary> plans) {
    final now = DateTime.now().toLocal();
    final upcoming = plans.where((plan) => plan.isUpcomingFrom(now)).toList()
      ..sort(GroupPlanSummary.compareUpcoming);

    return upcoming.firstOrNull;
  }
}
