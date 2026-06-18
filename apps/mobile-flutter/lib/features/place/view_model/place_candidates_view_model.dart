import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/place_models.dart';
import '../../../shared/models/plan_models.dart';
import '../../../shared/models/vote_models.dart';
import '../../map/view_model/route_recommendation_view_model.dart';
import '../../group/repository/group_repository.dart';
import '../../group/view_model/vote_view_model.dart';
import '../../plan/view_model/plan_detail_view_model.dart';
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
  double? lat,
  double? lng,
  int? radius,
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
            lat: scope.lat,
            lng: scope.lng,
            radius: scope.radius,
          );
    });

class PlaceCandidatesState {
  const PlaceCandidatesState({
    required this.candidates,
    required this.likedCandidateIds,
    required this.baseFavoriteCounts,
    required this.planTitle,
    required this.planLocation,
  });

  final List<PlaceCandidate> candidates;
  final Set<int> likedCandidateIds;
  final Map<int, int> baseFavoriteCounts;
  final String planTitle;
  final String planLocation;

  bool isLiked(int candidateId) => likedCandidateIds.contains(candidateId);

  int favoriteCountFor(int candidateId) {
    final baseCount = baseFavoriteCounts[candidateId] ?? 0;
    return baseCount + (isLiked(candidateId) ? 1 : 0);
  }

  PlaceCandidatesState withCandidate(PlaceCandidate candidate) {
    final nextCandidates = [...candidates];
    final existingIndex = nextCandidates.indexWhere(
      (current) => _sameCandidate(current, candidate),
    );
    if (existingIndex == -1) {
      nextCandidates.add(candidate);
    } else {
      nextCandidates[existingIndex] = candidate;
    }

    final nextFavoriteCounts = {...baseFavoriteCounts};
    nextFavoriteCounts.putIfAbsent(candidate.id, () => 0);

    return PlaceCandidatesState(
      candidates: List.unmodifiable(nextCandidates),
      likedCandidateIds: likedCandidateIds,
      baseFavoriteCounts: Map.unmodifiable(nextFavoriteCounts),
      planTitle: planTitle,
      planLocation: planLocation,
    );
  }

  PlaceCandidate? findMatchingCandidate(PlaceCandidate candidate) {
    for (final current in candidates) {
      if (_sameCandidate(current, candidate)) {
        return current;
      }
    }
    return null;
  }

  bool hasCandidate(PlaceCandidate candidate) {
    return findMatchingCandidate(candidate) != null;
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
      planTitle: planTitle,
      planLocation: planLocation,
    );
  }

  static bool _sameCandidate(PlaceCandidate current, PlaceCandidate next) {
    if (current.id == next.id) {
      return true;
    }

    final currentProviderKey = _providerKey(current);
    final nextProviderKey = _providerKey(next);
    if (currentProviderKey.isNotEmpty &&
        currentProviderKey == nextProviderKey) {
      return true;
    }

    final currentPlaceKey = _placeKey(current);
    final nextPlaceKey = _placeKey(next);
    if (currentPlaceKey.isNotEmpty && currentPlaceKey == nextPlaceKey) {
      return true;
    }

    final currentNameKey = _nameKey(current);
    final nextNameKey = _nameKey(next);
    return currentNameKey.isNotEmpty && currentNameKey == nextNameKey;
  }

  static String _providerKey(PlaceCandidate candidate) {
    final provider = candidate.provider.trim().toLowerCase();
    final providerPlaceId = candidate.providerPlaceId.trim().toLowerCase();
    if (provider.isEmpty || providerPlaceId.isEmpty) {
      return '';
    }
    return '$provider|$providerPlaceId';
  }

  static String _placeKey(PlaceCandidate candidate) {
    final name = candidate.name.trim().toLowerCase();
    final address = candidate.address.trim().toLowerCase();
    if (name.isEmpty || address.isEmpty) {
      return '';
    }
    return '$name|$address';
  }

  static String _nameKey(PlaceCandidate candidate) {
    final name = candidate.name.trim().toLowerCase();
    return name;
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
      planTitle: plan.title,
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

  Future<PlaceCandidate> addCandidate(PlaceCandidate candidate) async {
    final value = state.asData?.value;
    final existingCandidate = value?.findMatchingCandidate(candidate);
    if (existingCandidate != null) {
      return existingCandidate;
    }

    final repository = ref.read(placeRepositoryProvider);
    final savedCandidate = await repository.createCandidate(
      groupId: scope.groupId,
      planId: scope.planId,
      candidate: candidate,
    );
    if (value != null) {
      state = AsyncData(value.withCandidate(savedCandidate));
    }
    return savedCandidate;
  }

  Future<SchedulePlace> addCandidateToSchedule(PlaceCandidate candidate) async {
    final savedCandidate = await addCandidate(candidate);
    final repository = ref.read(placeRepositoryProvider);
    final schedulePlace = await repository.createSchedulePlace(
      groupId: scope.groupId,
      planId: scope.planId,
      candidateId: savedCandidate.id,
      name: savedCandidate.name,
    );
    _invalidatePlanRouteState();
    return schedulePlace;
  }

  Future<void> deleteSchedulePlace(String schedulePlaceId) async {
    final normalizedId = schedulePlaceId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    final repository = ref.read(placeRepositoryProvider);
    await repository.deleteSchedulePlace(
      groupId: scope.groupId,
      planId: scope.planId,
      schedulePlaceId: normalizedId,
    );
    _invalidatePlanRouteState();
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
    final candidateIds = value.candidates
        .where((candidate) => selectedCandidateIds.contains(candidate.id))
        .map((candidate) => candidate.id.toString())
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
        placeCandidateIds: candidateIds,
      ),
    );
    ref.invalidate(
      voteListViewModelProvider((groupId: scope.groupId, planId: scope.planId)),
    );
    return vote.id;
  }

  void _invalidatePlanRouteState() {
    ref.invalidate(
      planDetailViewModelProvider((
        groupId: scope.groupId,
        planId: scope.planId,
      )),
    );
    for (final travelMode in const ['walk', 'bike', 'car']) {
      ref.invalidate(
        routeRecommendationViewModelProvider((
          groupId: scope.groupId,
          planId: scope.planId,
          travelMode: travelMode,
        )),
      );
    }
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
