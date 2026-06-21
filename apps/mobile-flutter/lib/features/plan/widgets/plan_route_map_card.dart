import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/map/model/map_models.dart';
import '../../../features/map/widgets/onmu_map_view.dart';
import '../../../shared/models/plan_models.dart';
import '../../../shared/widgets/onmu_card.dart';
import '../../../shared/widgets/onmu_chip.dart';

const double _routePreviewMapHeight = 340;

const EdgeInsets _routePreviewCameraFitPadding = EdgeInsets.fromLTRB(
  48,
  88,
  48,
  104,
);

const EdgeInsets _routePreviewMarkerScreenSafetyPadding = EdgeInsets.fromLTRB(
  0,
  72,
  0,
  72,
);

class PlanRouteMapCard extends StatelessWidget {
  const PlanRouteMapCard({
    required this.routeState,
    required this.visitPlan,
    required this.travelMode,
    this.onTravelModeChanged,
    this.showTravelModeControls = true,
    this.height = _routePreviewMapHeight,
    super.key,
  });

  final AsyncValue<RouteRecommendation> routeState;
  final List<VisitPlan> visitPlan;
  final String travelMode;
  final ValueChanged<String>? onTravelModeChanged;
  final bool showTravelModeControls;
  final double height;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.bgGrid,
      borderColor: AppColors.lineSoft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: routeState.when(
                    data: (route) {
                      final stops = _routeStopsForVisitPlan(route, visitPlan);
                      final routeGeometry = _routeGeometryForVisibleStops(
                        route,
                        stops,
                      );
                      return OnmuMapView(
                        key: const ValueKey('plan-itinerary-route-map'),
                        points: stops,
                        routeGeometry: routeGeometry,
                        zoom: _mapZoomFor(stops),
                        cameraFitPadding: _routePreviewCameraFitPadding,
                        markerScreenSafetyPadding:
                            _routePreviewMarkerScreenSafetyPadding,
                        fallbackLabel: '장소 동선',
                      );
                    },
                    loading: () => const OnmuMapView(
                      key: ValueKey('plan-itinerary-route-map'),
                      points: [],
                      cameraFitPadding: _routePreviewCameraFitPadding,
                      markerScreenSafetyPadding:
                          _routePreviewMarkerScreenSafetyPadding,
                      fallbackLabel: '동선 계산 중입니다.',
                    ),
                    error: (error, stackTrace) => const OnmuMapView(
                      key: ValueKey('plan-itinerary-route-map'),
                      points: [],
                      cameraFitPadding: _routePreviewCameraFitPadding,
                      markerScreenSafetyPadding:
                          _routePreviewMarkerScreenSafetyPadding,
                      fallbackLabel: '동선 지도를 불러오지 못했어요',
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: const _RouteStatusPill(label: '장소 동선'),
                ),
                if (showTravelModeControls && onTravelModeChanged != null)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        _TravelModeChip(
                          label: '도보',
                          mode: 'walk',
                          selectedMode: travelMode,
                          onSelected: onTravelModeChanged!,
                        ),
                        _TravelModeChip(
                          label: '자전거',
                          mode: 'bike',
                          selectedMode: travelMode,
                          onSelected: onTravelModeChanged!,
                        ),
                        _TravelModeChip(
                          label: '차량',
                          mode: 'car',
                          selectedMode: travelMode,
                          onSelected: onTravelModeChanged!,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: routeState.when(
              data: (route) {
                final stops = _routeStopsForVisitPlan(route, visitPlan);
                return stops.length >= 2
                    ? _RouteSummaryPill(route: route, stops: stops)
                    : _RouteStatusPill(label: _routeStatusLabel(stops));
              },
              loading: () => const _RouteStatusPill(label: '동선 계산 중'),
              error: (error, stackTrace) =>
                  const _RouteStatusPill(label: '동선을 계산하지 못했어요'),
            ),
          ),
        ],
      ),
    );
  }
}

List<OnmuMapPoint> _uniqueRouteStops(List<OnmuMapPoint> stops) {
  final uniqueStops = <OnmuMapPoint>[];
  final seen = <String>{};
  for (final stop in stops) {
    final key = _routeStopKey(stop);
    if (key.isEmpty || !seen.add(key)) {
      continue;
    }
    uniqueStops.add(
      OnmuMapPoint(
        id: stop.id,
        label: stop.label,
        coordinate: stop.coordinate,
        order: uniqueStops.length + 1,
      ),
    );
  }
  return uniqueStops;
}

