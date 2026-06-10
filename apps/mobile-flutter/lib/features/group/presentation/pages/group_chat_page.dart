import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/group_chat_view_model.dart';
import '../widgets/group_cards.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({required this.groupId, super.key});

  final String groupId;

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(WidgetRef ref) {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메시지를 입력해 주세요.')));
      return;
    }

    ref
        .read(groupChatViewModelProvider(widget.groupId).notifier)
        .sendMessage(text);
    _messageController.clear();

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
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(groupChatViewModelProvider(widget.groupId));

        return state.when(
          data: (state) => _ThreadContent(
            state: state,
            messageController: _messageController,
            scrollController: _scrollController,
            onSend: () => _sendMessage(ref),
          ),
          loading: () => const OnmuScaffold(
            title: '채팅',
            children: [Center(child: CircularProgressIndicator())],
          ),
          error: (error, stackTrace) => OnmuScaffold(
            title: '채팅',
            children: [
              Text(
                '채팅을 불러오지 못했어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThreadContent extends StatelessWidget {
  const _ThreadContent({
    required this.state,
    required this.messageController,
    required this.scrollController,
    required this.onSend,
  });

  final GroupChatState state;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final group = state.group;

    return OnmuScaffold(
      title: group.name,
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupDetail(group.id)),
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
                  context.push(RoutePaths.groupVotes(group.id));
                case _ChatMenuAction.plan:
                  context.push(RoutePaths.planDetail(group.id, state.planId));
                case _ChatMenuAction.settings:
                  context.push(RoutePaths.groupSettings(group.id));
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
                value: _ChatMenuAction.plan,
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
      bottom: _MessageInput(controller: messageController, onSend: onSend),
      scrollController: scrollController,
      children: [
        if (state.pinnedPlan != null)
          _PlanChatAnchor(
            plan: state.pinnedPlan!,
            onTap: () =>
                context.push(RoutePaths.planDetail(group.id, state.planId)),
          ),
        const SizedBox(height: AppSpacing.md),
        _VoteNoticeCard(
          vote: state.vote,
          onTap: () =>
              context.push(RoutePaths.groupVote(group.id, state.voteId)),
        ),
        const SizedBox(height: AppSpacing.md),
        _SettlementNoticeCard(
          settlement: state.settlement,
          onTap: () => context.push(
            RoutePaths.planSettlementDetail(
              group.id,
              state.planId,
              state.settlement.id,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _DateDivider(label: '2024년 6월 2일'),
        const SizedBox(height: AppSpacing.md),
        for (final message in state.messages.where(
          (message) => message.sender != 'ONMU',
        )) ...[
          ChatMessageBubble(message: message),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

enum _ChatMenuAction { votes, plan, settings }

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

class _PlanChatAnchor extends StatelessWidget {
  const _PlanChatAnchor({required this.plan, required this.onTap});

  final GroupPinnedPlan plan;
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
                Text(plan.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${plan.dateLabel} · ${plan.placeName}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          OnmuChip(label: plan.displayStatusLabel, selected: true),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _VoteNoticeCard extends StatelessWidget {
  const _VoteNoticeCard({required this.vote, required this.onTap});

  final VoteCard vote;
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
                '${settlement.planTitle} 정산이 만들어졌어요.',
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
