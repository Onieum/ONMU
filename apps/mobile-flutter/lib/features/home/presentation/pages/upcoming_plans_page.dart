import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  final int groupId;
  final List<GroupPlanSummary> plans;

  @override
  Widget build(BuildContext context) {
    final weekPlans = plans.take(2).toList();
    final nextPlans = plans.skip(2).toList();

    return OnmuScaffold(
      title: '다가오는 약속',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(RoutePaths.home);
      },
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
        onPressed: () => context.push(RoutePaths.planNew(groupId)),
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

  static const _days = [
    ('24', '월', false),
    ('25', '화', false),
    ('26', '수', false),
    ('27', '목', false),
    ('28', '금', true),
    ('29', '토', false),
    ('30', '일', false),
  ];

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('2026년 6월', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final day in _days)
                Expanded(
                  child: _DayPill(
                    day: day.$1,
                    weekday: day.$2,
                    selected: day.$3,
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
  final int groupId;
  final List<GroupPlanSummary> plans;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        for (final plan in plans) ...[
          _UpcomingPlanCard(groupId: groupId, plan: plan),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
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
                    plan.statusType,
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
                    OnmuChip(label: plan.statusLabel, selected: true),
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
                    OnmuChip(label: plan.statusLabel),
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
