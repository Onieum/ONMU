import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
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
              title: '장소 추가하기',
              showBackButton: true,
              onBack: () => context.pop(),
              action: IconButton(
                tooltip: '장소 옵션',
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(child: _MapCanvas()),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.sm,
                    child: _SearchBar(
                      onTap: () => context.go(
                        RoutePaths.onmoimMeetupPlaceSearch(onmoimId, meetupId),
                      ),
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.lg,
                    top: 76,
                    child: IconButton.filledTonal(
                      tooltip: '필터',
                      onPressed: () => context.go(
                        RoutePaths.onmoimMeetupPlaceSearch(onmoimId, meetupId),
                      ),
                      icon: const Icon(Icons.tune),
                    ),
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: 0.34,
                    minChildSize: 0.24,
                    maxChildSize: 0.7,
                    builder: (context, scrollController) {
                      return _RecommendationSheet(
                        controller: scrollController,
                        onAddPressed: () => context.go(
                          RoutePaths.onmoimMeetupPlaces(onmoimId, meetupId),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textSub),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '장소 검색 (카페, 식당, 관광지)',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapCanvasPainter(),
      child: Stack(
        children: const [
          Positioned(left: 92, top: 132, child: _MapPin(order: 1)),
          Positioned(right: 96, top: 220, child: _MapPin(order: 2)),
          Positioned(right: 66, top: 128, child: _MapPin(order: 3)),
          Positioned(left: 184, top: 176, child: _CurrentLocationDot()),
        ],
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.lineSoft
      ..strokeWidth = 2;

    for (var y = 40.0; y < size.height; y += 58) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 28), roadPaint);
    }

    for (var x = 24.0; x < size.width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x + 40, size.height), roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.order});

  final int order;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primaryPink,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.bgDefault, width: 3),
          ),
          child: SizedBox.square(
            dimension: 36,
            child: Center(
              child: Text(
                '$order',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.textInverse),
              ),
            ),
          ),
        ),
        const Icon(Icons.location_on, color: AppColors.primaryPink),
      ],
    );
  }
}

class _CurrentLocationDot extends StatelessWidget {
  const _CurrentLocationDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentBlue,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.bgDefault, width: 4),
      ),
      child: const SizedBox.square(dimension: 24),
    );
  }
}

class _RecommendationSheet extends StatelessWidget {
  const _RecommendationSheet({
    required this.controller,
    required this.onAddPressed,
  });

  final ScrollController controller;
  final VoidCallback onAddPressed;

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
          AppSpacing.xl,
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
          Text('추천 장소', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '검색하거나 지도로 이동해 후보를 추가해요',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final candidate in demoPlaceCandidates) ...[
            _RecommendationTile(
              candidate: candidate,
              onAddPressed: onAddPressed,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            '4명이 함께 정하고 있어요',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.candidate,
    required this.onAddPressed,
  });

  final PlaceCandidate candidate;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgGrid,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const SizedBox.square(
              dimension: 58,
              child: Icon(
                Icons.photo_camera_outlined,
                color: AppColors.textSub,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${candidate.category} · ${candidate.travelTimeLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(candidate.tags.take(2).join(' · ')),
              ],
            ),
          ),
          IconButton.outlined(
            tooltip: '후보 추가',
            onPressed: onAddPressed,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
