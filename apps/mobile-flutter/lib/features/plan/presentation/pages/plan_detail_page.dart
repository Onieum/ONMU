import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/plan_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../view_model/plan_detail_view_model.dart';

class PlanDetailPage extends ConsumerWidget {
  const PlanDetailPage({
    required this.groupId,
    required this.planId,
    super.key,
    this.placeConfirmed = false,
  });

  final String groupId;
  final String planId;
  final bool placeConfirmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      planDetailViewModelProvider((groupId: groupId, planId: planId)),
    );

    return state.when(
      data: (state) {
        if (!placeConfirmed) {
          return _DraftPlanDetail(
            groupId: groupId,
            planId: planId,
            detail: state,
          );
        }

        return _ConfirmedPlanDetail(
          groupId: groupId,
          planId: planId,
          detail: state,
        );
      },
      loading: () => const OnmuScaffold(
        title: '약속 상세',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '약속 상세',
        children: [
          Text(
            '약속 상세를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DraftPlanDetail extends StatefulWidget {
  const _DraftPlanDetail({
    required this.groupId,
    required this.planId,
    required this.detail,
  });

  final String groupId;
  final String planId;
  final PlanDetailState detail;

  @override
  State<_DraftPlanDetail> createState() => _DraftPlanDetailState();
}

class _DraftPlanDetailState extends State<_DraftPlanDetail> {
  var _selectedDateIndex = 0;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: widget.detail.plan.title,
      titleSubtitle: _PlanLocationSubtitle(
        location: widget.detail.plan.location,
      ),
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go(RoutePaths.groupDetail(widget.groupId));
      },
      action: _PlanMoreMenu(
        onEditPressed: () => context.push(
          '${RoutePaths.planNew(widget.groupId)}?edit=${widget.planId}',
        ),
      ),
      bottom: _DraftPlaceActions(
        onSearchPressed: () => context.push(
          RoutePaths.planPlaceSearch(widget.groupId, widget.planId),
        ),
        onCandidatesPressed: () => context.push(
          RoutePaths.planPlaceCandidates(widget.groupId, widget.planId),
        ),
      ),
      children: [
        _PlanMemberSection(members: widget.detail.selectedMembers),
        const SizedBox(height: AppSpacing.md),
        _DateTabs(
          selectedIndex: _selectedDateIndex,
          onChanged: (index) => setState(() => _selectedDateIndex = index),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('일정 타임라인', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _TimelineCard(
          visitPlan: widget.detail.visitPlanForDate(_selectedDateIndex),
        ),
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
          key: const ValueKey('plan-place-action-search'),
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
          key: const ValueKey('plan-place-action-candidates'),
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

class _PlanMoreMenu extends StatelessWidget {
  const _PlanMoreMenu({required this.onEditPressed});

  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PlanMenuAction>(
      tooltip: '더보기',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case _PlanMenuAction.edit:
            onEditPressed();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: _PlanMenuAction.edit, child: Text('약속 수정하기')),
      ],
    );
  }
}

enum _PlanMenuAction { edit }

class _ConfirmedPlanDetail extends StatefulWidget {
  const _ConfirmedPlanDetail({
    required this.groupId,
    required this.planId,
    required this.detail,
  });

  final String groupId;
  final String planId;
  final PlanDetailState detail;

  @override
  State<_ConfirmedPlanDetail> createState() => _ConfirmedPlanDetailState();
}

class _ConfirmedPlanDetailState extends State<_ConfirmedPlanDetail> {
  var _selectedDateIndex = 0;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: widget.detail.plan.title,
      titleSubtitle: _PlanLocationSubtitle(
        location: widget.detail.plan.location,
      ),
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go(RoutePaths.groupDetail(widget.groupId));
      },
      action: _PlanMoreMenu(
        onEditPressed: () => context.push(
          '${RoutePaths.planNew(widget.groupId)}?edit=${widget.planId}',
        ),
      ),
      bottom: OnmuPrimaryButton(
        label: '저장하기',
        icon: Icons.check,
        color: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        onPressed: () => context.go(RoutePaths.groupDetail(widget.groupId)),
      ),
      children: [
        _PlanMemberSection(members: widget.detail.selectedMembers),
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
                  RoutePaths.planPlaceCandidates(widget.groupId, widget.planId),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OnmuSecondaryButton(
                label: '동선 보기',
                icon: Icons.route_outlined,
                onPressed: () => context.push(
                  RoutePaths.planItinerary(widget.groupId, widget.planId),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _TimelineCard(
          visitPlan: widget.detail.visitPlanForDate(_selectedDateIndex),
        ),
      ],
    );
  }
}

class _PlanLocationSubtitle extends StatelessWidget {
  const _PlanLocationSubtitle({required this.location});

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

class _PlanMemberSection extends StatelessWidget {
  const _PlanMemberSection({required this.members});

  final List<PlanMember> members;

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

class _MemberBadge extends StatelessWidget {
  const _MemberBadge({required this.member});

  final PlanMember member;

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
    final tabs = ['6/7 토', '6/8 일', '6/9 월'];

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
