import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/map/view_model/route_recommendation_view_model.dart';
import '../../../../shared/models/plan_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_top_bar.dart';
import '../../../place/presentation/widgets/plan_visit_time_picker.dart';
import '../../../place/view_model/place_candidates_view_model.dart';
import '../../view_model/plan_detail_view_model.dart';
import '../../widgets/plan_date_tabs.dart';
import '../../widgets/plan_route_map_card.dart';

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
                  PlanRouteMapCard(
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
                    onEditTime: (plan) => _editSchedulePlaceTime(state, plan),
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

  Future<bool> _editSchedulePlaceTime(
    PlanDetailState state,
    VisitPlan plan,
  ) async {
    final initialStart = _initialVisitStart(plan);
    final picked = await PlanVisitTimePicker.show(
      context: context,
      title: '방문 시간 수정',
      planStartsAt: state.plan.startsAt,
      planEndsAt: state.plan.endsAt,
      initialStart: initialStart,
      initialEnd: _initialVisitEnd(plan, initialStart),
    );
    if (picked == null) {
      return false;
    }

    await ref
        .read(
          placeCandidatesViewModelProvider((
            groupId: widget.groupId,
            planId: widget.planId,
          )).notifier,
        )
        .updateSchedulePlaceTime(
          schedulePlaceId: plan.id,
          startsAt: picked.start,
          endsAt: picked.end,
          note: plan.duration,
        );
    return true;
  }

  DateTime _initialVisitStart(VisitPlan plan) {
    final existing = plan.startsAt?.toLocal();
    if (existing != null) {
      return existing;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  DateTime _initialVisitEnd(VisitPlan plan, DateTime start) {
    final existing = plan.endsAt?.toLocal();
    if (existing != null && existing.isAfter(start)) {
      return existing;
    }
    return start.add(const Duration(hours: 1));
  }
}

class _RouteList extends StatelessWidget {
  const _RouteList({
    required this.groupId,
    required this.planId,
    required this.visitPlan,
    required this.onEditTime,
    required this.onDelete,
  });

  final String groupId;
  final String planId;
  final List<VisitPlan> visitPlan;
  final Future<bool> Function(VisitPlan plan) onEditTime;
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
              onEditTime: visitPlan[index].id.trim().isEmpty
                  ? null
                  : () => _editVisitTime(context, visitPlan[index]),
              onDelete: visitPlan[index].id.trim().isEmpty
                  ? null
                  : () => _deleteVisitPlan(context, visitPlan[index]),
            ),
        ],
      ),
    );
  }

  Future<void> _editVisitTime(BuildContext context, VisitPlan plan) async {
    late final bool updated;
    try {
      updated = await onEditTime(plan);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('방문 시간을 수정하지 못했어요.')));
      return;
    }
    if (!updated) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('방문 시간을 수정했어요.')));
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

enum _RoutePlaceAction { editTime, delete }

class _RouteListItem extends StatelessWidget {
  const _RouteListItem({
    required this.order,
    required this.plan,
    required this.onTap,
    required this.onEditTime,
    required this.onDelete,
  });

  final int order;
  final VisitPlan plan;
  final VoidCallback onTap;
  final VoidCallback? onEditTime;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final timeRangeLabel = _visitTimeRangeLabel(plan);
    final noteLabel = plan.duration.trim();
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
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    timeRangeLabel.isEmpty ? '방문 시간 미정' : timeRangeLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  ),
                  if (noteLabel.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      noteLabel,
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
                  case _RoutePlaceAction.editTime:
                    onEditTime?.call();
                    break;
                  case _RoutePlaceAction.delete:
                    onDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _RoutePlaceAction.editTime,
                  enabled: onEditTime != null,
                  child: const Text('시간 수정'),
                ),
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
