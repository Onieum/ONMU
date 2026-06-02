import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onmoim_cards.dart';

class OnMoimListPage extends StatelessWidget {
  const OnMoimListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '온모임',
      actions: [
        IconButton(
          tooltip: '온모임 검색',
          onPressed: () {},
          icon: const Icon(Icons.search),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        tooltip: '온모임 만들기',
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.textMain,
        shape: const CircleBorder(),
        onPressed: () => context.go(RoutePaths.onmoimDemo),
        child: const Icon(Icons.add),
      ),
      children: [
        const _OnMoimSearchField(),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text('내 모임', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.xs),
            const OnmuStickerLabel(label: '5', icon: Icons.favorite),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('최근 활동순')),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final group in demoOnMoimGroups) ...[
          OnMoimGroupCard(
            group: group,
            onTap: () => context.go(RoutePaths.onmoimDemo),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: 72),
      ],
    );
  }
}

class _OnMoimSearchField extends StatelessWidget {
  const _OnMoimSearchField();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
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
