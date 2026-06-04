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
import '../widgets/place_candidate_card.dart';

class PlaceSearchFilterPage extends StatelessWidget {
  const PlaceSearchFilterPage({
    required this.onmoimId,
    required this.meetupId,
    super.key,
  });

  final String onmoimId;
  final String meetupId;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '장소 검색하기',
      subtitle: '지도 화면에서 이어서 장소를 찾아요',
      children: [
        TextFormField(
          initialValue: '홍대 조용한 한식',
          decoration: InputDecoration(
            hintText: '장소명, 지역, 태그 검색',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: '검색어 지우기',
              onPressed: () {},
              icon: const Icon(Icons.close),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _FilterSection(
          title: '카테고리',
          chips: ['전체', '한식', '카페', '전시', '술집'],
          selectedIndexes: [0],
        ),
        const SizedBox(height: AppSpacing.md),
        const _FilterSection(
          title: '조건',
          chips: ['영업중', '브레이크타임 제외', '고위험 제외', '도보 15분'],
          selectedIndexes: [0, 1],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('검색 결과 24개', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final candidate in demoPlaceCandidates.take(2)) ...[
          PlaceCandidateCard(
            candidate: candidate,
            compact: true,
            onDetailPressed: () => context.go(
              RoutePaths.onmoimMeetupPlaceDetail(
                onmoimId,
                meetupId,
                candidate.id,
              ),
            ),
            onRegisterPressed: () => context.go(
              '${RoutePaths.onmoimMeetupDetail(onmoimId, meetupId)}?place=confirmed',
            ),
            onAddCandidatePressed: () =>
                context.go(RoutePaths.onmoimMeetupPlaces(onmoimId, meetupId)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        OnmuSecondaryButton(
          label: '추천 후보로 돌아가기',
          icon: Icons.arrow_back,
          onPressed: () =>
              context.go(RoutePaths.onmoimMeetupPlaces(onmoimId, meetupId)),
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
          Text(title, style: Theme.of(context).textTheme.titleSmall),
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
