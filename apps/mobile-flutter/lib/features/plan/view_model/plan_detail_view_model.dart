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
    return plan;
  }
}
