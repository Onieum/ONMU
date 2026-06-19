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
                      return OnmuMapView(
                        key: const ValueKey('plan-itinerary-route-map'),
                        points: stops,
                        routeGeometry: stops.length >= 2
                            ? route.geometry
                            : const [],
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
    final key = stop.label.trim().toLowerCase();
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

  final stopsByName = <String, OnmuMapPoint>{};
  for (final stop in _uniqueRouteStops(route.stops)) {
    final key = _normalizePlaceName(stop.label);
    if (key.isNotEmpty) {
      stopsByName.putIfAbsent(key, () => stop);
    }
  }

  final filtered = <OnmuMapPoint>[];
  for (final plan in visitPlan) {
    final stop = stopsByName[_normalizePlaceName(plan.place)];
    if (stop == null) {
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
                        : '${_durationLabel(route.durationSeconds)} · '
                              '${_distanceLabel(route.distanceMeters)} · '
                              '${_legLabel(route, stops)}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  if (!route.isFallback &&
                      _routeLegPreviewLabel(route).isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _routeLegPreviewLabel(route),
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
  if (route.legs.isNotEmpty) {
    return '${route.legs.length}구간';
  }
  return '${stops.length}곳';
}

String _routeLegPreviewLabel(RouteRecommendation route) {
  if (route.legs.isEmpty) {
    return '';
  }
  final leg = route.legs.first;
  final labels = [
    '${leg.fromName} → ${leg.toName}',
    if (leg.durationSeconds != null) _durationLabel(leg.durationSeconds!),
    if (leg.distanceMeters != null) _distanceLabel(leg.distanceMeters!),
  ];
  final suffix = route.legs.length > 1 ? ' 외 ${route.legs.length - 1}구간' : '';
  return '${labels.join(' · ')}$suffix';
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
