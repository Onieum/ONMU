import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/place_candidates_view_model.dart';
import '../widgets/place_candidate_card.dart';

class PlaceSearchFilterPage extends ConsumerWidget {
  const PlaceSearchFilterPage({
    required this.groupId,
    required this.planId,
    super.key,
  });

  final String groupId;
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      placeCandidatesViewModelProvider((groupId: groupId, planId: planId)),
    );

    return state.when(
      data: (state) => _PlaceSearchFilterContent(
        groupId: groupId,
        planId: planId,
        candidates: state.candidates,
      ),
      loading: () => const OnmuScaffold(
        title: '장소 검색하기',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '장소 검색하기',
        children: [
          Text(
            '검색 결과를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PlaceSearchFilterContent extends StatelessWidget {
  const _PlaceSearchFilterContent({
    required this.groupId,
    required this.planId,
    required this.candidates,
  });

  final String groupId;
  final String planId;
  final List<PlaceCandidate> candidates;

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
            Text(
              '검색 결과 ${candidates.length}개',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final candidate in candidates.take(2)) ...[
          PlaceCandidateCard(
            candidate: candidate,
            compact: true,
            onDetailPressed: () => context.go(
              RoutePaths.planPlaceCandidateDetail(
                groupId,
                planId,
                candidate.id,
              ),
            ),
            onRegisterPressed: () =>
                context.go(RoutePaths.planItinerary(groupId, planId)),
            onAddCandidatePressed: () =>
                context.go(RoutePaths.planPlaceCandidates(groupId, planId)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        OnmuSecondaryButton(
          label: '추천 후보로 돌아가기',
          icon: Icons.arrow_back,
          onPressed: () =>
              context.go(RoutePaths.planPlaceCandidates(groupId, planId)),
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
