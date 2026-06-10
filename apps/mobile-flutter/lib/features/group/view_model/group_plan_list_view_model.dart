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
    required this.upcomingPlans,
    required this.pastPlans,
    required this.members,
  });

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
    final upcomingPlans = _upcomingPlans(plans);

    return GroupPlanListState(
      upcomingPlans: upcomingPlans,
      pastPlans: plans.where((plan) => !upcomingPlans.contains(plan)).toList(),
      members: members,
    );
  }

  List<GroupPlanSummary> _upcomingPlans(List<GroupPlanSummary> plans) {
    final now = DateTime.now().toLocal();
    return plans.where((plan) => plan.isUpcomingFrom(now)).toList()
      ..sort(GroupPlanSummary.compareUpcoming);
  }
}
