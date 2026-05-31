import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onchat_models.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class OnChatMeetupBoardPage extends StatelessWidget {
  const OnChatMeetupBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '온챗 약속 보드',
      subtitle: '장소 투표와 준비 상태를 한 장의 보드처럼 붙여둡니다.',
      children: [
        OnmuCard(
          backgroundColor: AppColors.bgPaper,
          borderColor: AppColors.lineWarm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnmuStickerLabel(
                label: '약속 보드',
                icon: Icons.push_pin_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                demoPinnedMeetup.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                demoPinnedMeetup.dateLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              OnmuChip(label: demoPinnedMeetup.statusLabel, selected: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('장소 투표', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final candidate in demoPlaceCandidates.take(2)) ...[
          _VoteCard(candidate: candidate),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OnmuSecondaryButton(
                label: '장소 추천',
                icon: Icons.place_outlined,
                onPressed: () =>
                    context.go('${RoutePaths.placeCandidates}?voteResult=1'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OnmuPrimaryButton(
                label: '정산 만들기',
                icon: Icons.receipt_long_outlined,
                onPressed: () => context.go(RoutePaths.settlementNew),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VoteCard extends StatelessWidget {
  const _VoteCard({required this.candidate});

  final PlaceCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final isTop = candidate.id == 'cafe-moon';

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: isTop ? AppColors.linePink : AppColors.lineBrown,
      child: Row(
        children: [
          Icon(
            isTop ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isTop ? AppColors.primaryPink : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  candidate.summary,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          OnmuChip(label: isTop ? '3표' : '1표', selected: isTop),
        ],
      ),
    );
  }
}
