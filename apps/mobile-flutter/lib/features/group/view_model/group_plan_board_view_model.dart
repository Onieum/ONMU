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

class GroupPlanBoardViewModel extends AsyncNotifier<GroupPlanBoardState> {
  GroupPlanBoardViewModel(this.scope);

  final GroupPlanBoardScope scope;

  @override
  Future<GroupPlanBoardState> build() async {
    final groupRepository = ref.watch(groupRepositoryProvider);
    final placeRepository = ref.watch(placeRepositoryProvider);

    return GroupPlanBoardState(
      pinnedPlan: await groupRepository.fetchPinnedPlan(scope.groupId),
      candidates: await placeRepository.fetchCandidates(
        groupId: scope.groupId,
        planId: scope.planId,
      ),
      voteId: 501,
    );
  }
}
