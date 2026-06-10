import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/map/model/map_models.dart';

void main() {
  test('parses tile manifest pointer without hard-coded PMTiles URL', () {
    final manifest = TileManifest.fromJson({
      'styleUrl': 'https://tiles.onmu.cloud/styles/onmu-light.json',
      'current': {
        'tileset': {
          'url': 'pmtiles://https://tiles.onmu.cloud/pmtiles/korea-dev.pmtiles',
        },
      },
      'bounds': [124.0, 33.0, 132.0, 39.0],
      'center': [127.8, 36.5],
      'generatedAt': '2026-06-10T00:00:00Z',
    });

    expect(
      manifest.styleUrl,
      'https://tiles.onmu.cloud/styles/onmu-light.json',
    );
    expect(manifest.currentPmtilesUrl, contains('pmtiles://'));
    expect(manifest.center.lat, 36.5);
    expect(manifest.center.lng, 127.8);
    expect(manifest.bounds, [124.0, 33.0, 132.0, 39.0]);
  });
}
