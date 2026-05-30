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
import '../../../../shared/widgets/pixel_avatar.dart';

class MeetupDetailPage extends StatelessWidget {
  const MeetupDetailPage({required this.meetupId, super.key});

  final String meetupId;

  @override
  Widget build(BuildContext context) {
    final meetup = mockMeetup;
    final selectedMembers = meetup.members
        .where((member) => member.selected)
        .toList();

    return OnmuScaffold(
      title: '약속 상세',
      showBackButton: true,
      onBack: () => context.pop(),
      action: IconButton(
        tooltip: '더보기',
        onPressed: () {},
        icon: const Icon(Icons.more_vert),
      ),
      bottom: OnmuPrimaryButton(
        label: '동선 확인',
        icon: Icons.route_outlined,
        onPressed: () => context.push(RoutePaths.meetupRouteReview(meetup.id)),
      ),
      children: [
        _MeetupHeaderCard(meetup: meetup, members: selectedMembers),
        const SizedBox(height: AppSpacing.md),
        const _CountdownCard(),
        const SizedBox(height: AppSpacing.md),
        _MembersCard(members: selectedMembers),
        const SizedBox(height: AppSpacing.md),
        _ScheduleCard(meetup: meetup),
        const SizedBox(height: AppSpacing.md),
        _VisitPlanCard(visitPlan: meetup.visitPlan),
        const SizedBox(height: AppSpacing.md),
        _MemoCard(memo: meetup.memo),
        const SizedBox(height: AppSpacing.md),
        const _StatusCard(),
      ],
    );
  }
}

class _MeetupHeaderCard extends StatelessWidget {
  const _MeetupHeaderCard({required this.meetup, required this.members});

  final Meetup meetup;
  final List<MeetupMember> members;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            height: 76,
            child: Stack(
              children: [
                for (var index = 0; index < members.length; index++)
                  Positioned(
                    left: index * 24,
                    child: PixelAvatar(
                      label: members[index].name,
                      size: 52,
                      bodyColor: index.isEven
                          ? AppColors.primaryPurple
                          : AppColors.primaryPink,
                    ),
                  ),
              ],
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
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    OnmuChip(label: meetup.status, selected: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _IconText(
                  icon: Icons.calendar_month_outlined,
                  text: meetup.dateTime,
                ),
                const SizedBox(height: AppSpacing.xs),
                _IconText(
                  icon: Icons.location_on_outlined,
                  text: meetup.location,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.primaryPurple),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '약속까지 D-2',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '5월 24일 (금) 오늘',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const _ActionTile(icon: Icons.ios_share, label: '공유'),
          const SizedBox(width: AppSpacing.xs),
          const _ActionTile(icon: Icons.person_add_alt_1, label: '초대'),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgPurpleSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: SizedBox(
        width: 56,
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primaryPurple),
            const SizedBox(height: AppSpacing.xxs),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({required this.members});

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
              for (final member in members) _MemberBadge(member: member),
              const _AddMemberBadge(),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberBadge extends StatelessWidget {
  const _MemberBadge({required this.member});

  final MeetupMember member;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          PixelAvatar(label: member.name, size: 46),
          const SizedBox(height: AppSpacing.xs),
          Text(member.name, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _AddMemberBadge extends StatelessWidget {
  const _AddMemberBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.linePurple),
            ),
            child: const SizedBox.square(
              dimension: 46,
              child: Icon(Icons.add, color: AppColors.primaryPurple),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('추가', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const SizedBox.square(
              dimension: 52,
              child: Icon(Icons.calendar_month, color: AppColors.primaryPurple),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('선택한 일정', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  meetup.dateTime,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                const OnmuChip(label: '모두 가능한 시간', selected: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitPlanCard extends StatelessWidget {
  const _VisitPlanCard({required this.visitPlan});

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
          for (var index = 0; index < visitPlan.length; index++)
            _VisitPlanRow(
              order: index + 1,
              plan: visitPlan[index],
              isLast: index == visitPlan.length - 1,
            ),
        ],
      ),
    );
  }
}

class _VisitPlanRow extends StatelessWidget {
  const _VisitPlanRow({
    required this.order,
    required this.plan,
    required this.isLast,
  });

  final int order;
  final VisitPlan plan;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                Text(plan.time, style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  '~ ${plan.endTime}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: SizedBox.square(
                  dimension: 26,
                  child: Center(
                    child: Text(
                      '$order',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isLast)
                const Expanded(
                  child: VerticalDivider(
                    color: AppColors.linePurple,
                    thickness: 1,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.place,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${plan.kind} · 예상 소요 ${plan.duration}',
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _MemoCard extends StatelessWidget {
  const _MemoCard({required this.memo});

  final String memo;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      child: Row(
        children: [
          const Icon(
            Icons.sticky_note_2_outlined,
            color: AppColors.accentBrown,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('메모', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(memo, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primaryPurple),
              const SizedBox(width: AppSpacing.sm),
              Text('상태', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OnmuSecondaryButton(
                  label: '출발했어요',
                  icon: Icons.near_me_outlined,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: OnmuSecondaryButton(
                  label: '도착했어요',
                  icon: Icons.location_on_outlined,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          OnmuSecondaryButton(
            label: '늦을 것 같아요',
            icon: Icons.access_time,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

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
