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

class OnMoimGroupHomePage extends StatelessWidget {
  const OnMoimGroupHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final group = demoOnMoimGroups.first;

    return OnmuScaffold(
      useWarmBackground: false,
      children: [
        _GroupHomeHeader(group: group),
        const SizedBox(height: AppSpacing.md),
        _GroupTabs(group: group),
        const SizedBox(height: AppSpacing.md),
        _SectionHeader(
          title: '다가오는 약속',
          actionLabel: '전체 보기',
          onTap: () => context.go(RoutePaths.onmoimMeetups(group.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _UpcomingMeetupCard(
          meetup: demoPinnedMeetup,
          onTap: () => context.go(RoutePaths.onmoimDemoMeetup),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(
          title: '최근 기록',
          actionLabel: '전체 보기',
          onTap: () => context.go(RoutePaths.onmoimDemoMemories),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _RecentMemoryStrip(),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(
          title: '최근 대화',
          actionLabel: '전체 보기',
          onTap: () => context.go(RoutePaths.onmoimDemoChat),
        ),
        const SizedBox(height: AppSpacing.sm),
        _RecentChatPreview(onTap: () => context.go(RoutePaths.onmoimDemoChat)),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(
          title: '모임원',
          actionLabel: '전체 보기',
          onTap: () => context.go(RoutePaths.onmoimMembers(group.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MemberStrip(group: group),
      ],
    );
  }
}

class _GroupHomeHeader extends StatelessWidget {
  const _GroupHomeHeader({required this.group});

  final OnMoimGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 92,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: '온모임 목록으로 이동',
                  onPressed: () => context.go(RoutePaths.onmoim),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            ),
            Expanded(child: _HeaderAvatarCluster(members: group.members)),
            SizedBox(
              width: 92,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: '모임 검색',
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                  ),
                  IconButton(
                    tooltip: '모임 설정',
                    onPressed: () =>
                        context.go(RoutePaths.onmoimSettings(group.id)),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          group.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () => context.go(RoutePaths.onmoimMembers(group.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '멤버 ${group.members.length}명',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
                const SizedBox(width: AppSpacing.xxs),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderAvatarCluster extends StatelessWidget {
  const _HeaderAvatarCluster({required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 126,
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              child: PixelAvatar(label: members[0], size: 42),
            ),
            PixelAvatar(label: members[1], size: 46),
            Positioned(
              right: 0,
              child: PixelAvatar(label: members[2], size: 42),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTabs extends StatelessWidget {
  const _GroupTabs({required this.group});

  final OnMoimGroup group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GroupTab(label: '약속', selected: true, onTap: () {}),
        _GroupTab(
          label: '기록',
          selected: false,
          onTap: () => context.go(RoutePaths.onmoimMemories(group.id)),
        ),
        _GroupTab(
          label: '채팅',
          selected: false,
          onTap: () => context.go(RoutePaths.onmoimChat(group.id)),
        ),
      ],
    );
  }
}

class _GroupTab extends StatelessWidget {
  const _GroupTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primaryPink : AppColors.lineSoft,
                width: selected ? 2 : 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? AppColors.primaryPink : AppColors.textSub,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        TextButton.icon(
          onPressed: onTap,
          icon: Text(actionLabel),
          label: const Icon(Icons.chevron_right, size: 16),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSub,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
          ),
        ),
      ],
    );
  }
}

class _UpcomingMeetupCard extends StatelessWidget {
  const _UpcomingMeetupCard({required this.meetup, required this.onTap});

  final OnMoimPinnedMeetup meetup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          const _PhotoThumb(
            icon: Icons.water,
            width: 74,
            height: 74,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OnmuChip(label: meetup.statusLabel, selected: true),
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
                  '${meetup.dateLabel} · ${meetup.placeName}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    for (final member in ['지민', '민수', '하린', '현우']) ...[
                      PixelAvatar(label: member, size: 22),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      meetup.voteSummary,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentMemoryStrip extends StatelessWidget {
  const _RecentMemoryStrip();

  @override
  Widget build(BuildContext context) {
    const memories = [
      (Icons.park_outlined, AppColors.accentGreen),
      (Icons.water, AppColors.accentBlue),
      (Icons.nightlight_round, AppColors.accentBrown),
      (Icons.local_cafe_outlined, AppColors.accentOrange),
    ];

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: memories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final memory = memories[index];

          return _MemoryThumb(icon: memory.$1, color: memory.$2);
        },
      ),
    );
  }
}

class _MemoryThumb extends StatelessWidget {
  const _MemoryThumb({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _PhotoThumb(icon: icon, width: 76, height: 76, color: color),
        Positioned(
          right: -4,
          bottom: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.linePink),
            ),
            child: const SizedBox.square(
              dimension: 22,
              child: Icon(Icons.favorite, size: 14, color: AppColors.accentRed),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentChatPreview extends StatelessWidget {
  const _RecentChatPreview({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final message = demoOnMoimMessages.first;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            PixelAvatar(label: message.sender, size: 42),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        message.sender,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      Text(
                        '오전 10:20',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '다들 시간 괜찮을까?',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MemberStrip extends StatelessWidget {
  const _MemberStrip({required this.group});

  final OnMoimGroup group;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final member in group.members.take(4)) ...[
            _MemberAvatar(member: member),
            const SizedBox(width: AppSpacing.md),
          ],
          _InviteButton(
            onTap: () => context.go(RoutePaths.onmoimInvite(group.id)),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});

  final String member;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          PixelAvatar(label: member, size: 46),
          const SizedBox(height: AppSpacing.xs),
          Text(
            member,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  const _InviteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bgDefault,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.lineBrown),
              ),
              child: const SizedBox.square(
                dimension: 46,
                child: Icon(Icons.add, color: AppColors.accentBrown),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('초대', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.icon,
    required this.width,
    required this.height,
    required this.color,
  });

  final IconData icon;
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
