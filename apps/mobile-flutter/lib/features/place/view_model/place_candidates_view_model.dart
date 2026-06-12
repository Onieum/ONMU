import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/place_models.dart';
import '../../../shared/models/vote_models.dart';
import '../../group/repository/group_repository.dart';
import '../../group/view_model/vote_view_model.dart';
import '../../plan/repository/plan_repository.dart';
import '../repository/place_repository.dart';

typedef PlaceScope = ({String groupId, String planId});
typedef PlaceCandidateDetailScope = ({
  String groupId,
  String planId,
  String candidateId,
});
typedef PlaceSearchScope = ({
  String groupId,
  String planId,
  String query,
  String? category,
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

final placeSearchResultsProvider =
    FutureProvider.family<List<PlaceCandidate>, PlaceSearchScope>((ref, scope) {
      final query = scope.query.trim();
      if (query.isEmpty) {
        return Future.value(const []);
      }
      return ref
          .watch(placeRepositoryProvider)
          .searchPlaces(
            groupId: scope.groupId,
            planId: scope.planId,
            query: query,
            category: scope.category,
          );
    });

class PlaceCandidatesState {
  const PlaceCandidatesState({
    required this.candidates,
    required this.likedCandidateIds,
    required this.baseFavoriteCounts,
    required this.planLocation,
  });

  final List<PlaceCandidate> candidates;
  final Set<int> likedCandidateIds;
  final Map<int, int> baseFavoriteCounts;
  final String planLocation;

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
      planLocation: planLocation,
    );
  }
}

class PlaceCandidatesViewModel extends AsyncNotifier<PlaceCandidatesState> {
  PlaceCandidatesViewModel(this.scope);

  final PlaceScope scope;

  @override
  Future<PlaceCandidatesState> build() async {
    final placeRepository = ref.watch(placeRepositoryProvider);
    final planRepository = ref.watch(planRepositoryProvider);
    final candidates = await placeRepository.fetchCandidates(
      groupId: scope.groupId,
      planId: scope.planId,
    );
    final plan = await planRepository.fetchPlan(
      groupId: scope.groupId,
      planId: scope.planId,
    );

    return PlaceCandidatesState(
      candidates: List.unmodifiable(candidates),
      likedCandidateIds: <int>{},
      baseFavoriteCounts: _favoriteCountsFor(candidates),
      planLocation: plan.location,
    );
  }

  void toggleFavorite(int candidateId) {
    final value = state.asData?.value;
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
        groupId: scope.groupId,
        planId: scope.planId,
        title: title,
        modeLabel: modeLabel,
        deadlineDate: deadlineDate,
        deadlineTime: deadlineTime,
        candidateNames: candidateNames,
      ),
    );
    ref.invalidate(voteListViewModelProvider(scope.groupId));
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

class PlaceCandidateDetailViewModel extends AsyncNotifier<PlaceCandidate> {
  PlaceCandidateDetailViewModel(this.scope);

  final PlaceCandidateDetailScope scope;

  @override
  Future<PlaceCandidate> build() async {
    final repository = ref.watch(placeRepositoryProvider);
    return repository.fetchCandidate(
      groupId: scope.groupId,
      planId: scope.planId,
      candidateId: scope.candidateId,
    );
  }
}
