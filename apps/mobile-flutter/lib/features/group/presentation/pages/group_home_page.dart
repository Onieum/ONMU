import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_empty_state_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../view_model/group_home_view_model.dart';

class GroupHomePage extends ConsumerWidget {
  const GroupHomePage({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupHomeViewModelProvider(groupId));

    return state.when(
      data: (state) => _GroupHomeContent(state: state),
      loading: () => const OnmuScaffold(
        useWarmBackground: false,
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        useWarmBackground: false,
        children: [
          Text(
            '온모임 홈을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GroupHomeContent extends StatelessWidget {
  const _GroupHomeContent({required this.state});

  final GroupHomeState state;

  @override
  Widget build(BuildContext context) {
    final group = state.group;
    final ongoingPlan = state.ongoingPlan;
    final upcomingPlan = state.upcomingPlan;

    return OnmuScaffold(
      useWarmBackground: false,
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('group-home-create-plan-fab'),
        tooltip: '약속 만들기',
        onPressed: () => context.push(RoutePaths.planNew(group.id)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.textInverse,
        child: const Icon(Icons.add),
      ),
      children: [
        _GroupHomeHeader(group: group),
        const SizedBox(height: AppSpacing.md),
        _GroupTabs(group: group),
        const SizedBox(height: AppSpacing.md),
        if (ongoingPlan != null) ...[
          _UpcomingPlanCard(
            plan: ongoingPlan,
            statusLabel: '약속 진행 중',
            onTap: () =>
                context.push(RoutePaths.planDetail(group.id, ongoingPlan.id)),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _SectionHeader(
          title: '다가오는 약속',
          actionLabel: '전체 보기',
          onTap: () => context.push(RoutePaths.groupPlans(group.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (upcomingPlan != null)
          _UpcomingPlanCard(
            plan: upcomingPlan,
            onTap: () =>
                context.push(RoutePaths.planDetail(group.id, upcomingPlan.id)),
          )
        else
          const OnmuEmptyStateCard(title: '다가오는 약속이 없어요.'),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(
          title: '최근 기록',
          actionLabel: '전체 보기',
          onTap: () => context.push(RoutePaths.groupMemories(group.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _RecentMemoryStrip(group: group, memories: state.recentMemories),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(
          title: '최근 대화',
          actionLabel: '전체 보기',
          onTap: () => context.push(RoutePaths.groupChat(group.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _RecentChatPreview(
          message: state.recentMessage,
          onTap: () => context.push(RoutePaths.groupChat(group.id)),
        ),
      ],
    );
  }
}

class _GroupHomeHeader extends StatelessWidget {
  const _GroupHomeHeader({required this.group});

  final GroupSummary group;

  @override
  Widget build(BuildContext context) {
    const sideActionWidth = 104.0;
    final description = group.description.trim();

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: sideActionWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: '온모임 목록으로 이동',
                  onPressed: () => context.popOrGo(RoutePaths.groups),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            ),
            Expanded(child: _HeaderAvatarCluster(members: group.memberAvatars)),
            SizedBox(
              width: sideActionWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: '모임 설정',
                    onPressed: () =>
                        context.push(RoutePaths.groupSettings(group.id)),
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
        if (description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () => context.push(RoutePaths.groupMembers(group.id)),
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

  final List<GroupPlanMemberAvatar> members;

  @override
  Widget build(BuildContext context) {
    final displayMembers = members.isEmpty
        ? const [GroupPlanMemberAvatar(name: '온')]
        : members.take(3).toList(growable: false);

    return Center(
      child: SizedBox(
        width: 126,
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var index = 0; index < displayMembers.length; index += 1)
              Positioned(
                left: _avatarLeftOffset(index, displayMembers.length),
                child: PixelAvatar(
                  label: displayMembers[index].name,
                  profileImageUrl: displayMembers[index].profileImageUrl,
                  character: displayMembers[index].character,
                  size: index == 1 ? 46 : 42,
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _avatarLeftOffset(int index, int count) {
    if (count == 1) {
      return 42;
    }
    if (count == 2) {
      return index == 0 ? 30 : 58;
    }
    return index == 0 ? 0 : (index == 1 ? 40 : 84);
  }
}

class _GroupTabs extends StatelessWidget {
  const _GroupTabs({required this.group});

  final GroupSummary group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GroupTab(label: '약속', selected: true, onTap: () {}),
        _GroupTab(
          label: '기록',
          selected: false,
          onTap: () => context.push(RoutePaths.groupMemories(group.id)),
        ),
        _GroupTab(
          label: '채팅',
          selected: false,
          onTap: () => context.push(RoutePaths.groupChat(group.id)),
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

class _UpcomingPlanCard extends StatelessWidget {
  const _UpcomingPlanCard({
    required this.plan,
    required this.onTap,
    this.statusLabel,
  });

  final GroupPlanSummary plan;
  final VoidCallback onTap;
  final String? statusLabel;

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
                    if ((statusLabel ?? plan.displayStatusLabel)
                        .trim()
                        .isNotEmpty) ...[
                      OnmuChip(
                        label: statusLabel ?? plan.displayStatusLabel,
                        selected: true,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
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
                Row(
                  children: [
                    Flexible(
                      flex: 0,
                      child: Text(
                        plan.displayDateTimeLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.textSub,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        plan.placeName.trim().isEmpty
                            ? '장소 미정'
                            : plan.placeName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSub,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    for (final member in plan.memberAvatars.take(4)) ...[
                      PixelAvatar(
                        label: member.name,
                        profileImageUrl: member.profileImageUrl,
                        character: member.character,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${plan.memberCount}명 참여 예정',
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
  const _RecentMemoryStrip({required this.group, required this.memories});

  final GroupSummary group;
  final List<GroupMemoryRecord> memories;

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return const OnmuEmptyStateCard(
        title: '최근 기록이 없어요.',
        description: '기록을 만들면 이곳에 표시돼요.',
        icon: Icons.photo_library_outlined,
      );
    }

    final iconStyles = [
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
          final memory = iconStyles[index % iconStyles.length];
          final record = memories[index];

          return _MemoryThumb(
            icon: memory.$1,
            color: memory.$2,
            imageUrl: record.primaryImageUrl,
            onTap: () => context.push(
              RoutePaths.groupMemoryDetail(group.id, record.routeId),
            ),
          );
        },
      ),
    );
  }
}

class _MemoryThumb extends StatelessWidget {
  const _MemoryThumb({
    required this.icon,
    required this.color,
    this.imageUrl,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _MemoryThumbImage(icon: icon, color: color, imageUrl: imageUrl),
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
                child: Icon(
                  Icons.favorite,
                  size: 14,
                  color: AppColors.accentRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryThumbImage extends StatelessWidget {
  const _MemoryThumbImage({
    required this.icon,
    required this.color,
    this.imageUrl,
  });

  final IconData icon;
  final Color color;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _PhotoThumb(icon: icon, width: 76, height: 76, color: color);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.network(
        url,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _PhotoThumb(icon: icon, width: 76, height: 76, color: color);
        },
      ),
    );
  }
}

class _RecentChatPreview extends StatelessWidget {
  const _RecentChatPreview({required this.message, required this.onTap});

  final GroupMessage? message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = message;
    if (preview == null) {
      return Text('아직 대화가 없어요.', style: Theme.of(context).textTheme.bodyMedium);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            PixelAvatar(
              label: preview.sender,
              profileImageUrl: preview.senderProfileImageUrl,
              size: 42,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        preview.sender,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      Text(
                        preview.timeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    preview.message,
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
