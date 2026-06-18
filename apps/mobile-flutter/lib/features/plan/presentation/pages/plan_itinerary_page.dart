import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/map/model/map_models.dart';
import '../../../../features/map/view_model/route_recommendation_view_model.dart';
import '../../../../features/map/widgets/onmu_map_view.dart';
import '../../../../shared/models/plan_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_top_bar.dart';
import '../../../place/view_model/place_candidates_view_model.dart';
import '../../view_model/plan_detail_view_model.dart';
import '../../widgets/plan_date_tabs.dart';

class PlanItineraryPage extends ConsumerStatefulWidget {
  const PlanItineraryPage({
    required this.groupId,
    required this.planId,
    super.key,
  });

  final String groupId;
  final String planId;

  @override
  ConsumerState<PlanItineraryPage> createState() => _PlanItineraryPageState();
}

class _PlanItineraryPageState extends ConsumerState<PlanItineraryPage> {
  var _selectedDateIndex = 0;
  var _travelMode = 'walk';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      planDetailViewModelProvider((
        groupId: widget.groupId,
        planId: widget.planId,
      )),
    );

    return state.when(
      data: (state) => _buildContent(context, state),
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgWarm,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: AppColors.bgWarm,
        body: SafeArea(
          child: Center(
            child: Text(
              '동선을 불러오지 못했어요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PlanDetailState state) {
    final selectedVisitPlan = state.visitPlanForDate(_selectedDateIndex);
    final routeState = ref.watch(
      routeRecommendationViewModelProvider((
        groupId: widget.groupId,
        planId: widget.planId,
        travelMode: _travelMode,
      )),
    );

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      body: SafeArea(
        child: Column(
          children: [
            OnmuTopBar(
              title: '장소 동선',
              showBackButton: true,
              onBack: () => context.popOrGo(
                RoutePaths.planDetail(widget.groupId, widget.planId),
              ),
              action: IconButton(
                tooltip: '동선 옵션',
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  _RouteMap(
                    routeState: routeState,
                    visitPlan: selectedVisitPlan,
                    travelMode: _travelMode,
                    onTravelModeChanged: (mode) =>
                        setState(() => _travelMode = mode),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PlanDateTabs(
                    tabs: state.dateTabs,
                    selectedIndex: _selectedDateIndex,
                    onChanged: (index) =>
                        setState(() => _selectedDateIndex = index),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.dateTabForDate(_selectedDateIndex).headingLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('동선 목록', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  _RouteList(
                    groupId: widget.groupId,
                    planId: widget.planId,
                    visitPlan: selectedVisitPlan,
                    onDelete: _deleteSchedulePlace,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: OnmuPrimaryButton(
            label: '상세로 돌아가기',
            icon: Icons.check,
            color: AppColors.primaryPink,
            foregroundColor: AppColors.textInverse,
            onPressed: () => context.go(
              RoutePaths.planDetail(widget.groupId, widget.planId),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSchedulePlace(VisitPlan plan) async {
    await ref
        .read(
          placeCandidatesViewModelProvider((
            groupId: widget.groupId,
            planId: widget.planId,
          )).notifier,
        )
        .deleteSchedulePlace(plan.id);
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

class _RouteMap extends StatelessWidget {
  const _RouteMap({
    required this.routeState,
    required this.visitPlan,
    required this.travelMode,
    required this.onTravelModeChanged,
  });

  final AsyncValue<RouteRecommendation> routeState;
  final List<VisitPlan> visitPlan;
  final String travelMode;
  final ValueChanged<String> onTravelModeChanged;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.bgGrid,
      borderColor: AppColors.lineSoft,
      child: SizedBox(
        height: 280,
        child: Stack(
          children: [
            Positioned.fill(
              child: routeState.when(
                data: (route) {
                  final stops = _routeStopsForVisitPlan(route, visitPlan);
                  return OnmuMapView(
                    points: stops,
                    routeGeometry: stops.length >= 2
                        ? route.geometry
                        : const [],
                    zoom: _mapZoomFor(stops),
                    fallbackLabel: '장소 동선',
                  );
                },
                loading: () =>
                    const OnmuMapView(points: [], fallbackLabel: '동선 계산 중입니다.'),
                error: (error, stackTrace) => const OnmuMapView(
                  points: [],
                  fallbackLabel: '동선 지도를 불러오지 못했어요',
                ),
              ),
            ),
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
                    onSelected: onTravelModeChanged,
                  ),
                  _TravelModeChip(
                    label: '자전거',
                    mode: 'bike',
                    selectedMode: travelMode,
                    onSelected: onTravelModeChanged,
                  ),
                  _TravelModeChip(
                    label: '차량',
                    mode: 'car',
                    selectedMode: travelMode,
                    onSelected: onTravelModeChanged,
                  ),
                ],
              ),
            ),
            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
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
      ),
    );
  }
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

class _RouteList extends StatelessWidget {
  const _RouteList({
    required this.groupId,
    required this.planId,
    required this.visitPlan,
    required this.onDelete,
  });

  final String groupId;
  final String planId;
  final List<VisitPlan> visitPlan;
  final Future<void> Function(VisitPlan plan) onDelete;

  @override
  Widget build(BuildContext context) {
    if (visitPlan.isEmpty) {
      return OnmuCard(
        backgroundColor: AppColors.bgDefault,
        child: Text(
          '아직 추가된 방문 장소가 없어요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
        ),
      );
    }

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Column(
        children: [
          for (var index = 0; index < visitPlan.length; index += 1)
            _RouteListItem(
              order: index + 1,
              plan: visitPlan[index],
              onTap: () => _openPlaceSearch(context, visitPlan[index]),
              onDelete: visitPlan[index].id.trim().isEmpty
                  ? null
                  : () => _deleteVisitPlan(context, visitPlan[index]),
            ),
        ],
      ),
    );
  }

  void _openPlaceSearch(BuildContext context, VisitPlan plan) {
    final query = Uri.encodeComponent(plan.place.trim());
    context.push('${RoutePaths.planPlaceSearch(groupId, planId)}?query=$query');
  }

  Future<void> _deleteVisitPlan(BuildContext context, VisitPlan plan) async {
    try {
      await onDelete(plan);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('방문 장소를 삭제하지 못했어요.')));
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('방문 장소를 삭제했어요.')));
  }
}

enum _RoutePlaceAction { delete }

class _RouteListItem extends StatelessWidget {
  const _RouteListItem({
    required this.order,
    required this.plan,
    required this.onTap,
    required this.onDelete,
  });

  final int order;
  final VisitPlan plan;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final metaLabel = _visitPlanMetaLabel(plan);
    final timeRangeLabel = _visitTimeRangeLabel(plan);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: OnmuCard(
        onTap: onTap,
        backgroundColor: AppColors.bgPaper,
        borderColor: AppColors.lineSoft,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primaryPink,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: SizedBox.square(
                dimension: 30,
                child: Center(
                  child: Text(
                    '$order',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textInverse,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.place,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (metaLabel.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      metaLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                  ],
                  if (timeRangeLabel.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      timeRangeLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<_RoutePlaceAction>(
              tooltip: '장소 더보기',
              icon: const Icon(Icons.more_horiz),
              onSelected: (action) {
                switch (action) {
                  case _RoutePlaceAction.delete:
                    onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _RoutePlaceAction.delete,
                  enabled: onDelete != null,
                  child: const Text('삭제하기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _visitPlanMetaLabel(VisitPlan plan) {
  final kind = plan.kind.trim();
  final duration = plan.duration.trim();
  if (kind.isEmpty) {
    return duration;
  }
  if (duration.isEmpty) {
    return kind;
  }
  return '$kind · $duration';
}

String _visitTimeRangeLabel(VisitPlan plan) {
  final start = plan.time.trim();
  final end = plan.endTime.trim();
  if (start.isEmpty) {
    return end;
  }
  if (end.isEmpty) {
    return start;
  }
  return '$start ~ $end';
}
