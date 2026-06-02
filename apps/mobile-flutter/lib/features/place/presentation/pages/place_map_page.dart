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
import '../../../../shared/widgets/onmu_top_bar.dart';

class PlaceMapPage extends StatelessWidget {
  const PlaceMapPage({
    required this.onmoimId,
    required this.meetupId,
    super.key,
  });

  final String onmoimId;
  final String meetupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGrid,
      body: SafeArea(
        child: Column(
          children: [
            OnmuTopBar(
              title: '장소 지도',
              showBackButton: true,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: _MockMap(),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    bottom: 112,
                    child: FloatingActionButton.extended(
                      heroTag: 'place-map-list',
                      tooltip: '후보 목록 열기',
                      backgroundColor: AppColors.bgDefault,
                      foregroundColor: AppColors.textMain,
                      elevation: 2,
                      icon: const Icon(Icons.list_alt),
                      label: const Text('목록'),
                      onPressed: () => context.go(
                        RoutePaths.onmoimMeetupPlaces(onmoimId, meetupId),
                      ),
                    ),
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: 0.38,
                    minChildSize: 0.18,
                    maxChildSize: 0.72,
                    builder: (context, scrollController) {
                      return _CandidateSheet(
                        controller: scrollController,
                        onListPressed: () => context.go(
                          RoutePaths.onmoimMeetupPlaces(onmoimId, meetupId),
                        ),
                        onComparePressed: () => context.go(
                          RoutePaths.onmoimMeetupPlaceCompare(
                            onmoimId,
                            meetupId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateSheet extends StatelessWidget {
  const _CandidateSheet({
    required this.controller,
    required this.onListPressed,
    required this.onComparePressed,
  });

  final ScrollController controller;
  final VoidCallback onListPressed;
  final VoidCallback onComparePressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          96,
        ),
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.lineBrown,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const SizedBox(width: 44, height: 5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '후보 장소',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '아래로 내리면 지도만 볼 수 있어요',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textSub),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final candidate in demoPlaceCandidates) ...[
            _SheetCandidateTile(candidate: candidate),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: OnmuSecondaryButton(
                  label: '전체 목록',
                  icon: Icons.list_alt,
                  onPressed: onListPressed,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OnmuPrimaryButton(
                  label: '비교하기',
                  icon: Icons.compare_arrows,
                  onPressed: onComparePressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetCandidateTile extends StatelessWidget {
  const _SheetCandidateTile({required this.candidate});

  final PlaceCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${candidate.travelTimeLabel} · ${candidate.category}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${candidate.matchPercent}%',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: AppColors.primaryPink),
          ),
        ],
      ),
    );
  }
}

class _MockMap extends StatelessWidget {
  const _MockMap();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
            bottom: 168,
            child: _MapLabel(label: '하린', icon: Icons.face_4_outlined),
          ),
          Positioned(
            right: 54,
            bottom: 190,
            child: _MapLabel(label: '홍대입구역', icon: Icons.train_outlined),
          ),
          Center(child: _MapPin(label: '온무식당')),
        ],
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
