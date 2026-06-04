import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class UpcomingMeetupsPage extends StatelessWidget {
  const UpcomingMeetupsPage({super.key});

  static const _meetups = [
    _UpcomingMeetup(
      date: '05.28',
      weekday: 'SAT',
      title: '한남 카페 투어',
      place: '한남동 일대',
      time: '14:00',
      dday: 'D-2',
      note: '카페 세 곳을 천천히 둘러봐요.',
    ),
    _UpcomingMeetup(
      date: '05.30',
      weekday: 'MON',
      title: '홍대 전시회 구경',
      place: '홍대 일대',
      time: '14:00',
      dday: 'D-4',
      note: '전시를 보고 근처에서 저녁까지 이어가요.',
    ),
    _UpcomingMeetup(
      date: '06.02',
      weekday: 'THU',
      title: '북촌 소품샵 산책',
      place: '북촌로',
      time: '16:30',
      dday: 'D-7',
      note: '가볍게 걷고 마음에 드는 소품을 찾아봐요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '다가오는 약속 전체',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(RoutePaths.home);
      },
      subtitle: '곧 만날 약속들을 한 번에 확인해요.',
      children: [
        for (final meetup in _meetups) ...[
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
    required this.note,
  });

  final String date;
  final String weekday;
  final String title;
  final String place;
  final String time;
  final String dday;
  final String note;
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPinkSoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.linePink),
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
                    style: Theme.of(context).textTheme.labelMedium,
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
                      ),
                    ),
                    OnmuChip(label: meetup.dday, selected: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${meetup.time} · ${meetup.place}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(meetup.note, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
