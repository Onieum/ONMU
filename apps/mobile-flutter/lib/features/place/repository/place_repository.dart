import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/place_models.dart';

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => const MockPlaceRepository(),
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
  const MockPlaceRepository();

  @override
  Future<PlaceCandidate> fetchCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  }) async {
    return findPlaceCandidate(candidateId.toString());
  }

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async {
    return List.unmodifiable(mockPlaceCandidates);
  }

  @override
  Future<List<PlaceRisk>> fetchRisks({
    required Object groupId,
    required Object planId,
  }) async {
    return List.unmodifiable(mockPlaceRisks);
  }

  @override
  Future<PlaceVoteResult> fetchVoteResult({
    required Object groupId,
    required Object planId,
  }) async {
    return mockPlaceVoteResult;
  }
}
