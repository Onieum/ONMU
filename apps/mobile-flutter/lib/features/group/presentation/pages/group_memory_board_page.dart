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
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../repository/group_repository.dart';
import '../../view_model/group_memory_view_model.dart';
import '../widgets/group_memory_photo.dart';

class GroupMemoryBoardPage extends ConsumerWidget {
  const GroupMemoryBoardPage({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupMemoryBoardViewModelProvider(groupId));

    return state.when(
      data: (state) => _GroupMemoryBoardContent(groupId: groupId, state: state),
      loading: () => const OnmuScaffold(
        title: '기록',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '기록',
        children: [
          Text(
            '모임 기록을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

enum _MemoryFilter {
  all('전체'),
  record('기록'),
  memo('메모');

  const _MemoryFilter(this.label);

  final String label;

  bool accepts(GroupMemoryRecord memory) {
    return switch (this) {
      _MemoryFilter.all => true,
      _MemoryFilter.record => memory.isRecord,
      _MemoryFilter.memo => memory.isMemo,
    };
  }
}

class _GroupMemoryBoardContent extends ConsumerStatefulWidget {
  const _GroupMemoryBoardContent({required this.groupId, required this.state});

  final String groupId;
  final GroupMemoryBoardState state;

  @override
  ConsumerState<_GroupMemoryBoardContent> createState() =>
      _GroupMemoryBoardContentState();
}

class _GroupMemoryBoardContentState
    extends ConsumerState<_GroupMemoryBoardContent> {
  _MemoryFilter _filter = _MemoryFilter.all;
  final Set<String> _likedMemoryIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final group = widget.state.group;
    final memories = widget.state.memories
        .where(_filter.accepts)
        .toList(growable: false);

    return OnmuScaffold(
      title: group.name,
      titleSubtitle: _GroupTitleSubtitle(group: group),
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupDetail(group.id)),
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '채팅',
            onPressed: () => context.push(RoutePaths.groupChat(group.id)),
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primaryPink,
            ),
          ),
          IconButton(
            tooltip: '기록 옵션',
            onPressed: () => context.push(RoutePaths.groupSettings(group.id)),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'group-memory-create-${group.id}',
        onPressed: () => _showCreateMemorySheet(context, group.id),
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        icon: const Icon(Icons.add),
        label: const Text('기록 추가'),
      ),
      useWarmBackground: false,
      children: [
        _GroupTabs(group: group),
        const SizedBox(height: AppSpacing.md),
        _MemoryFilterRow(
          selected: _filter,
          onChanged: (filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: AppSpacing.md),
        if (memories.isEmpty)
          _EmptyMemoryFilterState(filter: _filter)
        else
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.63,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var index = 0; index < memories.length; index += 1)
                _MemoryCard(
                  groupId: group.id,
                  memory: memories[index],
                  photoIndex: index,
                  isLiked: _likedMemoryIds.contains(memories[index].routeId),
                  onToggleLike: () => setState(() {
                    final routeId = memories[index].routeId;
                    if (!_likedMemoryIds.add(routeId)) {
                      _likedMemoryIds.remove(routeId);
                    }
                  }),
                ),
            ],
          ),
        const SizedBox(height: 72),
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
              subtitle: const Text('모임방에 남길 기록을 추가해요.'),
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
    if (kind == null || !mounted) return;

    final input = await _showMemoryInputDialog(kind);
    if (input == null || !mounted) return;

    try {
      await ref
          .read(groupRepositoryProvider)
          .createGroupMemory(
            groupId: groupId,
            type: kind,
            title: input.title,
            memo: input.memo,
          );
      ref.invalidate(groupMemoryBoardViewModelProvider(widget.groupId));
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            kind == GroupMemoryKind.memo ? '메모를 추가했어요.' : '기록을 추가했어요.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('모임방 기록을 저장하지 못했어요.')),
      );
    }
  }

  Future<_MemoryDraftInput?> _showMemoryInputDialog(GroupMemoryKind kind) {
    final titleController = TextEditingController();
    final memoController = TextEditingController();
    return showDialog<_MemoryDraftInput>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(kind == GroupMemoryKind.memo ? '메모 작성' : '기록 작성'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: kind == GroupMemoryKind.memo ? '메모 제목' : '기록 제목',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: memoController,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: kind == GroupMemoryKind.memo ? '메모' : '내용',
              ),
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
              final memo = memoController.text.trim();
              if (memo.isEmpty) return;
              Navigator.of(context).pop(
                _MemoryDraftInput(
                  title: titleController.text.trim(),
                  memo: memo,
                ),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      memoController.dispose();
    });
  }
}

class _MemoryDraftInput {
  const _MemoryDraftInput({required this.title, required this.memo});

  final String title;
  final String memo;
}

class _GroupTitleSubtitle extends StatelessWidget {
  const _GroupTitleSubtitle({required this.group});

  final GroupSummary group;

  @override
  Widget build(BuildContext context) {
    final description = group.description.trim();
    final memberLabel = '멤버 ${group.members.length}명';
    final text = description.isEmpty
        ? memberLabel
        : '$description · $memberLabel';
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
    );
  }
}

class _GroupTabs extends StatelessWidget {
  const _GroupTabs({required this.group});

  final GroupSummary group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GroupTab(
          label: '약속',
          selected: false,
          onTap: () => context.push(RoutePaths.groupDetail(group.id)),
        ),
        _GroupTab(label: '기록', selected: true, onTap: () {}),
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
                width: selected ? 3 : 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? AppColors.textMain : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryFilterRow extends StatelessWidget {
  const _MemoryFilterRow({required this.selected, required this.onChanged});

  final _MemoryFilter selected;
  final ValueChanged<_MemoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (
            var index = 0;
            index < _MemoryFilter.values.length;
            index += 1
          ) ...[
            _MemoryFilterChip(
              label: _MemoryFilter.values[index].label,
              selected: selected == _MemoryFilter.values[index],
              onTap: () => onChanged(_MemoryFilter.values[index]),
            ),
            if (index != _MemoryFilter.values.length - 1)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _MemoryFilterChip extends StatelessWidget {
  const _MemoryFilterChip({
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

class _EmptyMemoryFilterState extends StatelessWidget {
  const _EmptyMemoryFilterState({required this.filter});

  final _MemoryFilter filter;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          '${filter.label} 항목이 아직 없어요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
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
                ? _MemoPreview(memory: memory)
                : _RecordPreview(
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

class _RecordPreview extends StatelessWidget {
  const _RecordPreview({
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
                _MemoryOverlayAction(
                  tooltip: isLiked ? '좋아요 취소' : '좋아요',
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.accentRed : AppColors.textMain,
                  onTap: onToggleLike,
                ),
                const SizedBox(width: AppSpacing.xxs),
                _MemoryOverlayAction(
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

class _MemoryOverlayAction extends StatelessWidget {
  const _MemoryOverlayAction({
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

class _MemoPreview extends StatelessWidget {
  const _MemoPreview({required this.memory});

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
