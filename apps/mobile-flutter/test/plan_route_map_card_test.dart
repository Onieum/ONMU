import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/map/model/map_models.dart';
import 'package:onmu_mobile/features/map/repository/tile_manifest_repository.dart';
import 'package:onmu_mobile/features/map/widgets/onmu_map_view.dart';
import 'package:onmu_mobile/features/plan/widgets/plan_route_map_card.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';

void main() {
  testWidgets('route map keeps route line visible above summary card', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tileManifestRepositoryProvider.overrideWithValue(
            const _ReadyTileManifestRepository(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PlanRouteMapCard(
              routeState: AsyncValue.data(_routeRecommendation),
              visitPlan: _visitPlan,
              travelMode: 'walk',
              onTravelModeChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final routeMap = tester.widget<OnmuMapView>(
      find.byKey(const ValueKey('plan-itinerary-route-map')),
    );

    expect(routeMap.routeGeometry, hasLength(2));
    expect(
      routeMap.cameraFitPadding.bottom,
      lessThan(onmuMapCameraFitPadding.bottom),
    );
    expect(
      routeMap.markerScreenSafetyPadding.top,
      lessThan(onmuMapMarkerScreenSafetyPadding.top),
    );
    expect(find.textContaining('1구간'), findsOneWidget);
  });

  testWidgets('route map slices full route geometry to visible date stops', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tileManifestRepositoryProvider.overrideWithValue(
            const _ReadyTileManifestRepository(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PlanRouteMapCard(
              routeState: AsyncValue.data(_multiDayRouteRecommendation),
              visitPlan: _firstDayVisitPlan,
              travelMode: 'walk',
              onTravelModeChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final routeMap = tester.widget<OnmuMapView>(
      find.byKey(const ValueKey('plan-itinerary-route-map')),
    );

    expect(routeMap.points, hasLength(2));
    expect(routeMap.routeGeometry, hasLength(3));
    expect(routeMap.routeGeometry.first.lng, 127.0143);
    expect(routeMap.routeGeometry.last.lng, 127.0158);
    expect(
      routeMap.routeGeometry.any((point) => point.lng == 127.1050),
      isFalse,
    );
    expect(find.text('5분 · 350m · 1구간'), findsOneWidget);
    expect(find.text('퍼스트커피랩행궁 → 렉스프레소뮤지엄 행궁 · 5분 · 350m'), findsOneWidget);
    expect(find.textContaining('9.3km'), findsNothing);
  });

  testWidgets('route map falls back to visible stop line for skipped stops', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tileManifestRepositoryProvider.overrideWithValue(
            const _ReadyTileManifestRepository(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PlanRouteMapCard(
              routeState: AsyncValue.data(_multiDayRouteRecommendation),
              visitPlan: _nonConsecutiveVisitPlan,
              travelMode: 'walk',
              onTravelModeChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final routeMap = tester.widget<OnmuMapView>(
      find.byKey(const ValueKey('plan-itinerary-route-map')),
    );

    expect(routeMap.points, hasLength(2));
    expect(routeMap.routeGeometry, hasLength(2));
    expect(routeMap.routeGeometry.first.lng, 127.0143);
    expect(routeMap.routeGeometry.last.lng, 127.1050);
    expect(find.text('1구간'), findsOneWidget);
    expect(find.text('퍼스트커피랩행궁 → 싸계면반 염통본점'), findsOneWidget);
  });

  testWidgets('route map matches duplicate place names by schedule id', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tileManifestRepositoryProvider.overrideWithValue(
            const _ReadyTileManifestRepository(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PlanRouteMapCard(
              routeState: AsyncValue.data(_duplicateNameRouteRecommendation),
              visitPlan: _secondDayDuplicateNameVisitPlan,
              travelMode: 'walk',
              onTravelModeChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final routeMap = tester.widget<OnmuMapView>(
      find.byKey(const ValueKey('plan-itinerary-route-map')),
    );

    expect(routeMap.points, hasLength(2));
    expect(routeMap.points.first.id, 'schedule-3');
    expect(routeMap.points.first.coordinate.lng, 127.0300);
    expect(routeMap.routeGeometry.first.lng, 127.0300);
    expect(routeMap.routeGeometry.last.lng, 127.0340);
    expect(
      routeMap.routeGeometry.any((point) => point.lng == 127.0100),
      isFalse,
    );
    expect(find.text('7분 · 420m · 1구간'), findsOneWidget);
    expect(find.text('동명 카페 → 둘째날 식당 · 7분 · 420m'), findsOneWidget);
  });
}

class _ReadyTileManifestRepository implements TileManifestRepository {
  const _ReadyTileManifestRepository();

  @override
  Future<TileManifest> fetchManifest() async {
    return _readyPmtilesManifest;
  }
}

const _readyPmtilesManifest = TileManifest(
  styleUrl: 'https://tiles.onmu.cloud/styles/onmu-light.json',
  currentPmtilesUrl:
      'pmtiles://https://tiles.onmu.cloud/pmtiles/korea-dev.pmtiles',
  bounds: [124, 33, 132, 39],
  center: OnmuLatLng(lat: 37.5665, lng: 126.978),
  generatedAt: null,
);

final _visitPlan = [
  const VisitPlan(
    id: 'schedule-1',
    time: '10:00',
    endTime: '11:00',
    place: '성수 카페',
    kind: '카페',
    duration: '1시간',
  ),
  const VisitPlan(
    id: 'schedule-2',
    time: '11:30',
    endTime: '12:30',
    place: '성수 전시',
    kind: '전시',
    duration: '1시간',
  ),
];

final _routeRecommendation = RouteRecommendation(
  provider: 'openrouteservice',
  stops: const [
    OnmuMapPoint(
      id: 'stop-1',
      label: '성수 카페',
      coordinate: OnmuLatLng(lat: 37.544, lng: 127.055),
      order: 1,
    ),
    OnmuMapPoint(
      id: 'stop-2',
      label: '성수 전시',
      coordinate: OnmuLatLng(lat: 37.546, lng: 127.058),
      order: 2,
    ),
  ],
  geometry: const [
    OnmuLatLng(lat: 37.544, lng: 127.055),
    OnmuLatLng(lat: 37.546, lng: 127.058),
  ],
  legs: const [
    RouteLeg(
      order: 1,
      fromStopId: 'stop-1',
      toStopId: 'stop-2',
      fromName: '성수 카페',
      toName: '성수 전시',
      distanceMeters: 450,
      durationSeconds: 420,
    ),
    RouteLeg(
      order: 2,
      fromStopId: 'stop-2',
      toStopId: 'stop-1',
      fromName: '성수 전시',
      toName: '성수 카페',
      distanceMeters: 430,
      durationSeconds: 390,
    ),
  ],
  distanceMeters: 880,
  durationSeconds: 810,
  travelMode: 'walk',
  liveProvider: true,
  fallbackReason: '',
  fetchedAt: null,
);

final _firstDayVisitPlan = [
  const VisitPlan(
    id: 'schedule-1',
    time: '10:00',
    endTime: '11:00',
    place: '퍼스트커피랩행궁',
    kind: '카페',
    duration: '1시간',
  ),
  const VisitPlan(
    id: 'schedule-2',
    time: '11:10',
    endTime: '12:00',
    place: '렉스프레소뮤지엄 행궁',
    kind: '전시',
    duration: '50분',
  ),
];

final _nonConsecutiveVisitPlan = [
  const VisitPlan(
    id: 'schedule-1',
    time: '10:00',
    endTime: '11:00',
    place: '퍼스트커피랩행궁',
    kind: '카페',
    duration: '1시간',
  ),
  const VisitPlan(
    id: 'schedule-3',
    time: '12:30',
    endTime: '13:30',
    place: '싸계면반 염통본점',
    kind: '음식점',
    duration: '1시간',
  ),
];

final _secondDayDuplicateNameVisitPlan = [
  const VisitPlan(
    id: 'schedule-3',
    time: '10:00',
    endTime: '11:00',
    place: '동명 카페',
    kind: '카페',
    duration: '1시간',
  ),
  const VisitPlan(
    id: 'schedule-4',
    time: '11:10',
    endTime: '12:00',
    place: '둘째날 식당',
    kind: '음식점',
    duration: '50분',
  ),
];

final _multiDayRouteRecommendation = RouteRecommendation(
  provider: 'openrouteservice',
  stops: const [
    OnmuMapPoint(
      id: 'stop-1',
      label: '퍼스트커피랩행궁',
      coordinate: OnmuLatLng(lat: 37.2859, lng: 127.0143),
      order: 1,
    ),
    OnmuMapPoint(
      id: 'stop-2',
      label: '렉스프레소뮤지엄 행궁',
      coordinate: OnmuLatLng(lat: 37.2863, lng: 127.0158),
      order: 2,
    ),
    OnmuMapPoint(
      id: 'stop-3',
      label: '싸계면반 염통본점',
      coordinate: OnmuLatLng(lat: 37.2970, lng: 127.1050),
      order: 3,
    ),
  ],
  geometry: const [
    OnmuLatLng(lat: 37.2859, lng: 127.0143),
    OnmuLatLng(lat: 37.2860, lng: 127.0150),
    OnmuLatLng(lat: 37.2863, lng: 127.0158),
    OnmuLatLng(lat: 37.2920, lng: 127.0800),
    OnmuLatLng(lat: 37.2970, lng: 127.1050),
  ],
  legs: const [
    RouteLeg(
      order: 1,
      fromStopId: 'stop-1',
      toStopId: 'stop-2',
      fromName: '퍼스트커피랩행궁',
      toName: '렉스프레소뮤지엄 행궁',
      distanceMeters: 350,
      durationSeconds: 300,
    ),
    RouteLeg(
      order: 2,
      fromStopId: 'stop-2',
      toStopId: 'stop-3',
      fromName: '렉스프레소뮤지엄 행궁',
      toName: '싸계면반 염통본점',
      distanceMeters: 9000,
      durationSeconds: 6420,
    ),
  ],
  distanceMeters: 9350,
  durationSeconds: 6720,
  travelMode: 'walk',
  liveProvider: true,
  fallbackReason: '',
  fetchedAt: null,
);

final _duplicateNameRouteRecommendation = RouteRecommendation(
  provider: 'openrouteservice',
  stops: const [
    OnmuMapPoint(
      id: 'schedule-1',
      label: '동명 카페',
      coordinate: OnmuLatLng(lat: 37.2800, lng: 127.0100),
      order: 1,
    ),
    OnmuMapPoint(
      id: 'schedule-2',
      label: '첫째날 전시',
      coordinate: OnmuLatLng(lat: 37.2820, lng: 127.0140),
      order: 2,
    ),
    OnmuMapPoint(
      id: 'schedule-3',
      label: '동명 카페',
      coordinate: OnmuLatLng(lat: 37.2900, lng: 127.0300),
      order: 3,
    ),
    OnmuMapPoint(
      id: 'schedule-4',
      label: '둘째날 식당',
      coordinate: OnmuLatLng(lat: 37.2920, lng: 127.0340),
      order: 4,
    ),
  ],
  geometry: const [
    OnmuLatLng(lat: 37.2800, lng: 127.0100),
    OnmuLatLng(lat: 37.2810, lng: 127.0120),
    OnmuLatLng(lat: 37.2820, lng: 127.0140),
    OnmuLatLng(lat: 37.2860, lng: 127.0220),
    OnmuLatLng(lat: 37.2900, lng: 127.0300),
    OnmuLatLng(lat: 37.2910, lng: 127.0320),
    OnmuLatLng(lat: 37.2920, lng: 127.0340),
  ],
  legs: const [
    RouteLeg(
      order: 1,
      fromStopId: 'schedule-1',
      toStopId: 'schedule-2',
      fromName: '동명 카페',
      toName: '첫째날 전시',
      distanceMeters: 380,
      durationSeconds: 360,
    ),
    RouteLeg(
      order: 2,
      fromStopId: 'schedule-2',
      toStopId: 'schedule-3',
      fromName: '첫째날 전시',
      toName: '동명 카페',
      distanceMeters: 1400,
      durationSeconds: 1200,
    ),
    RouteLeg(
      order: 3,
      fromStopId: 'schedule-3',
      toStopId: 'schedule-4',
      fromName: '동명 카페',
      toName: '둘째날 식당',
      distanceMeters: 420,
      durationSeconds: 420,
    ),
  ],
  distanceMeters: 2200,
  durationSeconds: 1980,
  travelMode: 'walk',
  liveProvider: true,
  fallbackReason: '',
  fetchedAt: null,
);