List<OnmuMapPoint> _routeStopsForVisitPlan(
  RouteRecommendation route,
  List<VisitPlan> visitPlan,
) {
  if (visitPlan.isEmpty) {
    return const [];
  }

  final stopsById = <String, OnmuMapPoint>{};
  final stopsByName = <String, OnmuMapPoint>{};
  for (final stop in _uniqueRouteStops(route.stops)) {
    final idKey = _normalizeStopId(stop.id);
    if (idKey.isNotEmpty) {
      stopsById.putIfAbsent(idKey, () => stop);
    }
    final key = _normalizePlaceName(stop.label);
    if (key.isNotEmpty) {
      stopsByName.putIfAbsent(key, () => stop);
    }
  }

  final filtered = <OnmuMapPoint>[];
  final usedStopKeys = <String>{};
  for (final plan in visitPlan) {
    final idKey = _normalizeStopId(plan.id);
    final nameKey = _normalizePlaceName(plan.place);
    final stopById = idKey.isEmpty ? null : stopsById[idKey];
    final stopByName = nameKey.isEmpty ? null : stopsByName[nameKey];
    final stop = stopById ?? stopByName;
    if (stop == null) {
      continue;
    }
    final stopKey = _routeStopKey(stop);
    if (stopKey.isNotEmpty && !usedStopKeys.add(stopKey)) {
      continue;
    }
    filtered.add(
      OnmuMapPoint(
        id: stop.id,
        label: stop.label,
        coordinate: stop.coordinate,
        order: filtered.length + 1,
      ),
    );
  }
  return List.unmodifiable(filtered);
}

List<OnmuLatLng> _routeGeometryForVisibleStops(
  RouteRecommendation route,
  List<OnmuMapPoint> stops,
) {
  if (stops.length < 2) {
    return const [];
  }

  final fallback = _stopCoordinates(stops);
  if (route.geometry.length < 2) {
    return fallback;
  }

  if (_routeStopsMatchVisibleStops(route, stops)) {
    return route.geometry;
  }

  final routeStopIndices = _routeStopIndicesForVisibleStops(route, stops);
  if (routeStopIndices.length != stops.length ||
      !_routeStopIndicesAreConsecutive(routeStopIndices)) {
    return fallback;
  }

  final startIndex = _nearestGeometryIndex(
    route.geometry,
    route.stops[routeStopIndices.first].coordinate,
  );
  final endIndex = _nearestGeometryIndex(
    route.geometry,
    route.stops[routeStopIndices.last].coordinate,
  );
  if (startIndex == null || endIndex == null || startIndex >= endIndex) {
    return fallback;
  }

  final sliced = route.geometry
      .sublist(startIndex, endIndex + 1)
      .where(isValidOnmuLatLng)
      .toList(growable: false);
  return sliced.length >= 2 ? sliced : fallback;
}

List<OnmuLatLng> _stopCoordinates(List<OnmuMapPoint> stops) {
  return stops
      .map((stop) => stop.coordinate)
      .where(isValidOnmuLatLng)
      .toList(growable: false);
}

bool _routeStopsMatchVisibleStops(
  RouteRecommendation route,
  List<OnmuMapPoint> stops,
) {
  if (route.stops.length != stops.length) {
    return false;
  }
  for (var index = 0; index < stops.length; index += 1) {
    if (!_stopsReferToSamePlace(route.stops[index], stops[index])) {
      return false;
    }
  }
  return true;
}

List<int> _routeStopIndicesForVisibleStops(
  RouteRecommendation route,
  List<OnmuMapPoint> stops,
) {
  final indices = <int>[];
  var searchStart = 0;
  for (final stop in stops) {
    if (_routeStopKey(stop).isEmpty) {
      return const [];
    }
    var found = -1;
    for (var index = searchStart; index < route.stops.length; index += 1) {
      if (_stopsReferToSamePlace(route.stops[index], stop)) {
        found = index;
        break;
      }
    }
    if (found < 0) {
      return const [];
    }
    indices.add(found);
    searchStart = found + 1;
  }
  return indices;
}

bool _routeStopIndicesAreConsecutive(List<int> indices) {
  if (indices.isEmpty) {
    return false;
  }
  for (var index = 1; index < indices.length; index += 1) {
    if (indices[index] != indices[index - 1] + 1) {
      return false;
    }
  }
  return true;
}

