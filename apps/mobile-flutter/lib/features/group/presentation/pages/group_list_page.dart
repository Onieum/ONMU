import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/group_list_view_model.dart';
import '../widgets/group_cards.dart';

class GroupListPage extends ConsumerWidget {
  const GroupListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupListViewModelProvider);

    return state.when(
      data: (state) => _GroupListContent(state: state),
      loading: () => const OnmuScaffold(
        title: '온모임',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '온모임',
        children: [
          Text(
            '온모임 목록을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GroupListContent extends StatelessWidget {
  const _GroupListContent({required this.state});

  final GroupListState state;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '온모임',
      floatingActionButton: FloatingActionButton(
        tooltip: '온모임 만들기',
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.textMain,
        shape: const CircleBorder(),
        onPressed: () => context.push(RoutePaths.groupNew),
        child: const Icon(Icons.add),
      ),
      children: [
        const _GroupSearchField(),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text('내 모임', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.xs),
            _GroupCountBadge(count: state.groupCount),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  _showGroupListSnack(context, '최근 활동순으로 정렬된 상태예요.'),
              child: const Text('최근 활동순'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final group in state.groups) ...[
          GroupSummaryCard(
            group: group,
            onTap: () => context.push(RoutePaths.groupDetail(group.id)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: 72),
      ],
    );
  }
}

class _GroupCountBadge extends StatelessWidget {
  const _GroupCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgSticker,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.linePink),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, size: 14, color: AppColors.primaryPink),
            const SizedBox(width: AppSpacing.xxs),
            Text('$count', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _GroupSearchField extends StatelessWidget {
  const _GroupSearchField();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: () =>
          _showGroupListSnack(context, '검색어 입력 UI는 다음 단계에서 실제 필드로 연결할게요.'),
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textMuted, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '모임, 멤버, 약속 검색',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

void _showGroupListSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
