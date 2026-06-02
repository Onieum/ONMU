import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push(RoutePaths.onmoimMeetupNewMembers('friends')),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('약속 만들기'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.textInverse,
        extendedPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      children: [
        if (!widget.showOnlyMeetups) ...[
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
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '알림',
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        _SectionTitle(
          title: '진행 중인 약속',
          actionLabel: '전체 보기',
          onTap: () => context.go(RoutePaths.onmoim),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActiveMeetupCard(meetup: meetup),
        const SizedBox(height: AppSpacing.xxl),
        _SectionTitle(title: '다가오는 약속', actionLabel: '전체 보기'),
        const SizedBox(height: AppSpacing.sm),
        const _UpcomingMeetupTile(
          date: '05.28',
          weekday: 'SAT',
          title: '한남 카페 투어',
          place: '한남동 일대',
          dday: 'D-2',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _UpcomingMeetupTile(
          date: '05.30',
          weekday: 'MON',
          title: '홍대 전시회 구경',
          place: '홍대 일대',
          dday: 'D-4',
        ),
        const SizedBox(height: AppSpacing.xxl),
        _SectionTitle(title: '지난 약속 아카이브', actionLabel: '전체 보기'),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 170,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _ArchiveCard(title: '강릉 당일치기 여행', date: '05.20'),
              SizedBox(width: AppSpacing.sm),
              _ArchiveCard(title: '연남동 데이트', date: '05.15'),
              SizedBox(width: AppSpacing.sm),
              _ArchiveCard(title: '롯데월드 나들이', date: '05.08'),
            ],
          ),
        ),
      ],
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
          TextButton(onPressed: onTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class _ActiveMeetupCard extends StatelessWidget {
  const _ActiveMeetupCard({required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.bgDefault,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
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
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '다운타우너 성수',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '18:30 · 도착까지 20분',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const _PaperScene(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                for (final member in meetup.members.take(4)) ...[
                  PixelAvatar(label: member.name, size: 36),
                  const SizedBox(width: AppSpacing.xs),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(
                    RoutePaths.onmoimMeetupDetail('friends', meetup.id),
                  ),
                  child: const Text('상세 보기'),
                ),
              ],
            ),
          ),
        ],
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
        width: 118,
        height: 118,
        child: Stack(
          children: [
            Positioned(
              left: 18,
              top: 20,
              child: Icon(Icons.local_cafe, color: AppColors.accentBrown),
            ),
            Positioned(
              right: 18,
              top: 32,
              child: Icon(Icons.auto_awesome, color: AppColors.accentOrange),
            ),
            Positioned(
              left: 26,
              bottom: 20,
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
  });

  final String date;
  final String weekday;
  final String title;
  final String place;
  final String dday;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                Text(date, style: Theme.of(context).textTheme.titleMedium),
                Text(weekday, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '14:00 · $place',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          OnmuChip(label: dday, selected: true),
        ],
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({required this.title, required this.date});

  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: OnmuCard(
        backgroundColor: AppColors.bgDefault,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Row(
              children: const [
                PixelAvatar(label: '지', size: 34),
                SizedBox(width: AppSpacing.xs),
                PixelAvatar(label: '민', size: 34),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
