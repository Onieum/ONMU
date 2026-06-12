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
    var plans = await groupRepository.fetchPlans(group.id);
    for (final candidateGroup in groups) {
      final candidatePlans = await groupRepository.fetchPlans(
        candidateGroup.id,
      );
      if (_activePlanSummary(candidatePlans) != null ||
          _upcomingPlans(candidatePlans).isNotEmpty) {
        group = candidateGroup;
        plans = candidatePlans;
        break;
      }
    }
    final activePlanSummary = _activePlanSummary(plans);
    if (activePlanSummary == null) {
      return HomeState(
        groupId: group.id,
        activePlan: null,
        upcomingPlans: _upcomingPlans(plans),
        settlementId: null,
        todayPlanCount: _countTodayPlans(plans),
      );
    }

    final activePlan = await planRepository.fetchPlan(
      groupId: group.id,
      planId: activePlanSummary.id,
    );
    final settlementId = await _fetchSettlementIdOrNull(
      settlementRepository: settlementRepository,
      groupId: group.id,
      planId: activePlan.id,
    );

    return HomeState(
      groupId: group.id,
      activePlan: activePlan,
      upcomingPlans: _upcomingPlans(plans),
      settlementId: settlementId,
      todayPlanCount: _countTodayPlans(plans),
    );
  }

  GroupPlanSummary? _activePlanSummary(List<GroupPlanSummary> plans) {
    final now = DateTime.now().toLocal();
    final activePlans = plans.where((plan) {
      final status = plan.progressStatus;
      if (plan.isPast || status != PlanProgressStatus.active) {
        return false;
      }

      final startsAt = plan.startsAt?.toLocal();
      return startsAt != null && !startsAt.isAfter(now);
    }).toList();

    activePlans.sort((left, right) {
      final leftStartsAt = left.startsAt?.toLocal();
      final rightStartsAt = right.startsAt?.toLocal();
      if (leftStartsAt == null && rightStartsAt == null) {
        return left.id.compareTo(right.id);
      }
      if (leftStartsAt == null) {
        return 1;
      }
      if (rightStartsAt == null) {
        return -1;
      }
      final compared = rightStartsAt.compareTo(leftStartsAt);
      return compared == 0 ? left.id.compareTo(right.id) : compared;
    });
    return activePlans.firstOrNull;
  }

  List<GroupPlanSummary> _upcomingPlans(List<GroupPlanSummary> plans) {
    final now = DateTime.now().toLocal();
    return plans.where((plan) => plan.isUpcomingFrom(now)).toList()
      ..sort(GroupPlanSummary.compareUpcoming);
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
