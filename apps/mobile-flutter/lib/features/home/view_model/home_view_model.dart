import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/plan_models.dart';
import '../../group/repository/group_repository.dart';

final homeViewModelProvider = AsyncNotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

class HomeState {
  const HomeState({
    required this.groupId,
    required this.activePlan,
    required this.todayPlans,
    required this.upcomingPlans,
    required this.calendarPlans,
    required this.settlementId,
    required this.todayPlanCount,
  });

  const HomeState.empty()
    : groupId = null,
      activePlan = null,
      todayPlans = const [],
      upcomingPlans = const [],
      calendarPlans = const [],
      settlementId = null,
      todayPlanCount = 0;

  final int? groupId;
  final Plan? activePlan;
  final List<GroupPlanSummary> todayPlans;
  final List<GroupPlanSummary> upcomingPlans;
  final List<GroupPlanSummary> calendarPlans;
  final int? settlementId;
  final int todayPlanCount;
}

class HomeViewModel extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final groupRepository = ref.watch(groupRepositoryProvider);

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
      if (_todayPlans(candidatePlans).isNotEmpty ||
          _upcomingPlans(candidatePlans).isNotEmpty) {
        group = candidateGroup;
        plans = candidatePlans;
        break;
      }
    }
    final todayPlans = _todayPlans(plans);

    return HomeState(
      groupId: group.id,
      activePlan: null,
      todayPlans: todayPlans,
      upcomingPlans: _upcomingPlans(plans),
      calendarPlans: _calendarPlans(plans),
      settlementId: null,
      todayPlanCount: todayPlans.length,
    );
  }

  List<GroupPlanSummary> _todayPlans(List<GroupPlanSummary> plans) {
    final now = DateTime.now().toLocal();
    return plans.where((plan) => plan.isRemainingTodayAt(now)).toList()
      ..sort(GroupPlanSummary.compareUpcoming);
  }

  List<GroupPlanSummary> _upcomingPlans(List<GroupPlanSummary> plans) {
    final now = DateTime.now().toLocal();
    return plans.where((plan) {
      if (!plan.isUpcomingFrom(now)) {
        return false;
      }
      final startsAt = plan.startsAt?.toLocal();
      if (startsAt == null) {
        return true;
      }
      return !_isSameLocalDate(startsAt, now);
    }).toList()..sort(GroupPlanSummary.compareUpcoming);
  }

  List<GroupPlanSummary> _calendarPlans(List<GroupPlanSummary> plans) {
    return plans.where((plan) => plan.startsAt != null).toList()
      ..sort(GroupPlanSummary.compareUpcoming);
  }

  bool _isSameLocalDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
