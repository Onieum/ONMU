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
    final riskColor = _riskColor(candidate.riskTone);

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: candidate.isOpen ? AppColors.lineBrown : AppColors.linePink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      candidate.summary,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _PlaceScoreBadge(score: candidate.score),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OnmuChip(label: candidate.riskLabel, selected: true),
              OnmuChip(
                label: candidate.travelTimeLabel,
                icon: Icons.directions_walk,
              ),
              OnmuChip(
                label: candidate.sourceLabel.split(' · ').first,
                icon: Icons.public,
              ),
              for (final tag in candidate.tags.take(compact ? 2 : 3))
                OnmuChip(label: tag),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.sm),
            _MemberFitMiniList(candidate: candidate),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: riskColor.withValues(alpha: 0.45)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: riskColor),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        candidate.risks.first,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                  label: '상세 보기',
                  icon: Icons.info_outline,
                  onPressed: onDetailPressed,
                ),
              ),
              if (onSelectPressed != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OnmuPrimaryButton(
                    label: '후보 추가',
                    icon: Icons.add,
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

  Color _riskColor(String tone) {
    return switch (tone) {
      'none' => AppColors.accentGreen,
      'medium' => AppColors.accentOrange,
      'unknown' => AppColors.textMuted,
      _ => AppColors.primaryPink,
    };
  }
}

class PlaceMemberFitBar extends StatelessWidget {
  const PlaceMemberFitBar({required this.fit, super.key});

  final MemberFit fit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              fit.label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: fit.score / 100,
              minHeight: 8,
              backgroundColor: AppColors.primaryPurpleSoft,
              color: AppColors.primaryPink,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 30,
            child: Text(
              '${fit.score}',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class ExternalSourceBadge extends StatelessWidget {
  const ExternalSourceBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OnmuStickerLabel(
      label: label,
      icon: Icons.sync,
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
    );
  }
}

class _MemberFitMiniList extends StatelessWidget {
  const _MemberFitMiniList({required this.candidate});

  final PlaceCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final fit in candidate.memberFits) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.linePurple),
            ),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Center(
                child: Text(
                  fit.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        const Spacer(),
        Text(
          '평균 ${candidate.matchPercent}',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.primaryPurpleDark),
        ),
      ],
    );
  }
}

class _PlaceScoreBadge extends StatelessWidget {
  const _PlaceScoreBadge({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '${score.toInt()}점',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.textInverse),
        ),
      ),
    );
  }
}
