import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:onmu_mobile/features/map/model/map_models.dart';
import 'package:onmu_mobile/features/map/repository/tile_manifest_repository.dart';
import 'package:onmu_mobile/features/map/widgets/onmu_map_view.dart';

void main() {
  test(
    'uses MapLibre for ready PMTiles manifest when runtime is available',
    () {
      expect(
        shouldUseOnmuMapLibre(
          manifest: _readyPmtilesManifest,
          platformViewAvailable: true,
          pmtilesProtocolReady: true,
        ),
        isTrue,
      );
    },
  );

  test('keeps fallback gates for missing runtime prerequisites', () {
    expect(
      shouldUseOnmuMapLibre(
        manifest: null,
        platformViewAvailable: true,
        pmtilesProtocolReady: true,
      ),
      isFalse,
    );
    expect(
      shouldUseOnmuMapLibre(
        manifest: _readyPmtilesManifest,
        platformViewAvailable: false,
        pmtilesProtocolReady: true,
      ),
      isFalse,
    );
    expect(
      shouldUseOnmuMapLibre(
        manifest: _readyPmtilesManifest,
        platformViewAvailable: true,
        pmtilesProtocolReady: false,
      ),
      isFalse,
    );
  });

  test('builds camera bounds from manifest bounds', () {
    final cameraBounds = cameraTargetBoundsFromManifest(_readyPmtilesManifest);

    expect(onmuMapMinUsableZoom, 6.2);
    expect(cameraBounds.bounds?.southwest.longitude, 124);
    expect(cameraBounds.bounds?.southwest.latitude, 33);
    expect(cameraBounds.bounds?.northeast.longitude, 132);
    expect(cameraBounds.bounds?.northeast.latitude, 39);
    expect(cameraTargetBoundsFromManifest(null), CameraTargetBounds.unbounded);
  });

  test('builds native annotations with numbered marker icons only', () async {
    const point = OnmuMapPoint(
      id: 'place-1',
      label: '긴 장소명은 지도 marker text로 쓰지 않는다',
      coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
      order: 7,
    );

    final symbol = nativeSymbolOptionsForPoint(point: point, focused: false);
    final focusedSymbol = nativeSymbolOptionsForPoint(
      point: point,
      focused: true,
    );
    final line = nativeLineOptionsForRoute(const [
      OnmuLatLng(lat: 37.5665, lng: 126.978),
      OnmuLatLng(lat: 37.5651, lng: 126.9895),
    ]);
    final casingLine = nativeLineCasingOptionsForRoute(const [
      OnmuLatLng(lat: 37.5665, lng: 126.978),
      OnmuLatLng(lat: 37.5651, lng: 126.9895),
    ]);
    final markerBytes = await createNativeMarkerIconBytes(
      order: point.order,
      focused: false,
    );
    final focusedMarkerBytes = await createNativeMarkerIconBytes(
      order: point.order,
      focused: true,
    );
    final markerCodec = await ui.instantiateImageCodec(markerBytes);
    final focusedMarkerCodec = await ui.instantiateImageCodec(
      focusedMarkerBytes,
    );
    final markerFrame = await markerCodec.getNextFrame();
    final focusedMarkerFrame = await focusedMarkerCodec.getNextFrame();
    addTearDown(markerFrame.image.dispose);
    addTearDown(focusedMarkerFrame.image.dispose);

    expect(symbol.iconImage, 'onmu-map-marker-normal-7');
    expect(symbol.iconAnchor, 'center');
    expect(symbol.iconSize, 1);
    expect(symbol.zIndex, 10);
    expect(symbol.textField, isNull);
    expect(focusedSymbol.iconImage, 'onmu-map-marker-focused-7');
    expect(focusedSymbol.zIndex, 40);
    expect(focusedSymbol.zIndex, greaterThan(symbol.zIndex!));
    expect(markerBytes, isNotEmpty);
    expect(markerFrame.image.width, onmuMapMarkerIconSize);
    expect(focusedMarkerFrame.image.width, onmuMapFocusedMarkerIconSize);
    expect(onmuMapMarkerFallbackSize, greaterThanOrEqualTo(44));
    expect(
      onmuMapFocusedMarkerFallbackSize,
      greaterThan(onmuMapMarkerFallbackSize),
    );
    expect(line?.geometry, hasLength(2));
    expect(line?.lineColor, '#2563EB');
    expect(line?.lineWidth, greaterThanOrEqualTo(8));
    expect(casingLine?.lineColor, '#FFFFFF');
    expect(casingLine?.lineWidth, greaterThan(line!.lineWidth!));
  });

  test('builds clustered catalog source separately from numbered markers', () {
    const catalogPoints = [
      OnmuCatalogMapPoint(
        id: 'catalog-1',
        category: '카페',
        coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
      ),
      OnmuCatalogMapPoint(
        id: 'catalog-2',
        category: '공원',
        coordinate: OnmuLatLng(lat: 37.5651, lng: 126.9895),
      ),
    ];
    const catalogClusters = [
      OnmuCatalogMapCluster(
        id: 'cluster-1',
        count: 12,
        coordinate: OnmuLatLng(lat: 37.566, lng: 126.98),
        bounds: OnmuMapBounds(
          south: 37.56,
          west: 126.97,
          north: 37.57,
          east: 126.99,
        ),
        categories: ['카페', '공원'],
      ),
    ];

    final source = catalogGeoJsonSourceProperties(
      catalogPoints,
      clusters: catalogClusters,
    ).toJson();
    final geojson = catalogGeoJsonForLayer(
      clusters: catalogClusters,
      points: catalogPoints,
    );
    final clusterLayer = catalogClusterCircleLayerProperties().toJson();
    final clusterCountLayer = catalogClusterCountLayerProperties().toJson();
    final dotLayer = catalogDotLayerProperties().toJson();

    expect(mapCatalogSourceId, isNot(mapNativePointDataKey));
    expect(mapCatalogClusterLayerId, contains('catalog'));
    expect(source['cluster'], isFalse);
    expect(source['promoteId'], 'id');
    expect(geojson['features'], hasLength(3));
    expect(geojson['features'][0]['properties']['point_count'], 12);
    expect(geojson['features'][1]['geometry']['coordinates'], [
      126.978,
      37.5665,
    ]);
    expect(clusterLayer['circle-color'], '#FF8FA3');
    expect(clusterLayer['circle-opacity'], 0.9);
    expect(clusterLayer['circle-radius'], isA<List>());
    expect(clusterCountLayer['text-field'], ['get', 'point_count_abbreviated']);
    expect(dotLayer['circle-radius'], lessThan(8));
    expect(dotLayer['circle-radius'], 5.2);
    expect(dotLayer['circle-opacity'], 0.9);
  });

  test('filters coordinates before native camera and annotation calls', () {
    final validCoordinates = validOnmuMapCoordinates(const [
      OnmuLatLng(lat: double.nan, lng: 126.978),
      OnmuLatLng(lat: 37.5665, lng: 126.978),
      OnmuLatLng(lat: 91, lng: 126.978),
      OnmuLatLng(lat: 37.5651, lng: double.infinity),
    ]);
    final validPoints = validOnmuMapPoints(const [
      OnmuMapPoint(
        id: 'bad',
        label: 'Bad',
        coordinate: OnmuLatLng(lat: double.nan, lng: 126.978),
        order: 1,
      ),
      OnmuMapPoint(
        id: 'ok',
        label: 'OK',
        coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
        order: 2,
      ),
    ]);

    expect(validCoordinates, hasLength(1));
    expect(validCoordinates.single.lat, 37.5665);
    expect(validPoints, hasLength(1));
    expect(validPoints.single.id, 'ok');
  });

  test('normalizes non-finite catalog viewport values', () {
    const validBounds = OnmuMapBounds(
      south: 37.50,
      west: 126.90,
      north: 37.62,
      east: 127.08,
    );
    const invalidBounds = OnmuMapBounds(
      south: double.nan,
      west: 126.90,
      north: 37.62,
      east: 127.08,
    );

    expect(onmuMapSafeZoom(double.infinity), onmuMapDefaultCatalogZoom);
    expect(onmuMapSafeZoom(double.nan, fallback: double.nan), 11);
    expect(
      const OnmuMapViewport(bounds: validBounds, zoom: double.infinity).apiZoom,
      11,
    );
    expect(const OnmuMapViewport(bounds: validBounds, zoom: 12.6).apiZoom, 13);
    expect(
      const OnmuMapViewport(bounds: validBounds, zoom: double.infinity).isValid,
      isFalse,
    );
    expect(
      const OnmuMapViewport(bounds: invalidBounds, zoom: 12).isValid,
      isFalse,
    );
  });

  test('recreates native map when route camera targets change', () {
    const point = OnmuMapPoint(
      id: 'place-1',
      label: '장소',
      coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
      order: 1,
    );

    final emptyKey = onmuMapCameraSeedKey(
      points: const [],
      routeGeometry: const [],
    );
    final loadedKey = onmuMapCameraSeedKey(
      points: const [point],
      routeGeometry: const [],
    );
    final routeLoadedKey = onmuMapCameraSeedKey(
      points: const [point],
      routeGeometry: const [OnmuLatLng(lat: 37.57, lng: 126.982)],
    );

    expect(loadedKey, isNot(emptyKey));
    expect(routeLoadedKey, isNot(loadedKey));
  });

  test('keeps native map seed stable for non-camera-target rebuilds', () {
    const point = OnmuMapPoint(
      id: 'place-1',
      label: '장소',
      coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
      order: 1,
    );
    const relabeledPoint = OnmuMapPoint(
      id: 'place-1',
      label: '선택된 장소',
      coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
      order: 1,
    );

    final firstKey = onmuMapCameraSeedKey(
      points: const [point],
      routeGeometry: const [],
    );
    final rebuiltKey = onmuMapCameraSeedKey(
      points: const [relabeledPoint],
      routeGeometry: const [],
    );

    expect(rebuiltKey, firstKey);
  });

  test('calculates initial zoom from route spread', () {
    expect(
      onmuMapInitialZoomForCoordinates(
        coordinates: const [OnmuLatLng(lat: 37.5665, lng: 126.978)],
        fallbackZoom: 11,
      ),
      14.2,
    );
    expect(
      onmuMapInitialZoomForCoordinates(
        coordinates: const [
          OnmuLatLng(lat: 37.5665, lng: 126.978),
          OnmuLatLng(lat: 37.568, lng: 126.981),
        ],
        fallbackZoom: 11,
      ),
      greaterThan(13),
    );
    expect(
      onmuMapInitialZoomForCoordinates(
        coordinates: const [
          OnmuLatLng(lat: 37.1, lng: 126.5),
          OnmuLatLng(lat: 37.9, lng: 127.5),
        ],
        fallbackZoom: 11,
      ),
      lessThan(9),
    );
  });

  test('does not refit camera when only focused marker changes', () {
    final oldPoints = [
      const OnmuMapPoint(
        id: 'place-1',
        label: '이전 라벨',
        coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
        order: 1,
      ),
    ];
    final rebuiltPoints = [
      const OnmuMapPoint(
        id: 'place-1',
        label: '라벨만 바뀌어도 camera target은 같다',
        coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
        order: 1,
      ),
    ];
    final movedPoints = [
      const OnmuMapPoint(
        id: 'place-1',
        label: '이동한 후보',
        coordinate: OnmuLatLng(lat: 37.57, lng: 126.982),
        order: 1,
      ),
    ];
    final reorderedPoints = [
      const OnmuMapPoint(
        id: 'place-1',
        label: '순서 변경 후보',
        coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
        order: 2,
      ),
    ];

    expect(haveSameMapPointCameraTargets(oldPoints, rebuiltPoints), isTrue);
    expect(haveSameMapPointCameraTargets(oldPoints, movedPoints), isFalse);
    expect(haveSameMapPointCameraTargets(oldPoints, reorderedPoints), isFalse);
    expect(
      haveSameRouteCameraTargets(
        const [OnmuLatLng(lat: 37.5665, lng: 126.978)],
        const [OnmuLatLng(lat: 37.5665, lng: 126.978)],
      ),
      isTrue,
    );
    expect(
      haveSameRouteCameraTargets(
        const [OnmuLatLng(lat: 37.5665, lng: 126.978)],
        const [OnmuLatLng(lat: 37.5651, lng: 126.9895)],
      ),
      isFalse,
    );
    expect(haveSameOptionalCameraTarget(null, null), isTrue);
    expect(
      haveSameOptionalCameraTarget(
        const OnmuLatLng(lat: 37.5665, lng: 126.978),
        const OnmuLatLng(lat: 37.5665, lng: 126.978),
      ),
      isTrue,
    );
    expect(
      haveSameOptionalCameraTarget(
        const OnmuLatLng(lat: 37.5665, lng: 126.978),
        const OnmuLatLng(lat: 37.57, lng: 126.982),
      ),
      isFalse,
    );
    expect(
      haveSameOptionalCameraTarget(
        null,
        const OnmuLatLng(lat: 37.5665, lng: 126.978),
      ),
      isFalse,
    );
    expect(
      shouldFitCameraForMapUpdate(
        pointsChanged: !haveSameMapPointCameraTargets(oldPoints, rebuiltPoints),
        routeGeometryChanged: false,
        centerChanged: false,
        zoomChanged: false,
        styleLoaded: false,
      ),
      isFalse,
    );
    expect(
      shouldFitCameraForMapUpdate(
        pointsChanged: true,
        routeGeometryChanged: false,
        centerChanged: false,
        zoomChanged: false,
        styleLoaded: false,
      ),
      isTrue,
    );
    expect(
      shouldFitCameraForMapUpdate(
        pointsChanged: false,
        routeGeometryChanged: false,
        centerChanged: true,
        zoomChanged: false,
        styleLoaded: false,
      ),
      isFalse,
    );
    expect(
      shouldFitCameraForMapUpdate(
        pointsChanged: false,
        routeGeometryChanged: false,
        centerChanged: false,
        zoomChanged: true,
        styleLoaded: false,
      ),
      isFalse,
    );
    expect(
      shouldFitCameraForMapUpdate(
        pointsChanged: false,
        routeGeometryChanged: false,
        centerChanged: false,
        zoomChanged: false,
        styleLoaded: true,
      ),
      isTrue,
    );
  });

  testWidgets('renders fallback map state when manifest fetch fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tileManifestRepositoryProvider.overrideWithValue(
            const _FailingTileManifestRepository(),
          ),
        ],
        child: const MaterialApp(
          home: SizedBox(
            width: 320,
            height: 240,
            child: OnmuMapView(
              fallbackLabel: '지도 fallback',
              points: [
                OnmuMapPoint(
                  id: '1',
                  label: 'ONMU',
                  coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
                  order: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('지도 fallback'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('ONMU', findRichText: true), findsNothing);
  });

  testWidgets('keeps fallback map when web PMTiles protocol is not ready', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tileManifestRepositoryProvider.overrideWithValue(
            const _ReadyTileManifestRepository(),
          ),
        ],
        child: const MaterialApp(
          home: SizedBox(
            width: 320,
            height: 240,
            child: OnmuMapView(
              points: [
                OnmuMapPoint(
                  id: '1',
                  label: 'PMTiles 후보',
                  coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
                  order: 1,
                ),
              ],
              debugWebPmtilesProtocolReady: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('지도 스크립트를 준비하는 중입니다.'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('PMTiles 후보', findRichText: true), findsNothing);
  });

  testWidgets(
    'keeps overlay pin when widget test binding prevents platform view',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tileManifestRepositoryProvider.overrideWithValue(
              const _ReadyTileManifestRepository(),
            ),
          ],
          child: const MaterialApp(
            home: SizedBox(
              width: 320,
              height: 240,
              child: OnmuMapView(
                fallbackLabel: '지도 타일 fallback',
                points: [
                  OnmuMapPoint(
                    id: '1',
                    label: 'PMTiles 후보',
                    coordinate: OnmuLatLng(lat: 37.5665, lng: 126.978),
                    order: 1,
                  ),
                ],
                routeGeometry: [
                  OnmuLatLng(lat: 37.5665, lng: 126.978),
                  OnmuLatLng(lat: 37.5651, lng: 126.9895),
                ],
                debugWebPmtilesProtocolReady: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('지도 타일 fallback'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('PMTiles 후보', findRichText: true), findsNothing);
    },
  );

  testWidgets(
    'reports unavailable current location without native controller',
    (tester) async {
      var unavailableCount = 0;

      Widget buildMap({required int requestSerial}) {
        return ProviderScope(
          overrides: [
            tileManifestRepositoryProvider.overrideWithValue(
              const _FailingTileManifestRepository(),
            ),
          ],
          child: MaterialApp(
            home: SizedBox(
              width: 320,
              height: 240,
              child: OnmuMapView(
                fallbackLabel: '지도 fallback',
                points: const [],
                myLocationRequestSerial: requestSerial,
                onMyLocationUnavailable: () {
                  unavailableCount += 1;
                },
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildMap(requestSerial: 0));
      await tester.pump();

      await tester.pumpWidget(buildMap(requestSerial: 1));
      await tester.pump();
      await tester.pump();

      expect(unavailableCount, 1);
    },
  );

  testWidgets(
    'ignores explicit camera focus safely when native controller is absent',
    (tester) async {
      var unavailableCount = 0;

      Widget buildMap({required int focusSerial}) {
        return ProviderScope(
          overrides: [
            tileManifestRepositoryProvider.overrideWithValue(
              const _FailingTileManifestRepository(),
            ),
          ],
          child: MaterialApp(
            home: SizedBox(
              width: 320,
              height: 240,
              child: OnmuMapView(
                fallbackLabel: '지도 fallback',
                points: const [],
                cameraFocusTarget: const OnmuLatLng(lat: 37.5665, lng: 126.978),
                cameraFocusRequestSerial: focusSerial,
                onMyLocationUnavailable: () {
                  unavailableCount += 1;
                },
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildMap(focusSerial: 0));
      await tester.pump();

      await tester.pumpWidget(buildMap(focusSerial: 1));
      await tester.pump();

      expect(find.text('지도 fallback'), findsOneWidget);
      expect(unavailableCount, 0);
    },
  );
}

class _FailingTileManifestRepository implements TileManifestRepository {
  const _FailingTileManifestRepository();

  @override
  Future<TileManifest> fetchManifest() {
    throw const FormatException('manifest unavailable');
  }
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
