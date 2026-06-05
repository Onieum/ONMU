import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
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
                  _RouteMap(onEditPressed: () {}),
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

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.onEditPressed});

  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.bgGrid,
      borderColor: AppColors.lineSoft,
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _RouteMapPainter())),
            const Positioned(
              left: 42,
              top: 28,
              child: _RoutePoint(order: 1, label: 'YYY 카페'),
            ),
            const Positioned(
              right: 86,
              top: 72,
              child: _RoutePoint(order: 2, label: '무드카페'),
            ),
            const Positioned(
              right: 56,
              top: 136,
              child: _RoutePoint(order: 3, label: '하루정원'),
            ),
            const Positioned(
              right: 42,
              bottom: 24,
              child: _RoutePoint(order: 4, label: '엔트릴 아이스크림'),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: OnmuSecondaryButton(
                label: '날짜별 일정 동선보기',
                icon: Icons.alt_route,
                onPressed: onEditPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
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

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({required this.order, required this.label});

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
  const _RouteList({required this.visitPlan});

  final List<VisitPlan> visitPlan;

  @override
  Widget build(BuildContext context) {
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
