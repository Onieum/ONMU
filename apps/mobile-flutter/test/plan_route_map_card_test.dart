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
    expect(find.textContaining('2구간'), findsOneWidget);
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
