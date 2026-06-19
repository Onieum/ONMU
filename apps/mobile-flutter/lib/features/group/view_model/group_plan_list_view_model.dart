import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../repository/group_repository.dart';

final groupPlanListViewModelProvider =
    AsyncNotifierProvider.family<
      GroupPlanListViewModel,
      GroupPlanListState,
      String
    >(GroupPlanListViewModel.new);

class GroupPlanListState {
  const GroupPlanListState({
    required this.ongoingPlans,
    required this.upcomingPlans,
    required this.pastPlans,
    required this.members,
  });

  final List<GroupPlanSummary> ongoingPlans;
  final List<GroupPlanSummary> upcomingPlans;
  final List<GroupPlanSummary> pastPlans;
  final List<GroupMemberProfile> members;
}

class GroupPlanListViewModel extends AsyncNotifier<GroupPlanListState> {
  GroupPlanListViewModel(this.groupId);

  final String groupId;

  @override
  Future<GroupPlanListState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final plans = await repository.fetchPlans(groupId);
    final members = await repository.fetchMembers(groupId);
    final now = DateTime.now().toLocal();
    final ongoingPlans = _ongoingPlans(plans, now);
    final upcomingPlans = _upcomingPlans(plans, now);

    return GroupPlanListState(
      ongoingPlans: ongoingPlans,
      upcomingPlans: upcomingPlans,
      pastPlans: _pastPlans(plans, ongoingPlans, upcomingPlans),
      members: members,
    );
  }

  List<GroupPlanSummary> _ongoingPlans(
    List<GroupPlanSummary> plans,
    DateTime now,
  ) {
    return plans.where((plan) => plan.isOngoingAt(now)).toList()
      ..sort(GroupPlanSummary.compareUpcoming);
  }

  List<GroupPlanSummary> _upcomingPlans(
    List<GroupPlanSummary> plans,
    DateTime now,
  ) {
    return plans
        .where((plan) => !plan.isOngoingAt(now) && plan.isUpcomingFrom(now))
        .toList()
      ..sort(GroupPlanSummary.compareUpcoming);
  }

  List<GroupPlanSummary> _pastPlans(
    List<GroupPlanSummary> plans,
    List<GroupPlanSummary> ongoingPlans,
    List<GroupPlanSummary> upcomingPlans,
  ) {
    final excludedIds = {
      ...ongoingPlans.map((plan) => plan.id),
      ...upcomingPlans.map((plan) => plan.id),
    };
    return plans.where((plan) => !excludedIds.contains(plan.id)).toList()
      ..sort(GroupPlanSummary.compareUpcoming);
  }
}
