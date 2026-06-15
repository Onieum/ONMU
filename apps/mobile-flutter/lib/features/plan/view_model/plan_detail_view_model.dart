import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.participantArrivals,
    this.currentTime,
  });

  final Plan plan;
  final List<PlanMember> selectedMembers;
  final List<List<VisitPlan>> visitPlansByDate;
  final List<PlanParticipantArrival> participantArrivals;
  final DateTime? currentTime;

  List<VisitPlan> visitPlanForDate(int index) {
    if (index < 0 || index >= visitPlansByDate.length) {
      return const [];
    }

    return visitPlansByDate[index];
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
    final displayVisitPlansByDate =
        visitPlansByDate.isEmpty && plan.visitPlan.isNotEmpty
        ? [plan.visitPlan]
        : visitPlansByDate;

    return PlanDetailState(
      plan: plan,
      selectedMembers: List.unmodifiable(
        _selectedMembers(plan, participantArrivals),
      ),
      visitPlansByDate: List.unmodifiable(
        displayVisitPlansByDate.map(List<VisitPlan>.unmodifiable),
      ),
      participantArrivals: List.unmodifiable(participantArrivals),
      currentTime: DateTime.now(),
    );
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
      final name = participant.displayName.trim();
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
    ref.invalidate(homeViewModelProvider);
    ref.invalidateSelf();
    return plan;
  }
}
