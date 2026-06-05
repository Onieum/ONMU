import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class GroupMemoryBoardPage extends ConsumerWidget {
  const GroupMemoryBoardPage({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupMemoryBoardViewModelProvider(groupId));

    return state.when(
      data: (state) => _GroupMemoryBoardContent(state: state),
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

class _GroupMemoryBoardContent extends StatelessWidget {
  const _GroupMemoryBoardContent({required this.state});

  final GroupMemoryBoardState state;

  @override
  Widget build(BuildContext context) {
    final group = state.group;

    return OnmuScaffold(
      title: group.name,
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go(RoutePaths.groupDetail(group.id));
      },
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '기록 검색',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('기록 검색은 다음 단계에서 연결할게요.')),
              );
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: '기록 옵션',
            onPressed: () => context.go(RoutePaths.groupSettings(group.id)),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      useWarmBackground: false,
      children: [
        _GroupTabs(group: group),
        const SizedBox(height: AppSpacing.md),
        const _MemoryFilterRow(),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.63,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var index = 0; index < state.memories.length; index += 1)
              _MemoryCard(
                groupId: group.id,
                memory: state.memories[index],
                photoIndex: index,
              ),
          ],
        ),
        const SizedBox(height: 72),
      ],
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
          onTap: () => context.go(RoutePaths.groupDetail(group.id)),
        ),
        _GroupTab(label: '기록', selected: true, onTap: () {}),
        _GroupTab(
          label: '채팅',
          selected: false,
          onTap: () => context.go(RoutePaths.groupChat(group.id)),
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
  const _MemoryFilterRow();

  @override
  Widget build(BuildContext context) {
    final filters = ['전체', '사진', '카페', '여행', '기타'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index += 1) ...[
            _MemoryFilterChip(label: filters[index], selected: index == 0),
            if (index != filters.length - 1)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _MemoryFilterChip extends StatelessWidget {
  const _MemoryFilterChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.groupId,
    required this.memory,
    required this.photoIndex,
  });

  final int groupId;
  final GroupMemoryRecord memory;
  final int photoIndex;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: () => context.go(RoutePaths.groupMemoryDetail(groupId, memory.id)),
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
                PixelAvatar(label: memory.author, size: 24),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  memory.author,
                  style: Theme.of(context).textTheme.labelMedium,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GroupMemoryPhoto(index: photoIndex),
                  Positioned(
                    right: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.bgDefault.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxs),
                        child: Icon(
                          Icons.favorite,
                          size: 18,
                          color: photoIndex == 3
                              ? AppColors.accentRed
                              : AppColors.textInverse,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
