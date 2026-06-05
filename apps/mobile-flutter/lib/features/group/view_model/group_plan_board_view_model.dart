import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/place_models.dart';
import '../../place/repository/place_repository.dart';
import '../repository/group_repository.dart';

typedef GroupPlanBoardScope = ({String groupId, String planId});

final groupPlanBoardViewModelProvider =
    AsyncNotifierProvider.family<
      GroupPlanBoardViewModel,
      GroupPlanBoardState,
      GroupPlanBoardScope
    >(GroupPlanBoardViewModel.new);

class GroupPlanBoardState {
  const GroupPlanBoardState({
    required this.pinnedPlan,
    required this.candidates,
    required this.voteId,
  });

  final GroupPinnedPlan? pinnedPlan;
  final List<PlaceCandidate> candidates;
  final int voteId;
}

class GroupPlanBoardViewModel
    extends FamilyAsyncNotifier<GroupPlanBoardState, GroupPlanBoardScope> {
  @override
  Future<GroupPlanBoardState> build(GroupPlanBoardScope arg) async {
    final groupRepository = ref.watch(groupRepositoryProvider);
    final placeRepository = ref.watch(placeRepositoryProvider);

    return GroupPlanBoardState(
      pinnedPlan: await groupRepository.fetchPinnedPlan(arg.groupId),
      candidates: await placeRepository.fetchCandidates(
        groupId: arg.groupId,
        planId: arg.planId,
      ),
      voteId: 501,
    );
  }
}
