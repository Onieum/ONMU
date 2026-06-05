import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/place_models.dart';
import '../../../shared/models/vote_models.dart';
import '../../group/repository/group_repository.dart';
import '../../group/view_model/vote_view_model.dart';
import '../repository/place_repository.dart';

typedef PlaceScope = ({String groupId, String planId});
typedef PlaceCandidateDetailScope = ({
  String groupId,
  String planId,
  String candidateId,
});

final placeCandidatesViewModelProvider =
    AsyncNotifierProvider.family<
      PlaceCandidatesViewModel,
      PlaceCandidatesState,
      PlaceScope
    >(PlaceCandidatesViewModel.new);

final placeCandidateDetailViewModelProvider =
    AsyncNotifierProvider.family<
      PlaceCandidateDetailViewModel,
      PlaceCandidate,
      PlaceCandidateDetailScope
    >(PlaceCandidateDetailViewModel.new);

class PlaceCandidatesState {
  const PlaceCandidatesState({
    required this.candidates,
    required this.likedCandidateIds,
    required this.baseFavoriteCounts,
  });

  final List<PlaceCandidate> candidates;
  final Set<int> likedCandidateIds;
  final Map<int, int> baseFavoriteCounts;

  bool isLiked(int candidateId) => likedCandidateIds.contains(candidateId);

  int favoriteCountFor(int candidateId) {
    final baseCount = baseFavoriteCounts[candidateId] ?? 0;
    return baseCount + (isLiked(candidateId) ? 1 : 0);
  }

  PlaceCandidatesState toggledFavorite(int candidateId) {
    final nextLikedIds = {...likedCandidateIds};
    if (!nextLikedIds.add(candidateId)) {
      nextLikedIds.remove(candidateId);
    }

    return PlaceCandidatesState(
      candidates: candidates,
      likedCandidateIds: Set.unmodifiable(nextLikedIds),
      baseFavoriteCounts: baseFavoriteCounts,
    );
  }
}

class PlaceCandidatesViewModel
    extends FamilyAsyncNotifier<PlaceCandidatesState, PlaceScope> {
  late PlaceScope _scope;

  @override
  Future<PlaceCandidatesState> build(PlaceScope arg) async {
    _scope = arg;
    final repository = ref.watch(placeRepositoryProvider);
    final candidates = await repository.fetchCandidates(
      groupId: arg.groupId,
      planId: arg.planId,
    );

    return PlaceCandidatesState(
      candidates: List.unmodifiable(candidates),
      likedCandidateIds: <int>{},
      baseFavoriteCounts: _favoriteCountsFor(candidates),
    );
  }

  void toggleFavorite(int candidateId) {
    final value = state.valueOrNull;
    if (value == null) {
      return;
    }

    state = AsyncData(value.toggledFavorite(candidateId));
  }

  Future<int> createPlaceVote({
    required String title,
    required String modeLabel,
    required String deadlineDate,
    required String deadlineTime,
    required Set<int> selectedCandidateIds,
  }) async {
    final value = state.requireValue;
    final candidateNames = value.candidates
        .where((candidate) => selectedCandidateIds.contains(candidate.id))
        .map((candidate) => candidate.name)
        .toList(growable: false);
    final repository = ref.read(groupRepositoryProvider);
    final vote = await repository.createVote(
      VoteCreateInput(
        groupId: _scope.groupId,
        planId: _scope.planId,
        title: title,
        modeLabel: modeLabel,
        deadlineDate: deadlineDate,
        deadlineTime: deadlineTime,
        candidateNames: candidateNames,
      ),
    );
    ref.invalidate(voteListViewModelProvider(_scope.groupId));
    return vote.id;
  }

  Map<int, int> _favoriteCountsFor(List<PlaceCandidate> candidates) {
    return {
      for (var index = 0; index < candidates.length; index += 1)
        candidates[index].id: switch (index) {
          0 => 3,
          1 => 2,
          _ => 1,
        },
    };
  }
}

class PlaceCandidateDetailViewModel
    extends FamilyAsyncNotifier<PlaceCandidate, PlaceCandidateDetailScope> {
  @override
  Future<PlaceCandidate> build(PlaceCandidateDetailScope arg) async {
    final repository = ref.watch(placeRepositoryProvider);
    return repository.fetchCandidate(
      groupId: arg.groupId,
      planId: arg.planId,
      candidateId: arg.candidateId,
    );
  }
}
