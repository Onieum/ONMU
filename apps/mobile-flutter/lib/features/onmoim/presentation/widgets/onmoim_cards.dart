import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';

class OnMoimGroupCard extends StatelessWidget {
  const OnMoimGroupCard({required this.group, required this.onTap, super.key});

  final OnMoimGroup group;
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
              const _AvatarCluster(),
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
                      '${group.members.length}명 · ${group.pinnedMeetupTitle}',
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
          Text(
            group.lastMessage,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class PinnedMeetupCard extends StatelessWidget {
  const PinnedMeetupCard({
    required this.meetup,
    required this.onBoardPressed,
    super.key,
  });

  final OnMoimPinnedMeetup meetup;
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
                  meetup.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            meetup.dateLabel,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            meetup.placeName,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              OnmuChip(label: meetup.statusLabel, selected: true),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  meetup.voteSummary,
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

  final OnMoimMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 286),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: message.isMine
                        ? AppColors.textMain
                        : AppColors.textMain,
                  ),
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
  const _AvatarCluster();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: const [
          Positioned(left: 0, child: _TinyAvatar(label: '민')),
          Positioned(left: 18, child: _TinyAvatar(label: '지')),
          Positioned(left: 36, child: _TinyAvatar(label: '나')),
        ],
      ),
    );
  }
}

class _TinyAvatar extends StatelessWidget {
  const _TinyAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 17,
      backgroundColor: AppColors.primaryPinkSoft,
      foregroundColor: AppColors.textMain,
      child: Text(label),
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
