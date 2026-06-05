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

class GroupPlanListViewModel
    extends FamilyAsyncNotifier<GroupPlanListState, String> {
  @override
  Future<GroupPlanListState> build(String arg) async {
    final repository = ref.watch(groupRepositoryProvider);
    final plans = await repository.fetchPlans(arg);
    final members = await repository.fetchMembers(arg);

    return GroupPlanListState(
      upcomingPlans: plans.where((plan) => !plan.isPast).toList(),
      pastPlans: plans.where((plan) => plan.isPast).toList(),
      members: members,
    );
  }
}
