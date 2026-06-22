import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
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
    final description = group.description.trim();
    final lastMessage = group.lastMessage.trim();

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
              _AvatarCluster(members: group.displayMemberAvatars),
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
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(
                  Icons.sticky_note_2_outlined,
                  size: 16,
                  color: AppColors.primaryPink,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (lastMessage.isNotEmpty) ...[
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
                    lastMessage,
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
              if (plan.hasDisplayStatus) ...[
                OnmuChip(label: plan.displayStatusLabel, selected: true),
                const SizedBox(width: AppSpacing.xs),
              ],
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
  const ChatMessageBubble({required this.message, this.onRetry, super.key});

  final GroupMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (!message.isMine) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelAvatar(
              label: message.sender,
              size: 32,
              profileImageUrl: message.senderProfileImageUrl,
              character: message.senderCharacter,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: _ChatMessageContent(
                message: message,
                maxWidth: 246,
                onRetry: onRetry,
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: _ChatMessageContent(
        message: message,
        maxWidth: 286,
        onRetry: onRetry,
      ),
    );
  }
}

class ChatActivityCard extends StatelessWidget {
  const ChatActivityCard({
    required this.message,
    required this.onTap,
    super.key,
  });

  final GroupMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (message.normalizedMessageType) {
      'plan_card' => Icons.event_available_outlined,
      'vote_card' => Icons.how_to_vote_outlined,
      'settlement_card' => Icons.receipt_long_outlined,
      'system' => Icons.campaign_outlined,
      _ => Icons.chat_bubble_outline,
    };
    final messageText = message.message.trim().isEmpty
        ? '새 활동이 있어요.'
        : message.message.trim();

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 336),
        child: OnmuCard(
          onTap: onTap,
          backgroundColor: AppColors.bgPaper,
          borderColor: _borderColor,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primaryPink),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      message.activityTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                  if (message.timeLabel.trim().isNotEmpty)
                    Text(
                      message.timeLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                messageText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    message.activityActionLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.primaryPink,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _borderColor {
    return switch (message.normalizedMessageType) {
      'plan_card' => AppColors.lineWarm,
      'vote_card' => AppColors.linePink,
      'settlement_card' => AppColors.lineBrown,
      'system' => AppColors.lineSoft,
      _ => AppColors.lineSoft,
    };
  }
}

class _ChatMessageContent extends StatelessWidget {
  const _ChatMessageContent({
    required this.message,
    required this.maxWidth,
    this.onRetry,
  });

  final GroupMessage message;
  final double maxWidth;
  final VoidCallback? onRetry;

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
              if (!message.isMine) ...[
                Text(
                  message.sender,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xxs),
              ],
              if (message.attachments.isNotEmpty) ...[
                _MessageAttachments(attachments: message.attachments),
                if (message.message.trim().isNotEmpty)
                  const SizedBox(height: AppSpacing.xs),
              ],
              if (message.message.trim().isNotEmpty)
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
              if (message.isMine &&
                  message.sendStatus != GroupMessageSendStatus.sent)
                _SendStatusRow(message: message, onRetry: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageAttachments extends StatelessWidget {
  const _MessageAttachments({required this.attachments});

  final List<GroupMessageAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final imageAttachments = attachments
        .where((attachment) => attachment.type == 'image')
        .toList(growable: false);
    if (imageAttachments.isEmpty) {
      return const SizedBox.shrink();
    }
    return _ChatImageGrid(attachments: imageAttachments);
  }
}

class _ChatImageGrid extends StatelessWidget {
  const _ChatImageGrid({required this.attachments});

  final List<GroupMessageAttachment> attachments;

  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final visible = attachments.take(4).toList(growable: false);
    final extraCount = attachments.length - visible.length;

    return switch (visible.length) {
      1 => AspectRatio(
        aspectRatio: _aspectRatioFor(visible.first),
        child: _ChatImageTile(attachment: visible.first),
      ),
      2 => Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: _ChatImageTile(attachment: visible[0]),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: _ChatImageTile(attachment: visible[1]),
            ),
          ),
        ],
      ),
      3 => AspectRatio(
        aspectRatio: 1.45,
        child: Row(
          children: [
            Expanded(flex: 2, child: _ChatImageTile(attachment: visible[0])),
            const SizedBox(width: _gap),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _ChatImageTile(attachment: visible[1])),
                  const SizedBox(height: _gap),
                  Expanded(child: _ChatImageTile(attachment: visible[2])),
                ],
              ),
            ),
          ],
        ),
      ),
      _ => AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _ChatImageTile(attachment: visible[0])),
                  const SizedBox(width: _gap),
                  Expanded(child: _ChatImageTile(attachment: visible[1])),
                ],
              ),
            ),
            const SizedBox(height: _gap),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _ChatImageTile(attachment: visible[2])),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: _ChatImageTile(
                      attachment: visible[3],
                      extraCount: extraCount,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    };
  }

  double _aspectRatioFor(GroupMessageAttachment attachment) {
    final width = attachment.width;
    final height = attachment.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return 4 / 3;
    }
    return (width / height).clamp(0.7, 1.8);
  }
}

class _ChatImageTile extends StatelessWidget {
  const _ChatImageTile({required this.attachment, this.extraCount = 0});

  final GroupMessageAttachment attachment;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    final url = attachment.publicUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Stack(
        fit: StackFit.expand,
        children: [
          url.isEmpty
              ? const _ChatImageFallback()
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const _ChatImageFallback(),
                ),
          if (extraCount > 0)
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.textMain.withAlpha(140),
              ),
              child: Center(
                child: Text(
                  '+$extraCount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatImageFallback extends StatelessWidget {
  const _ChatImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        border: Border.all(color: AppColors.lineWarm),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textMuted,
          size: 28,
        ),
      ),
    );
  }
}

class _SendStatusRow extends StatelessWidget {
  const _SendStatusRow({required this.message, required this.onRetry});

  final GroupMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isFailed = message.sendStatus.isFailed;
    final color = isFailed ? AppColors.primaryPink : AppColors.textSub;
    final label = isFailed ? '전송 실패' : '전송 중';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFailed ? Icons.error_outline : Icons.schedule_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
          if (isFailed && onRetry != null) ...[
            const SizedBox(width: AppSpacing.xs),
            InkWell(
              onTap: onRetry,
              child: Text(
                '재시도',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.primaryPink),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FinalSettlementResultRow extends StatelessWidget {
  const FinalSettlementResultRow({required this.result, super.key});

  final SettlementMemberResult result;

  @override
  Widget build(BuildContext context) {
    final trimmedName = result.name.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.characters.first;

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
            child: Text(initial),
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

  final List<GroupPlanMemberAvatar> members;

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
              child: PixelAvatar(
                label: members[index].name,
                profileImageUrl: members[index].profileImageUrl,
                character: members[index].character,
                size: 34,
              ),
            ),
        ],
      ),
    );
  }
}
