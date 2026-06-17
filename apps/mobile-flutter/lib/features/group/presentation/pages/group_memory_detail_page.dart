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

class _GroupMemoryDetailContent extends StatelessWidget {
  const _GroupMemoryDetailContent({required this.groupId, required this.state});

  final String groupId;
  final GroupMemoryDetailState state;

  @override
  Widget build(BuildContext context) {
    final memory = state.memory;

    return OnmuScaffold(
      title: '기록',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupMemories(groupId)),
      action: IconButton(
        tooltip: '기록 옵션',
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('기록 옵션은 이후에 연결할게요.')));
        },
        icon: const Icon(Icons.more_horiz),
      ),
      useWarmBackground: false,
      bottom: const _CommentInput(),
      children: [
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
