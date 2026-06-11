import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/map_models.dart';
import '../repository/route_repository.dart';

typedef RouteRecommendationScope = ({
  String groupId,
  String planId,
  String travelMode,
});

final routeRecommendationViewModelProvider =
    FutureProvider.family<RouteRecommendation, RouteRecommendationScope>((
      ref,
      scope,
    ) {
      return ref
          .watch(routeRepositoryProvider)
          .recommend(
            groupId: scope.groupId,
            planId: scope.planId,
            travelMode: scope.travelMode,
          );
    });
