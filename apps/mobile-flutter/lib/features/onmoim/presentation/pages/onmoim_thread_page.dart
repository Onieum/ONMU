import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onmoim_cards.dart';

class OnMoimThreadPage extends StatelessWidget {
  const OnMoimThreadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '채팅',
      subtitle: '친구들이 붙여둔 말풍선을 메모지처럼 확인합니다.',
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primaryPink,
                ),
                const SizedBox(width: AppSpacing.xs),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '메시지를 입력해보세요',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '전송',
                  onPressed: () {},
                  icon: const Icon(Icons.send_outlined),
                ),
              ],
            ),
          ),
        ),
      ),
      children: [
        PinnedMeetupCard(
          meetup: demoPinnedMeetup,
          onBoardPressed: () => context.go(RoutePaths.onmoimDemoMeetupBoard),
        ),
        const SizedBox(height: AppSpacing.md),
        const _StatusChipRow(),
        const SizedBox(height: AppSpacing.md),
        for (final message in demoOnMoimMessages) ...[
          ChatMessageBubble(message: message),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          backgroundColor: AppColors.bgPaper,
          borderColor: AppColors.lineWarm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnmuStickerLabel(
                label: 'ONMU 메모',
                icon: Icons.auto_awesome,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('ONMU 추천 카드', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '장소 후보를 투표 보드에 올리고 대화 흐름 안에서 바로 비교할 수 있어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              OnmuPrimaryButton(
                label: '투표 보드 보기',
                icon: Icons.how_to_vote_outlined,
                onPressed: () => context.go(RoutePaths.onmoimDemoMeetupBoard),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChipRow extends StatelessWidget {
  const _StatusChipRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: const [
        OnmuChip(label: '출발 1명', selected: true),
        OnmuChip(label: '도착 1명', selected: true),
        OnmuChip(label: '늦음 1명'),
        OnmuChip(label: '준비물 PDF'),
      ],
    );
  }
}
