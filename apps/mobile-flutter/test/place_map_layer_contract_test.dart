import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/place/presentation/pages/place_map_page.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';

void main() {
  test('keeps active result markers to top 20', () {
    final candidates = [
      for (var index = 0; index < 24; index += 1)
        _candidate(
          id: index + 1,
          lat: 37.5 + index * 0.001,
          lng: 126.9 + index * 0.001,
        ),
    ];

    final activeResults = activePlaceResultsForMap(candidates);
    final activeMarkers = mapPointsForPlaceCandidates(activeResults);

    expect(activeResults, hasLength(20));
    expect(activeMarkers, hasLength(20));
    expect(activeMarkers.first.order, 1);
    expect(activeMarkers.last.order, 20);
  });

  test('active result markers can still use fallback coordinates in tests', () {
    final candidates = [_candidate(id: 1), _candidate(id: 2)];

    final activeMarkers = mapPointsForPlaceCandidates(candidates);

    expect(activeMarkers, hasLength(2));
    expect(activeMarkers.first.order, 1);
  });

  test('maps user-facing categories to catalog categories', () {
    expect(mapCatalogCategoryForPlaceCategory('음식점'), '식당');
    expect(mapCatalogCategoryForPlaceCategory('카페'), '식당');
    expect(mapCatalogCategoryForPlaceCategory('가볼만한곳'), '관광명소');
    expect(mapCatalogCategoryForPlaceCategory('문화공간'), '문화공간');
    expect(mapCatalogCategoryForPlaceCategory(''), isNull);
  });

  test('uses cafe token as catalog filter for broad restaurant catalog', () {
    expect(
      mapCatalogFilterForPlaceCategory(
        primaryCategory: '카페',
        selectedFilter: null,
      ),
      '카페',
    );
    expect(
      mapCatalogFilterForPlaceCategory(
        primaryCategory: '카페',
        selectedFilter: '디저트',
      ),
      '디저트',
    );
    expect(
      mapCatalogFilterForPlaceCategory(
        primaryCategory: '음식점',
        selectedFilter: null,
      ),
      'all',
    );
  });
}

PlaceCandidate _candidate({required int id, double? lat, double? lng}) {
  return PlaceCandidate(
    id: id,
    name: '장소 $id',
    category: '카페',
    summary: '',
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
    latitude: lat,
    longitude: lng,
  );
}
