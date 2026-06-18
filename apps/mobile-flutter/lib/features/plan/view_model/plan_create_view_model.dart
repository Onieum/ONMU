import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/plan_models.dart';
import '../../group/repository/group_repository.dart';
import '../../group/view_model/group_home_view_model.dart';
import '../../group/view_model/group_list_view_model.dart';
import '../../group/view_model/group_plan_list_view_model.dart';
import '../../home/view_model/home_view_model.dart';
import '../repository/plan_repository.dart';

final planCreateControllerProvider = Provider<PlanCreateController>(
  (ref) => PlanCreateController(ref),
);

final groupPlanMemberOptionsProvider =
    FutureProvider.family<List<PlanMember>, String>((ref, groupId) async {
      final members = await ref
          .watch(groupRepositoryProvider)
          .fetchMembers(groupId);
      return members
          .where((member) => !member.invited && member.userId.trim().isNotEmpty)
          .map(
            (member) => PlanMember(
              userId: member.userId,
              name: member.name,
              message: member.note,
              badge: member.statusLabel,
              selected: true,
              profileImageUrl: member.profileImageUrl,
            ),
          )
          .toList(growable: false);
    });

class PlanCreateController {
  const PlanCreateController(this._ref);

  final Ref _ref;

  Future<Plan> createPlan(PlanCreateInput input) async {
    final plan = await _ref.read(planRepositoryProvider).createPlan(input);
    final groupId = input.groupId.toString();
    _ref.invalidate(groupPlanListViewModelProvider(groupId));
    _ref.invalidate(groupHomeViewModelProvider(groupId));
    _ref.invalidate(groupListViewModelProvider);
    _ref.invalidate(homeViewModelProvider);
    return plan;
  }
}
