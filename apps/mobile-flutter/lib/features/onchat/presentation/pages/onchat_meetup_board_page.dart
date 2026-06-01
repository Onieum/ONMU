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
      title: '약속 보드',
      subtitle: '온챗 · 우리들의 주말 · 투표 마감 D-1',
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OnmuPrimaryButton(
            label: '최종 장소 확정하기',
            icon: Icons.check_circle_outline,
            color: AppColors.primaryPink,
            onPressed: () => context.go(RoutePaths.onchatDemoChat),
          ),
        ),
      ),
      children: [
        const _BoardNoticeCard(),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text('장소 후보', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.xs),
            const OnmuChip(label: '3', selected: true),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < demoPlaceCandidates.length; index += 1) ...[
          _VoteCard(
            rank: index + 1,
            candidate: demoPlaceCandidates[index],
            voteCount: switch (index) {
              0 => 5,
              1 => 3,
              _ => 1,
            },
            progress: switch (index) {
              0 => 0.62,
              1 => 0.25,
              _ => 0.13,
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const _ParticipantResponseCard(),
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          backgroundColor: AppColors.bgPaper,
          borderColor: AppColors.lineWarm,
          child: Row(
            children: [
              const OnmuStickerLabel(label: '투표 결과', icon: Icons.edit_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '모두가 만족할 장소를 정해보아요!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
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
              child: OnmuSecondaryButton(
                label: '정산 보기',
                icon: Icons.receipt_long_outlined,
                onPressed: () => context.go(RoutePaths.settlementShare),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BoardNoticeCard extends StatelessWidget {
  const _BoardNoticeCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, color: AppColors.accentOrange),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demoPinnedMeetup.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '마음에 드는 장소에 투표해 주세요!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const OnmuChip(label: 'D-1', selected: true),
        ],
      ),
    );
  }
}

class _VoteCard extends StatelessWidget {
  const _VoteCard({
    required this.rank,
    required this.candidate,
    required this.voteCount,
    required this.progress,
  });

  final int rank;
  final PlaceCandidate candidate;
  final int voteCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1;

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: isTop ? AppColors.linePink : AppColors.lineSoft,
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        candidate.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '$voteCount표',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${candidate.category} · ${candidate.distanceLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.primaryPinkSoft,
                  color: AppColors.primaryPink,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantResponseCard extends StatelessWidget {
  const _ParticipantResponseCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('참여자 응답', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: const [
              Expanded(
                child: _ResponseTile(label: '참석', count: '5', selected: true),
              ),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _ResponseTile(label: '미정', count: '1'),
              ),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _ResponseTile(label: '불참', count: '0'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponseTile extends StatelessWidget {
  const _ResponseTile({
    required this.label,
    required this.count,
    this.selected = false,
  });

  final String label;
  final String count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.linePink : AppColors.lineSoft,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xxs),
            Text(count, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppColors.primaryPink,
      foregroundColor: AppColors.textInverse,
      child: Text('$rank'),
    );
  }
}
