import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/map_models.dart';
import '../repository/map_catalog_repository.dart';

typedef MapCatalogScope = ({
  String groupId,
  String planId,
  OnmuMapViewport viewport,
  String? category,
  String? filter,
  String? query,
});

final mapCatalogProvider =
    FutureProvider.family<OnmuCatalogMapData, MapCatalogScope>((ref, scope) {
      return ref
          .watch(mapCatalogRepositoryProvider)
          .fetchMapPoints(
            groupId: scope.groupId,
            planId: scope.planId,
            viewport: scope.viewport,
            category: scope.category,
            filter: scope.filter,
            query: scope.query,
          );
    });
