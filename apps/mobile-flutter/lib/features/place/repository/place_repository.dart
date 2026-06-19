import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/place_models.dart';
import '../../../shared/models/plan_models.dart';

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

  Future<PlaceCandidate> setCandidateHeart({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required bool hearted,
  });

  Future<SchedulePlace> createSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required String name,
    DateTime? startsAt,
    DateTime? endsAt,
    String note,
  });

  Future<SchedulePlace> updateSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
    DateTime? startsAt,
    DateTime? endsAt,
    String note,
  });

  Future<void> deleteSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
  });

  Future<List<PlaceCandidate>> searchPlaces({
    required Object groupId,
    required Object planId,
    required String query,
    String? category,
    double? lat,
    double? lng,
    int? radius,
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
  Future<PlaceCandidate> setCandidateHeart({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required bool hearted,
  }) async {
    final response = await _client.putObject(
      '/api/v1/groups/$groupId/plans/$planId/place-candidates/$candidateId/heart',
      body: {'hearted': hearted},
    );
    return _candidate(response);
  }

  @override
  Future<SchedulePlace> createSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required String name,
    DateTime? startsAt,
    DateTime? endsAt,
    String note = '',
  }) async {
    final response = await _client.postObject(
      '/api/v1/groups/$groupId/plans/$planId/schedule-places',
      body: {
        'candidateId': candidateId.toString(),
        'name': name.trim(),
        if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
        if (endsAt != null) 'endsAt': endsAt.toUtc().toIso8601String(),
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return _schedulePlace(response);
  }

  @override
  Future<SchedulePlace> updateSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
    DateTime? startsAt,
    DateTime? endsAt,
    String note = '',
  }) async {
    final response = await _client.patchObject(
      '/api/v1/groups/$groupId/plans/$planId/schedule-places/$schedulePlaceId',
      body: {
        'startsAt': startsAt?.toUtc().toIso8601String(),
        'endsAt': endsAt?.toUtc().toIso8601String(),
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return _schedulePlace(response);
  }

  @override
  Future<void> deleteSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
  }) async {
    await _client.deleteObject(
      '/api/v1/groups/$groupId/plans/$planId/schedule-places/$schedulePlaceId',
    );
  }

  @override
  Future<List<PlaceCandidate>> searchPlaces({
    required Object groupId,
    required Object planId,
    required String query,
    String? category,
    double? lat,
    double? lng,
    int? radius,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const [];
    }
    final body = <String, dynamic>{
      'groupId': groupId.toString(),
      'planId': planId.toString(),
      'query': normalizedQuery,
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
    };
    if (lat != null) {
      body['lat'] = lat;
    }
    if (lng != null) {
      body['lng'] = lng;
    }
    if (radius != null) {
      body['radius'] = radius;
    }
    final response = await _client.postObject(
      '/api/v1/place-search',
      body: body,
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
      heartCount: OnmuJson.readInt(
        json,
        'heartCount',
        OnmuJson.readInt(json, 'favoriteCount'),
      ),
      heartedByMe: OnmuJson.readBool(
        json,
        'myHearted',
        OnmuJson.readBool(
          json,
          'heartedByMe',
          OnmuJson.readBool(json, 'likedByMe'),
        ),
      ),
    );
  }

  SchedulePlace _schedulePlace(Map<String, dynamic> json) {
    return SchedulePlace(
      id: OnmuJson.readString(json, 'id'),
      groupId: OnmuJson.readString(json, 'groupId'),
      planId: OnmuJson.readString(json, 'planId'),
      candidateId: OnmuJson.readString(json, 'candidateId'),
      name: OnmuJson.readString(
        json,
        'name',
        OnmuJson.readString(json, 'placeName', '일정 장소'),
      ),
      startsAt: DateTime.tryParse(OnmuJson.readString(json, 'startsAt')),
      endsAt: DateTime.tryParse(OnmuJson.readString(json, 'endsAt')),
      note: OnmuJson.readString(json, 'note'),
      sortOrder: OnmuJson.readInt(json, 'sortOrder'),
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