int? _nearestGeometryIndex(List<OnmuLatLng> geometry, OnmuLatLng target) {
  if (!isValidOnmuLatLng(target)) {
    return null;
  }
  var bestIndex = -1;
  var bestDistance = double.infinity;
  for (var index = 0; index < geometry.length; index += 1) {
    final point = geometry[index];
    if (!isValidOnmuLatLng(point)) {
      continue;
    }
    final latDelta = point.lat - target.lat;
    final lngDelta = point.lng - target.lng;
    final distance = latDelta * latDelta + lngDelta * lngDelta;
    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = index;
    }
  }
  return bestIndex < 0 ? null : bestIndex;
}

String _routeStopKey(OnmuMapPoint stop) {
  final idKey = _normalizeStopId(stop.id);
  if (idKey.isNotEmpty) {
    return 'id:$idKey';
  }
  final nameKey = _normalizePlaceName(stop.label);
  if (nameKey.isEmpty) {
    return '';
  }
  final coordinate = stop.coordinate;
  if (isValidOnmuLatLng(coordinate)) {
    return 'name:$nameKey:${coordinate.lat.toStringAsFixed(6)},'
        '${coordinate.lng.toStringAsFixed(6)}';
  }
  return 'name:$nameKey';
}

bool _stopsReferToSamePlace(OnmuMapPoint routeStop, OnmuMapPoint visibleStop) {
  final routeId = _normalizeStopId(routeStop.id);
  final visibleId = _normalizeStopId(visibleStop.id);
  if (routeId.isNotEmpty && visibleId.isNotEmpty) {
    return routeId == visibleId;
  }
  return _normalizePlaceName(routeStop.label) ==
      _normalizePlaceName(visibleStop.label);
}

String _normalizeStopId(String value) {
  return value.trim().toLowerCase();
}

String _normalizePlaceName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
}

double _mapZoomFor(List<OnmuMapPoint> stops) {
  if (stops.length <= 1) {
    return 14;
  }
  if (stops.length == 2) {
    return 12;
  }
  return 10.8;
}

class _RouteSummaryPill extends StatelessWidget {
  const _RouteSummaryPill({required this.route, required this.stops});

