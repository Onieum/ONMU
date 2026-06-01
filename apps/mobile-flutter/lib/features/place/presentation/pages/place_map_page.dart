import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class PlaceMapPage extends StatelessWidget {
  const PlaceMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '지도 보기',
      subtitle: '지도 핀, 리스트 탭, 추천 후보를 한 화면에서 확인합니다.',
      useGridBackground: true,
      children: [
        const _MockMap(),
        const SizedBox(height: AppSpacing.md),
        for (final candidate in demoPlaceCandidates) ...[
          OnmuCard(
            backgroundColor: AppColors.bgDefault,
            child: Row(
              children: [
                const Icon(Icons.place, color: AppColors.primaryPink),
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
                        '${candidate.distanceLabel} · ${candidate.travelTimeLabel}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${candidate.matchPercent}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.accentBrown,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: OnmuSecondaryButton(
                label: '후보 목록',
                icon: Icons.list_alt,
                onPressed: () => context.go(RoutePaths.placeCandidates),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OnmuPrimaryButton(
                label: '비교하기',
                icon: Icons.compare_arrows,
                onPressed: () => context.go(RoutePaths.placeCompare),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MockMap extends StatelessWidget {
  const _MockMap();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.08,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bgPaper,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.lineBrown),
        ),
        child: Stack(
          children: const [
            Positioned(top: 18, left: 138, child: OnmuTape(width: 92)),
            Positioned(
              left: 28,
              top: 34,
              child: _MapLabel(label: '민서', icon: Icons.face_3_outlined),
            ),
            Positioned(
              right: 34,
              top: 58,
              child: _MapLabel(label: '지훈', icon: Icons.face_outlined),
            ),
            Positioned(
              left: 52,
              bottom: 48,
              child: _MapLabel(label: '하린', icon: Icons.face_4_outlined),
            ),
            Positioned(
              right: 54,
              bottom: 70,
              child: _MapLabel(label: '홍대입구역', icon: Icons.train_outlined),
            ),
            Center(child: _MapPin(label: '온무식당')),
          ],
        ),
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.lineBrown),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.accentBrown),
            const SizedBox(width: AppSpacing.xxs),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPink,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, color: AppColors.textMain),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
