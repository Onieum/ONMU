import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_decorations.dart';

class OnMoimGroupCard extends StatelessWidget {
  const OnMoimGroupCard({required this.group, required this.onTap, super.key});

  final OnMoimGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
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
                    ),
                    Text(
                      '${group.members.length}명 · ${group.pinnedMeetupTitle}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (group.unreadCount > 0)
                OnmuChip(label: '${group.unreadCount}', selected: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            group.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(group.lastMessage, style: Theme.of(context).textTheme.bodySmall),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnmuStickerLabel(label: '고정 약속', icon: Icons.push_pin_outlined),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.push_pin_outlined, color: AppColors.primaryPink),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  meetup.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.accentBrown),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(meetup.dateLabel, style: Theme.of(context).textTheme.bodyMedium),
          Text(meetup.placeName, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          OnmuChip(label: meetup.statusLabel, selected: true),
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

class SettlementStatusRow extends StatelessWidget {
  const SettlementStatusRow({required this.member, super.key});

  final SettlementMember member;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: member.isPaid
                ? AppColors.accentGreen
                : AppColors.primaryPinkSoft,
            foregroundColor: AppColors.textMain,
            child: Text(member.name.characters.first),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  member.amountLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          OnmuChip(label: member.statusLabel, selected: member.isPaid),
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
      width: 58,
      height: 34,
      child: Stack(
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