  final RouteRecommendation route;
  final List<OnmuMapPoint> stops;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lineSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.route, color: AppColors.primaryPink),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.isFallback
                        ? '${_routeFallbackLabel(route)} · ${stops.length}곳'
                        : _routeSummaryLabel(route, stops),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  if (!route.isFallback &&
                      _routeLegPreviewLabel(route, stops).isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _routeLegPreviewLabel(route, stops),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStatusPill extends StatelessWidget {
  const _RouteStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

String _routeStatusLabel(List<OnmuMapPoint> stops) {
  if (stops.isEmpty) {
    return '계산된 동선이 없어요';
  }
  return '방문 장소 1곳';
}

String _routeFallbackLabel(RouteRecommendation route) {
  return switch (route.fallbackReason) {
    'provider_unavailable' => '실제 경로 제공자 미설정',
    'provider_failure' => '실제 경로 계산 실패',
    'insufficient_coordinates' => '경로 계산 좌표 부족',
    _ => '실제 경로 확인 전',
  };
}

String _legLabel(RouteRecommendation route, List<OnmuMapPoint> stops) {
  final stopLegCount = stops.length - 1;
  if (stopLegCount > 0) {
    return '$stopLegCount구간';
  }
  return '${stops.length}곳';
}

String _routeSummaryLabel(RouteRecommendation route, List<OnmuMapPoint> stops) {
  final durationSeconds = _visibleRouteDurationSeconds(route, stops);
  final distanceMeters = _visibleRouteDistanceMeters(route, stops);
  return [
    if (durationSeconds > 0) _durationLabel(durationSeconds),
    if (distanceMeters > 0) _distanceLabel(distanceMeters),
    _legLabel(route, stops),
  ].join(' · ');
}

String _routeLegPreviewLabel(
  RouteRecommendation route,
  List<OnmuMapPoint> stops,
) {
  if (stops.length < 2) {
    return '';
  }

  final from = stops.first.label.trim();
  final to = stops[1].label.trim();
  if (from.isEmpty || to.isEmpty) {
    return '';
  }

  RouteLeg? matchingLeg;
  for (final leg in route.legs) {
    if (_legMatchesStops(leg, stops.first, stops[1])) {
      matchingLeg = leg;
      break;
    }
  }
  final useWholeRouteMetrics =
      matchingLeg == null &&
      stops.length == 2 &&
      _routeStopsMatchVisibleStops(route, stops);
  final durationSeconds =
      matchingLeg?.durationSeconds ??
      (useWholeRouteMetrics ? route.durationSeconds : 0);
  final distanceMeters =
      matchingLeg?.distanceMeters ??
      (useWholeRouteMetrics ? route.distanceMeters : 0);
  final labels = [
    '$from → $to',
    if (durationSeconds > 0) _durationLabel(durationSeconds),
    if (distanceMeters > 0) _distanceLabel(distanceMeters),
  ];
  final remainingLegCount = stops.length - 2;
  final suffix = remainingLegCount > 0 ? ' 외 $remainingLegCount구간' : '';
  return '${labels.join(' · ')}$suffix';
}

int _visibleRouteDistanceMeters(
  RouteRecommendation route,
  List<OnmuMapPoint> stops,
) {
  final legs = _visibleRouteLegs(route, stops);
  if (legs.length == stops.length - 1) {
    final values = legs.map((leg) => leg.distanceMeters).whereType<int>();
    if (values.length == legs.length) {
      return values.fold(0, (total, value) => total + value);
    }
  }
  return _routeStopsMatchVisibleStops(route, stops) ? route.distanceMeters : 0;
}

int _visibleRouteDurationSeconds(
  RouteRecommendation route,
  List<OnmuMapPoint> stops,
) {
  final legs = _visibleRouteLegs(route, stops);
  if (legs.length == stops.length - 1) {
    final values = legs.map((leg) => leg.durationSeconds).whereType<int>();
    if (values.length == legs.length) {
      return values.fold(0, (total, value) => total + value);
    }
  }
  return _routeStopsMatchVisibleStops(route, stops) ? route.durationSeconds : 0;
}

List<RouteLeg> _visibleRouteLegs(
  RouteRecommendation route,
  List<OnmuMapPoint> stops,
) {
  if (stops.length < 2) {
    return const [];
  }
  final legs = <RouteLeg>[];
  for (var index = 0; index < stops.length - 1; index += 1) {
    RouteLeg? matchingLeg;
    for (final leg in route.legs) {
      if (_legMatchesStops(leg, stops[index], stops[index + 1])) {
        matchingLeg = leg;
        break;
      }
    }
    if (matchingLeg == null) {
      return const [];
    }
    legs.add(matchingLeg);
  }
  return legs;
}

bool _legMatchesStops(RouteLeg leg, OnmuMapPoint from, OnmuMapPoint to) {
  return _legEndpointMatchesStop(leg.fromStopId, leg.fromName, from) &&
      _legEndpointMatchesStop(leg.toStopId, leg.toName, to);
}

bool _legEndpointMatchesStop(
  String legStopId,
  String legStopName,
  OnmuMapPoint stop,
) {
  final legId = _normalizeStopId(legStopId);
  final stopId = _normalizeStopId(stop.id);
  if (legId.isNotEmpty && stopId.isNotEmpty) {
    return legId == stopId;
  }
  return _normalizePlaceName(legStopName) == _normalizePlaceName(stop.label);
}

String _durationLabel(int seconds) {
  if (seconds <= 0) {
    return '시간 계산 중';
  }
  final minutes = (seconds / 60).ceil();
  if (minutes < 60) {
    return '$minutes분';
  }
  final hours = minutes ~/ 60;
  final restMinutes = minutes % 60;
  return restMinutes == 0 ? '$hours시간' : '$hours시간 $restMinutes분';
}

String _distanceLabel(int meters) {
  if (meters <= 0) {
    return '거리 계산 중';
  }
  if (meters < 1000) {
    return '${meters}m';
  }
  return '${(meters / 1000).toStringAsFixed(1)}km';
}

class _TravelModeChip extends StatelessWidget {
  const _TravelModeChip({
    required this.label,
    required this.mode,
    required this.selectedMode,
    required this.onSelected,
  });

  final String label;
  final String mode;
  final String selectedMode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return OnmuChip(
      label: label,
      selected: selectedMode == mode,
      onTap: () => onSelected(mode),
    );
  }
}
