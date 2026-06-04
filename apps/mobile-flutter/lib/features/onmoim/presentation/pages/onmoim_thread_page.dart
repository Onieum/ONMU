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
import '../widgets/onmoim_cards.dart';

class OnMoimThreadPage extends StatelessWidget {
  const OnMoimThreadPage({super.key});

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
      action: IconButton(
        tooltip: '채팅 설정',
        onPressed: () => context.go(RoutePaths.onmoimSettings(group.id)),
        icon: const Icon(Icons.more_vert),
      ),
      bottom: const _MessageInput(),
      children: [
        _MeetupChatAnchor(onTap: () => context.go(RoutePaths.onmoimDemoMeetup)),
        const SizedBox(height: AppSpacing.md),
        _VoteNoticeCard(
          vote: demoOnMoimVoteCard,
          onTap: () => context.go(RoutePaths.onmoimDemoMeetupPlaces),
        ),
        const SizedBox(height: AppSpacing.md),
        const _DateDivider(label: '2024년 6월 2일'),
        const SizedBox(height: AppSpacing.md),
        for (final message in demoOnMoimMessages) ...[
          ChatMessageBubble(message: message),
          const SizedBox(height: AppSpacing.sm),
        ],
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
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelAvatar(label: '온뮤', size: 42),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OnmuCard(
                backgroundColor: AppColors.bgDefault,
                borderColor: AppColors.linePink,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vote.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const OnmuChip(label: '투표', selected: true),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      vote.summary,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OnmuChip(label: vote.statusLabel),
                        const OnmuChip(label: '채팅 연계'),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            foregroundColor: AppColors.textInverse,
                            minimumSize: const Size(0, 36),
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
                  ],
                ),
              ),
            ),
          ],
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
  const _MessageInput();

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
          const Expanded(
            child: TextField(
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
            onPressed: () {},
            icon: const Icon(Icons.send_outlined),
          ),
        ],
      ),
    );
  }
}
