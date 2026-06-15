import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
import '../../repository/media_repository.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(WidgetRef ref) async {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메시지를 입력해 주세요.')));
      return;
    }

    _messageController.clear();
    final sendFuture = ref
        .read(groupChatViewModelProvider(widget.groupId).notifier)
        .sendMessage(text);
    _scheduleScrollToBottom();
    final sent = await sendFuture;
    if (!mounted) {
      return;
    }
    if (!sent) {
      _messageController.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메시지를 보내지 못했어요.')));
      return;
    }
  }

  Future<void> _sendImageMessage(WidgetRef ref) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked == null) {
      return;
    }

    final text = _messageController.text.trim();
    _messageController.clear();
    final sendFuture = ref
        .read(groupChatViewModelProvider(widget.groupId).notifier)
        .sendImageMessage(
          PickedChatImage(
            path: picked.path,
            fileName: picked.name,
            contentType: picked.mimeType ?? 'image/jpeg',
          ),
          text: text,
        );
    _scheduleScrollToBottom();
    final sent = await sendFuture;
    if (!mounted) {
      return;
    }
    if (!sent) {
      _messageController.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진을 보내지 못했어요.')));
      return;
    }
  }

  void _scheduleScrollToBottom() {
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
            onPickImage: () => _sendImageMessage(ref),
            onLoadOlderMessages: () => ref
                .read(groupChatViewModelProvider(widget.groupId).notifier)
                .loadOlderMessages(),
            onRetryMessage: (messageId) async {
              final retried = await ref
                  .read(groupChatViewModelProvider(widget.groupId).notifier)
                  .retryMessage(messageId);
              if (!mounted || !context.mounted || retried) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('메시지를 다시 보내지 못했어요.')),
              );
            },
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
    required this.onPickImage,
    required this.onLoadOlderMessages,
    required this.onRetryMessage,
  });

  final GroupChatState state;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final Future<void> Function() onSend;
  final Future<void> Function() onPickImage;
  final Future<void> Function() onLoadOlderMessages;
  final Future<void> Function(String messageId) onRetryMessage;

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
                  context.push(
                    state.planId > 0
                        ? RoutePaths.planDetail(group.id, state.planId)
                        : RoutePaths.planNew(group.id),
                  );
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
      bottom: _MessageInput(
        controller: messageController,
        onSend: onSend,
        onOpenActions: () => _showChatActions(context),
      ),
      scrollController: scrollController,
      children: [
        if (state.pinnedPlan != null)
          _PlanChatAnchor(
            plan: state.pinnedPlan!,
            onTap: () => context.push(
              state.planId > 0
                  ? RoutePaths.planDetail(group.id, state.planId)
                  : RoutePaths.planNew(group.id),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (state.vote != null && state.voteId > 0) ...[
          _VoteNoticeCard(
            vote: state.vote!,
            onTap: () =>
                context.push(RoutePaths.groupVote(group.id, state.voteId)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.settlement != null && state.planId > 0) ...[
          _SettlementNoticeCard(
            settlement: state.settlement!,
            onTap: () => context.push(
              RoutePaths.planSettlementDetail(
                group.id,
                state.planId,
                state.settlement!.id,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const _DateDivider(label: '2024년 6월 2일'),
        const SizedBox(height: AppSpacing.md),
        if (state.hasMoreOlderMessages) ...[
          _LoadOlderMessagesButton(
            loading: state.isLoadingOlderMessages,
            onPressed: state.isLoadingOlderMessages
                ? null
                : onLoadOlderMessages,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.unreadCount > 0) ...[
          _UnreadDivider(count: state.unreadCount),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final message in state.messages.where(
          (message) => message.sender != 'ONMU',
        )) ...[
          ChatMessageBubble(
            message: message,
            onRetry: message.canRetry ? () => onRetryMessage(message.id) : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Future<void> _showChatActions(BuildContext context) async {
    final group = state.group;
    final action = await showModalBottomSheet<_ChatActionCommand>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => const _ChatActionSheet(),
    );
    if (action == null || !context.mounted) {
      return;
    }

    switch (action) {
      case _ChatActionCommand.image:
        await onPickImage();
      case _ChatActionCommand.plan:
        context.push(RoutePaths.planNew(group.id));
      case _ChatActionCommand.place:
        context.push(
          state.planId > 0
              ? RoutePaths.planPlaceSearch(group.id, state.planId)
              : RoutePaths.planNew(group.id),
        );
      case _ChatActionCommand.vote:
        context.push(
          state.planId > 0
              ? RoutePaths.planVoteNew(group.id, state.planId)
              : RoutePaths.groupVotes(group.id),
        );
      case _ChatActionCommand.settlement:
        context.push(
          state.planId > 0
              ? RoutePaths.planSettlementNew(group.id, state.planId)
              : RoutePaths.planNew(group.id),
        );
    }
  }
}

enum _ChatMenuAction { votes, plan, settings }

enum _ChatActionCommand { image, plan, place, vote, settlement }

class _ChatActionSheet extends StatelessWidget {
  const _ChatActionSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lineSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('채팅 액션', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _ChatActionTile(
                icon: Icons.add_photo_alternate_outlined,
                label: '사진 첨부',
                command: _ChatActionCommand.image,
                onSelected: (command) => Navigator.of(context).pop(command),
              ),
              _ChatActionTile(
                icon: Icons.event_available_outlined,
                label: '약속 만들기',
                command: _ChatActionCommand.plan,
                onSelected: (command) => Navigator.of(context).pop(command),
              ),
              _ChatActionTile(
                icon: Icons.place_outlined,
                label: '장소 후보 찾기',
                command: _ChatActionCommand.place,
                onSelected: (command) => Navigator.of(context).pop(command),
              ),
              _ChatActionTile(
                icon: Icons.how_to_vote_outlined,
                label: '투표 만들기',
                command: _ChatActionCommand.vote,
                onSelected: (command) => Navigator.of(context).pop(command),
              ),
              _ChatActionTile(
                icon: Icons.receipt_long_outlined,
                label: '정산 시작',
                command: _ChatActionCommand.settlement,
                onSelected: (command) => Navigator.of(context).pop(command),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatActionTile extends StatelessWidget {
  const _ChatActionTile({
    required this.icon,
    required this.label,
    required this.command,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final _ChatActionCommand command;
  final ValueChanged<_ChatActionCommand> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 32,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      leading: Icon(icon, color: AppColors.primaryPink),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      onTap: () => onSelected(command),
    );
  }
}

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

class _LoadOlderMessagesButton extends StatelessWidget {
  const _LoadOlderMessagesButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.history_outlined, size: 18),
        label: Text(loading ? '불러오는 중' : '이전 메시지 더 보기'),
      ),
    );
  }
}

class _UnreadDivider extends StatelessWidget {
  const _UnreadDivider({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.linePink)),
        const SizedBox(width: AppSpacing.sm),
        OnmuChip(label: '$count개의 새 메시지', selected: true),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(child: Divider(color: AppColors.linePink)),
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
  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.onOpenActions,
  });

  final TextEditingController controller;
  final Future<void> Function() onSend;
  final VoidCallback onOpenActions;

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
          IconButton(
            tooltip: '채팅 액션',
            onPressed: onOpenActions,
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primaryPink,
            ),
          ),
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
