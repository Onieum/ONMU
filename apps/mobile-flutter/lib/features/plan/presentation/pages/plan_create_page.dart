import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../shared/models/plan_models.dart';
import '../../../../shared/models/preference_profile.dart';
import '../../../../shared/providers/state_providers.dart';
import '../../../../shared/widgets/onmu_date_time_range_picker.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../group/view_model/group_plan_list_view_model.dart';
import '../../../home/view_model/home_view_model.dart';
import '../../repository/plan_repository.dart';
import '../../view_model/plan_detail_view_model.dart';
import '../../widgets/plan_member_avatar_row.dart';

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
  final _dateTimeSectionKey = GlobalKey();
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

  List<PlanMember> _defaultSelectedMembers(
    AuthUser? currentUser,
    PreferenceProfile? preferenceProfile,
  ) {
    final displayName = currentUser?.displayName.trim();
    final name = displayName == null || displayName.isEmpty ? '나' : displayName;
    return [
      PlanMember(
        name: name,
        message: '기본 참여자',
        badge: '참여 중',
        selected: true,
        profileImageUrl: currentUser?.profileImageUrl ?? '',
        preferenceProfile: preferenceProfile,
      ),
    ];
  }

  Future<void> _handleDateTimeChanged(
    OnmuDateTimeRange range,
    List<PlanMember> selectedMembers,
  ) async {
    setState(() {
      _startsAt = range.start;
      _endsAt = range.end;
    });
    await _confirmDifficultMemberTimeIfNeeded(selectedMembers);
  }

  Future<bool> _confirmDifficultMemberTimeIfNeeded(
    List<PlanMember> selectedMembers,
  ) async {
    if (!_hasDifficultMemberForSelectedTime(selectedMembers)) {
      return true;
    }

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgDefault,
          content: const Text('해당 약속 시간에 참여가 힘든 멤버가 있어요. 그래도 진행할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('아니오'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: AppColors.textInverse,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('예'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return false;
    }
    if (shouldProceed != true) {
      _scrollToDateTimeSection();
      return false;
    }
    return true;
  }

  void _scrollToDateTimeSection() {
    FocusManager.instance.primaryFocus?.unfocus();
    final dateTimeContext = _dateTimeSectionKey.currentContext;
    if (dateTimeContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      dateTimeContext,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: 0.1,
    );
  }

  bool _hasDifficultMemberForSelectedTime(List<PlanMember> selectedMembers) {
    return selectedMembers.any(
      (member) =>
          _memberLooksDifficult(member) ||
          _memberUnavailableForSelectedTime(member, _startsAt),
    );
  }

  bool _memberLooksDifficult(PlanMember member) {
    final text = '${member.message} ${member.badge}'.trim();
    return text.contains('힘') ||
        text.contains('어려') ||
        text.contains('불가') ||
        text.contains('피하고');
  }

  bool _memberUnavailableForSelectedTime(PlanMember member, DateTime startsAt) {
    final profile = member.preferenceProfile;
    if (profile == null) {
      return false;
    }
    final localStartsAt = startsAt.toLocal();
    final selectedDate = DateTime(
      localStartsAt.year,
      localStartsAt.month,
      localStartsAt.day,
    );
    return profile.unavailableDates.any((value) {
      final parsed = DateTime.tryParse(value.trim())?.toLocal();
      if (parsed == null) {
        return false;
      }
      return parsed.year == selectedDate.year &&
          parsed.month == selectedDate.month &&
          parsed.day == selectedDate.day;
    });
  }

  void _scheduleLoadPlanIntoForm(Plan plan) {
    if (_loadedPlanId == plan.id) {
      return;
    }
    _loadedPlanId = plan.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _loadPlanIntoForm(plan));
    });
  }

  void _loadPlanIntoForm(Plan plan) {
    _titleController.text = plan.title;
    final parsedStartsAt = plan.startsAt ?? _parsePlanDateTime(plan.dateTime);
    if (parsedStartsAt != null) {
      _startsAt = parsedStartsAt.toUtc();
      _endsAt = (plan.endsAt ?? parsedStartsAt.add(const Duration(hours: 2)))
          .toUtc();
    }
    _locationController.text = plan.location;
    _memoController.text = plan.memo;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.editingPlanId == null) {
      final selectedMembers = _defaultSelectedMembers(
        ref.watch(authUserProvider),
        ref.watch(preferenceProfileProvider),
      );
      return _PlanCreateContent(
        groupId: widget.groupId,
        editingPlanId: null,
        dateTimeSectionKey: _dateTimeSectionKey,
        titleController: _titleController,
        startsAt: _startsAt,
        endsAt: _endsAt,
        onDateTimeChanged: (range) =>
            _handleDateTimeChanged(range, selectedMembers),
        locationController: _locationController,
        memoController: _memoController,
        selectedMembers: selectedMembers,
        onSave: _titleController.text.trim().isEmpty
            ? null
            : () async {
                final canProceed = await _confirmDifficultMemberTimeIfNeeded(
                  selectedMembers,
                );
                if (!canProceed) {
                  return;
                }
                final plan = await ref
                    .read(planRepositoryProvider)
                    .createPlan(
                      PlanCreateInput(
                        groupId: widget.groupId,
                        title: _titleController.text,
                        dateTime: _startsAt.toIso8601String(),
                        endsAt: _endsAt.toIso8601String(),
                        location: _locationController.text,
                        memo: _memoController.text,
                        members: selectedMembers,
                      ),
                    );
                ref.invalidate(groupPlanListViewModelProvider(widget.groupId));
                ref.invalidate(homeViewModelProvider);
                if (!context.mounted) {
                  return;
                }
                context.go(RoutePaths.planDetail(widget.groupId, plan.id));
              },
      );
    }

    final provider = planDetailViewModelProvider((
      groupId: widget.groupId,
      planId: widget.editingPlanId!,
    ));
    final state = ref.watch(provider);

    return state.when(
      data: (state) {
        _scheduleLoadPlanIntoForm(state.plan);

        return _PlanCreateContent(
          groupId: widget.groupId,
          editingPlanId: widget.editingPlanId,
          dateTimeSectionKey: _dateTimeSectionKey,
          titleController: _titleController,
          startsAt: _startsAt,
          endsAt: _endsAt,
          onDateTimeChanged: (range) =>
              _handleDateTimeChanged(range, state.selectedMembers),
          locationController: _locationController,
          memoController: _memoController,
          selectedMembers: state.selectedMembers,
          onSave: _titleController.text.trim().isEmpty
              ? null
              : () async {
                  final canProceed = await _confirmDifficultMemberTimeIfNeeded(
                    state.selectedMembers,
                  );
                  if (!canProceed) {
                    return;
                  }
                  await ref
                      .read(provider.notifier)
                      .savePlan(
                        editing: widget.editingPlanId != null,
                        input: PlanCreateInput(
                          groupId: widget.groupId,
                          title: _titleController.text,
                          dateTime: _startsAt.toIso8601String(),
                          endsAt: _endsAt.toIso8601String(),
                          location: _locationController.text,
                          memo: _memoController.text,
                          members: state.selectedMembers,
                        ),
                      );
                  if (!context.mounted) {
                    return;
                  }
                  context.go(RoutePaths.home);
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
    required this.dateTimeSectionKey,
    required this.titleController,
    required this.startsAt,
    required this.endsAt,
    required this.onDateTimeChanged,
    required this.locationController,
    required this.memoController,
    required this.selectedMembers,
    required this.onSave,
    this.editingPlanId,
  });

  final String groupId;
  final String? editingPlanId;
  final GlobalKey dateTimeSectionKey;
  final TextEditingController titleController;
  final DateTime startsAt;
  final DateTime endsAt;
  final Future<void> Function(OnmuDateTimeRange range) onDateTimeChanged;
  final TextEditingController locationController;
  final TextEditingController memoController;
  final List<PlanMember> selectedMembers;
  final Future<void> Function()? onSave;

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
        onPressed: onSave == null ? null : () => onSave!(),
      ),
      children: [
        _LabeledField(label: '약속 이름', controller: titleController),
        const SizedBox(height: AppSpacing.lg),
        Text('참여 멤버', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        _MemberPickerRow(members: selectedMembers),
        const SizedBox(height: AppSpacing.lg),
        KeyedSubtree(
          key: dateTimeSectionKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('날짜와 시간', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              _DateTimeRangeField(
                startsAt: startsAt,
                endsAt: endsAt,
                participantPreferences: _participantPreferences(
                  selectedMembers,
                ),
                onChanged: onDateTimeChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _LocationField(controller: locationController),
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
    required this.participantPreferences,
    required this.onChanged,
  });

  final DateTime startsAt;
  final DateTime endsAt;
  final List<PreferenceProfile> participantPreferences;
  final Future<void> Function(OnmuDateTimeRange range) onChanged;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: () async {
        final picked = await OnmuDateTimeRangePicker.show(
          context: context,
          initialStart: startsAt,
          initialEnd: endsAt,
          participantPreferences: participantPreferences,
        );
        if (picked != null) {
          await onChanged(picked);
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
  const _MemberPickerRow({required this.members});

  final List<PlanMember> members;

  @override
  Widget build(BuildContext context) {
    return PlanMemberAvatarRow(members: members);
  }
}

DateTime _defaultStartDateTime() {
  final now = DateTime.now();
  final tomorrow = now.add(const Duration(days: 1));
  return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14).toUtc();
}

DateTime? _parsePlanDateTime(String value) {
  final parsedIso = DateTime.tryParse(value.trim());
  if (parsedIso != null) {
    return parsedIso.toUtc();
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

  return DateTime(now.year, month, day, hour, minute).toUtc();
}

String _formatPlanDate(DateTime date) {
  final localDate = date.toLocal();
  final weekday = const [
    '월',
    '화',
    '수',
    '목',
    '금',
    '토',
    '일',
  ][localDate.weekday - 1];
  return '${localDate.month}월 ${localDate.day}일 ($weekday)';
}

String _formatPlanTime(DateTime date) {
  final localDate = date.toLocal();
  final hour = localDate.hour.toString().padLeft(2, '0');
  final minute = localDate.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

List<PreferenceProfile> _participantPreferences(List<PlanMember> members) {
  return members
      .map((member) => member.preferenceProfile)
      .whereType<PreferenceProfile>()
      .toList(growable: false);
}
