import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class PlaceComparePage extends StatelessWidget {
  const PlaceComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '장소 비교',
      subtitle: '후보별 느낌과 조건을 한 장의 메모처럼 비교합니다.',
      children: [
        OnmuCard(
          backgroundColor: AppColors.bgPaper,
          borderColor: AppColors.lineWarm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnmuStickerLabel(label: '오늘의 추천', icon: Icons.auto_awesome),
              const SizedBox(height: AppSpacing.sm),
              Text('가장 무난한 선택', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '카페 문라이트가 취향 점수와 이동 균형이 가장 좋아요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final candidate in demoPlaceCandidates) ...[
          _CompareCard(candidate: candidate),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            Expanded(
              child: OnmuSecondaryButton(
                label: '리스크',
                icon: Icons.warning_amber,
                onPressed: () => context.go(RoutePaths.placeRisks),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OnmuPrimaryButton(
                label: '온챗에 공유',
                icon: Icons.send_outlined,
                onPressed: () => context.go(RoutePaths.onchatMeetupBoard),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.candidate});

  final PlaceCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  candidate.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${candidate.matchPercent}%',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppColors.accentBrown),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoreRow(label: '취향', value: candidate.matchPercent / 100),
          _ScoreRow(
            label: '이동',
            value: candidate.travelTimeLabel == '평균 18분' ? 0.92 : 0.74,
          ),
          _ScoreRow(
            label: '리스크',
            value: candidate.risks.length == 1 ? 0.72 : 0.46,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            candidate.risks.join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppColors.primaryPinkSoft,
              color: value > 0.7
                  ? AppColors.primaryPink
                  : AppColors.accentOrange,
            ),
          ),
        ],
      ),
    );
  }
}
