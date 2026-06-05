import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onmoim_cards.dart';

class OnMoimThreadPage extends StatefulWidget {
  const OnMoimThreadPage({super.key});

  @override
  State<OnMoimThreadPage> createState() => _OnMoimThreadPageState();
}

class _OnMoimThreadPageState extends State<OnMoimThreadPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<OnMoimMessage> _messages = List.of(demoOnMoimMessages);

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메시지를 입력해 주세요.')));
      return;
    }

    setState(() {
      _messages.add(
        OnMoimMessage(
          sender: '나',
          message: text,
          timeLabel: '방금',
          isMine: true,
        ),
      );
      _messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = demoOnMoimGroups.first;

    return OnmuScaffold(
      title: group.name,
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go(RoutePaths.onmoimDemo);
      },
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '채팅 검색',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('채팅 검색은 다음 단계에서 연결할게요.')),
              );
            },
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<_ChatMenuAction>(
            tooltip: '채팅 메뉴',
            icon: const Icon(Icons.more_vert),
            color: AppColors.bgDefault,
            onSelected: (action) {
              switch (action) {
                case _ChatMenuAction.votes:
                  context.go(RoutePaths.onmoimVotes(group.id));
                case _ChatMenuAction.meetup:
                  context.go(RoutePaths.onmoimMeetupDetail(group.id, 'demo'));
                case _ChatMenuAction.settings:
                  context.go(RoutePaths.onmoimSettings(group.id));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _ChatMenuAction.votes,
                child: _ChatMenuItem(
                  icon: Icons.how_to_vote_outlined,
                  label: '투표 목록',
                ),
              ),
              const PopupMenuItem(
                value: _ChatMenuAction.meetup,
                child: _ChatMenuItem(
                  icon: Icons.event_note_outlined,
                  label: '약속 일정',
                ),
              ),
              const PopupMenuItem(
                value: _ChatMenuAction.settings,
                child: _ChatMenuItem(icon: Icons.tune_outlined, label: '모임 설정'),
              ),
            ],
          ),
        ],
      ),
      bottom: _MessageInput(
        controller: _messageController,
        onSend: _sendMessage,
      ),
      scrollController: _scrollController,
      children: [
        _MeetupChatAnchor(onTap: () => context.go(RoutePaths.onmoimDemoMeetup)),
        const SizedBox(height: AppSpacing.md),
        _VoteNoticeCard(
          vote: demoOnMoimVoteCard,
          onTap: () => context.push(RoutePaths.onmoimVote(group.id, 'demo')),
        ),
        const SizedBox(height: AppSpacing.md),
        _SettlementNoticeCard(
          settlement: demoSettlementSummary,
          onTap: () => context.push(
            RoutePaths.onmoimMeetupSettlementShare(
              group.id,
              'demo',
              demoSettlementSummary.id,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _DateDivider(label: '2024년 6월 2일'),
        const SizedBox(height: AppSpacing.md),
        for (final message in _messages.where(
          (message) => message.sender != 'ONMU',
        )) ...[
          ChatMessageBubble(message: message),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

enum _ChatMenuAction { votes, meetup, settings }

class _ChatMenuItem extends StatelessWidget {
  const _ChatMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryPink),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _MeetupChatAnchor extends StatelessWidget {
  const _MeetupChatAnchor({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.event_note_outlined, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demoPinnedMeetup.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${demoPinnedMeetup.dateLabel} · ${demoPinnedMeetup.placeName}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          OnmuChip(label: demoPinnedMeetup.statusLabel, selected: true),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _VoteNoticeCard extends StatelessWidget {
  const _VoteNoticeCard({required this.vote, required this.onTap});

  final OnMoimVoteCard vote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 336),
        child: OnmuCard(
          backgroundColor: AppColors.bgPaper,
          borderColor: AppColors.linePink,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 18,
                    color: AppColors.primaryPink,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'ONMU 알림',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                vote.summary,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: AppColors.textInverse,
                  minimumSize: const Size.fromHeight(36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                onPressed: onTap,
                icon: const Icon(Icons.place_outlined, size: 16),
                label: Text(vote.actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettlementNoticeCard extends StatelessWidget {
  const _SettlementNoticeCard({required this.settlement, required this.onTap});

  final SettlementSummary settlement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 336),
        child: OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.lineWarm,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: AppColors.primaryPink,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'ONMU 정산',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${settlement.meetupTitle} 정산이 만들어졌어요.',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '총 ${settlement.totalAmountLabel} · ${settlement.finalSummaryLabel}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: AppColors.textInverse,
                  minimumSize: const Size.fromHeight(36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                onPressed: onTap,
                icon: const Icon(Icons.payments_outlined, size: 16),
                label: const Text('정산 확인하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.lineSoft)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(child: Divider(color: AppColors.lineSoft)),
      ],
    );
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.add_circle_outline, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: '메시지를 입력해보세요',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          IconButton(
            tooltip: '전송',
            onPressed: onSend,
            icon: const Icon(Icons.send_outlined),
          ),
        ],
      ),
    );
  }
}
