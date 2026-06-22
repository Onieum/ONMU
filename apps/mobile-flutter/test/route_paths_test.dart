import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';

void main() {
  test('RoutePaths builds operating plan and record routes', () {
    expect(RoutePaths.planDetail(1, 101), '/groups/1/plans/101');
    expect(RoutePaths.planEdit(1, 103), '/groups/1/plans/103/edit');
    expect(RoutePaths.planItinerary(1, 101), '/groups/1/plans/101/itinerary');
    expect(
      RoutePaths.planSettlementNew(1, 103),
      '/groups/1/plans/103/settlements/new',
    );
    expect(
      RoutePaths.planSettlementCurrent(1, 103),
      '/groups/1/plans/103/settlements/current',
    );
    expect(
      RoutePaths.planSettlementBasis(1, 103, 'stl_301'),
      '/groups/1/plans/103/settlements/stl_301/basis',
    );
    expect(
      RoutePaths.planItinerary(1, 101, dateIndex: 1),
      '/groups/1/plans/101/itinerary?dateIndex=1',
    );
    expect(RoutePaths.records, '/records');
  });

  test('RoutePaths uses operating route segments only', () {
    final source = File('lib/core/routing/route_paths.dart').readAsStringSync();

    for (final forbidden in [
      'friends',
      'lunch-split',
      '/ootd/list',
      '/group/list',
      '/home/page',
      '/my/page',
      '/place/candidate',
      'planPlaceCompare',
      'planPlaceRisks',
      'groupListPage',
      'homePage',
      'memoryDetailPage',
      'myPage',
      'ootdListPage',
      'placeCandidatePage',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
  });

  test('place search route disables platform slide transition', () {
    final source = File('lib/core/routing/app_router.dart').readAsStringSync();
    final placeSearchRoute = RegExp(
      r"path: 'place-search',[\s\S]*?NoTransitionPage<void>",
    );

    expect(source, contains(placeSearchRoute));
  });
}
