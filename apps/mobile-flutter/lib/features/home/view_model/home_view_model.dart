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
    required this.todayPlanCount,
  });

  const HomeState.empty()
    : groupId = null,
      activePlan = null,
      upcomingPlans = const [],
      settlementId = null,
      todayPlanCount = 0;

  final int? groupId;
  final Plan? activePlan;
  final List<GroupPlanSummary> upcomingPlans;
  final int? settlementId;
  final int todayPlanCount;
}

class HomeViewModel extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final groupRepository = ref.watch(groupRepositoryProvider);
    final planRepository = ref.watch(planRepositoryProvider);
    final settlementRepository = ref.watch(settlementRepositoryProvider);

    final groups = await groupRepository.fetchGroups();
    if (groups.isEmpty) {
      return const HomeState.empty();
    }

    var group = groups.first;
    var pinnedPlan = await groupRepository.fetchPinnedPlan(group.id);
    var plans = await groupRepository.fetchPlans(group.id);
    for (final candidateGroup in groups) {
      final candidatePinnedPlan = await groupRepository.fetchPinnedPlan(
        candidateGroup.id,
      );
      final candidatePlans = await groupRepository.fetchPlans(
        candidateGroup.id,
      );
      if (candidatePinnedPlan != null || candidatePlans.isNotEmpty) {
        group = candidateGroup;
        pinnedPlan = candidatePinnedPlan;
        plans = candidatePlans;
        break;
      }
    }
    final activePlanId = pinnedPlan?.id ?? plans.firstOrNull?.id;
    if (activePlanId == null) {
      return HomeState(
        groupId: group.id,
        activePlan: null,
        upcomingPlans: const [],
        settlementId: null,
        todayPlanCount: _countTodayPlans(plans),
      );
    }

    final activePlan = await planRepository.fetchPlan(
      groupId: group.id,
      planId: activePlanId,
    );
    final settlementId = await _fetchSettlementIdOrNull(
      settlementRepository: settlementRepository,
      groupId: group.id,
      planId: activePlan.id,
    );

    return HomeState(
      groupId: group.id,
      activePlan: activePlan,
      upcomingPlans: plans.where((plan) => !plan.isPast).toList(),
      settlementId: settlementId,
      todayPlanCount: _countTodayPlans(plans),
    );
  }

  int _countTodayPlans(List<GroupPlanSummary> plans) {
    final now = DateTime.now().toLocal();
    return plans.where((plan) {
      final startsAt = plan.startsAt?.toLocal();
      if (startsAt == null) {
        return false;
      }
      return startsAt.year == now.year &&
          startsAt.month == now.month &&
          startsAt.day == now.day;
    }).length;
  }

  Future<int?> _fetchSettlementIdOrNull({
    required SettlementRepository settlementRepository,
    required Object groupId,
    required Object planId,
  }) async {
    try {
      final settlement = await settlementRepository.fetchSettlement(
        groupId: groupId,
        planId: planId,
      );
      return settlement.id;
    } catch (_) {
      return null;
    }
  }
}
