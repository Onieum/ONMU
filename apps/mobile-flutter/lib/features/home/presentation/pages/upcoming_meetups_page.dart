import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class UpcomingMeetupsPage extends StatelessWidget {
  const UpcomingMeetupsPage({super.key});

  static const _weekMeetups = [
    _UpcomingMeetup(
      date: '05.28',
      weekday: 'SAT',
      title: '한남 카페 투어',
      place: '한남동 일대',
      time: '14:00',
      dday: 'D-2',
      status: '예정',
      members: ['지', '민', '하', '현'],
    ),
    _UpcomingMeetup(
      date: '05.30',
      weekday: 'MON',
      title: '홍대 전시회 구경',
      place: '홍대 일대',
      time: '14:00',
      dday: 'D-4',
      status: '예정',
      members: ['지', '민', '소'],
    ),
  ];

  static const _nextMeetups = [
    _UpcomingMeetup(
      date: '06.07',
      weekday: 'FRI',
      title: '제주도 여행',
      place: '2박 3일 · 제주도 일대',
      time: '10:00',
      dday: 'D-12',
      status: '진행중',
      members: ['지', '민', '하', '현', '소', '준'],
    ),
    _UpcomingMeetup(
      date: '06.12',
      weekday: 'WED',
      title: '성수 디저트 모임',
      place: '성수동',
      time: '19:00',
      dday: 'D-17',
      status: '예정',
      members: ['지', '민', '현'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '다가오는 약속',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(RoutePaths.home);
      },
      action: Row(
        children: [
          IconButton(
            tooltip: '캘린더 보기',
            onPressed: () => _showSnack(context, '캘린더 보기는 다음 단계에서 연결할게요.'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: '약속 필터',
            onPressed: () => _showSnack(context, '필터는 예정/진행중 기준으로 준비 중이에요.'),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '약속 만들기',
        onPressed: () => context.push(RoutePaths.onmoimMeetupNew('friends')),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.textInverse,
        child: const Icon(Icons.add),
      ),
      children: [
        const _MonthHeader(),
        const SizedBox(height: AppSpacing.xxl),
        const _MeetupSection(title: '이번 주', meetups: _weekMeetups),
        const SizedBox(height: AppSpacing.xxl),
        const _MeetupSection(title: '다음 주', meetups: _nextMeetups),
        const SizedBox(height: 72),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader();

  static const _days = [
    ('24', '월', false),
    ('25', '화', false),
    ('26', '수', false),
    ('27', '목', false),
    ('28', '금', true),
    ('29', '토', false),
    ('30', '일', false),
  ];

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('2026년 6월', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final day in _days)
                Expanded(
                  child: _DayPill(
                    day: day.$1,
                    weekday: day.$2,
                    selected: day.$3,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.weekday,
    required this.selected,
  });

  final String day;
  final String weekday;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPinkSoft : AppColors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: selected ? Border.all(color: AppColors.linePink) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            Text(
              day,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.primaryPurple : AppColors.textMain,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              weekday,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? AppColors.primaryPurple : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetupSection extends StatelessWidget {
  const _MeetupSection({required this.title, required this.meetups});

  final String title;
  final List<_UpcomingMeetup> meetups;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        for (final meetup in meetups) ...[
          _UpcomingMeetupCard(meetup: meetup),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _UpcomingMeetup {
  const _UpcomingMeetup({
    required this.date,
    required this.weekday,
    required this.title,
    required this.place,
    required this.time,
    required this.dday,
    required this.status,
    required this.members,
  });

  final String date;
  final String weekday;
  final String title;
  final String place;
  final String time;
  final String dday;
  final String status;
  final List<String> members;
}

class _UpcomingMeetupCard extends StatelessWidget {
  const _UpcomingMeetupCard({required this.meetup});

  final _UpcomingMeetup meetup;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: () =>
          context.push(RoutePaths.onmoimMeetupDetail('friends', 'demo')),
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgPaper,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.lineBrown),
            ),
            child: SizedBox(
              width: 64,
              height: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    meetup.date,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    meetup.weekday,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meetup.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OnmuChip(label: meetup.dday, selected: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${meetup.time} · ${meetup.place}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    for (final member in meetup.members.take(4)) ...[
                      PixelAvatar(label: member, size: 22),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    if (meetup.members.length > 4)
                      OnmuChip(label: '+${meetup.members.length - 4}'),
                    const Spacer(),
                    OnmuChip(label: meetup.status),
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

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
