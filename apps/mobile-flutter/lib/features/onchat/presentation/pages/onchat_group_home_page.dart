import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onchat_models.dart';
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
      title: '모임 홈',
      subtitle: '대학 동기 여행단 · 빠른 액션으로 채팅, 약속, 추억, 정산을 이어갑니다.',
      actions: [
        IconButton(
          tooltip: '멤버 관리',
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      children: [
        const _GroupProfileCard(),
        const SizedBox(height: AppSpacing.md),
        PinnedMeetupCard(
          meetup: demoPinnedMeetup,
          onBoardPressed: () => context.go(RoutePaths.onchatMeetupBoard),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.62,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _QuickActionTile(
              label: '채팅',
              body: '모임 대화방',
              icon: Icons.chat_bubble_outline,
              onTap: () => context.go(RoutePaths.onchatDemoChat),
            ),
            _QuickActionTile(
              label: '약속',
              body: '일정 · 장소 논의',
              icon: Icons.calendar_month_outlined,
              onTap: () => context.go(RoutePaths.onchatMeetupBoard),
            ),
            _QuickActionTile(
              label: '추억',
              body: '사진 · 기록 모아보기',
              icon: Icons.photo_library_outlined,
              onTap: () => context.go(RoutePaths.onchatMemories),
            ),
            _QuickActionTile(
              label: '정산',
              body: '비용 관리하기',
              icon: Icons.calculate_outlined,
              onTap: () => context.go(RoutePaths.settlementShare),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.lineSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('최근 활동', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              const _ActivityRow(
                label: '고정',
                title: '여행 준비 체크리스트',
                body: '체크리스트 6/12 완료',
              ),
              const _ActivityRow(
                label: '추억',
                title: '민지님이 새 추억을 추가했어요',
                body: '제주 카페에서',
              ),
              const _ActivityRow(
                label: '정산',
                title: '정산 대기 중인 내역이 있어요',
                body: '교통비 · 숙소비 2건',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupProfileCard extends StatelessWidget {
  const _GroupProfileCard();

  @override
  Widget build(BuildContext context) {
    final group = demoOnChatGroups.first;

    return OnmuCard(
      backgroundColor: AppColors.primaryPinkSoft,
      borderColor: AppColors.linePink,
      child: Row(
        children: [
          const OnmuPixelBuddy(size: 82),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  group.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OnmuChip(label: '멤버 ${group.members.length}명'),
                    const OnmuChip(label: '2024.03.16부터'),
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.body,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String body;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryPinkSoft,
            foregroundColor: AppColors.primaryPink,
            child: Icon(icon),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.primaryPink),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.label,
    required this.title,
    required this.body,
  });

  final String label;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          OnmuChip(label: label, selected: label == '고정'),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
