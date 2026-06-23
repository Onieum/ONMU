import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/plan_models.dart';
import '../../../../shared/utils/onmu_plan_date_time_format.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_location_subtitle.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../map/view_model/route_recommendation_view_model.dart';
import '../../../place/presentation/widgets/plan_visit_time_picker.dart';
import '../../../place/view_model/place_candidates_view_model.dart';
import '../../view_model/plan_detail_view_model.dart';
import '../../widgets/plan_date_tabs.dart';
import '../../widgets/plan_member_avatar_row.dart';
import '../../widgets/plan_route_map_card.dart';

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
    final scope = (groupId: groupId, planId: planId);
    final provider = planDetailViewModelProvider(scope);
    final state = ref.watch(provider);
    final authUser = ref.watch(authUserProvider);
    final currentUserIds = {
      if (authUser?.id.trim().isNotEmpty == true) authUser!.id.trim(),
      if (authUser?.publicId?.trim().isNotEmpty == true)
        authUser!.publicId!.trim(),
    };

    return state.when(
      data: (state) {
        if (!placeConfirmed) {
          return _DraftPlanDetail(
            groupId: groupId,
            planId: planId,
            detail: state,
            currentUserIds: currentUserIds,
            onRemoveCurrentUser: () =>
                ref.read(provider.notifier).leaveAsCurrentUser(),
          );
        }

        return _ConfirmedPlanDetail(
          groupId: groupId,
          planId: planId,
          detail: state,
          currentUserIds: currentUserIds,
          onRemoveCurrentUser: () =>
              ref.read(provider.notifier).leaveAsCurrentUser(),
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
    required this.currentUserIds,
    required this.onRemoveCurrentUser,
  });

  final String groupId;
  final String planId;
  final PlanDetailState detail;
  final Set<String> currentUserIds;
  final Future<void> Function() onRemoveCurrentUser;

  @override
  State<_DraftPlanDetail> createState() => _DraftPlanDetailState();
}

class _DraftPlanDetailState extends State<_DraftPlanDetail> {
  late int _selectedDateIndex;
  var _dateSelectedByUser = false;

  @override
  void initState() {
    super.initState();
    _selectedDateIndex = widget.detail.firstVisitPlanDateIndex;
  }

