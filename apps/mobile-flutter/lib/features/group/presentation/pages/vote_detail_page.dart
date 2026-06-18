import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/models/vote_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/vote_view_model.dart';

class VoteDetailPage extends ConsumerWidget {
  const VoteDetailPage({
    required this.groupId,
    required this.voteId,
    super.key,
    this.planId,
  });

  final String groupId;
  final String voteId;
  final String? planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      voteDetailViewModelProvider((
        groupId: groupId,
        voteId: voteId,
        planId: planId,
      )),
    );

    return state.when(
      data: (state) {
        final provider = voteDetailViewModelProvider((
          groupId: groupId,
          voteId: voteId,
          planId: planId,
        ));
        return _VoteDetailContent(
          groupId: groupId,
          planId: planId,
          state: state,
          onVotePressed: (optionId) =>
              ref.read(provider.notifier).submitVote(optionId),
        );
      },
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
  const _VoteDetailContent({
    required this.groupId,
    required this.state,
    required this.onVotePressed,
    this.planId,
  });

  final String groupId;
  final String? planId;
  final VoteDetailState state;
  final Future<void> Function(String optionId) onVotePressed;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '투표 보기',
      showBackButton: true,
      onBack: () => context.popOrGo(
        planId == null
            ? RoutePaths.groupChat(groupId)
            : RoutePaths.planVotes(groupId, planId!),
      ),
      children: [
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.linePink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OnmuChip(
                    label: state.vote.displayStatusLabel,
                    selected: true,
                  ),
                  const Spacer(),
                  Text(
                    state.vote.participantCountLabel,
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
            voteCount: state.voteCountFor(state.candidates[index].id),
            option: state.optionForCandidate(state.candidates[index].id),
            selectedByMe: state.isSelectedCandidate(state.candidates[index].id),
            joinedByMe: state.vote.joinedByMe,
            closed: state.vote.displayStatusLabel == '마감',
            onVotePressed: onVotePressed,
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
    required this.voteCount,
    required this.option,
    required this.selectedByMe,
    required this.joinedByMe,
    required this.closed,
    required this.onVotePressed,
  });

  final PlaceCandidate candidate;
  final int rank;
  final List<String> voters;
  final int voteCount;
  final VoteOptionSummary? option;
  final bool selectedByMe;
  final bool joinedByMe;
  final bool closed;
  final Future<void> Function(String optionId) onVotePressed;

  @override
  Widget build(BuildContext context) {
    final selected = selectedByMe || voteCount > 0 || voters.isNotEmpty;
    final canVote = !closed && option?.id.trim().isNotEmpty == true;

    return OnmuCard(
      onTap: canVote ? () => _submit(context) : null,
      backgroundColor: selectedByMe
          ? AppColors.primaryPinkSoft
          : selected
          ? AppColors.bgPaper
          : AppColors.bgDefault,
      borderColor: selectedByMe ? AppColors.linePink : AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: selectedByMe
                      ? AppColors.primaryPink
                      : AppColors.bgGrid,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: SizedBox.square(
                  dimension: 34,
                  child: Center(
                    child: Text(
                      '$rank',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selectedByMe
                            ? AppColors.textInverse
                            : AppColors.textSub,
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
                      candidate.categoryTravelLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (selectedByMe)
                          const OnmuChip(label: '내 선택', selected: true),
                        if (voters.isEmpty && voteCount == 0)
                          const OnmuChip(label: '아직 선택한 사람이 없어요')
                        else if (voters.isEmpty)
                          OnmuChip(label: '$voteCount명 선택', selected: true)
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
                '$voteCount표',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? AppColors.primaryPink : AppColors.textSub,
                ),
              ),
            ],
          ),
          if (canVote) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: selectedByMe ? null : () => _submit(context),
                icon: Icon(
                  selectedByMe ? Icons.check_circle : Icons.how_to_vote,
                  size: 18,
                ),
                label: Text(
                  selectedByMe
                      ? '선택됨'
                      : joinedByMe
                      ? '다시 투표하기'
                      : '투표하기',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final optionId = option?.id.trim() ?? '';
    if (optionId.isEmpty || selectedByMe) {
      return;
    }
    try {
      await onVotePressed(optionId);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('투표를 저장하지 못했어요.')));
    }
  }
}
