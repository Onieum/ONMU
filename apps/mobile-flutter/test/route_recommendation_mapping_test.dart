import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/map/model/map_models.dart';

void main() {
  test('maps route recommendation response geometry as lng lat pairs', () {
    final route = RouteRecommendation.fromJson({
      'provider': 'openrouteservice',
      'travelMode': 'bike',
      'distanceMeters': 1234,
      'durationSeconds': 300,
      'liveProvider': true,
      'fetchedAt': '2026-06-10T00:00:00Z',
      'stops': [
        {
          'id': '201',
          'name': 'Start',
          'lat': 37.5665,
          'lng': 126.978,
          'order': 1,
        },
        {
          'id': '202',
          'name': 'End',
          'lat': 37.5651,
          'lng': 126.9895,
          'order': 2,
        },
      ],
      'geometry': [
        [126.978, 37.5665],
        [126.9895, 37.5651],
      ],
      'legs': [
        {
          'order': 1,
          'fromStopId': '201',
          'toStopId': '202',
          'fromName': 'Start',
          'toName': 'End',
          'distanceMeters': 1234,
          'durationSeconds': 300,
        },
      ],
    });

    expect(route.provider, 'openrouteservice');
    expect(route.travelMode, 'bike');
    expect(route.liveProvider, isTrue);
    expect(route.isFallback, isFalse);
    expect(route.legs.single.fromName, 'Start');
    expect(route.legs.single.toName, 'End');
    expect(route.legs.single.distanceMeters, 1234);
    expect(route.legs.single.durationSeconds, 300);
    expect(route.stops, hasLength(2));
    expect(route.geometry.first.lng, 126.978);
    expect(route.geometry.first.lat, 37.5665);
  });

  test('maps route fallback reason without treating dev mock as live', () {
    final route = RouteRecommendation.fromJson({
      'provider': 'dev-mock',
      'fallbackReason': 'provider_failure',
      'liveProvider': false,
      'distanceMeters': 0,
      'durationSeconds': 0,
      'stops': [],
      'geometry': [],
    });

    expect(route.isFallback, isTrue);
    expect(route.fallbackReason, 'provider_failure');
    expect(route.liveProvider, isFalse);
  });

  test('drops route coordinates that native maps cannot animate', () {
    final route = RouteRecommendation.fromJson({
      'provider': 'openrouteservice',
      'liveProvider': true,
      'stops': [
        {'id': 'bad-nan', 'name': 'NaN Place', 'lat': 'NaN', 'lng': 126.978},
        {'id': 'bad-range', 'name': 'Range Place', 'lat': 91, 'lng': 126.978},
        {'id': 'ok', 'name': 'Valid Place', 'lat': 37.5665, 'lng': 126.978},
      ],
      'geometry': [
        ['Infinity', 37.5665],
        [126.978, 91],
        [126.978, 37.5665],
      ],
    });

    expect(route.stops, hasLength(1));
    expect(route.stops.single.id, 'ok');
    expect(route.geometry, hasLength(1));
    expect(route.geometry.single.lat, 37.5665);
    expect(route.geometry.single.lng, 126.978);
  });
}
