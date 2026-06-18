import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/vote_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../view_model/vote_view_model.dart';

class GroupVoteListPage extends StatefulWidget {
  const GroupVoteListPage({required this.groupId, super.key, this.planId});

  final String groupId;
  final String? planId;

  @override
  State<GroupVoteListPage> createState() => _GroupVoteListPageState();
}

class _GroupVoteListPageState extends State<GroupVoteListPage> {
  var _selectedFilter = VoteFilter.all;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(
          voteListViewModelProvider((
            groupId: widget.groupId,
            planId: widget.planId,
          )),
        );

        return state.when(
          data: (state) => _VoteListContent(
            state: state,
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) => setState(() {
              _selectedFilter = filter;
            }),
          ),
          loading: () => const OnmuScaffold(
            title: '투표 목록',
            children: [Center(child: CircularProgressIndicator())],
          ),
          error: (error, stackTrace) => OnmuScaffold(
            title: '투표 목록',
            children: [
              Text(
                '투표 목록을 불러오지 못했어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VoteListContent extends StatelessWidget {
  const _VoteListContent({
    required this.state,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final VoteListState state;
  final VoteFilter selectedFilter;
  final ValueChanged<VoteFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final group = state.group;
    final ongoingVotes = state.votes
        .where((vote) => !vote.closed)
        .where((vote) => selectedFilter.matches(vote))
        .toList();
    final closedVotes = state.votes
        .where((vote) => vote.closed)
        .where((vote) => selectedFilter.matches(vote))
        .toList();

    return OnmuScaffold(
      title: '투표 목록',
      showBackButton: true,
      onBack: () => context.popOrGo(
        state.planId == 0
            ? RoutePaths.groupChat(group.id)
            : RoutePaths.planDetail(group.id, state.planId),
      ),
      action: state.planId == 0
          ? null
          : IconButton(
              tooltip: '투표 만들기',
              onPressed: () =>
                  context.push(RoutePaths.planVoteNew(group.id, state.planId)),
              icon: const Icon(Icons.add_circle_outline),
            ),
      useWarmBackground: false,
      children: [
        Text(
          state.planId == 0 ? '${group.name} · 모임 투표' : '${group.name} · 약속 투표',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in VoteFilter.values) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  onTap: () => onFilterChanged(filter),
                  child: OnmuChip(
                    label: filter.label,
                    icon: filter.icon,
                    selected: selectedFilter == filter,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (ongoingVotes.isNotEmpty) ...[
          _SectionHeader(
            title: '진행 중인 투표',
            metaLabel: '${ongoingVotes.length}개',
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final vote in ongoingVotes) ...[
            _VoteSummaryCard(
              vote: vote,
              onTap: () =>
                  context.push(_votePath(group.id, state.planId, vote)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (closedVotes.isNotEmpty) ...[
          _SectionHeader(title: '지난 투표', metaLabel: '${closedVotes.length}개'),
          const SizedBox(height: AppSpacing.sm),
          for (final vote in closedVotes) ...[
            _ClosedVoteRow(
              vote: vote,
              onTap: () =>
                  context.push(_votePath(group.id, state.planId, vote)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        if (ongoingVotes.isEmpty && closedVotes.isEmpty)
          _EmptyVoteState(filterLabel: selectedFilter.label),
        _VoteListHint(
          onTap: () => context.popOrGo(RoutePaths.groupChat(group.id)),
        ),
      ],
    );
  }

  String _votePath(Object groupId, int planId, VoteSummary vote) {
    final targetPlanId = _targetPlanId(vote);
    if (targetPlanId != null) {
      return RoutePaths.planVote(groupId, targetPlanId, vote.id);
    }
    if (planId <= 0) {
      return RoutePaths.groupVote(groupId, vote.id);
    }
    return RoutePaths.planVote(groupId, planId, vote.id);
  }

  Object? _targetPlanId(VoteSummary vote) {
    if (vote.targetType.trim().toUpperCase() != 'PLAN') {
      return null;
    }
    final targetId = vote.targetId.trim();
    return targetId.isEmpty ? null : targetId;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.metaLabel});

  final String title;
  final String metaLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Text(
          metaLabel,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primaryPink),
        ),
      ],
    );
  }
}

class _VoteSummaryCard extends StatelessWidget {
  const _VoteSummaryCard({required this.vote, required this.onTap});

  final VoteSummary vote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _VoteIconBadge(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vote.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        OnmuChip(
                          label: vote.statusLabel,
                          selected: true,
                          icon: vote.closed
                              ? Icons.check_circle_outline
                              : Icons.hourglass_bottom_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      vote.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _LinkedPlanInfo(vote: vote),
          const SizedBox(height: AppSpacing.md),
          for (final option in vote.options.take(3)) ...[
            _VoteOptionProgress(option: option),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _ParticipantStack(names: vote.participants),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: onTap,
                icon: const Icon(Icons.how_to_vote_outlined, size: 16),
                label: Text(vote.actionLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteIconBadge extends StatelessWidget {
  const _VoteIconBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPinkSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.linePink),
      ),
      child: const SizedBox.square(
        dimension: 40,
        child: Icon(Icons.how_to_vote_outlined, color: AppColors.primaryPink),
      ),
    );
  }
}

class _LinkedPlanInfo extends StatelessWidget {
  const _LinkedPlanInfo({required this.vote});

  final VoteSummary vote;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.lineWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.event_note_outlined, color: AppColors.primaryPink),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vote.planLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    vote.planMeta,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
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

class _VoteOptionProgress extends StatelessWidget {
  const _VoteOptionProgress({required this.option});

  final VoteOptionSummary option;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Text(
              option.countLabel,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.primaryPink),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: option.progress,
            minHeight: 7,
            backgroundColor: AppColors.primaryPinkSoft,
            color: AppColors.primaryPink,
          ),
        ),
      ],
    );
  }
}

class _ParticipantStack extends StatelessWidget {
  const _ParticipantStack({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      width: 24 + names.take(4).length * 18,
      child: Stack(
        children: [
          for (var index = 0; index < names.take(4).length; index += 1)
            Positioned(
              left: index * 18,
              child: PixelAvatar(label: names[index], size: 30),
            ),
        ],
      ),
    );
  }
}

class _ClosedVoteRow extends StatelessWidget {
  const _ClosedVoteRow({required this.vote, required this.onTap});

  final VoteSummary vote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vote.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  vote.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          OnmuChip(label: vote.statusLabel),
        ],
      ),
    );
  }
}

class _EmptyVoteState extends StatelessWidget {
  const _EmptyVoteState({required this.filterLabel});

  final String filterLabel;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineSoft,
      child: Column(
        children: [
          const Icon(
            Icons.how_to_vote_outlined,
            size: 42,
            color: AppColors.primaryPink,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$filterLabel 투표가 아직 없어요',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '채팅에서 공유된 투표가 생기면 여기에 모아볼게요.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

class _VoteListHint extends StatelessWidget {
  const _VoteListHint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.primaryPinkSoft,
      borderColor: AppColors.linePink,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '채팅에 올라온 투표를 한곳에서 다시 볼 수 있어요.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.primaryPink),
        ],
      ),
    );
  }
}
