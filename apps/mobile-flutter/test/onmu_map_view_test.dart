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

    expect(symbol.iconImage, 'onmu-map-marker-normal-7');
    expect(symbol.iconAnchor, 'center');
    expect(symbol.textField, isNull);
    expect(focusedSymbol.iconImage, 'onmu-map-marker-focused-7');
    expect(markerBytes, isNotEmpty);
    expect(line?.geometry, hasLength(2));
    expect(line?.lineColor, '#1D4ED8');
    expect(line?.lineWidth, greaterThan(6));
    expect(casingLine?.lineColor, '#FFFFFF');
    expect(casingLine?.lineWidth, greaterThan(line!.lineWidth!));
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
      center: null,
      zoom: 11,
    );
    final loadedKey = onmuMapCameraSeedKey(
      points: const [point],
      routeGeometry: const [],
      center: null,
      zoom: 11,
    );

    expect(loadedKey, isNot(emptyKey));
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
