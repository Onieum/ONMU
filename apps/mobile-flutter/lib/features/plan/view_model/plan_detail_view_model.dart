import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../group/view_model/group_home_view_model.dart';
import '../../group/view_model/group_list_view_model.dart';
import '../../group/view_model/group_plan_list_view_model.dart';
import '../../home/view_model/home_view_model.dart';
import '../../../shared/models/plan_models.dart';
import '../repository/plan_repository.dart';

typedef PlanScope = ({String groupId, String planId});

final planDetailViewModelProvider =
    AsyncNotifierProvider.family<
      PlanDetailViewModel,
      PlanDetailState,
      PlanScope
    >(PlanDetailViewModel.new);

class PlanDetailState {
  const PlanDetailState({
    required this.plan,
    required this.selectedMembers,
    required this.visitPlansByDate,
    required this.dateTabs,
    required this.participantArrivals,
    this.currentTime,
  });

  final Plan plan;
  final List<PlanMember> selectedMembers;
  final List<List<VisitPlan>> visitPlansByDate;
  final List<PlanDateTab> dateTabs;
  final List<PlanParticipantArrival> participantArrivals;
  final DateTime? currentTime;

  List<VisitPlan> visitPlanForDate(int index) {
    if (index < 0 || index >= visitPlansByDate.length) {
      return const [];
    }

    return visitPlansByDate[index];
  }

  PlanDateTab dateTabForDate(int index) {
    if (dateTabs.isEmpty) {
      return const PlanDateTab(tabLabel: '일정', headingLabel: '일정 동선');
    }
    if (index < 0 || index >= dateTabs.length) {
      return dateTabs.first;
    }
    return dateTabs[index];
  }

  bool get canShareArrivalStatus =>
      plan.isInProgressAt(currentTime ?? DateTime.now());
}

class PlanDetailViewModel extends AsyncNotifier<PlanDetailState> {
  PlanDetailViewModel(this.scope);

  final PlanScope scope;

  @override
  Future<PlanDetailState> build() async {
    final repository = ref.watch(planRepositoryProvider);
    final plan = await repository.fetchPlan(
      groupId: scope.groupId,
      planId: scope.planId,
    );
    final visitPlansByDate = await repository.fetchVisitPlansByDate(
      groupId: scope.groupId,
      planId: scope.planId,
    );
    final participantArrivals = await repository.fetchPlanParticipants(
      groupId: scope.groupId,
      planId: scope.planId,
    );
    final displayVisitPlansByDate = _alignVisitPlansByPlanDates(
      plan: plan,
      visitPlansByDate: visitPlansByDate,
    );

    return PlanDetailState(
      plan: plan,
      selectedMembers: List.unmodifiable(
        _selectedMembers(plan, participantArrivals),
      ),
      visitPlansByDate: List.unmodifiable(
        displayVisitPlansByDate.map(List<VisitPlan>.unmodifiable),
      ),
      dateTabs: List.unmodifiable(
        buildPlanDateTabs(plan: plan, dayCount: displayVisitPlansByDate.length),
      ),
      participantArrivals: List.unmodifiable(participantArrivals),
      currentTime: DateTime.now(),
    );
  }

  List<List<VisitPlan>> _alignVisitPlansByPlanDates({
    required Plan plan,
    required List<List<VisitPlan>> visitPlansByDate,
  }) {
    final count = _planDayCount(plan, visitPlansByDate.length);
    final result = List.generate(count, (_) => <VisitPlan>[]);
    final startDate = _dateOnly(
      plan.startsAt?.toLocal() ?? DateTime.tryParse(plan.dateTime)?.toLocal(),
    );
    final flattened = visitPlansByDate.expand((plans) => plans).toList();
    final hasDatedVisits =
        startDate != null &&
        flattened.any((visit) {
          return visit.startsAt != null;
        });

    if (hasDatedVisits) {
      for (final visit in flattened) {
        final visitDate = _dateOnly(visit.startsAt?.toLocal());
        final index = visitDate == null
            ? 0
            : visitDate.difference(startDate).inDays;
        if (index < 0 || index >= result.length) {
          result.first.add(visit);
          continue;
        }
        result[index].add(visit);
      }
      return result.map(List<VisitPlan>.unmodifiable).toList(growable: false);
    }

    for (var index = 0; index < visitPlansByDate.length; index += 1) {
      if (index >= result.length) {
        break;
      }
      result[index].addAll(visitPlansByDate[index]);
    }
    return result.map(List<VisitPlan>.unmodifiable).toList(growable: false);
  }

