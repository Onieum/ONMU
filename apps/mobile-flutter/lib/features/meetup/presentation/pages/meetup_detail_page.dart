import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/meetup_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
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

class _DraftMeetupDetail extends StatefulWidget {
  const _DraftMeetupDetail({
    required this.onmoimId,
    required this.meetupId,
    required this.members,
  });

  final String onmoimId;
  final String meetupId;
  final List<MeetupMember> members;

  @override
  State<_DraftMeetupDetail> createState() => _DraftMeetupDetailState();
}

class _DraftMeetupDetailState extends State<_DraftMeetupDetail> {
  var _selectedDateIndex = 0;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '제주도 여행',
      titleSubtitle: const _MeetupLocationSubtitle(location: '제주도 일대'),
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go(RoutePaths.onmoimDetail(widget.onmoimId));
      },
      action: _MeetupMoreMenu(
        onEditPressed: () => context.push(
          '${RoutePaths.onmoimMeetupNewMembers(widget.onmoimId)}?edit=${widget.meetupId}',
        ),
      ),
      bottom: _DraftPlaceActions(
        onSearchPressed: () => context.push(
          RoutePaths.onmoimMeetupPlaceMap(widget.onmoimId, widget.meetupId),
        ),
        onCandidatesPressed: () => context.push(
          RoutePaths.onmoimMeetupPlaces(widget.onmoimId, widget.meetupId),
        ),
      ),
      children: [
        _MeetupMemberSection(members: widget.members),
        const SizedBox(height: AppSpacing.md),
        _DateTabs(
          selectedIndex: _selectedDateIndex,
          onChanged: (index) => setState(() => _selectedDateIndex = index),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('일정 타임라인', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _TimelineCard(visitPlan: _visitPlanByDate(_selectedDateIndex)),
      ],
    );
  }
}

class _DraftPlaceActions extends StatelessWidget {
  const _DraftPlaceActions({
    required this.onSearchPressed,
    required this.onCandidatesPressed,
  });

  static const _buttonHeight = 52.0;

  final VoidCallback onSearchPressed;
  final VoidCallback onCandidatesPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: const ValueKey('meetup-place-action-search'),
          height: _buttonHeight,
          child: OnmuPrimaryButton(
            label: '장소 검색하기',
            icon: Icons.add_location_alt_outlined,
            color: AppColors.primaryPink,
            foregroundColor: AppColors.textInverse,
            onPressed: onSearchPressed,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          key: const ValueKey('meetup-place-action-candidates'),
          height: _buttonHeight,
          child: OnmuSecondaryButton(
            label: '후보 리스트 보기',
            icon: Icons.favorite_border,
            onPressed: onCandidatesPressed,
          ),
        ),
      ],
    );
  }
}

class _MeetupMoreMenu extends StatelessWidget {
  const _MeetupMoreMenu({required this.onEditPressed});

  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MeetupMenuAction>(
      tooltip: '더보기',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case _MeetupMenuAction.edit:
            onEditPressed();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _MeetupMenuAction.edit, child: Text('약속 수정하기')),
      ],
    );
  }
}

enum _MeetupMenuAction { edit }

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
      titleSubtitle: const _MeetupLocationSubtitle(location: '제주도 일대'),
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go(RoutePaths.onmoimDetail(widget.onmoimId));
      },
      action: _MeetupMoreMenu(
        onEditPressed: () => context.push(
          '${RoutePaths.onmoimMeetupNewMembers(widget.onmoimId)}?edit=${widget.meetupId}',
        ),
      ),
      bottom: OnmuPrimaryButton(
        label: '저장하기',
        icon: Icons.check,
        color: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        onPressed: () => context.go(RoutePaths.onmoimDetail(widget.onmoimId)),
      ),
      children: [
        _MeetupMemberSection(members: widget.members),
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
        _TimelineCard(visitPlan: _visitPlanByDate(_selectedDateIndex)),
      ],
    );
  }
}

class _MeetupLocationSubtitle extends StatelessWidget {
  const _MeetupLocationSubtitle({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 16,
          color: AppColors.textSub,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          location,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
        ),
      ],
    );
  }
}

class _MeetupMemberSection extends StatelessWidget {
  const _MeetupMemberSection({required this.members});

  final List<MeetupMember> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

List<VisitPlan> _visitPlanByDate(int index) {
  switch (index) {
    case 1:
      return const [
        VisitPlan(
          time: '10:30',
          endTime: '12:00',
          place: '협재 해수욕장',
          kind: '관광',
          duration: '1시간 30분',
        ),
        VisitPlan(
          time: '12:20',
          endTime: '13:40',
          place: '한림 흑돼지 식당',
          kind: '식사',
          duration: '1시간 20분',
        ),
        VisitPlan(
          time: '14:10',
          endTime: '16:00',
          place: '카페 오션뷰',
          kind: '카페',
          duration: '1시간 50분',
        ),
      ];
    case 2:
      return const [
        VisitPlan(
          time: '09:30',
          endTime: '11:00',
          place: '오름 산책로',
          kind: '산책',
          duration: '1시간 30분',
        ),
        VisitPlan(
          time: '11:30',
          endTime: '13:00',
          place: '동문시장',
          kind: '식사',
          duration: '1시간 30분',
        ),
      ];
    default:
      return mockMeetup.visitPlan;
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
