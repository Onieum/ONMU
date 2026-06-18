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
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/models/preference_profile.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_plan_status_chip.dart';
import '../../../../shared/widgets/onmu_upcoming_plan_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../view_model/home_view_model.dart';
import '../../view_model/home_notifications_view_model.dart';
import '../widgets/home_recent_record_cards.dart';
import '../../../preferences/preference_summary_page.dart';

String _resolveDisplayName(AuthUser? user) {
  final displayName = user?.displayName.trim();
  if (displayName == null || displayName.isEmpty) {
    return '사용자';
  }
  if (displayName.toLowerCase() == 'onmu user') {
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
        ref.watch(authUserProvider) ?? authBootstrap.asData?.value.user;
    final displayName = _resolveDisplayName(authUser);

    return state.when(
      data: (state) => _HomeContent(
        showOnlyPlans: widget.showOnlyPlans,
        displayName: displayName,
        profileImageUrl: authUser?.profileImageUrl,
        groupId: state.groupId,
        todayPlans: state.todayPlans,
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

class _HomeContent extends ConsumerWidget {
  const _HomeContent({
    required this.showOnlyPlans,
    required this.displayName,
    this.profileImageUrl,
    required this.groupId,
    required this.todayPlans,
    required this.upcomingPlans,
    required this.todayPlanCount,
  });

  final bool showOnlyPlans;
  final String displayName;
  final String? profileImageUrl;
  final int? groupId;
  final List<GroupPlanSummary> todayPlans;
  final List<GroupPlanSummary> upcomingPlans;
  final int todayPlanCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref
        .watch(notificationUnreadCountProvider)
        .maybeWhen(data: (count) => count, orElse: () => 0);
    final recentRecords = showOnlyPlans
        ? null
        : ref.watch(homeRecentRecordsProvider);
    return OnmuScaffold(
      children: [
        if (!showOnlyPlans) ...[
          _HomeHeader(
            displayName: displayName,
            profileImageUrl: profileImageUrl,
            todayPlanCount: todayPlanCount,
            unreadNotificationCount: unreadCount,
            onNotificationTap: () async {
              await context.push(RoutePaths.homeNotifications);
              ref.invalidate(notificationUnreadCountProvider);
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        const _SectionTitle(title: '오늘의 약속'),
        const SizedBox(height: AppSpacing.sm),
        if (todayPlans.isEmpty)
          const _EmptyTodayPlanCard()
        else
          _TodayPlansGrid(groupId: groupId, plans: todayPlans),
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
            OnmuUpcomingPlanCard(
              plan: plan,
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
          _RecentRecordsPreview(records: recentRecords),
        ],
      ],
    );
  }
}

class _EmptyTodayPlanCard extends StatelessWidget {
  const _EmptyTodayPlanCard();

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
          Text('오늘 남은 약속이 없어요', style: Theme.of(context).textTheme.titleMedium),
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

class _RecentRecordsPreview extends StatelessWidget {
  const _RecentRecordsPreview({required this.records});

  final AsyncValue<List<OotdRecord>>? records;

  @override
  Widget build(BuildContext context) {
    final value = records;
    if (value == null) {
      return const SizedBox.shrink();
    }

    return value.when(
      data: (records) {
        if (records.isEmpty) {
          return const HomeRecentRecordsEmptyCard();
        }
        return Column(
          children: [
            for (final record in records.take(2)) ...[
              HomeRecentRecordCard(
                record: record,
                onTap: record.id == null
                    ? null
                    : () => context.push(RoutePaths.recordDetail(record.id!)),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
      loading: () => const OnmuCard(
        backgroundColor: AppColors.bgDefault,
        borderColor: AppColors.lineSoft,
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const HomeRecentRecordsEmptyCard(),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.displayName,
    this.profileImageUrl,
    required this.todayPlanCount,
    required this.unreadNotificationCount,
    required this.onNotificationTap,
  });

  final String displayName;
  final String? profileImageUrl;
  final int todayPlanCount;
  final int unreadNotificationCount;
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
            _NotificationIconButton(
              unreadCount: unreadNotificationCount,
              onPressed: onNotificationTap,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            PixelAvatar(
              label: avatarLabel,
              size: 64,
              profileImageUrl: profileImageUrl,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요,',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '$displayName님',
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

class _NotificationIconButton extends StatelessWidget {
  const _NotificationIconButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = unreadCount > 99 ? '99+' : unreadCount.toString();
    return SizedBox.square(
      dimension: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            tooltip: '알림',
            onPressed: onPressed,
            icon: const Icon(Icons.notifications_none),
          ),
          if (unreadCount > 0)
            Positioned(
              top: 7,
              right: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.bgDefault, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textInverse,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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

class _TodayPlansGrid extends StatelessWidget {
  const _TodayPlansGrid({required this.groupId, required this.plans});

  final int? groupId;
  final List<GroupPlanSummary> plans;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: 176,
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisExtent: constraints.maxWidth,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return _TodayPlanCard(
              plan: plan,
              onTap: () {
                final currentGroupId = groupId;
                if (currentGroupId == null) {
                  context.go(RoutePaths.groups);
                  return;
                }
                context.push(RoutePaths.planDetail(currentGroupId, plan.id));
              },
            );
          },
        ),
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  const _TodayPlanCard({required this.plan, required this.onTap});

  final GroupPlanSummary plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarMembers = _avatarMembers(plan);

    return OnmuCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OnmuPlanStatusChip(
                status: plan.progressStatus,
                label: plan.displayStatusLabel,
              ),
              const Spacer(),
              Text(
                _todayTimeLabel(plan),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            plan.title,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            plan.placeName.trim().isEmpty ? '장소 미정' : plan.placeName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              for (final member in avatarMembers)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: PixelAvatar(
                    label: member.name,
                    size: 28,
                    profileImageUrl: member.profileImageUrl,
                  ),
                ),
              if (plan.extraMemberCount > 0)
                Text(
                  '+${plan.extraMemberCount}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _todayTimeLabel(GroupPlanSummary plan) {
    return plan.displayTimeRangeLabel;
  }

  List<GroupPlanMemberAvatar> _avatarMembers(GroupPlanSummary plan) {
    final members = plan.memberAvatars.take(4).toList(growable: false);
    if (members.isNotEmpty) {
      return members;
    }

    return List.generate(
      plan.memberCount.clamp(0, 4).toInt(),
      (index) => GroupPlanMemberAvatar(name: '참여자 ${index + 1}'),
      growable: false,
    );
  }
}
