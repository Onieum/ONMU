import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/meetup_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/onmu_step_progress.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class MeetupCompletePage extends StatelessWidget {
  const MeetupCompletePage({required this.meetupId, super.key});

  final String meetupId;

  @override
  Widget build(BuildContext context) {
    final meetup = mockMeetup;
    final selectedMembers = meetup.members
        .where((member) => member.selected)
        .toList();

    return OnmuScaffold(
      title: '완료',
      action: TextButton(
        onPressed: () => context.go(RoutePaths.home),
        child: const Text('닫기'),
      ),
      bottom: Row(
        children: [
          Expanded(
            child: OnmuSecondaryButton(
              label: '공유하기',
              icon: Icons.ios_share,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OnmuPrimaryButton(
              label: '약속 홈으로 이동',
              icon: Icons.home_outlined,
              onPressed: () => context.go(RoutePaths.meetups),
            ),
          ),
        ],
      ),
      children: [
        const OnmuStepProgress(currentIndex: 3),
        const SizedBox(height: AppSpacing.xl),
        _CompleteHero(meetup: meetup, members: selectedMembers),
        const SizedBox(height: AppSpacing.md),
        _CompleteTimeline(visitPlan: meetup.visitPlan),
        const SizedBox(height: AppSpacing.md),
        _CompleteMembers(members: selectedMembers),
        const SizedBox(height: AppSpacing.md),
        const _CompleteReminderCard(),
      ],
    );
  }
}

class _CompleteHero extends StatelessWidget {
  const _CompleteHero({required this.meetup, required this.members});

  final Meetup meetup;
  final List<MeetupMember> members;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '약속 만들기 완료!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Icon(Icons.celebration, color: AppColors.accentOrange),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '참여자들에게 공유할 약속 카드가 준비됐어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              for (final member in members)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: PixelAvatar(label: member.name, size: 44),
                ),
              const Spacer(),
              OnmuChip(label: meetup.status, selected: true),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meetup.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SummaryLine(
                    icon: Icons.calendar_month_outlined,
                    text: meetup.dateTime,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SummaryLine(
                    icon: Icons.location_on_outlined,
                    text: meetup.location,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteTimeline extends StatelessWidget {
  const _CompleteTimeline({required this.visitPlan});

  final List<VisitPlan> visitPlan;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route, color: AppColors.primaryPurple),
              const SizedBox(width: AppSpacing.sm),
              Text('방문 일정', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final plan in visitPlan.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  OnmuChip(label: plan.time, selected: true),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      plan.place,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CompleteMembers extends StatelessWidget {
  const _CompleteMembers({required this.members});

  final List<MeetupMember> members;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: AppColors.primaryPurple),
              const SizedBox(width: AppSpacing.sm),
              Text('참여자', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('4명', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final member in members)
                Column(
                  children: [
                    PixelAvatar(label: member.name, size: 44),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompleteReminderCard extends StatelessWidget {
  const _CompleteReminderCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_none,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('알림 설정', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _ReminderSummary(label: '약속 하루 전 알림', value: '5월 25일 오후 7:00'),
          const _ReminderSummary(label: '출발 시간 알림', value: '5월 26일 오전 10:30'),
        ],
      ),
    );
  }
}

class _ReminderSummary extends StatelessWidget {
  const _ReminderSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.primaryPurple),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSub),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
