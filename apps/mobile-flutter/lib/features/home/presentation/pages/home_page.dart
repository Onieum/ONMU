import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/models/plan_models.dart';
import '../../../../shared/models/preference_profile.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../view_model/home_view_model.dart';
import '../../../preferences/preference_summary_page.dart';

String _resolveDisplayName(AuthUser? user) {
  final displayName = user?.displayName.trim();
  if (displayName == null || displayName.isEmpty) {
    return '사용자';
  }
  return displayName;
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({this.showOnlyPlans = false, this.summaryProfile, super.key});

  final bool showOnlyPlans;
  final PreferenceProfile? summaryProfile;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _summaryShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _showSummaryIfNeeded();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summaryProfile != widget.summaryProfile) {
      _summaryShown = false;
      _showSummaryIfNeeded();
    }
  }

  void _showSummaryIfNeeded() {
    final profile = widget.summaryProfile;
    if (_summaryShown || profile == null) {
      return;
    }

    _summaryShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showPreferenceSummaryBottomSheet(context, profile);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final authBootstrap = ref.watch(authBootstrapProvider);
    final authUser =
        authBootstrap.asData?.value.user ?? ref.watch(authUserProvider);
    final displayName = _resolveDisplayName(authUser);

    return state.when(
      data: (state) => _HomeContent(
        showOnlyPlans: widget.showOnlyPlans,
        displayName: displayName,
        groupId: state.groupId,
        activePlan: state.activePlan,
        upcomingPlans: state.upcomingPlans,
        todayPlanCount: state.todayPlanCount,
      ),
      loading: () => const OnmuScaffold(
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        children: [
          Text(
            '홈 데이터를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.showOnlyPlans,
    required this.displayName,
    required this.groupId,
    required this.activePlan,
    required this.upcomingPlans,
    required this.todayPlanCount,
  });

  final bool showOnlyPlans;
  final String displayName;
  final int? groupId;
  final Plan? activePlan;
  final List<GroupPlanSummary> upcomingPlans;
  final int todayPlanCount;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      children: [
        if (!showOnlyPlans) ...[
          _HomeHeader(
            displayName: displayName,
            todayPlanCount: todayPlanCount,
            onNotificationTap: () => context.push(RoutePaths.homeNotifications),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        const _SectionTitle(title: '진행 중인 약속'),
        const SizedBox(height: AppSpacing.sm),
        if (activePlan == null)
          const _EmptyPlanCard()
        else
          _ActivePlanCard(
            plan: activePlan!,
            onTap: () =>
                context.push(RoutePaths.planDetail(groupId!, activePlan!.id)),
            onChatTap: () => context.push(RoutePaths.groupChat(groupId!)),
          ),
        const SizedBox(height: AppSpacing.xxl),
        _SectionTitle(
          title: '다가오는 약속',
          actionLabel: '전체 보기',
          onTap: () => context.push(RoutePaths.homeUpcomingPlans),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (upcomingPlans.isEmpty)
          const _EmptyUpcomingPlanCard()
        else
          for (final plan in upcomingPlans.take(2)) ...[
            _UpcomingPlanTile(
              date: _upcomingPlanDate(plan),
              title: plan.title,
              place: plan.placeName,
              statusLabel: plan.displayStatusLabel,
              onTap: () =>
                  context.push(RoutePaths.planDetail(groupId ?? 0, plan.id)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        if (!showOnlyPlans) ...[
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle(
            title: '최근 기록',
            actionLabel: '전체 보기',
            onTap: () => context.push(RoutePaths.homeRecentRecords),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _EmptyRecentRecordCard(),
        ],
      ],
    );
  }
}

_UpcomingPlanDate _upcomingPlanDate(GroupPlanSummary plan) {
  final startsAt = plan.startsAt?.toLocal();
  if (startsAt == null) {
    final label = plan.dateLabel.trim().isEmpty ? '일정' : plan.dateLabel;
    return _UpcomingPlanDate(monthDay: label, weekday: '미정', time: '--:--');
  }

  final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final hour = startsAt.hour.toString().padLeft(2, '0');
  final minute = startsAt.minute.toString().padLeft(2, '0');
  return _UpcomingPlanDate(
    monthDay: '${startsAt.month}월 ${startsAt.day}일',
    weekday: '${weekdays[startsAt.weekday - 1]}요일',
    time: '$hour:$minute',
  );
}

class _UpcomingPlanDate {
  const _UpcomingPlanDate({
    required this.monthDay,
    required this.weekday,
    required this.time,
  });

  final String monthDay;
  final String weekday;
  final String time;
}

class _EmptyPlanCard extends StatelessWidget {
  const _EmptyPlanCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_busy_outlined, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text('진행 중인 약속이 없어요', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _EmptyUpcomingPlanCard extends StatelessWidget {
  const _EmptyUpcomingPlanCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        '다가오는 약속이 없어요.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.displayName,
    required this.todayPlanCount,
    required this.onNotificationTap,
  });

  final String displayName;
  final int todayPlanCount;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final avatarLabel = displayName.trim().isEmpty ? '온' : displayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _HomeLogo(),
            const Spacer(),
            IconButton(
              tooltip: '알림',
              onPressed: onNotificationTap,
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            PixelAvatar(label: avatarLabel, size: 64),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요, $displayName님',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    todayPlanCount == 0
                        ? '오늘 예정된 약속이 없어요'
                        : '오늘은 $todayPlanCount개의 약속이 있어요',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeLogo extends StatelessWidget {
  const _HomeLogo();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ONMU 로고',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPinkSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.linePink),
            ),
            child: const SizedBox.square(
              dimension: 28,
              child: Icon(
                Icons.favorite,
                size: 16,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'ONMU',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primaryPurpleDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onTap});

  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton.icon(
            onPressed: onTap,
            icon: Text(actionLabel!),
            label: const Icon(Icons.chevron_right, size: 16),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryPurple,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({
    required this.plan,
    required this.onTap,
    required this.onChatTap,
  });

  final Plan plan;
  final VoidCallback onTap;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.bgDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OnmuChip(label: '진행 중', selected: true),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      plan.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      plan.location,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSub,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      plan.dateTime,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const _PaperScene(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (final member in plan.members.take(4)) ...[
                      PixelAvatar(label: member.name, size: 32),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _CompactHomeButton(
                label: '채팅',
                icon: Icons.chat_bubble_outline,
                onTap: onChatTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactHomeButton extends StatelessWidget {
  const _CompactHomeButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.linePink),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(icon, size: 13, color: AppColors.primaryPurple),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperScene extends StatelessWidget {
  const _PaperScene();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgGrid,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: const SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          children: [
            Positioned(
              left: 17,
              top: 18,
              child: Icon(Icons.local_cafe, color: AppColors.accentBrown),
            ),
            Positioned(
              right: 16,
              top: 28,
              child: Icon(Icons.auto_awesome, color: AppColors.accentOrange),
            ),
            Positioned(
              left: 26,
              bottom: 18,
              child: Icon(Icons.favorite, color: AppColors.primaryPink),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingPlanTile extends StatelessWidget {
  const _UpcomingPlanTile({
    required this.date,
    required this.title,
    required this.place,
    required this.statusLabel,
    required this.onTap,
  });

  final _UpcomingPlanDate date;
  final String title;
  final String place;
  final String statusLabel;
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgPaper,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: SizedBox(
              width: 64,
              height: 74,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date.monthDay,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMain,
                      height: 1.05,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    date.weekday,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSub,
                      height: 1.05,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    date.time,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMain,
                      height: 1.05,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(width: 1, height: 50, color: AppColors.lineSoft),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  place.trim().isEmpty ? '장소 미정' : place,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 58),
            child: OnmuChip(label: statusLabel, selected: true),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecentRecordCard extends StatelessWidget {
  const _EmptyRecentRecordCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        '최근 기록이 없어요.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
      ),
    );
  }
}
