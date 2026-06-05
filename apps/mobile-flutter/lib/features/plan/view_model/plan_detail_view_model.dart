import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final Plan plan;
  final List<PlanMember> selectedMembers;
  final List<List<VisitPlan>> visitPlansByDate;

  List<VisitPlan> visitPlanForDate(int index) {
    if (index < 0 || index >= visitPlansByDate.length) {
      return const [];
    }

    return visitPlansByDate[index];
  }
}

class PlanDetailViewModel
    extends FamilyAsyncNotifier<PlanDetailState, PlanScope> {
  @override
  Future<PlanDetailState> build(PlanScope arg) async {
    final repository = ref.watch(planRepositoryProvider);
    final plan = await repository.fetchPlan(
      groupId: arg.groupId,
      planId: arg.planId,
    );
    final visitPlansByDate = await repository.fetchVisitPlansByDate(
      groupId: arg.groupId,
      planId: arg.planId,
    );

    return PlanDetailState(
      plan: plan,
      selectedMembers: List.unmodifiable(
        plan.members.where((member) => member.selected),
      ),
      visitPlansByDate: List.unmodifiable(
        visitPlansByDate.map(List<VisitPlan>.unmodifiable),
      ),
    );
  }
}
