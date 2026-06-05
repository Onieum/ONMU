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
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
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
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _locationController = TextEditingController();
  final _memoController = TextEditingController();
  int? _loadedPlanId;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _titleController,
      _startController,
      _endController,
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
      _startController,
      _endController,
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
    _startController.text = plan.dateTime;
    _endController.text = plan.dateTime;
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

        return _PlanCreateContent(
          groupId: widget.groupId,
          editingPlanId: widget.editingPlanId,
          titleController: _titleController,
          startController: _startController,
          endController: _endController,
          locationController: _locationController,
          memoController: _memoController,
          selectedMembers: state.selectedMembers,
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
                          dateTime:
                              '${_startController.text} - ${_endController.text}',
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
    required this.startController,
    required this.endController,
    required this.locationController,
    required this.memoController,
    required this.selectedMembers,
    required this.onSave,
    this.editingPlanId,
  });

  final String groupId;
  final String? editingPlanId;
  final TextEditingController titleController;
  final TextEditingController startController;
  final TextEditingController endController;
  final TextEditingController locationController;
  final TextEditingController memoController;
  final List<PlanMember> selectedMembers;
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
        _DateTimeField(label: '시작', controller: startController),
        const SizedBox(height: AppSpacing.sm),
        _DateTimeField(label: '끝', controller: endController),
        const SizedBox(height: AppSpacing.lg),
        _LocationField(controller: locationController),
        const SizedBox(height: AppSpacing.lg),
        Text('참여 멤버', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        _MemberPickerRow(members: selectedMembers),
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

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('지역', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_on_outlined),
            suffixIcon: Icon(Icons.cancel),
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
    return Row(
      children: [
        for (final member in members) ...[
          _MemberBadge(member: member),
          const SizedBox(width: AppSpacing.sm),
        ],
        _AddMemberBadge(),
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
