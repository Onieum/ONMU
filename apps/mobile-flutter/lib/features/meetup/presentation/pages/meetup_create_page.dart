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

class MeetupCreatePage extends StatelessWidget {
  const MeetupCreatePage({
    required this.onmoimId,
    super.key,
    this.editingMeetupId,
  });

  final String onmoimId;
  final String? editingMeetupId;

  @override
  Widget build(BuildContext context) {
    final selectedMembers = mockMembers
        .where((member) => member.selected)
        .toList();
    final editing = editingMeetupId != null;

    return OnmuScaffold(
      title: editing ? '약속 수정하기' : '약속 만들기',
      showBackButton: true,
      onBack: () => context.pop(),
      bottom: OnmuPrimaryButton(
        label: editing ? '수정 완료' : '약속 만들기',
        icon: editing ? Icons.check : Icons.add_task,
        color: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        onPressed: () => context.go(
          RoutePaths.onmoimMeetupDetail(
            onmoimId,
            editingMeetupId ?? mockMeetup.id,
          ),
        ),
      ),
      children: [
        _LabeledField(label: '약속 이름', value: '제주도 여행'),
        const SizedBox(height: AppSpacing.lg),
        Text('날짜와 시간', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        const _DateTimeField(label: '시작', value: '2024.06.07 (금)  오전 10:00'),
        const SizedBox(height: AppSpacing.sm),
        const _DateTimeField(label: '끝', value: '2024.06.09 (일)  오후 6:00'),
        const SizedBox(height: AppSpacing.lg),
        _LocationField(value: '제주도 일대'),
        const SizedBox(height: AppSpacing.lg),
        Text('참여 멤버', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        _MemberPickerRow(members: selectedMembers),
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
  const _LabeledField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(initialValue: value),
      ],
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('지역', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: value,
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

  final List<MeetupMember> members;

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

  final MeetupMember member;

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
