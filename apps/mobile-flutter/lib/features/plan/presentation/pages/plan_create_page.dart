import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/models/plan_models.dart';
import '../../../../shared/widgets/onmu_date_time_range_picker.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../view_model/plan_detail_view_model.dart';

class PlanCreatePage extends ConsumerStatefulWidget {
  const PlanCreatePage({required this.groupId, super.key, this.editingPlanId});

  final String groupId;
  final String? editingPlanId;

  @override
  ConsumerState<PlanCreatePage> createState() => _PlanCreatePageState();
}

class _PlanCreatePageState extends ConsumerState<PlanCreatePage> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _memoController = TextEditingController();
  late DateTime _startsAt;
  late DateTime _endsAt;
  int? _loadedPlanId;

  @override
  void initState() {
    super.initState();
    _startsAt = _defaultStartDateTime();
    _endsAt = _startsAt.add(const Duration(hours: 2));
    for (final controller in [
      _titleController,
      _locationController,
      _memoController,
    ]) {
      controller.addListener(_sync);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _titleController,
      _locationController,
      _memoController,
    ]) {
      controller
        ..removeListener(_sync)
        ..dispose();
    }
    super.dispose();
  }

  void _sync() => setState(() {});

  void _loadPlanIntoForm(Plan plan) {
    if (_loadedPlanId == plan.id) {
      return;
    }
    _loadedPlanId = plan.id;
    _titleController.text = plan.title;
    final parsedStartsAt = _parsePlanDateTime(plan.dateTime);
    if (parsedStartsAt != null) {
      _startsAt = parsedStartsAt;
      _endsAt = parsedStartsAt.add(const Duration(hours: 2));
    }
    _locationController.text = plan.location;
    _memoController.text = plan.memo;
  }

  @override
  Widget build(BuildContext context) {
    final provider = planDetailViewModelProvider((
      groupId: widget.groupId,
      planId: widget.editingPlanId ?? '101',
    ));
    final state = ref.watch(provider);

    return state.when(
      data: (state) {
        _loadPlanIntoForm(state.plan);
        final authUser = ref.watch(authUserProvider);

        return _PlanCreateContent(
          groupId: widget.groupId,
          editingPlanId: widget.editingPlanId,
          titleController: _titleController,
          startsAt: _startsAt,
          endsAt: _endsAt,
          onDateTimeChanged: (range) {
            setState(() {
              _startsAt = range.start;
              _endsAt = range.end;
            });
          },
          locationController: _locationController,
          memoController: _memoController,
          selectedMembers: state.selectedMembers,
          groupMembers: state.groupMembers,
          participantArrivals: state.participantArrivals,
          currentUserId: authUser?.id ?? authUser?.publicId ?? '',
          onAddCurrentUser: () =>
              ref.read(provider.notifier).joinAsCurrentUser(),
          onRemoveCurrentUser: () =>
              ref.read(provider.notifier).leaveAsCurrentUser(),
          onSave: _titleController.text.trim().isEmpty
              ? null
              : () async {
                  final plan = await ref
                      .read(provider.notifier)
                      .savePlan(
                        editing: widget.editingPlanId != null,
                        input: PlanCreateInput(
                          groupId: widget.groupId,
                          title: _titleController.text,
                          dateTime: _startsAt.toIso8601String(),
                          location: _locationController.text,
                          memo: _memoController.text,
                          members: state.plan.members,
                        ),
                      );
                  if (!context.mounted) {
                    return;
                  }
                  context.go(RoutePaths.planDetail(widget.groupId, plan.id));
                },
        );
      },
      loading: () => const OnmuScaffold(
        title: '약속 만들기',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '약속 만들기',
        children: [
          Text(
            '약속 정보를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PlanCreateContent extends StatelessWidget {
  const _PlanCreateContent({
    required this.groupId,
    required this.titleController,
    required this.startsAt,
    required this.endsAt,
    required this.onDateTimeChanged,
    required this.locationController,
    required this.memoController,
    required this.selectedMembers,
    required this.groupMembers,
    required this.participantArrivals,
    required this.currentUserId,
    required this.onAddCurrentUser,
    required this.onRemoveCurrentUser,
    required this.onSave,
    this.editingPlanId,
  });

  final String groupId;
  final String? editingPlanId;
  final TextEditingController titleController;
  final DateTime startsAt;
  final DateTime endsAt;
  final ValueChanged<OnmuDateTimeRange> onDateTimeChanged;
  final TextEditingController locationController;
  final TextEditingController memoController;
  final List<PlanMember> selectedMembers;
  final List<GroupMemberProfile> groupMembers;
  final List<PlanParticipantArrival> participantArrivals;
  final String currentUserId;
  final Future<void> Function() onAddCurrentUser;
  final Future<void> Function() onRemoveCurrentUser;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final editing = editingPlanId != null;

    return OnmuScaffold(
      title: editing ? '약속 수정하기' : '약속 만들기',
      showBackButton: true,
      onBack: () {
        final fallback = editing
            ? RoutePaths.planDetail(groupId, editingPlanId!)
            : RoutePaths.groupDetail(groupId);
        context.popOrGo(fallback);
      },
      bottom: OnmuPrimaryButton(
        label: editing ? '수정 완료' : '약속 만들기',
        icon: editing ? Icons.check : Icons.add_task,
        color: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        onPressed: onSave,
      ),
      children: [
        _LabeledField(label: '약속 이름', controller: titleController),
        const SizedBox(height: AppSpacing.lg),
        Text('날짜와 시간', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        _DateTimeRangeField(
          startsAt: startsAt,
          endsAt: endsAt,
          onChanged: onDateTimeChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        _LocationField(controller: locationController),
        const SizedBox(height: AppSpacing.lg),
        Text('참여 멤버', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        _MemberPickerRow(
          members: selectedMembers,
          groupMembers: groupMembers,
          participantArrivals: participantArrivals,
          currentUserId: currentUserId,
          onAddCurrentUser: onAddCurrentUser,
          onRemoveCurrentUser: onRemoveCurrentUser,
        ),
        const SizedBox(height: AppSpacing.lg),
        _LabeledField(label: '메모', controller: memoController),
        const SizedBox(height: AppSpacing.xl),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.linePink,
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primaryPink),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '장소는 다음 단계에서 함께 정해요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(controller: controller),
      ],
    );
  }
}

class _DateTimeRangeField extends StatelessWidget {
  const _DateTimeRangeField({
    required this.startsAt,
    required this.endsAt,
    required this.onChanged,
  });

  final DateTime startsAt;
  final DateTime endsAt;
  final ValueChanged<OnmuDateTimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: () async {
        final picked = await OnmuDateTimeRangePicker.show(
          context: context,
          initialStart: startsAt,
          initialEnd: endsAt,
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.event_available, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('선택한 일정', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${_formatPlanDate(startsAt)} · ${_formatPlanTime(startsAt)} ~ ${_formatPlanTime(endsAt)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.expand_more, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _LocationField extends StatefulWidget {
  const _LocationField({required this.controller});

  final TextEditingController controller;

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
  }

  @override
  void didUpdateWidget(covariant _LocationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    super.dispose();
  }

  void _sync() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('지역', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: const ValueKey('plan-location-field'),
          controller: widget.controller,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: hasText
                ? IconButton(
                    tooltip: '지역 지우기',
                    onPressed: widget.controller.clear,
                    icon: const Icon(Icons.cancel),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _MemberPickerRow extends StatelessWidget {
  const _MemberPickerRow({
    required this.members,
    required this.groupMembers,
    required this.participantArrivals,
    required this.currentUserId,
    required this.onAddCurrentUser,
    required this.onRemoveCurrentUser,
  });

  final List<PlanMember> members;
  final List<GroupMemberProfile> groupMembers;
  final List<PlanParticipantArrival> participantArrivals;
  final String currentUserId;
  final Future<void> Function() onAddCurrentUser;
  final Future<void> Function() onRemoveCurrentUser;

  @override
  Widget build(BuildContext context) {
    final currentParticipant = _currentParticipant();

    return Row(
      children: [
        for (final member in members) ...[
          _MemberBadge(member: member),
          const SizedBox(width: AppSpacing.sm),
        ],
        _AddMemberBadge(
          onTap: () async {
            final action = await showModalBottomSheet<_PlanMemberPickerAction>(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.transparent,
              builder: (context) => _PlanMemberPickerSheet(
                members: groupMembers,
                selectedNames: members.map((member) => member.name).toSet(),
                currentUserParticipating: currentParticipant != null,
                canRemoveCurrentUser: currentParticipant != null,
              ),
            );
            if (action == null || !context.mounted) {
              return;
            }
            switch (action) {
              case _PlanMemberPickerAction.addCurrentUser:
                await onAddCurrentUser();
              case _PlanMemberPickerAction.removeCurrentUser:
                await onRemoveCurrentUser();
            }
            if (!context.mounted) {
              return;
            }
            final message = switch (action) {
              _PlanMemberPickerAction.addCurrentUser => '내 참여 상태를 추가했어요.',
              _PlanMemberPickerAction.removeCurrentUser => '내 참여를 취소했어요.',
            };
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          },
        ),
      ],
    );
  }

  PlanParticipantArrival? _currentParticipant() {
    final normalizedCurrentUserId = currentUserId.trim();
    if (normalizedCurrentUserId.isEmpty) {
      return null;
    }

    for (final participant in participantArrivals) {
      if (participant.isFallback) {
        continue;
      }
      final status = participant.participantStatus.trim().toLowerCase();
      if (status == 'left' || status == 'declined') {
        continue;
      }
      if (participant.userId == normalizedCurrentUserId) {
        return participant;
      }
    }
    return null;
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
          PixelAvatar(
            label: member.name,
            size: 42,
            profileImageUrl: member.profileImageUrl,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            member.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _AddMemberBadge extends StatelessWidget {
  const _AddMemberBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: Column(
        children: [
          Tooltip(
            message: '참여 멤버 추가',
            child: Material(
              key: const ValueKey('plan-member-add-button'),
              color: AppColors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: onTap,
                child: DecoratedBox(
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
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('추가', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _PlanMemberPickerSheet extends StatelessWidget {
  const _PlanMemberPickerSheet({
    required this.members,
    required this.selectedNames,
    required this.currentUserParticipating,
    required this.canRemoveCurrentUser,
  });

  final List<GroupMemberProfile> members;
  final Set<String> selectedNames;
  final bool currentUserParticipating;
  final bool canRemoveCurrentUser;

  @override
  Widget build(BuildContext context) {
    final activeMembers = members
        .where((member) => !member.invited)
        .toList(growable: false);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgGrid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '참여 멤버 추가',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '모임 멤버만 약속에 참여할 수 있어요.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: AppSpacing.md),
              OnmuCard(
                backgroundColor: AppColors.bgDefault,
                borderColor: AppColors.linePink,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1,
                      color: AppColors.primaryPink,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '현재 서버 계약상 내 참여만 직접 추가할 수 있어요.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: currentUserParticipating
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pop(_PlanMemberPickerAction.addCurrentUser),
                      child: Text(
                        currentUserParticipating ? '참여 중' : '내 참여 추가',
                      ),
                    ),
                    if (canRemoveCurrentUser) ...[
                      const SizedBox(width: AppSpacing.xs),
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(_PlanMemberPickerAction.removeCurrentUser),
                        child: const Text('내 참여 취소'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: activeMembers.isEmpty
                    ? OnmuCard(
                        backgroundColor: AppColors.bgDefault,
                        borderColor: AppColors.lineSoft,
                        child: Text(
                          '불러온 모임 멤버가 없어요.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: activeMembers.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final member = activeMembers[index];
                          final selected = selectedNames.contains(member.name);
                          return OnmuCard(
                            backgroundColor: AppColors.bgDefault,
                            borderColor: selected
                                ? AppColors.linePink
                                : AppColors.lineSoft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                PixelAvatar(
                                  label: member.name,
                                  size: 36,
                                  profileImageUrl: member.profileImageUrl,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        member.note,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSub,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  Text(
                                    '참여 중',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.primaryPink,
                                        ),
                                  ),
                                if (!selected)
                                  Text(
                                    '서버 지원 필요',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PlanMemberPickerAction { addCurrentUser, removeCurrentUser }

DateTime _defaultStartDateTime() {
  final now = DateTime.now();
  final tomorrow = now.add(const Duration(days: 1));
  return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14);
}

DateTime? _parsePlanDateTime(String value) {
  final parsedIso = DateTime.tryParse(value.trim());
  if (parsedIso != null) {
    return parsedIso.toLocal();
  }

  final match = RegExp(
    r'(\d{1,2})[월.]\s*(\d{1,2})(?:일)?(?:[^오\d]*(오전|오후)?)?\s*(\d{1,2})?:?(\d{2})?',
  ).firstMatch(value);
  if (match == null) {
    return null;
  }

  final now = DateTime.now();
  final month = int.tryParse(match.group(1) ?? '');
  final day = int.tryParse(match.group(2) ?? '');
  if (month == null || day == null) {
    return null;
  }

  var hour = int.tryParse(match.group(4) ?? '') ?? 14;
  final minute = int.tryParse(match.group(5) ?? '') ?? 0;
  final meridiem = match.group(3);
  if (meridiem == '오후' && hour < 12) {
    hour += 12;
  }
  if (meridiem == '오전' && hour == 12) {
    hour = 0;
  }

  return DateTime(now.year, month, day, hour, minute);
}

String _formatPlanDate(DateTime date) {
  final weekday = const ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];
  return '${date.month}월 ${date.day}일 ($weekday)';
}

String _formatPlanTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
