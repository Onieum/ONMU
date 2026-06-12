import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/map/model/map_models.dart';
import 'package:onmu_mobile/features/map/repository/tile_manifest_repository.dart';
import 'package:onmu_mobile/features/map/widgets/onmu_map_view.dart';

void main() {
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
    expect(find.text('ONMU', findRichText: true), findsOneWidget);
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
    expect(find.text('PMTiles 후보', findRichText: true), findsOneWidget);
  });
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
    return const TileManifest(
      styleUrl: 'https://tiles.onmu.cloud/styles/onmu-light.json',
      currentPmtilesUrl:
          'pmtiles://https://tiles.onmu.cloud/pmtiles/korea-dev.pmtiles',
      bounds: [124, 33, 132, 39],
      center: OnmuLatLng(lat: 37.5665, lng: 126.978),
      generatedAt: null,
    );
  }
}
