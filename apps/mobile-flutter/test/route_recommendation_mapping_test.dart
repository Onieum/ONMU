import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/map/model/map_models.dart';

void main() {
  test('maps route recommendation response geometry as lng lat pairs', () {
    final route = RouteRecommendation.fromJson({
      'provider': 'dev-mock',
      'travelMode': 'bike',
      'distanceMeters': 1234,
      'durationSeconds': 300,
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
    });

    expect(route.provider, 'dev-mock');
    expect(route.travelMode, 'bike');
    expect(route.stops, hasLength(2));
    expect(route.geometry.first.lng, 126.978);
    expect(route.geometry.first.lat, 37.5665);
  });
}
