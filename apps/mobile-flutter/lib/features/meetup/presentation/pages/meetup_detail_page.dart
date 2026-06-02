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
  const MeetupDetailPage({
    required this.onmoimId,
    required this.meetupId,
    super.key,
  });

  final String onmoimId;
  final String meetupId;

  @override
  Widget build(BuildContext context) {
    final meetup = mockMeetup;
    final selectedMembers = meetup.members
        .where((member) => member.selected)
        .toList();

    return OnmuScaffold(
      title: meetup.title,
      showBackButton: true,
      onBack: () => context.pop(),
      action: IconButton(
        tooltip: '더보기',
        onPressed: () {},
        icon: const Icon(Icons.more_vert),
      ),
      bottom: OnmuPrimaryButton(
        label: '지도에서 후보 보기',
        icon: Icons.map_outlined,
        onPressed: () =>
            context.push(RoutePaths.onmoimMeetupPlaceMap(onmoimId, meetup.id)),
      ),
      children: [
        _MeetupHeaderCard(meetup: meetup, members: selectedMembers),
        const SizedBox(height: AppSpacing.sm),
        _CountdownCard(
          onMapPressed: () => context.push(
            RoutePaths.onmoimMeetupPlaceMap(onmoimId, meetup.id),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _MembersCard(members: selectedMembers),
        const SizedBox(height: AppSpacing.sm),
        _ScheduleCard(meetup: meetup),
        const SizedBox(height: AppSpacing.sm),
        _MeetupActionCard(onmoimId: onmoimId, meetupId: meetup.id),
        const SizedBox(height: AppSpacing.md),
        _VisitPlanCard(visitPlan: meetup.visitPlan),
        const SizedBox(height: AppSpacing.md),
        _MemoCard(memo: meetup.memo),
      ],
    );
  }
}

class _MeetupActionCard extends StatelessWidget {
  const _MeetupActionCard({required this.onmoimId, required this.meetupId});

  final String onmoimId;
  final String meetupId;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.dashboard_customize,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '약속 도구',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '후보 비교, 정산, 동선 확인을 여기서 이어갈 수 있어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OnmuSecondaryButton(
                  label: '지도 보기',
                  icon: Icons.map_outlined,
                  onPressed: () => context.push(
                    RoutePaths.onmoimMeetupPlaceMap(onmoimId, meetupId),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OnmuSecondaryButton(
                  label: '정산 보기',
                  icon: Icons.payments_outlined,
                  onPressed: () => context.push(
                    RoutePaths.onmoimMeetupSettlementShare(
                      onmoimId,
                      meetupId,
                      'lunch-split',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OnmuSecondaryButton(
                  label: '약속 보드',
                  icon: Icons.dashboard_outlined,
                  onPressed: () => context.push(
                    RoutePaths.onmoimMeetupBoard(onmoimId, meetupId),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OnmuSecondaryButton(
                  label: '정산 만들기',
                  icon: Icons.receipt_long_outlined,
                  onPressed: () => context.push(
                    RoutePaths.onmoimMeetupSettlementNew(onmoimId, meetupId),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OnmuSecondaryButton(
            label: '동선 확인',
            icon: Icons.route_outlined,
            onPressed: () => context.push(
              RoutePaths.onmoimMeetupRouteReview(onmoimId, meetupId),
            ),
          ),
        ],
      ),
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
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.linePink,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 98,
            height: 62,
            child: Stack(
              children: [
                for (var index = 0; index < members.length; index++)
                  Positioned(
                    left: index * 22,
                    child: PixelAvatar(
                      label: members[index].name,
                      size: 46,
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
                const SizedBox(height: AppSpacing.xs),
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
  const _CountdownCard({required this.onMapPressed});

  final VoidCallback onMapPressed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primaryPurple),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '다음 할 일',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const OnmuChip(label: '장소 진행중', selected: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '장소 후보 3개 중 하나를 골라요. 혜린, 현우 투표가 남았어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          const _ProgressSteps(),
          const SizedBox(height: AppSpacing.md),
          OnmuPrimaryButton(
            label: '지도에서 비교하기',
            icon: Icons.map_outlined,
            onPressed: onMapPressed,
          ),
        ],
      ),
    );
  }
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _ProgressStep(label: '참여자', done: true)),
        SizedBox(width: AppSpacing.xs),
        Expanded(child: _ProgressStep(label: '시간', done: true)),
        SizedBox(width: AppSpacing.xs),
        Expanded(child: _ProgressStep(label: '장소', done: false)),
        SizedBox(width: AppSpacing.xs),
        Expanded(child: _ProgressStep(label: '완료', done: false)),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: done ? AppColors.primaryPurpleSoft : AppColors.bgDefault,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: done ? AppColors.linePurple : AppColors.lineSoft,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: done ? AppColors.primaryPurpleDark : AppColors.textMuted,
          ),
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
              Text(
                '${members.length}명',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
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
