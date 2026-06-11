import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../model/map_models.dart';

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return ApiRouteRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class RouteRepository {
  Future<RouteRecommendation> recommend({
    required Object groupId,
    required Object planId,
    required String travelMode,
  });
}

class ApiRouteRepository implements RouteRepository {
  const ApiRouteRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<RouteRecommendation> recommend({
    required Object groupId,
    required Object planId,
    required String travelMode,
  }) async {
    final route = await _client.postObject(
      '/api/v1/routes/recommend',
      body: {
        'groupId': groupId.toString(),
        'planId': planId.toString(),
        'travelMode': travelMode,
      },
    );
    return RouteRecommendation.fromJson(route);
  }
}
