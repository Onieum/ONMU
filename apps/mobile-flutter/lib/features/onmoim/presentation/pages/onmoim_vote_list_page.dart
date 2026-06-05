import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class OnMoimVoteListPage extends StatefulWidget {
  const OnMoimVoteListPage({required this.onmoimId, super.key});

  final String onmoimId;

  @override
  State<OnMoimVoteListPage> createState() => _OnMoimVoteListPageState();
}

class _OnMoimVoteListPageState extends State<OnMoimVoteListPage> {
  var _selectedFilter = _VoteFilter.all;

  @override
  Widget build(BuildContext context) {
    final group = demoOnMoimGroups.firstWhere(
      (group) => group.id == widget.onmoimId,
      orElse: () => demoOnMoimGroups.first,
    );
    final ongoingVotes = _demoVoteSummaries
        .where((vote) => !vote.closed)
        .where((vote) => _selectedFilter.matches(vote))
        .toList();
    final closedVotes = _demoVoteSummaries
        .where((vote) => vote.closed)
        .where((vote) => _selectedFilter.matches(vote))
        .toList();

    return OnmuScaffold(
      title: '투표 목록',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go(RoutePaths.onmoimChat(widget.onmoimId));
      },
      action: IconButton(
        tooltip: '투표 만들기',
        onPressed: () => context.push(
          RoutePaths.onmoimMeetupPlaceVoteNew(widget.onmoimId, 'demo'),
        ),
        icon: const Icon(Icons.add_circle_outline),
      ),
      useWarmBackground: false,
      children: [
        Text(
          '${group.name} · 채팅에서 만든 투표',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in _VoteFilter.values) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: OnmuChip(
                    label: filter.label,
                    icon: filter.icon,
                    selected: _selectedFilter == filter,
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
                  context.push(RoutePaths.onmoimVote(widget.onmoimId, vote.id)),
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
                  context.push(RoutePaths.onmoimVote(widget.onmoimId, vote.id)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        if (ongoingVotes.isEmpty && closedVotes.isEmpty)
          _EmptyVoteState(filterLabel: _selectedFilter.label),
        _VoteListHint(onTap: () => context.go(RoutePaths.onmoimChat(group.id))),
      ],
    );
  }
}

enum _VoteFilter {
  all('전체', Icons.favorite_outlined),
  ongoing('진행 중', Icons.hourglass_bottom_outlined),
  closed('마감', Icons.check_circle_outline),
  mine('내가 참여', Icons.person_outline);

  const _VoteFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  bool matches(_VoteSummary vote) {
    return switch (this) {
      _VoteFilter.all => true,
      _VoteFilter.ongoing => !vote.closed,
      _VoteFilter.closed => vote.closed,
      _VoteFilter.mine => vote.joinedByMe,
    };
  }
}

class _VoteSummary {
  const _VoteSummary({
    required this.id,
    required this.title,
    required this.statusLabel,
    required this.description,
    required this.meetupLabel,
    required this.meetupMeta,
    required this.participants,
    required this.options,
    required this.closed,
    required this.joinedByMe,
    required this.actionLabel,
  });

  final String id;
  final String title;
  final String statusLabel;
  final String description;
  final String meetupLabel;
  final String meetupMeta;
  final List<String> participants;
  final List<_VoteOptionSummary> options;
  final bool closed;
  final bool joinedByMe;
  final String actionLabel;
}

class _VoteOptionSummary {
  const _VoteOptionSummary({
    required this.label,
    required this.countLabel,
    required this.progress,
  });

  final String label;
  final String countLabel;
  final double progress;
}

const _demoVoteSummaries = [
  _VoteSummary(
    id: 'demo',
    title: '제주도 여행 장소 투표',
    statusLabel: '진행 중',
    description: '카페 오션뷰 외 2곳 · 4명 참여',
    meetupLabel: '제주도 여행',
    meetupMeta: '6.7 - 6.9 · 제주도 일대',
    participants: ['지민', '민수', '하린', '현우'],
    options: [
      _VoteOptionSummary(label: '카페 오션뷰', countLabel: '3표', progress: 0.78),
      _VoteOptionSummary(label: '흑돼지 맛집 돈사돈', countLabel: '2표', progress: 0.56),
      _VoteOptionSummary(label: '협재 해수욕장', countLabel: '1표', progress: 0.32),
    ],
    closed: false,
    joinedByMe: true,
    actionLabel: '투표 확인하기',
  ),
  _VoteSummary(
    id: 'seongsu-time',
    title: '성수 카페 투어 시간 정하기',
    statusLabel: '오늘 마감',
    description: '오후 2시 / 4시 / 6시 · 5명 참여',
    meetupLabel: '성수 카페 투어',
    meetupMeta: '6.5 오후 2:00 · 성수동 일대',
    participants: ['지연', '민수', '하린'],
    options: [
      _VoteOptionSummary(label: '오후 2시', countLabel: '3표', progress: 0.64),
      _VoteOptionSummary(label: '오후 4시', countLabel: '2표', progress: 0.46),
    ],
    closed: false,
    joinedByMe: false,
    actionLabel: '결과 보기',
  ),
  _VoteSummary(
    id: 'picnic-menu',
    title: '한강 피크닉 메뉴',
    statusLabel: '마감',
    description: '김밥과 샌드위치가 최종 선택됐어요',
    meetupLabel: '한강 피크닉',
    meetupMeta: '5.10 오후 1:00 · 여의도 한강공원',
    participants: ['지민', '하린', '현우'],
    options: [
      _VoteOptionSummary(label: '김밥', countLabel: '4표', progress: 0.86),
      _VoteOptionSummary(label: '샌드위치', countLabel: '3표', progress: 0.68),
    ],
    closed: true,
    joinedByMe: true,
    actionLabel: '결과 보기',
  ),
  _VoteSummary(
    id: 'board-place',
    title: '보드게임 모임 장소',
    statusLabel: '마감',
    description: '홍대 보드게임카페로 정했어요',
    meetupLabel: '보드게임 모임',
    meetupMeta: '5.5 오후 6:00 · 홍대 일대',
    participants: ['민서', '지훈'],
    options: [
      _VoteOptionSummary(label: '홍대 보드게임카페', countLabel: '5표', progress: 0.92),
      _VoteOptionSummary(label: '연남동 카페', countLabel: '2표', progress: 0.34),
    ],
    closed: true,
    joinedByMe: false,
    actionLabel: '결과 보기',
  ),
];

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

  final _VoteSummary vote;
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
          _LinkedMeetupInfo(vote: vote),
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

class _LinkedMeetupInfo extends StatelessWidget {
  const _LinkedMeetupInfo({required this.vote});

  final _VoteSummary vote;

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
                    vote.meetupLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    vote.meetupMeta,
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

  final _VoteOptionSummary option;

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

  final _VoteSummary vote;
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
