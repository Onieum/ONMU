import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/place_models.dart';

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  return ApiPlaceRepository(ref.watch(onmuApiClientProvider));
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

  Future<PlaceCandidate> createCandidate({
    required Object groupId,
    required Object planId,
    required PlaceCandidate candidate,
  });

  Future<List<PlaceCandidate>> searchPlaces({
    required Object groupId,
    required Object planId,
    required String query,
    String? category,
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
  Future<PlaceCandidate> createCandidate({
    required Object groupId,
    required Object planId,
    required PlaceCandidate candidate,
  }) async {
    final response = await _client.postObject(
      '/api/v1/groups/$groupId/plans/$planId/place-candidates',
      body: {
        'name': candidate.name.trim(),
        'category': candidate.category.trim(),
        'address': candidate.address.trim(),
        'summary': candidate.summary.trim(),
        'tags': candidate.tags,
        if (candidate.provider.trim().isNotEmpty)
          'provider': candidate.provider.trim(),
        if (candidate.providerPlaceId.trim().isNotEmpty)
          'providerPlaceId': candidate.providerPlaceId.trim(),
        if (candidate.roadAddress.trim().isNotEmpty)
          'roadAddress': candidate.roadAddress.trim(),
        if (candidate.latitude != null) 'lat': candidate.latitude,
        if (candidate.longitude != null) 'lng': candidate.longitude,
        if (candidate.latitude != null) 'latitude': candidate.latitude,
        if (candidate.longitude != null) 'longitude': candidate.longitude,
        if (candidate.sourceUrl.trim().isNotEmpty)
          'sourceUrl': candidate.sourceUrl.trim(),
        if (candidate.fetchedAt != null)
          'fetchedAt': candidate.fetchedAt!.toUtc().toIso8601String(),
      },
    );
    return _candidate(response);
  }

  @override
  Future<List<PlaceCandidate>> searchPlaces({
    required Object groupId,
    required Object planId,
    required String query,
    String? category,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const [];
    }
    final response = await _client.postObject(
      '/api/v1/place-search',
      body: {
        'groupId': groupId.toString(),
        'planId': planId.toString(),
        'query': normalizedQuery,
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
      },
    );
    return OnmuJson.asMapList(
      response['results'],
    ).map(_candidate).toList(growable: false);
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
      note: '투표가 만들어지면 결과를 연결합니다.',
    );
  }

  PlaceCandidate _candidate(Map<String, dynamic> json) {
    return PlaceCandidate(
      id: _candidateId(json),
      name: OnmuJson.readString(json, 'name', '장소 후보'),
      category: OnmuJson.readString(json, 'category', '장소'),
      summary: OnmuJson.readString(json, 'summary'),
      score: 0,
      matchPercent: 0,
      distanceLabel: OnmuJson.readString(json, 'distanceLabel'),
      travelTimeLabel: OnmuJson.readString(json, 'travelTimeLabel'),
      priceLabel: OnmuJson.readString(json, 'priceLabel'),
      isOpen: OnmuJson.readBool(json, 'isOpen', true),
      address: OnmuJson.readString(json, 'address'),
      openingLabel: OnmuJson.readString(json, 'openingLabel'),
      sourceLabel: OnmuJson.readString(json, 'sourceLabel'),
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
      provider: OnmuJson.readString(json, 'provider'),
      providerPlaceId: OnmuJson.readString(json, 'providerPlaceId'),
      roadAddress: OnmuJson.readString(json, 'roadAddress'),
      sourceUrl: OnmuJson.readString(json, 'sourceUrl'),
      latitude:
          _readNullableDouble(json, 'lat') ??
          _readNullableDouble(json, 'latitude'),
      longitude:
          _readNullableDouble(json, 'lng') ??
          _readNullableDouble(json, 'longitude'),
      fetchedAt: DateTime.tryParse(OnmuJson.readString(json, 'fetchedAt')),
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
      distanceLabel: '',
      travelTimeLabel: '',
      priceLabel: '',
      isOpen: true,
      address: '',
      openingLabel: '',
      sourceLabel: '',
      riskLabel: '',
      riskTone: 'none',
      memberFits: const [],
      tags: const [],
      reasons: const [],
      risks: const [],
    );
  }

  double? _readNullableDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  int _candidateId(Map<String, dynamic> json) {
    final explicitId = OnmuJson.readInt(json, 'id');
    if (explicitId != 0) {
      return explicitId;
    }
    final providerKey = [
      OnmuJson.readString(json, 'provider'),
      OnmuJson.readString(json, 'providerPlaceId'),
      OnmuJson.readString(json, 'name'),
    ].join('|');
    return providerKey.hashCode & 0x7fffffff;
  }
}
