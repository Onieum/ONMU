import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/place_models.dart';
import '../../../shared/repository/in_memory_onmu_store.dart';

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => MockPlaceRepository(ref.watch(inMemoryOnmuStoreProvider)),
);

abstract interface class PlaceRepository {
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  });

  Future<PlaceCandidate> fetchCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  });

  Future<List<PlaceRisk>> fetchRisks({
    required Object groupId,
    required Object planId,
  });

  Future<PlaceVoteResult> fetchVoteResult({
    required Object groupId,
    required Object planId,
  });
}

class MockPlaceRepository implements PlaceRepository {
  MockPlaceRepository(this._store);

  final InMemoryOnmuStore _store;

  @override
  Future<PlaceCandidate> fetchCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  }) async {
    return _store.fetchPlaceCandidate(
      groupId: groupId,
      planId: planId,
      candidateId: candidateId,
    );
  }

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchPlaceCandidates(groupId: groupId, planId: planId);
  }

  @override
  Future<List<PlaceRisk>> fetchRisks({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchPlaceRisks(groupId: groupId, planId: planId);
  }

  @override
  Future<PlaceVoteResult> fetchVoteResult({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchPlaceVoteResult(groupId: groupId, planId: planId);
  }
}