  List<PlanMember> _selectedMembers(
    Plan plan,
    List<PlanParticipantArrival> participantArrivals,
  ) {
    final planMembers = plan.members
        .where((member) => member.selected)
        .toList(growable: false);
    final selectedMembers = [...planMembers];
    final selectedNames = {
      for (final member in selectedMembers) member.name.trim(),
    };

    for (final participant in participantArrivals) {
      if (participant.isFallback) {
        continue;
      }
      final status = participant.participantStatus.trim().toLowerCase();
      if (status == 'left' || status == 'declined') {
        continue;
      }
      final name = participant.nickname.trim();
      if (name.isEmpty || selectedNames.contains(name)) {
        continue;
      }
      selectedNames.add(name);
      selectedMembers.add(
        PlanMember(
          userId: participant.userId,
          name: name,
          message: '',
          badge: '참여 중',
          selected: true,
          profileImageUrl: participant.profileImageUrl,
          preferenceProfile: participant.preferenceProfile,
        ),
      );
    }

    return selectedMembers;
  }

  Future<void> updateMyArrivalStatus(PlanArrivalStatus status) async {
    final detail = state.asData?.value;
    if (status != PlanArrivalStatus.none &&
        detail != null &&
        !detail.canShareArrivalStatus) {
      throw StateError('약속 진행 시간에만 상태를 공유할 수 있습니다.');
    }

    final repository = ref.read(planRepositoryProvider);
    await repository.updateMyArrivalStatus(
      groupId: scope.groupId,
      planId: scope.planId,
      status: status,
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> joinAsCurrentUser() async {
    await updateMyArrivalStatus(PlanArrivalStatus.none);
  }

  Future<void> leaveAsCurrentUser() async {
    final repository = ref.read(planRepositoryProvider);
    await repository.leaveAsCurrentUser(
      groupId: scope.groupId,
      planId: scope.planId,
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> addParticipant(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }
    final repository = ref.read(planRepositoryProvider);
    await repository.addParticipant(
      groupId: scope.groupId,
      planId: scope.planId,
      userId: normalizedUserId,
    );
    ref.invalidateSelf();
    await future;
  }

  Future<Plan> savePlan({
    required PlanCreateInput input,
    required bool editing,
  }) async {
    final repository = ref.read(planRepositoryProvider);
    final plan = editing
        ? await repository.updatePlan(planId: scope.planId, input: input)
        : await repository.createPlan(input);

    ref.invalidate(groupPlanListViewModelProvider(scope.groupId));
    ref.invalidate(groupHomeViewModelProvider(scope.groupId));
    ref.invalidate(groupListViewModelProvider);
    ref.invalidate(homeViewModelProvider);
    ref.invalidateSelf();
    return plan;
  }
}

class PlanDateTab {
  const PlanDateTab({required this.tabLabel, required this.headingLabel});

  final String tabLabel;
  final String headingLabel;
}

List<PlanDateTab> buildPlanDateTabs({
  required Plan plan,
  required int dayCount,
}) {
  final count = _planDayCount(plan, dayCount);
  final start =
      plan.startsAt?.toLocal() ?? DateTime.tryParse(plan.dateTime)?.toLocal();
  if (start == null) {
    final fallback = plan.dateTime.trim().isEmpty ? '일정' : plan.dateTime.trim();
    return [
      for (var index = 0; index < count; index += 1)
        PlanDateTab(
          tabLabel: count == 1 ? fallback : 'Day ${index + 1}',
          headingLabel: count == 1 ? '$fallback 동선' : 'Day ${index + 1} 동선',
        ),
    ];
  }

  return [
    for (var index = 0; index < count; index += 1)
      _dateTabFor(start.add(Duration(days: index))),
  ];
}

int _planDayCount(Plan plan, int fallbackDayCount) {
  final start =
      plan.startsAt?.toLocal() ?? DateTime.tryParse(plan.dateTime)?.toLocal();
  if (start == null) {
    return fallbackDayCount <= 0 ? 1 : fallbackDayCount;
  }
  final end = (plan.endsAt?.toLocal() ?? start);
  final startDate = _dateOnly(start)!;
  final endDate = _dateOnly(end)!;
  final span = endDate.difference(startDate).inDays + 1;
  final planSpan = span <= 0 ? 1 : span;
  return planSpan > fallbackDayCount ? planSpan : fallbackDayCount;
}

DateTime? _dateOnly(DateTime? value) {
  if (value == null) {
    return null;
  }
  return DateTime(value.year, value.month, value.day);
}

PlanDateTab _dateTabFor(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final label = '${date.month}/${date.day} ${weekdays[date.weekday - 1]}';
  return PlanDateTab(tabLabel: label, headingLabel: '$label 동선');
}
