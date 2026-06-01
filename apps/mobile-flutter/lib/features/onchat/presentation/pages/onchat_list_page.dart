import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onchat_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onchat_cards.dart';

class OnChatListPage extends StatelessWidget {
  const OnChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '온챗',
      subtitle: '모임, 친구, 약속을 검색하고 이어봅니다.',
      actions: [
        IconButton(
          tooltip: '온챗 검색',
          onPressed: () {},
          icon: const Icon(Icons.search),
        ),
        IconButton(
          tooltip: '온챗 만들기',
          onPressed: () {},
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
      children: [
        const _OnChatSearchField(),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text('내가 참여한 모임', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.xs),
            const OnmuStickerLabel(label: '5', icon: Icons.favorite),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.keyboard_arrow_down),
              label: const Text('최신순'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final group in demoOnChatGroups) ...[
          OnChatGroupCard(
            group: group,
            onTap: () => context.go(RoutePaths.onchatDemoGroup),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _CreateGroupCard(
          onPressed: () => context.go(RoutePaths.onchatDemoGroup),
        ),
      ],
    );
  }
}

class _OnChatSearchField extends StatelessWidget {
  const _OnChatSearchField();

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
          const Icon(Icons.search, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '모임, 친구, 약속 검색',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CreateGroupCard extends StatelessWidget {
  const _CreateGroupCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Row(
        children: [
          const OnmuPixelBuddy(size: 52),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '새로운 모임을 만들어보세요!',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '친구들과 약속을 만들고 온챗에서 함께 소통해요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          OnmuPrimaryButton(
            label: '모임 만들기',
            icon: Icons.add,
            color: AppColors.primaryPink,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
