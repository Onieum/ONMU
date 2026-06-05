import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/vote_view_model.dart';

class VoteDetailPage extends ConsumerWidget {
  const VoteDetailPage({
    required this.groupId,
    required this.voteId,
    super.key,
  });

  final String groupId;
  final String voteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      voteDetailViewModelProvider((groupId: groupId, voteId: voteId)),
    );

    return state.when(
      data: (state) => _VoteDetailContent(groupId: groupId, state: state),
      loading: () => const OnmuScaffold(
        title: '투표 보기',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '투표 보기',
        children: [
          Text(
            '투표 상세를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _VoteDetailContent extends StatelessWidget {
  const _VoteDetailContent({required this.groupId, required this.state});

  final String groupId;
  final VoteDetailState state;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '투표 보기',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupChat(groupId)),
      children: [
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.linePink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OnmuChip(label: state.vote.statusLabel, selected: true),
                  const Spacer(),
                  Text(
                    '3명 참여',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.vote.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '모임 채팅에서 공유된 장소 투표예요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('후보별 투표 현황', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < state.candidates.length; index += 1) ...[
          _VoteCandidateResult(
            candidate: state.candidates[index],
            rank: index + 1,
            voters: state.votersFor(state.candidates[index].id),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _VoteCandidateResult extends StatelessWidget {
  const _VoteCandidateResult({
    required this.candidate,
    required this.rank,
    required this.voters,
  });

  final PlaceCandidate candidate;
  final int rank;
  final List<String> voters;

  @override
  Widget build(BuildContext context) {
    final selected = voters.isNotEmpty;

    return OnmuCard(
      backgroundColor: selected
          ? AppColors.primaryPinkSoft
          : AppColors.bgDefault,
      borderColor: selected ? AppColors.linePink : AppColors.lineSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryPink : AppColors.bgGrid,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: SizedBox.square(
              dimension: 34,
              child: Center(
                child: Text(
                  '$rank',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? AppColors.textInverse : AppColors.textSub,
                  ),
                ),
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${candidate.category} · ${candidate.travelTimeLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (voters.isEmpty)
                      const OnmuChip(label: '아직 선택한 사람이 없어요')
                    else
                      for (final voter in voters)
                        OnmuChip(label: '$voter님 선택', selected: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${voters.length}표',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: selected ? AppColors.primaryPink : AppColors.textSub,
            ),
          ),
        ],
      ),
    );
  }
}
