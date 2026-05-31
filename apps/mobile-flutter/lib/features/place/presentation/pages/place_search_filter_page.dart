import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/place_candidate_card.dart';

class PlaceSearchFilterPage extends StatelessWidget {
  const PlaceSearchFilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '장소 검색',
      subtitle: '원하는 분위기와 피하고 싶은 조건을 작은 스티커처럼 고릅니다.',
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: '성수역, 조용한 카페, 디저트',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: '검색어 지우기',
              onPressed: () {},
              icon: const Icon(Icons.close),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _FilterSection(
          title: '장소 분위기',
          chips: ['조용함', '사진 잘 나옴', '예약 가능', '역 근처'],
          selectedIndexes: [0, 1],
        ),
        const SizedBox(height: AppSpacing.md),
        const _FilterSection(
          title: '피하고 싶은 조건',
          chips: ['브레이크타임', '매운 메뉴', '웨이팅', '견과류'],
          selectedIndexes: [0, 2],
        ),
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          backgroundColor: AppColors.bgPaper,
          borderColor: AppColors.lineWarm,
          child: Row(
            children: [
              const Icon(Icons.favorite_outline, color: AppColors.primaryPink),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '민서와 하린의 카페 취향을 우선 반영 중이에요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('검색 결과', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final candidate in demoPlaceCandidates.take(2)) ...[
          PlaceCandidateCard(
            candidate: candidate,
            compact: true,
            onDetailPressed: () =>
                context.go('/meetups/demo/places/${candidate.id}'),
            onSelectPressed: () => context.go(RoutePaths.placeCompare),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        OnmuSecondaryButton(
          label: '추천 후보로 돌아가기',
          icon: Icons.arrow_back,
          onPressed: () => context.go(RoutePaths.placeCandidates),
        ),
      ],
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.chips,
    required this.selectedIndexes,
  });

  final String title;
  final List<String> chips;
  final List<int> selectedIndexes;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnmuStickerLabel(label: title, icon: Icons.sell_outlined),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (var index = 0; index < chips.length; index += 1)
                OnmuChip(
                  label: chips[index],
                  selected: selectedIndexes.contains(index),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
