import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onchat_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onchat_cards.dart';

class OnChatGroupHomePage extends StatelessWidget {
  const OnChatGroupHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '성수 토요일 멤버',
      subtitle: '대화, 약속 보드, 추억 보드, 정산을 작은 노트처럼 넘겨봅니다.',
      children: [
        PinnedMeetupCard(
          meetup: demoPinnedMeetup,
          onBoardPressed: () => context.go(RoutePaths.onchatMeetupBoard),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OnmuPrimaryButton(
                label: '대화 보기',
                icon: Icons.chat_bubble_outline,
                onPressed: () => context.go(RoutePaths.onchatDemoChat),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OnmuSecondaryButton(
                label: '약속 만들기',
                icon: Icons.add,
                onPressed: () => context.go(RoutePaths.onchatMeetupNew),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnmuStickerLabel(
                label: '빠른 이동',
                icon: Icons.bookmark_outline,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  OnmuChip(label: '장소 투표', selected: true),
                  OnmuChip(label: '추억 보드'),
                  OnmuChip(label: '정산'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _QuickLink(
                label: '장소 후보 투표 보드',
                icon: Icons.how_to_vote_outlined,
                onTap: () => context.go(RoutePaths.onchatMeetupBoard),
              ),
              _QuickLink(
                label: '함께 남긴 추억',
                icon: Icons.auto_stories_outlined,
                onTap: () => context.go(RoutePaths.onchatMemories),
              ),
              _QuickLink(
                label: '정산 만들기',
                icon: Icons.receipt_long_outlined,
                onTap: () => context.go(RoutePaths.settlementNew),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
