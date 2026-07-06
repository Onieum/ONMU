import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/map_models.dart';

const defaultOnmuTileManifestUrl =
    'https://tiles.onmu.cloud/manifest.json';

final tileManifestRepositoryProvider = Provider<TileManifestRepository>((ref) {
  const manifestUrl = String.fromEnvironment(
    'ONMU_TILE_MANIFEST_URL',
    defaultValue: defaultOnmuTileManifestUrl,
  );
  return HttpTileManifestRepository(Dio(), manifestUrl);
});

final tileManifestProvider = FutureProvider<TileManifest>((ref) {
  return ref.watch(tileManifestRepositoryProvider).fetchManifest();
});

abstract interface class TileManifestRepository {
  Future<TileManifest> fetchManifest();
}

class HttpTileManifestRepository implements TileManifestRepository {
  const HttpTileManifestRepository(this._dio, this.manifestUrl);

  final Dio _dio;
  final String manifestUrl;

  @override
  Future<TileManifest> fetchManifest() async {
    final response = await _dio.get<Object?>(manifestUrl);
    final data = response.data;
    if (data is Map) {
      return TileManifest.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    throw const FormatException('invalid tile manifest');
  }
}
