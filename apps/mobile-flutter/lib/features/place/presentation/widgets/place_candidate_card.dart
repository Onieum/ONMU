import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_decorations.dart';

class PlaceCandidateCard extends StatelessWidget {
  const PlaceCandidateCard({
    required this.candidate,
    required this.onDetailPressed,
    super.key,
    this.onSelectPressed,
    this.compact = false,
  });

  final PlaceCandidate candidate;
  final VoidCallback onDetailPressed;
  final VoidCallback? onSelectPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: candidate.isOpen ? AppColors.lineBrown : AppColors.linePink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            OnmuStickerLabel(
              label: candidate.category,
              icon: Icons.local_cafe_outlined,
              backgroundColor: AppColors.bgPaper,
              borderColor: AppColors.lineWarm,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlaceBadge(score: candidate.score),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${candidate.category} · ${candidate.distanceLabel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              OnmuChip(
                label: candidate.isOpen ? '영업 중' : '확인 필요',
                selected: !candidate.isOpen,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            candidate.summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OnmuChip(
                label: '취향 ${candidate.matchPercent}%',
                icon: Icons.favorite_outline,
                selected: true,
              ),
              OnmuChip(
                label: candidate.travelTimeLabel,
                icon: Icons.directions_walk,
              ),
              OnmuChip(label: candidate.priceLabel, icon: Icons.payments),
              for (final tag in candidate.tags.take(compact ? 1 : 3))
                OnmuChip(label: tag),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final reason in candidate.reasons.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 17,
                      color: AppColors.accentGreen,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        reason,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OnmuSecondaryButton(
                  label: '상세',
                  icon: Icons.info_outline,
                  onPressed: onDetailPressed,
                ),
              ),
              if (onSelectPressed != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OnmuPrimaryButton(
                    label: '후보 선택',
                    icon: Icons.check,
                    color: AppColors.primaryPink,
                    onPressed: onSelectPressed,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceBadge extends StatelessWidget {
  const _PlaceBadge({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineWarm),
      ),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.accentOrange),
            Text(
              score.toStringAsFixed(1),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.accentBrown),
            ),
          ],
        ),
      ),
    );
  }
}
