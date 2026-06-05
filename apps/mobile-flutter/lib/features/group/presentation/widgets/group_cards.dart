import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class GroupSummaryCard extends StatelessWidget {
  const GroupSummaryCard({required this.group, required this.onTap, super.key});

  final GroupSummary group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarCluster(members: group.members),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${group.members.length}명 · ${group.pinnedPlanTitle}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (group.unreadCount > 0)
                    OnmuChip(label: '${group.unreadCount}', selected: true),
                  const SizedBox(height: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: 16,
                color: AppColors.primaryPink,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  group.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const _CompactStatus(label: '진행중'),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  group.lastMessage,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PinnedPlanCard extends StatelessWidget {
  const PinnedPlanCard({
    required this.plan,
    required this.onBoardPressed,
    super.key,
  });

  final GroupPinnedPlan plan;
  final VoidCallback onBoardPressed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      onTap: onBoardPressed,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const OnmuChip(label: '고정', selected: true),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.accentBrown),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.push_pin, color: AppColors.primaryPink),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  plan.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            plan.dateLabel,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            plan.placeName,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              OnmuChip(label: plan.statusLabel, selected: true),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  plan.voteSummary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({required this.message, super.key});

  final GroupMessage message;

  @override
  Widget build(BuildContext context) {
    if (!message.isMine) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelAvatar(label: message.sender, size: 32),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: _ChatMessageContent(message: message, maxWidth: 246),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: _ChatMessageContent(message: message, maxWidth: 286),
    );
  }
}

class _ChatMessageContent extends StatelessWidget {
  const _ChatMessageContent({required this.message, required this.maxWidth});

  final GroupMessage message;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: message.isMine
              ? AppColors.primaryPinkSoft
              : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: message.isMine ? AppColors.linePink : AppColors.lineBrown,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.sender,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: message.isMine
                      ? AppColors.textSub
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                message.message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMain),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                message.timeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: message.isMine
                      ? AppColors.textSub
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinalSettlementResultRow extends StatelessWidget {
  const FinalSettlementResultRow({required this.result, super.key});

  final SettlementMemberResult result;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: result.willReceive
                ? AppColors.accentGreen
                : AppColors.primaryPinkSoft,
            foregroundColor: AppColors.textMain,
            child: Text(result.name.characters.first),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '부담 ${result.finalShareLabel} · 결제 ${result.paidAmountLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  result.resultLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMain),
                ),
              ],
            ),
          ),
          if (result.isMe) const OnmuChip(label: '나', selected: true),
        ],
      ),
    );
  }
}

class _AvatarCluster extends StatelessWidget {
  const _AvatarCluster({required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < members.take(3).length; index += 1)
            Positioned(
              left: index * 18,
              child: PixelAvatar(label: members[index], size: 34),
            ),
        ],
      ),
    );
  }
}

class _CompactStatus extends StatelessWidget {
  const _CompactStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPurpleSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.linePurple),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.primaryPurpleDark),
        ),
      ),
    );
  }
}
