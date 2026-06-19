import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../model/map_models.dart';

final mapCatalogRepositoryProvider = Provider<MapCatalogRepository>((ref) {
  return ApiMapCatalogRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class MapCatalogRepository {
  Future<OnmuCatalogMapData> fetchMapPoints({
    required Object groupId,
    required Object planId,
    required OnmuMapViewport viewport,
    String? category,
    String? filter,
    String? query,
  });
}

class ApiMapCatalogRepository implements MapCatalogRepository {
  const ApiMapCatalogRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<OnmuCatalogMapData> fetchMapPoints({
    required Object groupId,
    required Object planId,
    required OnmuMapViewport viewport,
    String? category,
    String? filter,
    String? query,
  }) async {
    final response = await _client.postObject(
      '/api/v1/map-points',
      body: {
        'groupId': groupId.toString(),
        'planId': planId.toString(),
        'bounds': viewport.bounds.toJson(),
        'zoom': viewport.apiZoom,
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
        if (filter != null && filter.trim().isNotEmpty) 'filter': filter.trim(),
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
      },
    );
    return OnmuCatalogMapData.fromJson(response);
  }
}
