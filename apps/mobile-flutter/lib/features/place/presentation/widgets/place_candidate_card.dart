import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';

class PlaceCandidateCard extends StatelessWidget {
  const PlaceCandidateCard({
    required this.candidate,
    required this.onDetailPressed,
    super.key,
    this.onRegisterPressed,
    this.onAddCandidatePressed,
    this.compact = false,
  });

  final PlaceCandidate candidate;
  final VoidCallback onDetailPressed;
  final VoidCallback? onRegisterPressed;
  final VoidCallback? onAddCandidatePressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(candidate.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            candidate.categoryDistanceLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (candidate.summary.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              candidate.summary,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (candidate.travelTimeLabel.trim().isNotEmpty)
                OnmuChip(
                  label: candidate.travelTimeLabel,
                  icon: Icons.directions_walk,
                ),
              for (final tag in candidate.tags.take(compact ? 2 : 3))
                OnmuChip(label: tag),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.sm),
            MemberPreferenceList(candidate: candidate),
          ],
          const SizedBox(height: AppSpacing.md),
          OnmuSecondaryButton(
            label: '상세 보기',
            icon: Icons.info_outline,
            onPressed: onDetailPressed,
          ),
          if (onRegisterPressed != null || onAddCandidatePressed != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (onAddCandidatePressed != null)
                  Expanded(
                    child: OnmuSecondaryButton(
                      label: '후보에 추가하기',
                      icon: Icons.favorite_border,
                      onPressed: onAddCandidatePressed,
                    ),
                  ),
                if (onRegisterPressed != null && onAddCandidatePressed != null)
                  const SizedBox(width: AppSpacing.sm),
                if (onRegisterPressed != null)
                  Expanded(
                    child: OnmuPrimaryButton(
                      label: '일정에 바로 등록하기',
                      icon: Icons.event_available_outlined,
                      color: AppColors.primaryPink,
                      foregroundColor: AppColors.textInverse,
                      onPressed: onRegisterPressed,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MemberPreferenceList extends StatelessWidget {
  const MemberPreferenceList({required this.candidate, super.key});

  final PlaceCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final names = ['민서', '하린', '지우', '현우'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < candidate.memberFits.length; index += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.favorite,
                  size: 16,
                  color: AppColors.accentRed,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${names[index % names.length]}님이 ${index.isEven ? '좋아하는' : '가고 싶어하는'} 장소입니다 · ${candidate.memberFits[index].note}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
