import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/place_models.dart';
import '../../../shared/repository/in_memory_onmu_store.dart';

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  if (ref.watch(onmuApiEnabledProvider)) {
    return ApiPlaceRepository(ref.watch(onmuApiClientProvider));
  }
  return MockPlaceRepository(ref.watch(inMemoryOnmuStoreProvider));
});

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

class ApiPlaceRepository implements PlaceRepository {
  ApiPlaceRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async {
    final candidates = await _client.getList(
      '/api/v1/groups/$groupId/plans/$planId/place-candidates',
    );
    return candidates.map(_candidate).toList(growable: false);
  }

  @override
  Future<PlaceCandidate> fetchCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  }) async {
    final candidates = await fetchCandidates(groupId: groupId, planId: planId);
    if (candidates.isEmpty) {
      return _emptyCandidate(candidateId);
    }
    return candidates.firstWhere(
      (candidate) => candidate.id.toString() == candidateId.toString(),
      orElse: () => _emptyCandidate(candidateId),
    );
  }

  @override
  Future<List<PlaceRisk>> fetchRisks({
    required Object groupId,
    required Object planId,
  }) async {
    return const [];
  }

  @override
  Future<PlaceVoteResult> fetchVoteResult({
    required Object groupId,
    required Object planId,
  }) async {
    return const PlaceVoteResult(
      title: '투표 결과',
      selectedPlaceName: '아직 선택된 장소가 없어요',
      voters: [],
      note: 'Spring API 투표가 만들어지면 결과를 연결합니다.',
    );
  }

  PlaceCandidate _candidate(Map<String, dynamic> json) {
    return PlaceCandidate(
      id: OnmuJson.readInt(json, 'id'),
      name: OnmuJson.readString(json, 'name', '장소 후보'),
      category: OnmuJson.readString(json, 'category', '장소'),
      summary: OnmuJson.readString(json, 'summary', 'Spring API 장소 후보'),
      score: 0,
      matchPercent: 0,
      distanceLabel: OnmuJson.readString(json, 'distanceLabel', '거리 정보 준비 중'),
      travelTimeLabel: OnmuJson.readString(json, 'travelTimeLabel', '이동 시간 준비 중'),
      priceLabel: OnmuJson.readString(json, 'priceLabel', '가격 정보 준비 중'),
      isOpen: OnmuJson.readBool(json, 'isOpen', true),
      address: OnmuJson.readString(json, 'address'),
      openingLabel: OnmuJson.readString(json, 'openingLabel', '영업 정보 확인 중'),
      sourceLabel: '',
      riskLabel: '',
      riskTone: 'none',
      memberFits: OnmuJson.asMapList(json['memberFits'])
          .map(
            (fit) => MemberFit(
              label: OnmuJson.readString(fit, 'label'),
              score: 0,
              note: OnmuJson.readString(fit, 'note'),
            ),
          )
          .toList(growable: false),
      tags: OnmuJson.stringList(json['tags']),
      reasons: OnmuJson.stringList(json['reasons']),
      risks: const [],
    );
  }

  PlaceCandidate _emptyCandidate(Object candidateId) {
    return PlaceCandidate(
      id: int.tryParse(candidateId.toString()) ?? 0,
      name: '장소 후보',
      category: '장소',
      summary: '장소 후보 API 응답이 비어 있습니다.',
      score: 0,
      matchPercent: 0,
      distanceLabel: '거리 정보 준비 중',
      travelTimeLabel: '이동 시간 준비 중',
      priceLabel: '가격 정보 준비 중',
      isOpen: true,
      address: '',
      openingLabel: '영업 정보 확인 중',
      sourceLabel: '',
      riskLabel: '',
      riskTone: 'none',
      memberFits: const [],
      tags: const [],
      reasons: const [],
      risks: const [],
    );
  }
}
