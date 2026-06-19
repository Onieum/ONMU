import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../models/group_models.dart';
import 'onmu_card.dart';
import 'onmu_plan_status_chip.dart';

class OnmuUpcomingPlanCard extends StatelessWidget {
  const OnmuUpcomingPlanCard({
    required this.plan,
    required this.onTap,
    super.key,
  });

  final GroupPlanSummary plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = _UpcomingPlanDate.from(plan);

    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _UpcomingPlanDateCapsule(date: date),
          const SizedBox(width: AppSpacing.sm),
          Container(width: 1, height: 50, color: AppColors.lineSoft),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  plan.placeName.trim().isEmpty ? '장소 미정' : plan.placeName,
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
          if (plan.hasDisplayStatus)
            Flexible(
              flex: 0,
              child: OnmuPlanStatusChip(
                status: plan.progressStatus,
                label: plan.displayStatusLabel,
              ),
            ),
        ],
      ),
    );
  }
}

class _UpcomingPlanDateCapsule extends StatelessWidget {
  const _UpcomingPlanDateCapsule({required this.date});

  final _UpcomingPlanDate date;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: SizedBox(
        width: 76,
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
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingPlanDate {
  const _UpcomingPlanDate({
    required this.monthDay,
    required this.weekday,
    required this.time,
  });

  factory _UpcomingPlanDate.from(GroupPlanSummary plan) {
    final startsAt = plan.startsAt?.toLocal();
    if (startsAt == null) {
      final label = plan.dateLabel.trim().isEmpty ? '일정' : plan.dateLabel;
      return _UpcomingPlanDate(monthDay: label, weekday: '미정', time: '--:--');
    }

    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return _UpcomingPlanDate(
      monthDay: '${startsAt.month}월 ${startsAt.day}일',
      weekday: '${weekdays[startsAt.weekday - 1]}요일',
      time: plan.displayTimeRangeLabel,
    );
  }

  final String monthDay;
  final String weekday;
  final String time;
}
