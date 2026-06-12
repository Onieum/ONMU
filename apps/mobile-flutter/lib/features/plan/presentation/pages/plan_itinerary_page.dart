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
import '../../view_model/plan_detail_view_model.dart';

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
                    travelMode: _travelMode,
                    onTravelModeChanged: (mode) =>
                        setState(() => _travelMode = mode),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DateTabs(
                    selectedIndex: _selectedDateIndex,
                    onChanged: (index) =>
                        setState(() => _selectedDateIndex = index),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '6/7 토 동선',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('동선 목록', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  _RouteList(
                    routeState: routeState,
                    visitPlan: state.visitPlanForDate(_selectedDateIndex),
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

class _RouteMap extends StatelessWidget {
  const _RouteMap({
    required this.routeState,
    required this.travelMode,
    required this.onTravelModeChanged,
  });

  final AsyncValue<RouteRecommendation> routeState;
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
                data: (route) => OnmuMapView(
                  points: _uniqueRouteStops(route.stops),
                  routeGeometry: route.geometry,
                  fallbackLabel: '동선 지도 미리보기',
                ),
                loading: () =>
                    const OnmuMapView(points: [], fallbackLabel: '동선 계산 중입니다.'),
                error: (error, stackTrace) => const OnmuMapView(
                  points: [],
                  fallbackLabel: '동선 지도를 불러오지 못했습니다.',
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
              child: routeState.maybeWhen(
                data: (route) => _RouteSummaryPill(route: route),
                loading: () => const _RouteStatusPill(label: '동선 계산 중'),
                orElse: () => const _RouteStatusPill(label: '동선 준비 중'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteSummaryPill extends StatelessWidget {
  const _RouteSummaryPill({required this.route});

  final RouteRecommendation route;

  @override
  Widget build(BuildContext context) {
    final stops = _uniqueRouteStops(route.stops);
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
              child: Text(
                '${_durationLabel(route.durationSeconds)} · '
                '${_distanceLabel(route.distanceMeters)} · '
                '${stops.length}곳',
                style: Theme.of(context).textTheme.labelLarge,
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

class RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.lineSoft
      ..strokeWidth = 1;
    for (var x = 24.0; x < size.width; x += 56) {
      canvas.drawLine(Offset(x, 0), Offset(x + 30, size.height), gridPaint);
    }
    for (var y = 30.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 18), gridPaint);
    }

    final path = Path()
      ..moveTo(66, 58)
      ..cubicTo(120, 96, 156, 42, size.width - 108, 96)
      ..quadraticBezierTo(size.width - 58, 128, size.width - 72, 158)
      ..quadraticBezierTo(size.width - 108, 190, size.width - 58, 224);

    final linePaint = Paint()
      ..color = AppColors.primaryPink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RoutePoint extends StatelessWidget {
  const RoutePoint({required this.order, required this.label, super.key});

  final int order;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primaryPink,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.bgDefault, width: 3),
          ),
          child: SizedBox.square(
            dimension: 32,
            child: Center(
              child: Text(
                '$order',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.textInverse),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        OnmuChip(label: label),
      ],
    );
  }
}

class _DateTabs extends StatelessWidget {
  const _DateTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = ['6/7 토', '6/8 일', '6/9 월'];

    return Row(
      children: [
        for (var index = 0; index < tabs.length; index += 1)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: index == selectedIndex
                          ? AppColors.primaryPink
                          : AppColors.lineSoft,
                      width: 2,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: index == selectedIndex
                          ? AppColors.primaryPink
                          : AppColors.textSub,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RouteList extends StatelessWidget {
  const _RouteList({required this.routeState, required this.visitPlan});

  final AsyncValue<RouteRecommendation> routeState;
  final List<VisitPlan> visitPlan;

  @override
  Widget build(BuildContext context) {
    final stops = routeState.maybeWhen(
      data: (route) => _uniqueRouteStops(route.stops),
      orElse: () => const <OnmuMapPoint>[],
    );
    if (stops.isNotEmpty) {
      return OnmuCard(
        backgroundColor: AppColors.bgDefault,
        child: Column(
          children: [
            for (var index = 0; index < stops.length; index += 1)
              _RouteStopListItem(
                point: stops[index],
                isLast: index == stops.length - 1,
              ),
          ],
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
              isLast: index == visitPlan.length - 1,
            ),
        ],
      ),
    );
  }
}

class _RouteStopListItem extends StatelessWidget {
  const _RouteStopListItem({required this.point, required this.isLast});

  final OnmuMapPoint point;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPink,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: SizedBox.square(
              dimension: 28,
              child: Center(
                child: Text(
                  '${point.order}',
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
                  point.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  isLast ? '도착 장소' : '다음 장소로 이동',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteListItem extends StatelessWidget {
  const _RouteListItem({
    required this.order,
    required this.plan,
    required this.isLast,
  });

  final int order;
  final VisitPlan plan;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primaryPink,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: SizedBox.square(
                  dimension: 26,
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
                child: Text(
                  plan.place,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(plan.endTime, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(
              '${plan.kind} · ${plan.duration}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (!isLast) const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
