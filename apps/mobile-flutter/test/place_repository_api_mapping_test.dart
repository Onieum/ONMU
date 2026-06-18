import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/place/repository/place_repository.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';

void main() {
  test('creates a schedule place through the Spring API contract', () async {
    final requestedPaths = <String>[];
    final requestedBodies = <Map<String, dynamic>>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          requestedBodies.add(Map<String, dynamic>.from(options.data as Map));
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'id': '701',
                'groupId': '1',
                'planId': '104',
                'candidateId': '204',
                'name': '성수 테스트 카페',
                'placeName': '성수 테스트 카페',
                'sortOrder': 1,
                'note': '점심',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiPlaceRepository(OnmuApiClient(dio));

    final saved = await repository.createSchedulePlace(
      groupId: 1,
      planId: 104,
      candidateId: 204,
      name: '성수 테스트 카페',
      note: '점심',
    );

    expect(requestedPaths.single, '/api/v1/groups/1/plans/104/schedule-places');
    expect(requestedBodies.single, {
      'candidateId': '204',
      'name': '성수 테스트 카페',
      'note': '점심',
    });
    expect(saved.id, '701');
    expect(saved.candidateId, '204');
    expect(saved.name, '성수 테스트 카페');
    expect(saved.sortOrder, 1);
  });

  test('deletes a schedule place through the Spring API contract', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 204,
              data: null,
            ),
          );
        },
      ),
    );
    final repository = ApiPlaceRepository(OnmuApiClient(dio));

    await repository.deleteSchedulePlace(
      groupId: 1,
      planId: 104,
      schedulePlaceId: '701',
    );

    expect(
      requests.single.path,
      '/api/v1/groups/1/plans/104/schedule-places/701',
    );
    expect(requests.single.method, 'DELETE');
  });

  test('creates a place candidate through the Spring API contract', () async {
    final requestedPaths = <String>[];
    final requestedBodies = <Map<String, dynamic>>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          requestedBodies.add(Map<String, dynamic>.from(options.data as Map));
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'id': '204',
                'name': '성수 테스트 카페',
                'category': '카페',
                'summary': 'provider 검색 결과에서 저장된 후보',
                'address': '서울 성동구 테스트로 1',
                'sourceLabel': '외부 검색',
                'provider': 'KAKAO',
                'providerPlaceId': 'kakao-204',
                'roadAddress': '서울 성동구 테스트로 1',
                'sourceUrl': 'https://example.com/place/204',
                'lat': 37.544,
                'lng': 127.055,
                'fetchedAt': '2026-06-12T00:00:00Z',
                'tags': ['카페', '조용함'],
                'reasons': ['지도 후보로 저장됨'],
              },
            ),
          );
        },
      ),
    );
    final repository = ApiPlaceRepository(OnmuApiClient(dio));

    final saved = await repository.createCandidate(
      groupId: 1,
      planId: 104,
      candidate: PlaceCandidate(
        id: 9901,
        name: '성수 테스트 카페',
        category: '카페',
        summary: 'provider 검색 결과에서 저장된 후보',
        score: 0,
        matchPercent: 0,
        distanceLabel: '',
        travelTimeLabel: '도보 5분',
        priceLabel: '',
        isOpen: true,
        address: '서울 성동구 테스트로 1',
        openingLabel: '',
        sourceLabel: '',
        riskLabel: '',
        riskTone: 'none',
        memberFits: const [],
        tags: const ['카페', '조용함'],
        reasons: const ['지도 후보로 저장됨'],
        risks: const [],
        provider: 'KAKAO',
        providerPlaceId: 'kakao-204',
        roadAddress: '서울 성동구 테스트로 1',
        sourceUrl: 'https://example.com/place/204',
        latitude: 37.544,
        longitude: 127.055,
        fetchedAt: DateTime.utc(2026, 6, 12),
      ),
    );

    expect(
      requestedPaths.single,
      '/api/v1/groups/1/plans/104/place-candidates',
    );
    expect(requestedBodies.single['name'], '성수 테스트 카페');
    expect(requestedBodies.single['provider'], 'KAKAO');
    expect(requestedBodies.single['providerPlaceId'], 'kakao-204');
    expect(requestedBodies.single['lat'], 37.544);
    expect(requestedBodies.single['lng'], 127.055);
    expect(requestedBodies.single['tags'], ['카페', '조용함']);
    expect(saved.id, 204);
    expect(saved.sourceLabel, '외부 검색');
    expect(saved.latitude, 37.544);
    expect(saved.longitude, 127.055);
    expect(saved.distanceLabel, '');
    expect(saved.travelTimeLabel, '');
    expect(saved.priceLabel, '');
    expect(saved.openingLabel, '');
  });
}
