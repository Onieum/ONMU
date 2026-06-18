import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/group_plan_board_view_model.dart';

class GroupPlanBoardPage extends ConsumerWidget {
  const GroupPlanBoardPage({
    required this.groupId,
    required this.planId,
    super.key,
  });

  final String groupId;
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      groupPlanBoardViewModelProvider((groupId: groupId, planId: planId)),
    );

    return state.when(
      data: (state) => _GroupPlanBoardContent(
        groupId: groupId,
        planId: planId,
        state: state,
      ),
      loading: () => const OnmuScaffold(
        title: '약속 보드',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '약속 보드',
        children: [
          Text(
            '약속 보드를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GroupPlanBoardContent extends StatelessWidget {
  const _GroupPlanBoardContent({
    required this.groupId,
    required this.planId,
    required this.state,
  });

  final String groupId;
  final String planId;
  final GroupPlanBoardState state;

  @override
  Widget build(BuildContext context) {
    final subtitle = state.subtitle;
    final hasVote = state.voteId > 0;

    return OnmuScaffold(
      title: '약속 보드',
      subtitle: subtitle.isEmpty ? null : subtitle,
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OnmuPrimaryButton(
            label: '최종 장소 확정하기',
            icon: Icons.check_circle_outline,
            color: AppColors.primaryPink,
            onPressed: () => context.go(RoutePaths.planDetail(groupId, planId)),
          ),
        ),
      ),
      children: [
        _BoardNoticeCard(
          title: state.boardTitle,
          badgeLabel: state.noticeBadgeLabel,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text('장소 후보', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.xs),
            OnmuChip(label: '${state.candidateResults.length}', selected: true),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (
          var index = 0;
          index < state.candidateResults.length;
          index += 1
        ) ...[
          _VoteCard(rank: index + 1, result: state.candidateResults[index]),
          const SizedBox(height: AppSpacing.md),
        ],
        _ParticipantResponseCard(responses: state.participantResponses),
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          backgroundColor: AppColors.bgPaper,
          borderColor: AppColors.lineWarm,
          child: Row(
            children: [
              const OnmuStickerLabel(label: '투표 결과', icon: Icons.edit_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  state.voteDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OnmuSecondaryButton(
          label: state.voteActionLabel,
          icon: hasVote ? Icons.how_to_vote_outlined : Icons.info_outline,
          onPressed: hasVote
              ? () => context.go(
                  RoutePaths.planVote(groupId, planId, state.voteId),
                )
              : null,
        ),
      ],
    );
  }
}

class _BoardNoticeCard extends StatelessWidget {
  const _BoardNoticeCard({required this.title, required this.badgeLabel});

  final String title;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, color: AppColors.accentOrange),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '마음에 드는 장소에 투표해 주세요!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          OnmuChip(label: badgeLabel, selected: true),
        ],
      ),
    );
  }
}

class _VoteCard extends StatelessWidget {
  const _VoteCard({required this.rank, required this.result});

  final int rank;
  final GroupPlanBoardCandidateResult result;

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1;
    final candidate = result.candidate;

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: isTop ? AppColors.linePink : AppColors.lineSoft,
      child: Row(
        children: [
          _RankBadge(rank: rank),
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
                    Text(
                      result.voteCountLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  candidate.categoryDistanceLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: result.progress,
                  minHeight: 8,
                  backgroundColor: AppColors.primaryPinkSoft,
                  color: AppColors.primaryPink,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  result.progressLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantResponseCard extends StatelessWidget {
  const _ParticipantResponseCard({required this.responses});

  final List<GroupPlanParticipantResponse> responses;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('참여자 응답', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (responses.isEmpty)
            Text(
              '참여자 정보를 불러오지 못했어요.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Row(
              children: [
                for (var index = 0; index < responses.length; index += 1) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(child: _ResponseTile(response: responses[index])),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ResponseTile extends StatelessWidget {
  const _ResponseTile({required this.response});

  final GroupPlanParticipantResponse response;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: response.selected
            ? AppColors.primaryPinkSoft
            : AppColors.bgDefault,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: response.selected ? AppColors.linePink : AppColors.lineSoft,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Text(response.label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              response.count.toString(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppColors.primaryPink,
      foregroundColor: AppColors.textInverse,
      child: Text('$rank'),
    );
  }
}