  @override
  void didUpdateWidget(covariant _DraftPlanDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId ||
        oldWidget.planId != widget.planId) {
      _dateSelectedByUser = false;
      _selectedDateIndex = widget.detail.firstVisitPlanDateIndex;
      return;
    }
    if (!_dateSelectedByUser &&
        widget.detail.visitPlanForDate(_selectedDateIndex).isEmpty) {
      _selectedDateIndex = widget.detail.firstVisitPlanDateIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedVisitPlan = widget.detail.visitPlanForDate(
      _selectedDateIndex,
    );
    final canLeavePlan =
        widget.detail.participantArrivals.activeParticipantFor(
          widget.currentUserIds,
        ) !=
        null;

    return OnmuScaffold(
      title: widget.detail.plan.title,
      titleSubtitle: OnmuLocationSubtitle(
        location: widget.detail.plan.location,
      ),
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupDetail(widget.groupId)),
      action: _PlanMoreMenu(
        canLeavePlan: canLeavePlan,
        onEditPressed: () =>
            context.push(RoutePaths.planEdit(widget.groupId, widget.planId)),
        onLeavePressed: () => _leavePlan(context, widget.onRemoveCurrentUser),
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
        _PlanScheduleCard(plan: widget.detail.plan),
        const SizedBox(height: AppSpacing.md),
        _PlanMemberSection(members: widget.detail.selectedMembers),
        if (widget.detail.canCreateSettlement) ...[
          const SizedBox(height: AppSpacing.md),
          _SettlementEntryCard(
            onPressed: () => context.push(
              RoutePaths.planSettlementNew(widget.groupId, widget.planId),
            ),
          ),
        ],
        if (widget.detail.canShareArrivalStatus) ...[
          const SizedBox(height: AppSpacing.md),
          _ArrivalStatusSection(
            groupId: widget.groupId,
            planId: widget.planId,
            participants: widget.detail.participantArrivals,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PlanDateTabs(
          tabs: widget.detail.dateTabs,
          selectedIndex: _selectedDateIndex,
          onChanged: (index) => setState(() {
            _dateSelectedByUser = true;
            _selectedDateIndex = index;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('일정 타임라인', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _PlanItineraryPreviewSection(
          groupId: widget.groupId,
          planId: widget.planId,
          visitPlan: selectedVisitPlan,
        ),
        const SizedBox(height: AppSpacing.md),
        _TimelineCard(
          groupId: widget.groupId,
          planId: widget.planId,
          planStartsAt: widget.detail.plan.startsAt,
          planEndsAt: widget.detail.plan.endsAt,
          visitPlan: selectedVisitPlan,
        ),
        const SizedBox(height: AppSpacing.md),
        _PlanMemoSection(memo: widget.detail.plan.memo),
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
  const _PlanMoreMenu({
    required this.canLeavePlan,
    required this.onEditPressed,
    required this.onLeavePressed,
  });

  final bool canLeavePlan;
  final VoidCallback onEditPressed;
  final VoidCallback onLeavePressed;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PlanMenuAction>(
      tooltip: '더보기',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case _PlanMenuAction.edit:
            onEditPressed();
          case _PlanMenuAction.leave:
            onLeavePressed();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _PlanMenuAction.edit,
          child: Text('약속 수정하기'),
        ),
        if (canLeavePlan)
          const PopupMenuItem(
            value: _PlanMenuAction.leave,
            child: Text('약속에서 나가기'),
          ),
      ],
    );
  }
}

enum _PlanMenuAction { edit, leave }

class _ConfirmedPlanDetail extends StatefulWidget {
  const _ConfirmedPlanDetail({
    required this.groupId,
    required this.planId,
    required this.detail,
    required this.currentUserIds,
    required this.onRemoveCurrentUser,
  });

  final String groupId;
  final String planId;
  final PlanDetailState detail;
  final Set<String> currentUserIds;
  final Future<void> Function() onRemoveCurrentUser;

  @override
  State<_ConfirmedPlanDetail> createState() => _ConfirmedPlanDetailState();
}

class _ConfirmedPlanDetailState extends State<_ConfirmedPlanDetail> {
  late int _selectedDateIndex;
  var _dateSelectedByUser = false;

  @override
  void initState() {
    super.initState();
    _selectedDateIndex = widget.detail.firstVisitPlanDateIndex;
  }

  @override
  void didUpdateWidget(covariant _ConfirmedPlanDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId ||
        oldWidget.planId != widget.planId) {
      _dateSelectedByUser = false;
      _selectedDateIndex = widget.detail.firstVisitPlanDateIndex;
      return;
    }
    if (!_dateSelectedByUser &&
        widget.detail.visitPlanForDate(_selectedDateIndex).isEmpty) {
      _selectedDateIndex = widget.detail.firstVisitPlanDateIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedVisitPlan = widget.detail.visitPlanForDate(
      _selectedDateIndex,
    );
    final canLeavePlan =
        widget.detail.participantArrivals.activeParticipantFor(
          widget.currentUserIds,
        ) !=
        null;

    return OnmuScaffold(
      title: widget.detail.plan.title,
      titleSubtitle: OnmuLocationSubtitle(
        location: widget.detail.plan.location,
      ),
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupDetail(widget.groupId)),
      action: _PlanMoreMenu(
        canLeavePlan: canLeavePlan,
        onEditPressed: () =>
            context.push(RoutePaths.planEdit(widget.groupId, widget.planId)),
        onLeavePressed: () => _leavePlan(context, widget.onRemoveCurrentUser),
      ),
      bottom: OnmuPrimaryButton(
        label: '저장하기',
        icon: Icons.check,
        color: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        onPressed: () => context.go(RoutePaths.groupDetail(widget.groupId)),
      ),
      children: [
        _PlanScheduleCard(plan: widget.detail.plan),
        const SizedBox(height: AppSpacing.md),
        _PlanMemberSection(members: widget.detail.selectedMembers),
        if (widget.detail.canCreateSettlement) ...[
          const SizedBox(height: AppSpacing.md),
          _SettlementEntryCard(
            onPressed: () => context.push(
              RoutePaths.planSettlementNew(widget.groupId, widget.planId),
            ),
          ),
        ],
        if (widget.detail.canShareArrivalStatus) ...[
          const SizedBox(height: AppSpacing.md),
          _ArrivalStatusSection(
            groupId: widget.groupId,
            planId: widget.planId,
            participants: widget.detail.participantArrivals,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PlanDateTabs(
          tabs: widget.detail.dateTabs,
          selectedIndex: _selectedDateIndex,
          onChanged: (index) => setState(() {
            _dateSelectedByUser = true;
            _selectedDateIndex = index;
          }),
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
                  RoutePaths.planItinerary(
                    widget.groupId,
                    widget.planId,
                    dateIndex: _selectedDateIndex,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _PlanItineraryPreviewSection(
          groupId: widget.groupId,
          planId: widget.planId,
          visitPlan: selectedVisitPlan,
        ),
        const SizedBox(height: AppSpacing.md),
        _TimelineCard(
          groupId: widget.groupId,
          planId: widget.planId,
          planStartsAt: widget.detail.plan.startsAt,
          planEndsAt: widget.detail.plan.endsAt,
          visitPlan: selectedVisitPlan,
        ),
        const SizedBox(height: AppSpacing.md),
        _PlanMemoSection(memo: widget.detail.plan.memo),
      ],
    );
  }
}

class _PlanScheduleCard extends StatelessWidget {
  const _PlanScheduleCard({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final startsAt = plan.startsAt?.toLocal();
    if (startsAt == null) {
      return const SizedBox.shrink();
    }
    final endsAt =
        plan.endsAt?.toLocal() ?? startsAt.add(const Duration(hours: 2));
    final rangeLabel = formatOnmuPlanDateTimeRange(startsAt, endsAt);

    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPinkSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.linePink),
            ),
            child: const SizedBox.square(
              dimension: 44,
              child: Icon(
                Icons.event_available_rounded,
                color: AppColors.primaryPink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '약속 일정',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryPink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(rangeLabel, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementEntryCard extends StatelessWidget {
  const _SettlementEntryCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.linePink,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPinkSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.linePink),
            ),
            child: const SizedBox.square(
              dimension: 44,
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primaryPink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('정산', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '결제 항목을 입력하거나 확정된 송금 내역을 확인해요.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OnmuSecondaryButton(
                    label: '정산 만들기/결과 보기',
                    icon: Icons.arrow_forward,
                    onPressed: onPressed,
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

class _ArrivalStatusSection extends ConsumerWidget {
  const _ArrivalStatusSection({
    required this.groupId,
    required this.planId,
    required this.participants,
  });

  final String groupId;
  final String planId;
  final List<PlanParticipantArrival> participants;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleParticipants = participants
        .where(
          (participant) => participant.arrivalStatus != PlanArrivalStatus.none,
        )
        .toList(growable: false);

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('약속 상태 알리기', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '출발, 도착, 지각 상태를 모임원에게 공유해요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ArrivalStatusButton(
                  label: '출발',
                  icon: Icons.directions_walk,
                  onPressed: () =>
                      _updateStatus(context, ref, PlanArrivalStatus.departed),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _ArrivalStatusButton(
                  label: '도착',
                  icon: Icons.location_on_outlined,
                  onPressed: () =>
                      _updateStatus(context, ref, PlanArrivalStatus.arrived),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _ArrivalStatusButton(
                  label: '지각',
                  icon: Icons.schedule,
                  onPressed: () =>
                      _updateStatus(context, ref, PlanArrivalStatus.late),
                ),
              ),
            ],
          ),
          if (visibleParticipants.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final participant in visibleParticipants.take(6))
                  _ParticipantArrivalChip(participant: participant),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    PlanArrivalStatus status,
  ) async {
    try {
      await ref
          .read(
            planDetailViewModelProvider((
              groupId: groupId,
              planId: planId,
            )).notifier,
          )
          .updateMyArrivalStatus(status);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${status.label} 상태를 공유했어요.')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상태를 공유하지 못했어요.')));
    }
  }
}

class _ArrivalStatusButton extends StatelessWidget {
  const _ArrivalStatusButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryPurple,
        side: const BorderSide(color: AppColors.linePink),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

class _ParticipantArrivalChip extends StatelessWidget {
  const _ParticipantArrivalChip({required this.participant});

  final PlanParticipantArrival participant;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgSticker,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.linePink),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '${participant.nickname} ${participant.arrivalStatus.label}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.primaryPurpleDark),
        ),
      ),
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
        PlanMemberAvatarRow(members: members),
      ],
    );
  }
}

Future<void> _leavePlan(
  BuildContext context,
  Future<void> Function() onRemoveCurrentUser,
) async {
  try {
    await onRemoveCurrentUser();
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('약속에서 나가지 못했어요.')));
    return;
  }
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('약속에서 나갔어요.')));
}

