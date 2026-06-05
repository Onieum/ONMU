import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';

void main() {
  test('RoutePaths builds operating plan and record routes', () {
    expect(RoutePaths.planDetail('g1', 'p1'), '/groups/g1/plans/p1');
    expect(
      RoutePaths.planItinerary('g1', 'p1'),
      '/groups/g1/plans/p1/itinerary',
    );
    expect(RoutePaths.records, '/records');
  });

  test('RoutePaths does not carry demo seeds or legacy route segments', () {
    final source = File('lib/core/routing/route_paths.dart').readAsStringSync();

    for (final forbidden in [
      'friends',
      'demo',
      'lunch-split',
      'onmoimDemo',
      '/onmoim',
      '/meetups',
      '/ootd/list',
      'planPlaceCompare',
      'planPlaceRisks',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
  });
}
