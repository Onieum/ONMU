import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../view_model/group_home_view_model.dart';
import '../../view_model/group_list_view_model.dart';
import '../../view_model/group_memory_view_model.dart';
import '../widgets/group_memory_photo.dart';

class GroupMemoryDetailPage extends ConsumerWidget {
  const GroupMemoryDetailPage({
    required this.groupId,
    required this.memoryId,
    super.key,
  });

  final String groupId;
  final String memoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      groupMemoryDetailViewModelProvider((
        groupId: groupId,
        memoryId: memoryId,
      )),
    );

    return state.when(
      data: (state) =>
          _GroupMemoryDetailContent(groupId: groupId, state: state),
      loading: () => const OnmuScaffold(
        title: '기록',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '기록',
        children: [
          Text(
            '기록 상세를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

enum _MemoryDetailAction { edit, delete }

class _GroupMemoryDetailContent extends ConsumerWidget {
  const _GroupMemoryDetailContent({required this.groupId, required this.state});

  final String groupId;
  final GroupMemoryDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memory = state.memory;

    return OnmuScaffold(
      title: '기록',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupMemories(groupId)),
      action: PopupMenuButton<_MemoryDetailAction>(
        tooltip: '기록 옵션',
        icon: const Icon(Icons.more_vert),
        onSelected: (action) => switch (action) {
          _MemoryDetailAction.edit => _editMemory(context, ref, memory),
          _MemoryDetailAction.delete => _deleteMemory(context, ref, memory),
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: _MemoryDetailAction.edit, child: Text('수정하기')),
          PopupMenuItem(value: _MemoryDetailAction.delete, child: Text('삭제하기')),
        ],
      ),
      useWarmBackground: false,
      bottom: const _CommentInput(),
      children: [
        if (!memory.isMemo) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AspectRatio(
              aspectRatio: 1.36,
              child: GroupMemoryPhoto(
                index: state.photoIndex,
                imageUrl: memory.primaryImageUrl,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _MemoryBody(memory: memory),
        const SizedBox(height: AppSpacing.lg),
        const Divider(color: AppColors.lineSoft),
        const SizedBox(height: AppSpacing.md),
        Text('댓글 0', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        const _EmptyCommentState(),
        const SizedBox(height: 72),
      ],
    );
  }

  Future<void> _editMemory(
    BuildContext context,
    WidgetRef ref,
    GroupMemoryRecord memory,
  ) async {
    final result = await _showMemoryEditDialog(context, memory);
    if (result == null || !context.mounted) return;
    final repository = ref.read(groupRepositoryProvider);
    await repository.updateGroupMemory(
      groupId: groupId,
      memoryId: memory.routeId,
      type: memory.kind,
      title: result.title,
      memo: result.memo,
      date: _dateFromLabel(memory.dateLabel),
    );
    ref.invalidate(groupMemoryBoardViewModelProvider(groupId));
    ref.invalidate(
      groupMemoryDetailViewModelProvider((
        groupId: groupId,
        memoryId: memory.routeId,
      )),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('수정했어요.')));
  }

  Future<void> _deleteMemory(
    BuildContext context,
    WidgetRef ref,
    GroupMemoryRecord memory,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제하기'),
        content: const Text('이 기록을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repository = ref.read(groupRepositoryProvider);
    await repository.deleteGroupMemory(
      groupId: groupId,
      memoryId: memory.routeId,
    );
    ref
      ..invalidate(groupMemoryBoardViewModelProvider(groupId))
      ..invalidate(groupHomeViewModelProvider(groupId))
      ..invalidate(groupListViewModelProvider);
    if (!context.mounted) return;
    context.popOrGo(RoutePaths.groupMemories(groupId));
  }
}

class _MemoryEditDraft {
  const _MemoryEditDraft({required this.title, required this.memo});

  final String title;
  final String memo;
}

Future<_MemoryEditDraft?> _showMemoryEditDialog(
  BuildContext context,
  GroupMemoryRecord memory,
) {
  final titleController = TextEditingController(text: memory.title);
  final memoController = TextEditingController(text: memory.description);
  return showDialog<_MemoryEditDraft>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('수정하기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: '제목'),
            maxLength: 40,
          ),
          TextField(
            controller: memoController,
            decoration: const InputDecoration(labelText: '내용'),
            minLines: 3,
            maxLines: 5,
            maxLength: 300,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _MemoryEditDraft(
              title: titleController.text.trim(),
              memo: memoController.text.trim(),
            ),
          ),
          child: const Text('저장'),
        ),
      ],
    ),
  ).whenComplete(() {
    titleController.dispose();
    memoController.dispose();
  });
}

DateTime? _dateFromLabel(String value) {
  final match = RegExp(r'(\d{4})\.(\d{2})\.(\d{2})').firstMatch(value);
  if (match == null) return null;
  final year = int.tryParse(match.group(1) ?? '');
  final month = int.tryParse(match.group(2) ?? '');
  final day = int.tryParse(match.group(3) ?? '');
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

class _MemoryBody extends StatelessWidget {
  const _MemoryBody({required this.memory});

  final GroupMemoryRecord memory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelAvatar(
              label: memory.author,
              size: 40,
              profileImageUrl: memory.authorProfileImageUrl,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.author,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    memory.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    memory.dateLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          memory.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [for (final tag in memory.tags) _TagPill(label: tag)],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Icon(Icons.favorite, color: AppColors.accentRed),
            const SizedBox(width: AppSpacing.xs),
            Text('12', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: AppSpacing.lg),
            const Icon(Icons.mode_comment_outlined, color: AppColors.textSub),
            const SizedBox(width: AppSpacing.xs),
            Text('3', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPinkSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.linePink),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primaryPink),
        ),
      ),
    );
  }
}

class _EmptyCommentState extends StatelessWidget {
  const _EmptyCommentState();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineSoft,
      child: Center(
        child: Text(
          '아직 댓글이 없어요.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          IconButton(
            tooltip: '댓글 보내기',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('댓글 작성은 목업으로만 확인해요.')),
              );
            },
            icon: const Icon(Icons.send_outlined),
          ),
        ],
      ),
    );
  }
}
