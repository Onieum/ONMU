import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/place_models.dart';
import '../repository/place_repository.dart';

typedef PlaceScope = ({String groupId, String planId});

final placeCandidatesViewModelProvider =
    AsyncNotifierProvider.family<
      PlaceCandidatesViewModel,
      PlaceCandidatesState,
      PlaceScope
    >(PlaceCandidatesViewModel.new);

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
  @override
  Future<PlaceCandidatesState> build(PlaceScope arg) async {
    final repository = ref.watch(placeRepositoryProvider);
    final candidates = await repository.fetchCandidates(
      groupId: arg.groupId,
      planId: arg.planId,
    );

    return PlaceCandidatesState(
      candidates: List.unmodifiable(candidates),
      likedCandidateIds: const {},
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