class _PlanItineraryPreviewSection extends ConsumerWidget {
  const _PlanItineraryPreviewSection({
    required this.groupId,
    required this.planId,
    required this.visitPlan,
  });

  final String groupId;
  final String planId;
  final List<VisitPlan> visitPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(
      routeRecommendationViewModelProvider((
        groupId: groupId,
        planId: planId,
        travelMode: 'walk',
      )),
    );
    return PlanRouteMapCard(
      routeState: routeState,
      visitPlan: visitPlan,
      travelMode: 'walk',
      showTravelModeControls: false,
      height: 240,
    );
  }
}

class _PlanMemoSection extends StatelessWidget {
  const _PlanMemoSection({required this.memo});

  final String memo;

  @override
  Widget build(BuildContext context) {
    final trimmedMemo = memo.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('약속 메모', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OnmuCard(
            backgroundColor: AppColors.bgPaper,
            borderColor: AppColors.lineSoft,
            child: Text(
              trimmedMemo.isEmpty ? '아직 적어둔 메모가 없어요.' : trimmedMemo,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMain),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard({
    required this.groupId,
    required this.planId,
    required this.planStartsAt,
    required this.planEndsAt,
    required this.visitPlan,
  });

  final String groupId;
  final String planId;
  final DateTime? planStartsAt;
  final DateTime? planEndsAt;
  final List<VisitPlan> visitPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Column(
        children: [
          if (visitPlan.isEmpty)
            Text(
              '방문 장소를 추가하면 일정 동선이 표시돼요.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
            )
          else
            for (var index = 0; index < visitPlan.length; index += 1)
              _TimelineItem(
                order: index + 1,
                plan: visitPlan[index],
                onTap: () => _openPlaceSearch(context, visitPlan[index]),
                onEditTime: visitPlan[index].id.trim().isEmpty
                    ? null
                    : () => _editVisitTime(context, ref, visitPlan[index]),
                onDelete: visitPlan[index].id.trim().isEmpty
                    ? null
                    : () => _deleteVisitPlan(context, ref, visitPlan[index]),
              ),
        ],
      ),
    );
  }

  void _openPlaceSearch(BuildContext context, VisitPlan plan) {
    final query = Uri.encodeComponent(plan.place.trim());
    context.push('${RoutePaths.planPlaceSearch(groupId, planId)}?query=$query');
  }

  Future<void> _editVisitTime(
    BuildContext context,
    WidgetRef ref,
    VisitPlan plan,
  ) async {
    final initialStart = _initialVisitStart(plan);
    final picked = await PlanVisitTimePicker.show(
      context: context,
      title: '방문 시간 수정',
      planStartsAt: planStartsAt,
      planEndsAt: planEndsAt,
      initialStart: initialStart,
      initialEnd: _initialVisitEnd(plan, initialStart),
    );
    if (picked == null) {
      return;
    }

    try {
      await ref
          .read(
            placeCandidatesViewModelProvider((
              groupId: groupId,
              planId: planId,
            )).notifier,
          )
          .updateSchedulePlaceTime(
            schedulePlaceId: plan.id,
            startsAt: picked.start,
            endsAt: picked.end,
            note: plan.duration,
          );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('방문 시간을 수정하지 못했어요.')));
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('방문 시간을 수정했어요.')));
  }

  Future<void> _deleteVisitPlan(
    BuildContext context,
    WidgetRef ref,
    VisitPlan plan,
  ) async {
    try {
      await ref
          .read(
            placeCandidatesViewModelProvider((
              groupId: groupId,
              planId: planId,
            )).notifier,
          )
          .deleteSchedulePlace(plan.id);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('방문 장소를 삭제하지 못했어요.')));
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('방문 장소를 삭제했어요.')));
  }

  DateTime _initialVisitStart(VisitPlan plan) {
    final existing = plan.startsAt?.toLocal();
    if (existing != null) {
      return existing;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  DateTime _initialVisitEnd(VisitPlan plan, DateTime start) {
    final existing = plan.endsAt?.toLocal();
    if (existing != null && existing.isAfter(start)) {
      return existing;
    }
    return start.add(const Duration(hours: 1));
  }
}

enum _TimelinePlaceAction { editTime, delete }

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.order,
    required this.plan,
    required this.onTap,
    required this.onEditTime,
    required this.onDelete,
  });

  final int order;
  final VisitPlan plan;
  final VoidCallback onTap;
  final VoidCallback? onEditTime;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final metaLabel = _visitTimeRangeLabel(plan);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              children: [
                if (plan.time.trim().isNotEmpty) ...[
                  Text(
                    plan.time,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
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
              onTap: onTap,
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
                          metaLabel.isEmpty ? '방문 시간 미정' : metaLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_TimelinePlaceAction>(
                    tooltip: '일정 더보기',
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (action) {
                      switch (action) {
                        case _TimelinePlaceAction.editTime:
                          onEditTime?.call();
                          break;
                        case _TimelinePlaceAction.delete:
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _TimelinePlaceAction.editTime,
                        enabled: onEditTime != null,
                        child: const Text('시간 수정'),
                      ),
                      PopupMenuItem(
                        value: _TimelinePlaceAction.delete,
                        enabled: onDelete != null,
                        child: const Text('삭제하기'),
                      ),
                    ],
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

String _visitTimeRangeLabel(VisitPlan plan) {
  final start = plan.time.trim();
  final end = plan.endTime.trim();
  if (start.isEmpty) {
    return end;
  }
  if (end.isEmpty) {
    return start;
  }
  return '$start ~ $end';
}
