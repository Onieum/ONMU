import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/plan_models.dart';
import '../../group/repository/group_repository.dart';
import '../../plan/repository/plan_repository.dart';
import '../../settlement/repository/settlement_repository.dart';

final homeViewModelProvider = AsyncNotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

class HomeState {
  const HomeState({
    required this.groupId,
    required this.activePlan,
    required this.upcomingPlans,
    required this.settlementId,
  });

  final int groupId;
  final Plan activePlan;
  final List<GroupPlanSummary> upcomingPlans;
  final int settlementId;
}

class HomeViewModel extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final groupRepository = ref.watch(groupRepositoryProvider);
    final planRepository = ref.watch(planRepositoryProvider);
    final settlementRepository = ref.watch(settlementRepositoryProvider);

    final groups = await groupRepository.fetchGroups();
    final group = groups.first;
    final pinnedPlan = await groupRepository.fetchPinnedPlan(group.id);
    final plans = await groupRepository.fetchPlans(group.id);
    final activePlanId = pinnedPlan?.id ?? plans.first.id;
    final activePlan = await planRepository.fetchPlan(
      groupId: group.id,
      planId: activePlanId,
    );
    final settlement = await settlementRepository.fetchSettlement(
      groupId: group.id,
      planId: activePlan.id,
    );

    return HomeState(
      groupId: group.id,
      activePlan: activePlan,
      upcomingPlans: plans.where((plan) => !plan.isPast).toList(),
      settlementId: settlement.id,
    );
  }
}
