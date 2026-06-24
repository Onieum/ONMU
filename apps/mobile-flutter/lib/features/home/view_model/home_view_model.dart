import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/ootd_model.dart';
import '../../../shared/models/plan_models.dart';
import '../repository/home_repository.dart';
import '../../ootd/repository/record_repository.dart';

final homeViewModelProvider = AsyncNotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

final homeRecentRecordsProvider = FutureProvider<List<OotdRecord>>((ref) async {
  final records = await ref.watch(recordRepositoryProvider).fetchMyRecords();
  return _recentRecords(records);
});

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
    final homeRepository = ref.watch(homeRepositoryProvider);

    final summary = await homeRepository.fetchSummary();
    if (summary.groups.isEmpty) {
      return const HomeState.empty();
    }

    final plans = summary.upcomingPlans;
    final todayPlans = _todayPlans(plans);
    final activePlan = _activePlan(summary, plans);

    return HomeState(
      groupId: _selectedGroupId(summary),
      activePlan: activePlan == null ? null : _toPlan(activePlan),
      todayPlans: todayPlans,
      upcomingPlans: _upcomingPlans(plans),
      calendarPlans: _calendarPlans(plans),
      settlementId: int.tryParse(
        summary.settlementId.trim().isNotEmpty
            ? summary.settlementId
            : activePlan?.settlementId ?? '',
      ),
      todayPlanCount: todayPlans.length,
    );
  }

  int _selectedGroupId(HomeSummary summary) {
    for (final plan in [
      summary.activePlan,
      summary.nextPlan,
      ...summary.upcomingPlans,
    ]) {
      final groupId = plan?.groupId;
      if (groupId != null) {
        return groupId;
      }
    }
    return summary.groups.first.id;
  }

  GroupPlanSummary? _activePlan(
    HomeSummary summary,
    List<GroupPlanSummary> plans,
  ) {
    if (summary.activePlan != null) {
      return summary.activePlan;
    }
    final now = DateTime.now().toLocal();
    for (final plan in plans) {
      if (plan.isOngoingAt(now)) {
        return plan;
      }
    }
    return null;
  }

  Plan _toPlan(GroupPlanSummary summary) {
    return Plan(
      id: summary.id,
      title: summary.title,
      dateTime: summary.dateLabel,
      location: summary.placeName,
      status: summary.statusType,
      memo: '',
      members: const [],
      timeCandidates: const [],
      visitPlan: const [],
      startsAt: summary.startsAt,
      endsAt: summary.endsAt,
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

List<OotdRecord> _recentRecords(List<OotdRecord> records) {
  final sorted = records.toList(growable: false)
    ..sort((left, right) => right.date.compareTo(left.date));
  return List.unmodifiable(sorted);
}
