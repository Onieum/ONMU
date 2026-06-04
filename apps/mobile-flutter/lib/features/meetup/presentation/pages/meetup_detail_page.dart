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
    this.placeConfirmed = false,
  });

  final String onmoimId;
  final String meetupId;
  final bool placeConfirmed;

  @override
  Widget build(BuildContext context) {
    final members = mockMembers.where((member) => member.selected).toList();

    if (!placeConfirmed) {
      return _DraftMeetupDetail(
        onmoimId: onmoimId,
        meetupId: meetupId,
        members: members,
      );
    }

    return _ConfirmedMeetupDetail(
      onmoimId: onmoimId,
      meetupId: meetupId,
      members: members,
    );
  }
}

class _DraftMeetupDetail extends StatelessWidget {
  const _DraftMeetupDetail({
    required this.onmoimId,
    required this.meetupId,
    required this.members,
  });

  final String onmoimId;
  final String meetupId;
  final List<MeetupMember> members;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '제주도 여행',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go(RoutePaths.onmoimDetail(onmoimId));
      },
      action: IconButton(
        tooltip: '더보기',
        onPressed: () {},
        icon: const Icon(Icons.more_vert),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OnmuPrimaryButton(
            label: '장소 검색하기',
            icon: Icons.add_location_alt_outlined,
            color: AppColors.primaryPink,
            foregroundColor: AppColors.textInverse,
            onPressed: () => context.push(
              RoutePaths.onmoimMeetupPlaceMap(onmoimId, meetupId),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OnmuSecondaryButton(
            label: '후보 리스트 보기',
            icon: Icons.favorite_border,
            onPressed: () =>
                context.push(RoutePaths.onmoimMeetupPlaces(onmoimId, meetupId)),
          ),
        ],
      ),
      children: [
        _MeetupMetaRow(members: members),
        const SizedBox(height: AppSpacing.xl),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          child: SizedBox(
            height: 320,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 88,
                  color: AppColors.primaryPink,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('일정이 없어요', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '장소를 검색하거나 후보 리스트에서 골라볼까요?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmedMeetupDetail extends StatefulWidget {
  const _ConfirmedMeetupDetail({
    required this.onmoimId,
    required this.meetupId,
    required this.members,
  });

  final String onmoimId;
  final String meetupId;
  final List<MeetupMember> members;

  @override
  State<_ConfirmedMeetupDetail> createState() => _ConfirmedMeetupDetailState();
}

class _ConfirmedMeetupDetailState extends State<_ConfirmedMeetupDetail> {
  var _selectedDateIndex = 0;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '제주도 여행',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go(RoutePaths.onmoimDetail(widget.onmoimId));
      },
      action: IconButton(
        tooltip: '더보기',
        onPressed: () {},
        icon: const Icon(Icons.more_vert),
      ),
      bottom: OnmuPrimaryButton(
        label: '저장하기',
        icon: Icons.check,
        color: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        onPressed: () => context.go(RoutePaths.onmoimDetail(widget.onmoimId)),
      ),
      children: [
        _MeetupMetaRow(members: widget.members),
        const SizedBox(height: AppSpacing.md),
        _DateTabs(
          selectedIndex: _selectedDateIndex,
          onChanged: (index) => setState(() => _selectedDateIndex = index),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text('일정 타임라인', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OnmuSecondaryButton(
                label: '후보 리스트 보기',
                icon: Icons.favorite_border,
                onPressed: () => context.push(
                  RoutePaths.onmoimMeetupPlaces(
                    widget.onmoimId,
                    widget.meetupId,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OnmuSecondaryButton(
                label: '동선 보기',
                icon: Icons.route_outlined,
                onPressed: () => context.push(
                  RoutePaths.onmoimMeetupRouteReview(
                    widget.onmoimId,
                    widget.meetupId,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _TimelineCard(visitPlan: mockMeetup.visitPlan),
      ],
    );
  }
}

class _MeetupMetaRow extends StatelessWidget {
  const _MeetupMetaRow({required this.members});

  final List<MeetupMember> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: const [
            OnmuChip(label: '6.7 (금) 오전 10:00'),
            OnmuChip(label: '제주도 일대'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '참여자 ${members.length}명',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final member in members) ...[
              _MemberBadge(member: member),
              const SizedBox(width: AppSpacing.sm),
            ],
            const _AddMemberBadge(),
          ],
        ),
      ],
    );
  }
}

class _MemberBadge extends StatelessWidget {
  const _MemberBadge({required this.member});

  final MeetupMember member;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: Column(
        children: [
          PixelAvatar(label: member.name, size: 42),
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
      width: 50,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.lineBrown),
            ),
            child: const SizedBox.square(
              dimension: 42,
              child: Icon(Icons.add, color: AppColors.primaryPink),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('추가', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _DateTabs extends StatelessWidget {
  const _DateTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = ['6/7 토', '6/8 일', '6/9 월'];

    return Row(
      children: [
        for (var index = 0; index < tabs.length; index += 1)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: index == selectedIndex
                          ? AppColors.primaryPink
                          : AppColors.lineSoft,
                      width: 2,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: index == selectedIndex
                          ? AppColors.primaryPink
                          : AppColors.textSub,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.visitPlan});

  final List<VisitPlan> visitPlan;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Column(
        children: [
          for (var index = 0; index < visitPlan.length; index += 1)
            _TimelineItem(order: index + 1, plan: visitPlan[index]),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.order, required this.plan});

  final int order;
  final VisitPlan plan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              children: [
                Text(plan.time, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xxs),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: SizedBox.square(
                    dimension: 24,
                    child: Center(
                      child: Text(
                        '$order',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.textInverse),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OnmuCard(
              backgroundColor: AppColors.bgPaper,
              borderColor: AppColors.lineSoft,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.place,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${plan.kind} · ${plan.duration}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '일정 더보기',
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz),
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
