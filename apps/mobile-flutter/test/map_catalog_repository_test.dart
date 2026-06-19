import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/map/model/map_models.dart';
import 'package:onmu_mobile/features/map/repository/map_catalog_repository.dart';

void main() {
  test('posts B2 map-points contract and maps cluster response', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'canonical': true,
                'mode': 'clusters',
                'zoom': 12,
                'bounds': {
                  'south': 37.50,
                  'west': 126.90,
                  'north': 37.62,
                  'east': 127.08,
                },
                'clusters': [
                  {
                    'id': 'cluster:1',
                    'type': 'cluster',
                    'count': 14,
                    'lat': 37.56,
                    'lng': 127.01,
                    'bounds': {
                      'south': 37.55,
                      'west': 127.00,
                      'north': 37.57,
                      'east': 127.02,
                    },
                    'categories': ['카페', '공원'],
                  },
                ],
                'points': [],
              },
            ),
          );
        },
      ),
    );
    final repository = ApiMapCatalogRepository(OnmuApiClient(dio));

    final response = await repository.fetchMapPoints(
      groupId: 1,
      planId: 104,
      viewport: const OnmuMapViewport(
        zoom: 12.2,
        bounds: OnmuMapBounds(
          south: 37.50,
          west: 126.90,
          north: 37.62,
          east: 127.08,
        ),
      ),
      category: '카페',
      filter: 'all',
      query: '성수',
    );

    expect(requests.single.path, '/api/v1/map-points');
    expect(requests.single.method, 'POST');
    expect(requests.single.data, {
      'groupId': '1',
      'planId': '104',
      'bounds': {
        'south': 37.50,
        'west': 126.90,
        'north': 37.62,
        'east': 127.08,
      },
      'zoom': 12,
      'category': '카페',
      'filter': 'all',
      'query': '성수',
    });
    expect(response.mode, 'clusters');
    expect(response.clusters.single.id, 'cluster:1');
    expect(response.clusters.single.count, 14);
    expect(response.clusters.single.bounds.north, 37.57);
    expect(response.points, isEmpty);
  });

  test('maps B2 map-points point response for catalog dot layer', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'mode': 'points',
                'zoom': 16,
                'bounds': {
                  'south': 37.50,
                  'west': 126.90,
                  'north': 37.62,
                  'east': 127.08,
                },
                'clusters': [],
                'points': [
                  {
                    'id': 'catalog-1',
                    'type': 'point',
                    'provider': 'onmu_catalog',
                    'providerPlaceId': 'cat-1',
                    'name': '성수 테스트 카페',
                    'category': '카페',
                    'address': '서울 성동구 테스트로 1',
                    'roadAddress': '서울 성동구 테스트로 1',
                    'lat': 37.544,
                    'lng': 127.055,
                  },
                ],
              },
            ),
          );
        },
      ),
    );
    final repository = ApiMapCatalogRepository(OnmuApiClient(dio));

    final response = await repository.fetchMapPoints(
      groupId: 1,
      planId: 104,
      viewport: const OnmuMapViewport(
        zoom: 16,
        bounds: OnmuMapBounds(
          south: 37.50,
          west: 126.90,
          north: 37.62,
          east: 127.08,
        ),
      ),
    );

    expect(response.mode, 'points');
    expect(response.clusters, isEmpty);
    expect(response.points.single.provider, 'onmu_catalog');
    expect(response.points.single.providerPlaceId, 'cat-1');
    expect(response.points.single.coordinate.lat, 37.544);
    expect(response.points.single.coordinate.lng, 127.055);
  });
}
