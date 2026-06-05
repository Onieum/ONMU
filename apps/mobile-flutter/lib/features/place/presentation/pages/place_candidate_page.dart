import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../view_model/place_candidates_view_model.dart';

class PlaceCandidatePage extends ConsumerWidget {
  const PlaceCandidatePage({
    required this.groupId,
    required this.planId,
    super.key,
    this.showVoteResult = false,
  });

  final String groupId;
  final String planId;
  final bool showVoteResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = placeCandidatesViewModelProvider((
      groupId: groupId,
      planId: planId,
    ));
    final state = ref.watch(provider);

    return state.when(
      data: (state) => _PlaceCandidateContent(
        groupId: groupId,
        planId: planId,
        showVoteResult: showVoteResult,
        state: state,
        onFavoritePressed: (candidateId) {
          ref.read(provider.notifier).toggleFavorite(candidateId);
        },
      ),
      loading: () => const OnmuScaffold(
        title: '장소 후보 리스트',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '장소 후보 리스트',
        children: [
          Text(
            '장소 후보를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PlaceCandidateContent extends StatelessWidget {
  const _PlaceCandidateContent({
    required this.groupId,
    required this.planId,
    required this.showVoteResult,
    required this.state,
    required this.onFavoritePressed,
  });

  final String groupId;
  final String planId;
  final bool showVoteResult;
  final PlaceCandidatesState state;
  final ValueChanged<int> onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '장소 후보 리스트',
      showBackButton: true,
      onBack: () => context.pop(),
      action: TextButton(
        onPressed: () => context.push(RoutePaths.planVoteNew(groupId, planId)),
        child: const Text('투표 만들기'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '후보 추가',
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        shape: const CircleBorder(),
        onPressed: () =>
            context.push(RoutePaths.planPlaceSearch(groupId, planId)),
        child: const Icon(Icons.add),
      ),
      bottom: OnmuCard(
        backgroundColor: AppColors.bgPaper,
        borderColor: AppColors.lineWarm,
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: AppColors.accentOrange),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '약속 멤버가 함께 모은 장소 후보예요',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      children: [
        _HeaderRow(showVoteResult: showVoteResult),
        const SizedBox(height: AppSpacing.md),
        const _CategoryChips(),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < state.candidates.length; index += 1) ...[
          _CandidateListCard(
            order: index + 1,
            candidate: state.candidates[index],
            liked: state.isLiked(state.candidates[index].id),
            favoriteCount: state.favoriteCountFor(state.candidates[index].id),
            onFavoritePressed: () =>
                onFavoritePressed(state.candidates[index].id),
            onDetailPressed: () => context.push(
              RoutePaths.planPlaceCandidateDetail(
                groupId,
                planId,
                state.candidates[index].id,
              ),
            ),
            onRegisterPressed: () => _goConfirmed(context),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: 72),
      ],
    );
  }

  void _goConfirmed(BuildContext context) {
    context.go(RoutePaths.planItinerary(groupId, planId));
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.showVoteResult});

  final bool showVoteResult;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: const [
            OnmuChip(label: '제주도 여행'),
            OnmuChip(label: '제주도 일대'),
          ],
        ),
        if (showVoteResult) ...[
          const SizedBox(height: AppSpacing.sm),
          OnmuCard(
            backgroundColor: AppColors.bgDefault,
            borderColor: AppColors.linePink,
            child: Text(
              '온모임 투표 결과를 후보 리스트에 이어서 보여줘요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text('참여자 4명', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: const [
            PixelAvatar(label: '지우', size: 36),
            SizedBox(width: AppSpacing.sm),
            PixelAvatar(label: '민수', size: 36),
            SizedBox(width: AppSpacing.sm),
            PixelAvatar(label: '하린', size: 36),
            SizedBox(width: AppSpacing.sm),
            PixelAvatar(label: '현우', size: 36),
          ],
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    final categories = ['전체', '카페', '식사', '관광', '숙소'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < categories.length; index += 1) ...[
            OnmuChip(label: categories[index], selected: index == 1),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _CandidateListCard extends StatelessWidget {
  const _CandidateListCard({
    required this.order,
    required this.candidate,
    required this.liked,
    required this.favoriteCount,
    required this.onFavoritePressed,
    required this.onDetailPressed,
    required this.onRegisterPressed,
  });

  final int order;
  final PlaceCandidate candidate;
  final bool liked;
  final int favoriteCount;
  final VoidCallback onFavoritePressed;
  final VoidCallback onDetailPressed;
  final VoidCallback onRegisterPressed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onDetailPressed,
      backgroundColor: liked ? AppColors.primaryPinkSoft : AppColors.bgDefault,
      borderColor: liked ? AppColors.linePink : AppColors.lineSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPink,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: SizedBox.square(
              dimension: 28,
              child: Center(
                child: Text(
                  '$order',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        candidate.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          tooltip: liked ? '하트 취소' : '하트',
                          onPressed: onFavoritePressed,
                          icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            color: AppColors.accentRed,
                          ),
                        ),
                        Text(
                          '$favoriteCount',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '${candidate.category} · ${candidate.tags.take(2).join(' · ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  candidate.summary,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onRegisterPressed,
                    child: const Text('일정에 등록'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
