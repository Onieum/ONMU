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
import '../../../../shared/widgets/onmu_empty_state_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../repository/group_repository.dart';
import '../../view_model/group_home_view_model.dart';
import '../widgets/group_memory_photo.dart';

class GroupHomePage extends ConsumerWidget {
  const GroupHomePage({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupHomeViewModelProvider(groupId));

    return state.when(
      data: (state) => _GroupHomeContent(state: state),
      loading: () => const OnmuScaffold(
        useWarmBackground: false,
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        useWarmBackground: false,
        children: [
          Text(
            '온모임 홈을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

enum _GroupHomeTab {
  plans('약속'),
  memories('기록');

  const _GroupHomeTab(this.label);

  final String label;
}

enum _GroupHomeMemoryFilter {
  all('전체'),
  record('기록'),
  memo('메모');

  const _GroupHomeMemoryFilter(this.label);

  final String label;

  bool accepts(GroupMemoryRecord memory) {
    return switch (this) {
      _GroupHomeMemoryFilter.all => true,
      _GroupHomeMemoryFilter.record => memory.isRecord,
      _GroupHomeMemoryFilter.memo => memory.isMemo,
    };
  }
}

class _GroupHomeContent extends ConsumerStatefulWidget {
  const _GroupHomeContent({required this.state});

  final GroupHomeState state;

  @override
  ConsumerState<_GroupHomeContent> createState() => _GroupHomeContentState();
}

class _GroupHomeContentState extends ConsumerState<_GroupHomeContent> {
  var _selectedTab = _GroupHomeTab.plans;
  var _memoryFilter = _GroupHomeMemoryFilter.all;
  final Set<String> _likedMemoryIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final group = state.group;

    return OnmuScaffold(
      useWarmBackground: false,
      floatingActionButton: _selectedTab == _GroupHomeTab.plans
          ? FloatingActionButton(
              key: const ValueKey('group-home-create-plan-fab'),
              tooltip: '약속 만들기',
              onPressed: () => context.push(RoutePaths.planNew(group.id)),
              backgroundColor: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              key: const ValueKey('group-home-create-memory-fab'),
              tooltip: '기록 추가',
              onPressed: () => _showCreateMemorySheet(context, group.id),
              backgroundColor: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              child: const Icon(Icons.add),
            ),
      children: [
        _GroupHomeHeader(group: group),
        const SizedBox(height: AppSpacing.md),
        _GroupTabs(
          selected: _selectedTab,
          onChanged: (tab) => setState(() => _selectedTab = tab),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _selectedTab == _GroupHomeTab.plans
              ? _GroupPlansTab(
                  key: const ValueKey('group-plans-tab'),
                  state: state,
                )
              : _GroupMemoriesTab(
                  key: const ValueKey('group-memories-tab'),
                  group: group,
                  memories: state.memories,
                  selectedFilter: _memoryFilter,
                  likedMemoryIds: _likedMemoryIds,
                  onFilterChanged: (filter) =>
                      setState(() => _memoryFilter = filter),
                  onToggleLike: (memory) => setState(() {
                    if (!_likedMemoryIds.add(memory.routeId)) {
                      _likedMemoryIds.remove(memory.routeId);
                    }
                  }),
                ),
        ),
      ],
    );
  }

  Future<void> _showCreateMemorySheet(
    BuildContext context,
    Object groupId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final kind = await showModalBottomSheet<GroupMemoryKind>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_stories_outlined),
              title: const Text('기록 작성'),
              subtitle: const Text('사진이 있는 모임 기록을 추가해요.'),
              onTap: () => Navigator.of(context).pop(GroupMemoryKind.record),
            ),
            ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: const Text('메모 작성'),
              subtitle: const Text('메모장처럼 짧은 내용을 남겨요.'),
              onTap: () => Navigator.of(context).pop(GroupMemoryKind.memo),
            ),
          ],
        ),
      ),
    );
    if (kind == null || !context.mounted) return;

    final input = await _showMemoryInputDialog(context, kind);
    if (input == null || !context.mounted) return;

    try {
      await ref
          .read(groupRepositoryProvider)
          .createGroupMemory(
            groupId: groupId,
            type: kind,
            title: input.title,
            memo: input.description,
            date: DateTime.now(),
          );
      ref.invalidate(groupHomeViewModelProvider(groupId.toString()));
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              kind == GroupMemoryKind.memo ? '메모를 추가했어요.' : '기록을 추가했어요.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('모임방 기록을 저장하지 못했어요.')),
      );
    }
  }

  Future<_GroupHomeMemoryDraft?> _showMemoryInputDialog(
    BuildContext context,
    GroupMemoryKind kind,
  ) {
    final titleController = TextEditingController();
    final memoController = TextEditingController();
    return showDialog<_GroupHomeMemoryDraft>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(kind == GroupMemoryKind.memo ? '메모 작성' : '기록 작성'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: kind == GroupMemoryKind.memo ? '메모 제목' : '기록 제목',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: memoController,
              decoration: InputDecoration(
                labelText: kind == GroupMemoryKind.memo ? '메모' : '내용',
              ),
              minLines: 3,
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(
                _GroupHomeMemoryDraft(
                  title: titleController.text,
                  description: memoController.text,
                ),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

class _GroupHomeMemoryDraft {
  const _GroupHomeMemoryDraft({required this.title, required this.description});

  final String title;
  final String description;
}

class _GroupPlansTab extends StatelessWidget {
  const _GroupPlansTab({required this.state, super.key});

  final GroupHomeState state;

  @override
  Widget build(BuildContext context) {
    final group = state.group;
    final ongoingPlan = state.ongoingPlan;
    final upcomingPlan = state.upcomingPlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ongoingPlan != null) ...[
          _UpcomingPlanCard(
            plan: ongoingPlan,
            statusLabel: '약속 진행 중',
            onTap: () =>
                context.push(RoutePaths.planDetail(group.id, ongoingPlan.id)),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _SectionHeader(
          title: '다가오는 약속',
          actionLabel: '전체 보기',
          onTap: () => context.push(RoutePaths.groupPlans(group.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.plansLoadFailed)
          const OnmuEmptyStateCard(title: '약속 정보를 불러오지 못했어요.')
        else if (upcomingPlan != null)
          _UpcomingPlanCard(
            plan: upcomingPlan,
            onTap: () =>
                context.push(RoutePaths.planDetail(group.id, upcomingPlan.id)),
          )
        else
          const OnmuEmptyStateCard(title: '다가오는 약속이 없어요.'),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(
          title: '최근 기록',
          actionLabel: '전체 보기',
          onTap: () => context.push(RoutePaths.groupMemories(group.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _RecentMemoryStrip(group: group, memories: state.recentMemories),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(
          title: '최근 대화',
          actionLabel: '전체 보기',
          onTap: () => context.push(RoutePaths.groupChat(group.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _RecentChatPreview(
          message: state.recentMessage,
          onTap: () => context.push(RoutePaths.groupChat(group.id)),
        ),
      ],
    );
  }
}

class _GroupMemoriesTab extends StatelessWidget {
  const _GroupMemoriesTab({
    required this.group,
    required this.memories,
    required this.selectedFilter,
    required this.likedMemoryIds,
    required this.onFilterChanged,
    required this.onToggleLike,
    super.key,
  });

  final GroupSummary group;
  final List<GroupMemoryRecord> memories;
  final _GroupHomeMemoryFilter selectedFilter;
  final Set<String> likedMemoryIds;
  final ValueChanged<_GroupHomeMemoryFilter> onFilterChanged;
  final ValueChanged<GroupMemoryRecord> onToggleLike;

  @override
  Widget build(BuildContext context) {
    final filtered = memories.where(selectedFilter.accepts).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupMemoryFilterRow(
          selected: selectedFilter,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        if (filtered.isEmpty)
          OnmuEmptyStateCard(title: '${selectedFilter.label} 기록이 아직 없어요.')
        else
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.63,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var index = 0; index < filtered.length; index += 1)
                _GroupHomeMemoryCard(
                  groupId: group.id,
                  memory: filtered[index],
                  photoIndex: index,
                  isLiked: likedMemoryIds.contains(filtered[index].routeId),
                  onToggleLike: () => onToggleLike(filtered[index]),
                ),
            ],
          ),
        const SizedBox(height: 88),
      ],
    );
  }
}

class _GroupMemoryFilterRow extends StatelessWidget {
  const _GroupMemoryFilterRow({
    required this.selected,
    required this.onChanged,
  });

  final _GroupHomeMemoryFilter selected;
  final ValueChanged<_GroupHomeMemoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (
            var index = 0;
            index < _GroupHomeMemoryFilter.values.length;
            index += 1
          ) ...[
            _GroupMemoryFilterChip(
              label: _GroupHomeMemoryFilter.values[index].label,
              selected: selected == _GroupHomeMemoryFilter.values[index],
              onTap: () => onChanged(_GroupHomeMemoryFilter.values[index]),
            ),
            if (index != _GroupHomeMemoryFilter.values.length - 1)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _GroupMemoryFilterChip extends StatelessWidget {
  const _GroupMemoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppColors.bgDefault : AppColors.bgWarm,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.lineBrown : AppColors.lineSoft,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? AppColors.textMain : AppColors.textSub,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupHomeMemoryCard extends StatelessWidget {
  const _GroupHomeMemoryCard({
    required this.groupId,
    required this.memory,
    required this.photoIndex,
    required this.isLiked,
    required this.onToggleLike,
  });

  final int groupId;
  final GroupMemoryRecord memory;
  final int photoIndex;
  final bool isLiked;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: () =>
          context.push(RoutePaths.groupMemoryDetail(groupId, memory.routeId)),
      backgroundColor: AppColors.bgDefault,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxs,
              AppSpacing.xxs,
              AppSpacing.xxs,
              0,
            ),
            child: Row(
              children: [
                PixelAvatar(
                  label: memory.author,
                  size: 24,
                  profileImageUrl: memory.authorProfileImageUrl,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    memory.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              memory.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              memory.dateLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: memory.isMemo
                ? _GroupHomeMemoPreview(memory: memory)
                : _GroupHomeRecordPreview(
                    memory: memory,
                    photoIndex: photoIndex,
                    isLiked: isLiked,
                    onToggleLike: onToggleLike,
                    onComment: () => context.push(
                      RoutePaths.groupMemoryDetail(groupId, memory.routeId),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupHomeRecordPreview extends StatelessWidget {
  const _GroupHomeRecordPreview({
    required this.memory,
    required this.photoIndex,
    required this.isLiked,
    required this.onToggleLike,
    required this.onComment,
  });

  final GroupMemoryRecord memory;
  final int photoIndex;
  final bool isLiked;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GroupMemoryPhoto(index: photoIndex, imageUrl: memory.primaryImageUrl),
          Positioned(
            right: AppSpacing.xs,
            bottom: AppSpacing.xs,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GroupMemoryOverlayAction(
                  tooltip: isLiked ? '좋아요 취소' : '좋아요',
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.accentRed : AppColors.textMain,
                  onTap: onToggleLike,
                ),
                const SizedBox(width: AppSpacing.xxs),
                _GroupMemoryOverlayAction(
                  tooltip: '댓글',
                  icon: Icons.chat_bubble_outline,
                  color: AppColors.primaryPink,
                  onTap: onComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupMemoryOverlayAction extends StatelessWidget {
  const _GroupMemoryOverlayAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.bgDefault.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 34,
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class _GroupHomeMemoPreview extends StatelessWidget {
  const _GroupHomeMemoPreview({required this.memory});

  final GroupMemoryRecord memory;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.sticky_note_2_outlined,
                color: AppColors.textSub,
                size: 22,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: Text(
                memory.description,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMain,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHomeHeader extends StatelessWidget {
  const _GroupHomeHeader({required this.group});

  final GroupSummary group;

  @override
  Widget build(BuildContext context) {
    final description = group.description.trim();

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              IconButton(
                tooltip: '온모임 목록으로 이동',
                onPressed: () => context.popOrGo(RoutePaths.groups),
                icon: const Icon(Icons.arrow_back),
              ),
              const Spacer(),
              IconButton(
                tooltip: '채팅',
                onPressed: () => context.push(RoutePaths.groupChat(group.id)),
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primaryPink,
                ),
              ),
              IconButton(
                tooltip: '모임 옵션',
                onPressed: () =>
                    context.push(RoutePaths.groupSettings(group.id)),
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            group.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () => context.push(RoutePaths.groupMembers(group.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '멤버 ${group.members.length}명',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
                const SizedBox(width: AppSpacing.xxs),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupTabs extends StatelessWidget {
  const _GroupTabs({required this.selected, required this.onChanged});

  final _GroupHomeTab selected;
  final ValueChanged<_GroupHomeTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GroupTab(
          label: _GroupHomeTab.plans.label,
          selected: selected == _GroupHomeTab.plans,
          onTap: () => onChanged(_GroupHomeTab.plans),
        ),
        _GroupTab(
          label: _GroupHomeTab.memories.label,
          selected: selected == _GroupHomeTab.memories,
          onTap: () => onChanged(_GroupHomeTab.memories),
        ),
      ],
    );
  }
}

class _GroupTab extends StatelessWidget {
  const _GroupTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primaryPink : AppColors.lineSoft,
                width: selected ? 2 : 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? AppColors.primaryPink : AppColors.textSub,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        TextButton.icon(
          onPressed: onTap,
          icon: Text(actionLabel),
          label: const Icon(Icons.chevron_right, size: 16),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSub,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
          ),
        ),
      ],
    );
  }
}

class _UpcomingPlanCard extends StatelessWidget {
  const _UpcomingPlanCard({
    required this.plan,
    required this.onTap,
    this.statusLabel,
  });

  final GroupPlanSummary plan;
  final VoidCallback onTap;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          const _PhotoThumb(
            icon: Icons.water,
            width: 74,
            height: 74,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if ((statusLabel ?? plan.displayStatusLabel)
                        .trim()
                        .isNotEmpty) ...[
                      OnmuChip(
                        label: statusLabel ?? plan.displayStatusLabel,
                        selected: true,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Expanded(
                      child: Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Flexible(
                      flex: 0,
                      child: Text(
                        plan.displayDateTimeLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.textSub,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        plan.placeName.trim().isEmpty
                            ? '장소 미정'
                            : plan.placeName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSub,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    for (final member in plan.memberAvatars.take(4)) ...[
                      PixelAvatar(
                        label: member.name,
                        profileImageUrl: member.profileImageUrl,
                        character: member.character,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${plan.memberCount}명 참여 예정',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
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

class _RecentMemoryStrip extends StatelessWidget {
  const _RecentMemoryStrip({required this.group, required this.memories});

  final GroupSummary group;
  final List<GroupMemoryRecord> memories;

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return const OnmuEmptyStateCard(
        title: '최근 기록이 없어요.',
        description: '기록을 만들면 이곳에 표시돼요.',
        icon: Icons.photo_library_outlined,
      );
    }

    final iconStyles = [
      (Icons.park_outlined, AppColors.accentGreen),
      (Icons.water, AppColors.accentBlue),
      (Icons.nightlight_round, AppColors.accentBrown),
      (Icons.local_cafe_outlined, AppColors.accentOrange),
    ];

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: memories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final memory = iconStyles[index % iconStyles.length];
          final record = memories[index];

          return _MemoryThumb(
            icon: memory.$1,
            color: memory.$2,
            imageUrl: record.primaryImageUrl,
            onTap: () => context.push(
              RoutePaths.groupMemoryDetail(group.id, record.routeId),
            ),
          );
        },
      ),
    );
  }
}

class _MemoryThumb extends StatelessWidget {
  const _MemoryThumb({
    required this.icon,
    required this.color,
    this.imageUrl,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _MemoryThumbImage(icon: icon, color: color, imageUrl: imageUrl),
          Positioned(
            right: -4,
            bottom: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bgDefault,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.linePink),
              ),
              child: const SizedBox.square(
                dimension: 22,
                child: Icon(
                  Icons.favorite,
                  size: 14,
                  color: AppColors.accentRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryThumbImage extends StatelessWidget {
  const _MemoryThumbImage({
    required this.icon,
    required this.color,
    this.imageUrl,
  });

  final IconData icon;
  final Color color;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _PhotoThumb(icon: icon, width: 76, height: 76, color: color);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.network(
        url,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _PhotoThumb(icon: icon, width: 76, height: 76, color: color);
        },
      ),
    );
  }
}

class _RecentChatPreview extends StatelessWidget {
  const _RecentChatPreview({required this.message, required this.onTap});

  final GroupMessage? message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = message;
    if (preview == null) {
      return Text('아직 대화가 없어요.', style: Theme.of(context).textTheme.bodyMedium);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            PixelAvatar(
              label: preview.sender,
              profileImageUrl: preview.senderProfileImageUrl,
              character: preview.senderCharacter,
              size: 42,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        preview.sender,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      Text(
                        preview.timeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    preview.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.icon,
    required this.width,
    required this.height,
    required this.color,
  });

  final IconData icon;
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
