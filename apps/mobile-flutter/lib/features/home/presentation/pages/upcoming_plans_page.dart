import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../view_model/home_view_model.dart';

class UpcomingPlansPage extends ConsumerWidget {
  const UpcomingPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);

    return state.when(
      data: (state) => _UpcomingPlansContent(
        groupId: state.groupId,
        plans: state.upcomingPlans,
      ),
      loading: () => const OnmuScaffold(
        title: '다가오는 약속',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '다가오는 약속',
        children: [
          Text(
            '다가오는 약속을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _UpcomingPlansContent extends StatelessWidget {
  const _UpcomingPlansContent({required this.groupId, required this.plans});

  final int? groupId;
  final List<GroupPlanSummary> plans;

  @override
  Widget build(BuildContext context) {
    final weekPlans = plans.take(2).toList();
    final nextPlans = plans.skip(2).toList();

    return OnmuScaffold(
      title: '다가오는 약속',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.home),
      action: Row(
        children: [
          IconButton(
            tooltip: '캘린더 보기',
            onPressed: () => _showSnack(context, '캘린더 보기는 다음 단계에서 연결할게요.'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: '약속 필터',
            onPressed: () => _showSnack(context, '필터는 예정/진행중 기준으로 준비 중이에요.'),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '약속 만들기',
        onPressed: () {
          if (groupId == null) {
            context.go(RoutePaths.groups);
            return;
          }
          context.push(RoutePaths.planNew(groupId!));
        },
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.textInverse,
        child: const Icon(Icons.add),
      ),
      children: [
        const _MonthHeader(),
        const SizedBox(height: AppSpacing.xxl),
        _PlanSection(title: '이번 주', groupId: groupId, plans: weekPlans),
        const SizedBox(height: AppSpacing.xxl),
        _PlanSection(title: '다음 주', groupId: groupId, plans: nextPlans),
        const SizedBox(height: 72),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader();

  List<DateTime> _createDays(DateTime today) {
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(
      DateTime.daysPerWeek,
      (index) => startOfWeek.add(Duration(days: index)),
    );
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = _createDays(today);

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${today.year}년 ${today.month}월',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: _DayPill(
                    day: day.day.toString(),
                    weekday: _weekdayLabel(day),
                    selected:
                        day.year == today.year &&
                        day.month == today.month &&
                        day.day == today.day,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.weekday,
    required this.selected,
  });

  final String day;
  final String weekday;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPinkSoft : AppColors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: selected ? Border.all(color: AppColors.linePink) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            Text(
              day,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.primaryPurple : AppColors.textMain,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              weekday,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? AppColors.primaryPurple : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection({
    required this.title,
    required this.groupId,
    required this.plans,
  });

  final String title;
  final int? groupId;
  final List<GroupPlanSummary> plans;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        if (plans.isEmpty)
          const _EmptyPlanSectionCard()
        else
          for (final plan in plans) ...[
            _UpcomingPlanCard(groupId: groupId!, plan: plan),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _EmptyPlanSectionCard extends StatelessWidget {
  const _EmptyPlanSectionCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        '표시할 약속이 없어요.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
      ),
    );
  }
}

class _UpcomingPlanCard extends StatelessWidget {
  const _UpcomingPlanCard({required this.groupId, required this.plan});

  final int groupId;
  final GroupPlanSummary plan;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: () => context.push(RoutePaths.planDetail(groupId, plan.id)),
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgPaper,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.lineBrown),
            ),
            child: SizedBox(
              width: 64,
              height: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    plan.dateLabel.split(' ').first,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    plan.displayStatusLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OnmuChip(label: plan.displayStatusLabel, selected: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  plan.placeName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    for (
                      var index = 0;
                      index < plan.memberCount && index < 4;
                      index += 1
                    ) ...[
                      PixelAvatar(label: '${index + 1}', size: 22),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    if (plan.extraMemberCount > 0)
                      OnmuChip(label: '+${plan.extraMemberCount}'),
                    const Spacer(),
                    OnmuChip(label: plan.displayStatusLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
