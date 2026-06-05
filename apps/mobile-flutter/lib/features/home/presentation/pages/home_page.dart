import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/demo_route_seeds.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/meetup_models.dart';
import '../../../../shared/models/preference_profile.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../../preferences/preference_summary_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    this.showOnlyMeetups = false,
    this.summaryProfile,
    super.key,
  });

  final bool showOnlyMeetups;
  final PreferenceProfile? summaryProfile;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final meetup = mockMeetup;

    return OnmuScaffold(
      children: [
        if (!widget.showOnlyMeetups) ...[
          _HomeHeader(
            onNotificationTap: () => context.push(RoutePaths.homeNotifications),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        const _SectionTitle(title: '진행 중인 약속'),
        const SizedBox(height: AppSpacing.sm),
        _ActiveMeetupCard(
          meetup: meetup,
          onTap: () => context.push(
            RoutePaths.planDetail(DemoRouteSeeds.groupId, meetup.id),
          ),
          onChatTap: () =>
              context.push(RoutePaths.groupChat(DemoRouteSeeds.groupId)),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _SectionTitle(
          title: '다가오는 약속',
          actionLabel: '전체 보기',
          onTap: () => context.push(RoutePaths.homeUpcomingPlans),
        ),
        const SizedBox(height: AppSpacing.sm),
        _UpcomingMeetupTile(
          date: '05.28',
          weekday: 'SAT',
          title: '한남 카페 투어',
          place: '한남동 일대',
          dday: 'D-2',
          onTap: () => context.push(
            RoutePaths.planDetail(DemoRouteSeeds.groupId, meetup.id),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _UpcomingMeetupTile(
          date: '05.30',
          weekday: 'MON',
          title: '홍대 전시회 구경',
          place: '홍대 일대',
          dday: 'D-4',
          onTap: () => context.push(
            RoutePaths.planDetail(DemoRouteSeeds.groupId, meetup.id),
          ),
        ),
        if (!widget.showOnlyMeetups) ...[
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle(
            title: '최근 기록',
            actionLabel: '전체 보기',
            onTap: () => context.push(RoutePaths.homeRecentRecords),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _RecentRecordStrip(),
        ],
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _HomeLogo(),
            const Spacer(),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: '알림',
                  onPressed: onNotificationTap,
                  icon: const Icon(Icons.notifications_none),
                ),
                Positioned(
                  right: 11,
                  top: 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.bgWarm, width: 2),
                    ),
                    child: const SizedBox.square(dimension: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const PixelAvatar(label: '지', size: 64),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요, 지우님',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '오늘은 2개의 약속이 있어요',
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

class _ActiveMeetupCard extends StatelessWidget {
  const _ActiveMeetupCard({
    required this.meetup,
    required this.onTap,
    required this.onChatTap,
  });

  final Meetup meetup;
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
                      '성수 저녁 약속',
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '다운타우너 성수',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSub,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '18:30 · 도착까지 20분',
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
                    for (final member in meetup.members.take(4)) ...[
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

class _UpcomingMeetupTile extends StatelessWidget {
  const _UpcomingMeetupTile({
    required this.date,
    required this.weekday,
    required this.title,
    required this.place,
    required this.dday,
    required this.onTap,
  });

  final String date;
  final String weekday;
  final String title;
  final String place;
  final String dday;
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
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(date, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  weekday,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
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
                  '14:00 · $place',
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
          OnmuChip(label: dday, selected: true),
        ],
      ),
    );
  }
}

class _RecentRecordStrip extends StatelessWidget {
  const _RecentRecordStrip();

  static const _records = [
    _RecentRecordData('성수동 카페', '05.24', Icons.local_cafe_outlined, '12'),
    _RecentRecordData('제주 바다', '05.16', Icons.water, '8'),
    _RecentRecordData('한강 피크닉', '05.10', Icons.park_outlined, '15'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _records.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) =>
            _RecentRecordCard(record: _records[index]),
      ),
    );
  }
}

class _RecentRecordCard extends StatelessWidget {
  const _RecentRecordCard({required this.record});

  final _RecentRecordData record;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: OnmuCard(
        backgroundColor: AppColors.bgDefault,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RecordImageTile(icon: record.icon, height: 68),
            const SizedBox(height: AppSpacing.xs),
            Text(
              record.title,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  record.date,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                ),
                const Spacer(),
                const Icon(
                  Icons.favorite,
                  size: 13,
                  color: AppColors.accentRed,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  record.likes,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordImageTile extends StatelessWidget {
  const _RecordImageTile({required this.icon, required this.height});

  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgGrid,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Icon(icon, color: AppColors.primaryPink, size: 28),
      ),
    );
  }
}

class _RecentRecordData {
  const _RecentRecordData(this.title, this.date, this.icon, this.likes);

  final String title;
  final String date;
  final IconData icon;
  final String likes;
}
