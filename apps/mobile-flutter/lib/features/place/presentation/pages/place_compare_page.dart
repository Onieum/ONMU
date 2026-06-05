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

class PlaceComparePage extends StatelessWidget {
  const PlaceComparePage({
    required this.onmoimId,
    required this.meetupId,
    super.key,
  });

  final String onmoimId;
  final String meetupId;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '후보 비교',
      subtitle: '기준: 홍대 토요일 18:00',
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OnmuPrimaryButton(
            label: '온무식당 선택하기',
            icon: Icons.check_circle_outline,
            color: AppColors.primaryPurple,
            foregroundColor: AppColors.textInverse,
            onPressed: () =>
                context.go(RoutePaths.planBoard(onmoimId, meetupId)),
          ),
        ),
      ),
      children: const [
        _CandidateCompareTable(),
        SizedBox(height: AppSpacing.lg),
        _MemberFitSummary(),
        SizedBox(height: AppSpacing.lg),
        _RecommendationConclusion(),
      ],
    );
  }
}

class _CandidateCompareTable extends StatelessWidget {
  const _CandidateCompareTable();

  @override
  Widget build(BuildContext context) {
    final candidates = demoPlaceCandidates;

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          border: TableBorder.all(color: AppColors.lineSoft),
          children: [
            _row(
              context,
              candidates.map((candidate) => candidate.name).toList(),
              isHeader: true,
            ),
            _row(
              context,
              candidates.map((candidate) => candidate.travelTimeLabel).toList(),
            ),
            _row(
              context,
              candidates.map((candidate) => candidate.category).toList(),
            ),
            _row(
              context,
              candidates
                  .map(
                    (candidate) => candidate.openingLabel.contains('LO')
                        ? candidate.openingLabel.split('·').last.trim()
                        : '정보 오래됨',
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _row(
    BuildContext context,
    List<String> values, {
    bool isHeader = false,
    int? highlightedIndex,
  }) {
    return TableRow(
      children: [
        for (var index = 0; index < values.length; index += 1)
          ColoredBox(
            color: index == highlightedIndex
                ? AppColors.primaryPinkSoft
                : isHeader
                ? AppColors.primaryPurpleSoft
                : AppColors.bgDefault,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.md,
              ),
              child: Text(
                values[index],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isHeader
                      ? AppColors.primaryPurpleDark
                      : AppColors.textMain,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MemberFitSummary extends StatelessWidget {
  const _MemberFitSummary();

  @override
  Widget build(BuildContext context) {
    final fits = demoPlaceCandidates.first.memberFits.take(3);

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('참여자 선호', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final fit in fits) ...[
            Text(
              '${fit.label}님이 온무식당을 ${fit.note} 장소로 보고 있어요.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _RecommendationConclusion extends StatelessWidget {
  const _RecommendationConclusion();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('추천 결론', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '온무식당은 이동 시간이 짧고 한식을 좋아하는 멤버들이 함께 고르기 좋은 후보예요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: const [
              OnmuChip(label: '한식 선호', selected: true),
              OnmuChip(label: '이동 쉬움', selected: true),
            ],
          ),
        ],
      ),
    );
  }
}
