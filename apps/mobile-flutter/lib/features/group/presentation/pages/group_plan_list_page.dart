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
import '../../view_model/group_plan_list_view_model.dart';

class GroupPlanListPage extends ConsumerWidget {
  const GroupPlanListPage({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupPlanListViewModelProvider(groupId));

    return state.when(
      data: (state) => _GroupPlanListContent(groupId: groupId, state: state),
      loading: () => const OnmuScaffold(
        title: '약속',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '약속',
        children: [
          Text(
            '약속 목록을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GroupPlanListContent extends StatelessWidget {
  const _GroupPlanListContent({required this.groupId, required this.state});

  final String groupId;
  final GroupPlanListState state;

  @override
  Widget build(BuildContext context) {
    final upcoming = state.upcomingPlans;
    final past = state.pastPlans;

    return OnmuScaffold(
      title: '약속',
      showBackButton: true,
      onBack: () => context.go(RoutePaths.groupDetail(groupId)),
      action: IconButton(
        tooltip: '약속 만들기',
        onPressed: () => context.go(RoutePaths.planNew(groupId)),
        icon: const Icon(Icons.add, color: AppColors.primaryPink),
      ),
      useWarmBackground: false,
      children: [
        const _PlanSearchSortRow(),
        const SizedBox(height: AppSpacing.lg),
        _PlanSectionTitle(
          title: '다가오는 약속',
          count: upcoming.length,
          onCreateTap: () => context.go(RoutePaths.planNew(groupId)),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final plan in upcoming) ...[
          _PlanSummaryCard(
            plan: plan,
            members: state.members,
            onTap: () => context.go(RoutePaths.planDetail(groupId, plan.id)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _PlanSectionTitle(title: '지난 약속', count: past.length),
          const SizedBox(height: AppSpacing.sm),
          for (final plan in past) ...[
            _PlanSummaryCard(
              plan: plan,
              members: state.members,
              onTap: () => context.go(RoutePaths.planDetail(groupId, plan.id)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        const SizedBox(height: 72),
      ],
    );
  }
}

class _PlanSectionTitle extends StatelessWidget {
  const _PlanSectionTitle({
    required this.title,
    required this.count,
    this.onCreateTap,
  });

  final String title;
  final int count;
  final VoidCallback? onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: AppSpacing.xs),
        OnmuChip(label: '$count개'),
        const Spacer(),
        if (onCreateTap != null)
          TextButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('약속 만들기'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryPink,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}

class _PlanSearchSortRow extends StatelessWidget {
  const _PlanSearchSortRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OnmuCard(
            onTap: () =>
                _showPlanListSnack(context, '약속 검색 입력은 다음 단계에서 연결할게요.'),
            backgroundColor: AppColors.bgDefault,
            borderColor: AppColors.lineSoft,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '모임 약속 검색',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _showPlanListSnack(context, '현재는 날짜 순으로 정렬되어 있어요.'),
          icon: const Icon(Icons.keyboard_arrow_down),
          label: const Text('날짜 순'),
        ),
        IconButton.outlined(
          tooltip: '약속 필터',
          onPressed: () =>
              _showPlanListSnack(context, '진행 중, 예정, 완료 필터는 다음 단계에서 연결할게요.'),
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({
    required this.plan,
    required this.members,
    required this.onTap,
  });

  final GroupPlanSummary plan;
  final List<GroupMemberProfile> members;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanThumb(kind: plan.iconKind),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OnmuChip(label: plan.statusLabel, selected: !plan.isPast),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: '약속 더보기',
                      onPressed: () => _showPlanListSnack(
                        context,
                        '${plan.title} 더보기 메뉴는 다음 단계에서 연결할게요.',
                      ),
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
                Text(
                  plan.dateLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  plan.placeName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (final member in members.take(
                      plan.memberCount > 4 ? 4 : plan.memberCount,
                    )) ...[
                      PixelAvatar(label: member.name, size: 22),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    if (plan.extraMemberCount > 0)
                      OnmuChip(label: '+${plan.extraMemberCount}'),
                    const Spacer(),
                    OnmuChip(label: plan.statusType, selected: !plan.isPast),
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

void _showPlanListSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _PlanThumb extends StatelessWidget {
  const _PlanThumb({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      'coffee' => Icons.local_cafe_outlined,
      'park' => Icons.park_outlined,
      _ => Icons.water,
    };
    final color = switch (kind) {
      'coffee' => AppColors.accentBrown,
      'park' => AppColors.accentGreen,
      _ => AppColors.accentBlue,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: SizedBox.square(
        dimension: 82,
        child: Icon(icon, color: color, size: 34),
      ),
    );
  }
}
