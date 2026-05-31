import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class PlaceDetailPage extends StatelessWidget {
  const PlaceDetailPage({required this.placeId, super.key});

  final String placeId;

  @override
  Widget build(BuildContext context) {
    final candidate = findPlaceCandidate(placeId);

    return OnmuScaffold(
      title: '장소 상세',
      subtitle: '바텀시트로 열릴 상세 정보를 모바일 화면에서 먼저 검토합니다.',
      children: [
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.linePurple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                candidate.summary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final tag in candidate.tags)
                    OnmuChip(label: tag, selected: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _InfoRow(label: '이동', value: candidate.travelTimeLabel),
        _InfoRow(label: '거리', value: candidate.distanceLabel),
        _InfoRow(label: '예상 비용', value: candidate.priceLabel),
        _InfoRow(
          label: '영업 상태',
          value: candidate.isOpen ? '지금 영업 중' : '영업 정보 확인 필요',
        ),
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('추천 이유', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              for (final reason in candidate.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 17,
                        color: AppColors.primaryPink,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(reason)),
                    ],
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
                label: '목록',
                icon: Icons.arrow_back,
                onPressed: () => context.go(RoutePaths.placeCandidates),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OnmuPrimaryButton(
                label: '비교에 담기',
                icon: Icons.add_task,
                onPressed: () => context.go(RoutePaths.placeCompare),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: OnmuCard(
        backgroundColor: AppColors.bgDefault,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
