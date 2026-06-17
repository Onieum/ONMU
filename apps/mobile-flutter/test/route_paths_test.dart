import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';

void main() {
  test('RoutePaths builds operating plan and record routes', () {
    expect(RoutePaths.planDetail(1, 101), '/groups/1/plans/101');
    expect(RoutePaths.planEdit(1, 103), '/groups/1/plans/103/edit');
    expect(RoutePaths.planItinerary(1, 101), '/groups/1/plans/101/itinerary');
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
}
