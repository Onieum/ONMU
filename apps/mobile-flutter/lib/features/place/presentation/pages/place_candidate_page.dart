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
import '../widgets/place_candidate_card.dart';

class PlaceCandidatePage extends StatelessWidget {
  const PlaceCandidatePage({super.key, this.showVoteResult = false});

  final bool showVoteResult;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '장소 후보',
      subtitle: '홍대 토요일 저녁 · 5월 31일 토요일 18:00',
      actions: [
        IconButton(
          tooltip: '장소 옵션',
          onPressed: () {},
          icon: const Icon(Icons.more_horiz),
        ),
      ],
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OnmuPrimaryButton(
            label: '+ 후보 비교',
            icon: Icons.compare_arrows,
            color: AppColors.primaryPurple,
            foregroundColor: AppColors.textInverse,
            onPressed: () => context.go(RoutePaths.placeCompare),
          ),
        ),
      ),
      children: [
        if (showVoteResult) ...[
          const _VoteResultCarryoverCard(),
          const SizedBox(height: AppSpacing.md),
        ],
        const _PlaceSegmentTabs(),
        const SizedBox(height: AppSpacing.md),
        const _MapPreviewCard(),
        const SizedBox(height: AppSpacing.md),
        _PlaceSearchRow(
          onSearchPressed: () => context.go(RoutePaths.placeSearch),
          onFilterPressed: () => context.go(RoutePaths.placeSearch),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text('추천 후보', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.go(RoutePaths.placeSearch),
              icon: const Icon(Icons.chevron_right),
              label: const Text('24개 보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final candidate in demoPlaceCandidates.take(2)) ...[
          PlaceCandidateCard(
            candidate: candidate,
            onDetailPressed: () {
              context.go('/meetups/demo/places/${candidate.id}');
            },
            onSelectPressed: () => context.go(RoutePaths.placeCompare),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        OnmuSecondaryButton(
          label: '운영 리스크 확인',
          icon: Icons.warning_amber,
          onPressed: () => context.go(RoutePaths.placeRisks),
        ),
      ],
    );
  }
}

class _PlaceSegmentTabs extends StatelessWidget {
  const _PlaceSegmentTabs();

  @override
  Widget build(BuildContext context) {
    const tabs = ['일정', '장소', '상태', '기록'];

    return OnmuCard(
      padding: const EdgeInsets.all(AppSpacing.xs),
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tab == '장소'
                      ? AppColors.primaryPurple
                      : AppColors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    tab,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: tab == '장소'
                          ? AppColors.textInverse
                          : AppColors.textSub,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnmuStickerLabel(label: '지도 미리보기', icon: Icons.map_outlined),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 118,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bgGrid,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lineSoft),
                    ),
                    child: CustomPaint(painter: _MapPreviewPainter()),
                  ),
                ),
                const Positioned(
                  left: 68,
                  top: 28,
                  child: _MapPin(label: '온무식당', selected: true),
                ),
                const Positioned(
                  right: 28,
                  bottom: 24,
                  child: _MapPin(label: '무드카페'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '홍대입구역 기준 도보 5-11분 후보를 모았어요.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PlaceSearchRow extends StatelessWidget {
  const _PlaceSearchRow({
    required this.onSearchPressed,
    required this.onFilterPressed,
  });

  final VoidCallback onSearchPressed;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OnmuCard(
            onTap: onSearchPressed,
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
                    '장소명, 지역, 태그 검색',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filledTonal(
          tooltip: '필터',
          onPressed: onFilterPressed,
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }
}

class _VoteResultCarryoverCard extends StatelessWidget {
  const _VoteResultCarryoverCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnmuTape(width: 76),
          const SizedBox(height: AppSpacing.xs),
          Text(
            demoPlaceVoteResult.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${demoPlaceVoteResult.selectedPlaceName}에 ${demoPlaceVoteResult.voters.length}명이 투표했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            demoPlaceVoteResult.note,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPurple : AppColors.bgDefault,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.primaryPurpleDark : AppColors.lineBrown,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? AppColors.textInverse : AppColors.textMain,
          ),
        ),
      ),
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lineSoft
      ..strokeWidth = 1.4;

    for (var x = 24.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x + 34, size.height), paint);
    }
    for (var y = 20.0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 10), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
