import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/plan_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_location_subtitle.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../view_model/plan_detail_view_model.dart';
import '../../widgets/plan_member_avatar_row.dart';

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
  var _selectedDateIndex = 0;

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
        onEditPressed: () => context.push(
          '${RoutePaths.planNew(widget.groupId)}?edit=${widget.planId}',
        ),
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
        _PlanMemberSection(members: widget.detail.selectedMembers),
        if (widget.detail.canShareArrivalStatus) ...[
          const SizedBox(height: AppSpacing.md),
          _ArrivalStatusSection(
            groupId: widget.groupId,
            planId: widget.planId,
            participants: widget.detail.participantArrivals,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _DateTabs(
          selectedIndex: _selectedDateIndex,
          onChanged: (index) => setState(() => _selectedDateIndex = index),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('일정 타임라인', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _PlanItineraryPreviewSection(visitPlan: selectedVisitPlan),
        const SizedBox(height: AppSpacing.md),
        _TimelineCard(visitPlan: selectedVisitPlan),
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
  var _selectedDateIndex = 0;

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
        onEditPressed: () => context.push(
          '${RoutePaths.planNew(widget.groupId)}?edit=${widget.planId}',
        ),
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
        _PlanMemberSection(members: widget.detail.selectedMembers),
        if (widget.detail.canShareArrivalStatus) ...[
          const SizedBox(height: AppSpacing.md),
          _ArrivalStatusSection(
            groupId: widget.groupId,
            planId: widget.planId,
            participants: widget.detail.participantArrivals,
          ),
        ],
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
        _PlanItineraryPreviewSection(visitPlan: selectedVisitPlan),
        const SizedBox(height: AppSpacing.md),
        _TimelineCard(visitPlan: selectedVisitPlan),
        const SizedBox(height: AppSpacing.md),
        _PlanMemoSection(memo: widget.detail.plan.memo),
      ],
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
          '${participant.displayName} ${participant.arrivalStatus.label}',
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

class _PlanItineraryPreviewSection extends StatelessWidget {
  const _PlanItineraryPreviewSection({required this.visitPlan});

  final List<VisitPlan> visitPlan;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.bgGrid,
      borderColor: AppColors.lineSoft,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          children: [
            const Positioned.fill(child: _MapFrameBackground()),
            Positioned(
              left: AppSpacing.sm,
              top: AppSpacing.sm,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.lineSoft),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    '좌표 연동 전 미리보기',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.textSub),
                  ),
                ),
              ),
            ),
            if (visitPlan.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    '방문 장소가 정해지면 지도 미리보기를 보여드릴게요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
                  ),
                ),
              )
            else
              for (var index = 0; index < visitPlan.length; index += 1)
                _MapMarker(
                  order: index + 1,
                  place: visitPlan[index].place,
                  alignment: _markerAlignment(index, visitPlan.length),
                ),
          ],
        ),
      ),
    );
  }

  Alignment _markerAlignment(int index, int count) {
    if (count <= 1) {
      return const Alignment(0, 0.1);
    }

    final progress = index / (count - 1);
    final x = -0.72 + (progress * 1.44);
    final wave = index.isEven ? -0.28 : 0.3;
    return Alignment(x, wave);
  }
}

class _MapFrameBackground extends StatelessWidget {
  const _MapFrameBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MapFramePainter());
  }
}

class _MapFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = AppColors.lineBrown.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final gridPaint = Paint()
      ..color = AppColors.lineSoft.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var x = size.width / 4; x < size.width; x += size.width / 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = size.height / 3; y < size.height; y += size.height / 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final route = Path()
      ..moveTo(size.width * 0.14, size.height * 0.62)
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.24,
        size.width * 0.54,
        size.height * 0.78,
        size.width * 0.72,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.24,
        size.width * 0.88,
        size.height * 0.62,
        size.width * 0.92,
        size.height * 0.5,
      );
    canvas.drawPath(route, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.order,
    required this.place,
    required this.alignment,
  });

  final int order;
  final String place;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Tooltip(
        message: place,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primaryPink,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.bgDefault, width: 2),
                ),
                child: SizedBox.square(
                  dimension: 28,
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
              const SizedBox(height: AppSpacing.xxs),
              Text(
                place,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textMain),
              ),
            ],
          ),
        ),
      ),
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
