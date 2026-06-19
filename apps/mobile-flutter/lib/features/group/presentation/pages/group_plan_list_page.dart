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
import '../../../../shared/widgets/onmu_plan_thumbnail.dart';
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

class _GroupPlanListContent extends StatefulWidget {
  const _GroupPlanListContent({required this.groupId, required this.state});

  final String groupId;
  final GroupPlanListState state;

  @override
  State<_GroupPlanListContent> createState() => _GroupPlanListContentState();
}

class _GroupPlanListContentState extends State<_GroupPlanListContent> {
  final _searchController = TextEditingController();
  var _filter = _PlanListFilter.all;
  var _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_syncSearch);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_syncSearch)
      ..dispose();
    super.dispose();
  }

  void _syncSearch() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final ongoing = _visiblePlans(widget.state.ongoingPlans);
    final upcoming = _visiblePlans(widget.state.upcomingPlans);
    final past = _visiblePlans(widget.state.pastPlans);
    final showOngoing =
        _filter == _PlanListFilter.all || _filter == _PlanListFilter.ongoing;
    final showUpcoming =
        _filter == _PlanListFilter.all || _filter == _PlanListFilter.upcoming;
    final showPast =
        _filter == _PlanListFilter.all || _filter == _PlanListFilter.past;

    return OnmuScaffold(
      title: '약속',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupDetail(widget.groupId)),
      action: IconButton(
        tooltip: '약속 만들기',
        onPressed: () => context.push(RoutePaths.planNew(widget.groupId)),
        icon: const Icon(Icons.add, color: AppColors.primaryPink),
      ),
      pinnedHeader: _PlanListPinnedTools(
        controller: _searchController,
        filter: _filter,
        sortAscending: _sortAscending,
        onFilterChanged: (filter) => setState(() => _filter = filter),
        onSortToggle: () => setState(() => _sortAscending = !_sortAscending),
      ),
      useWarmBackground: false,
      children: [
        if (showOngoing && ongoing.isNotEmpty) ...[
          _PlanSectionTitle(title: '진행 중인 약속', count: ongoing.length),
          const SizedBox(height: AppSpacing.sm),
          for (final plan in ongoing) ...[
            _PlanSummaryCard(
              plan: plan,
              members: widget.state.members,
              statusLabel: '약속 진행 중',
              onTap: () =>
                  context.push(RoutePaths.planDetail(widget.groupId, plan.id)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        if (showUpcoming) ...[
          if (showOngoing && ongoing.isNotEmpty)
            const SizedBox(height: AppSpacing.md),
          _PlanSectionTitle(
            title: '다가오는 약속',
            count: upcoming.length,
            onCreateTap: () => context.push(RoutePaths.planNew(widget.groupId)),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final plan in upcoming) ...[
            _PlanSummaryCard(
              plan: plan,
              members: widget.state.members,
              onTap: () =>
                  context.push(RoutePaths.planDetail(widget.groupId, plan.id)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        if (showPast && past.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _PlanSectionTitle(title: '지난 약속', count: past.length),
          const SizedBox(height: AppSpacing.sm),
          for (final plan in past) ...[
            _PlanSummaryCard(
              plan: plan,
              members: widget.state.members,
              onTap: () =>
                  context.push(RoutePaths.planDetail(widget.groupId, plan.id)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        const SizedBox(height: 72),
      ],
    );
  }

  List<GroupPlanSummary> _visiblePlans(List<GroupPlanSummary> source) {
    final query = _searchController.text.trim().toLowerCase();
    final plans = source.where((plan) {
      if (query.isEmpty) {
        return true;
      }
      return plan.title.toLowerCase().contains(query) ||
          plan.placeName.toLowerCase().contains(query) ||
          plan.dateLabel.toLowerCase().contains(query) ||
          plan.displayDateTimeLabel.toLowerCase().contains(query) ||
          plan.displayStatusLabel.toLowerCase().contains(query);
    }).toList();

    plans.sort(GroupPlanSummary.compareUpcoming);
    if (!_sortAscending) {
      return plans.reversed.toList(growable: false);
    }
    return plans;
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

enum _PlanListFilter {
  all('전체'),
  ongoing('진행중'),
  upcoming('다가오는 약속'),
  past('지난 약속');

  const _PlanListFilter(this.label);

  final String label;
}

class _PlanListPinnedTools extends StatelessWidget {
  const _PlanListPinnedTools({
    required this.controller,
    required this.filter,
    required this.sortAscending,
    required this.onFilterChanged,
    required this.onSortToggle,
  });

  final TextEditingController controller;
  final _PlanListFilter filter;
  final bool sortAscending;
  final ValueChanged<_PlanListFilter> onFilterChanged;
  final VoidCallback onSortToggle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withValues(alpha: 0.94),
        border: const Border(bottom: BorderSide(color: AppColors.lineSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '모임 약속 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: '검색어 지우기',
                        onPressed: controller.clear,
                        icon: const Icon(Icons.cancel),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in _PlanListFilter.values) ...[
                    _PlanToolCapsule(
                      label: option.label,
                      selected: filter == option,
                      onTap: () => onFilterChanged(option),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  _PlanToolCapsule(
                    label: sortAscending ? '날짜 오름차순' : '날짜 내림차순',
                    icon: sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    selected: true,
                    onTap: onSortToggle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanToolCapsule extends StatelessWidget {
  const _PlanToolCapsule({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? AppColors.primaryPink
        : AppColors.textSub;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.linePink : AppColors.lineSoft,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: foregroundColor),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: foregroundColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({
    required this.plan,
    required this.members,
    required this.onTap,
    this.statusLabel,
  });

  final GroupPlanSummary plan;
  final List<GroupMemberProfile> members;
  final VoidCallback onTap;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnmuPlanThumbnail(
            iconKind: plan.iconKind,
            imageUrl: plan.thumbnailImageUrl,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                  plan.displayDateTimeLabel,
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
                      PixelAvatar(
                        label: member.name,
                        size: 22,
                        profileImageUrl: member.profileImageUrl,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    if (plan.extraMemberCount > 0)
                      OnmuChip(label: '+${plan.extraMemberCount}'),
                    const Spacer(),
                    if ((statusLabel ?? plan.displayStatusLabel)
                        .trim()
                        .isNotEmpty)
                      OnmuChip(
                        label: statusLabel ?? plan.displayStatusLabel,
                        selected: !plan.isPast,
                      ),
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
