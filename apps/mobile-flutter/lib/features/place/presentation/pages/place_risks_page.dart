import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class PlaceRisksPage extends StatelessWidget {
  const PlaceRisksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '장소 리스크',
      subtitle: '휴무, 웨이팅, 비선호 조건을 작게 붙여두고 먼저 확인합니다.',
      children: [
        for (final risk in demoPlaceRisks) ...[
          _RiskCard(risk: risk),
          const SizedBox(height: AppSpacing.md),
        ],
        OnmuPrimaryButton(
          label: '괜찮은 후보만 비교하기',
          icon: Icons.compare_arrows,
          onPressed: () => context.go(RoutePaths.placeCompare),
        ),
      ],
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.risk});

  final PlaceRisk risk;

  @override
  Widget build(BuildContext context) {
    final color = switch (risk.level) {
      PlaceRiskLevel.blocker => AppColors.accentRed,
      PlaceRiskLevel.warning => AppColors.accentOrange,
      PlaceRiskLevel.notice => AppColors.accentBlue,
    };

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: color),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  risk.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(risk.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          OnmuSecondaryButton(
            label: risk.actionLabel,
            icon: Icons.check_circle_outline,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
