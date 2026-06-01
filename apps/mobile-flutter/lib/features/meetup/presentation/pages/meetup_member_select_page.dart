import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/meetup_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/onmu_step_progress.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class MeetupMemberSelectPage extends StatefulWidget {
  const MeetupMemberSelectPage({super.key});

  @override
  State<MeetupMemberSelectPage> createState() => _MeetupMemberSelectPageState();
}

class _MeetupMemberSelectPageState extends State<MeetupMemberSelectPage> {
  late final Set<String> _selectedMemberNames = mockMembers
      .where((member) => member.selected)
      .map((member) => member.name)
      .toSet();

  @override
  Widget build(BuildContext context) {
    final selectedMembers = mockMembers
        .where((member) => _selectedMemberNames.contains(member.name))
        .toList();
    final selectedCount = selectedMembers.length;

    return OnmuScaffold(
      title: '참여자 선택',
      showBackButton: true,
      onBack: () => context.pop(),
      bottom: OnmuCard(
        backgroundColor: AppColors.bgDefault,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.groups_rounded,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '선택된 참여자 $selectedCount/10',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(RoutePaths.meetupNewTitle),
                  child: const OnmuChip(
                    label: '약속 이름 입력',
                    icon: Icons.edit_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OnmuPrimaryButton(
              label: '다음 단계로',
              icon: Icons.arrow_forward,
              onPressed: () => context.push(RoutePaths.meetupNewSchedule),
            ),
          ],
        ),
      ),
      children: [
        const OnmuStepProgress(currentIndex: 0),
        const SizedBox(height: AppSpacing.xl),
        OnmuCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '누구와 함께할까요?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '최대 10명까지 초대할 수 있어요.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              for (final member in selectedMembers)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: PixelAvatar(label: member.name, size: 38),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const TextField(
          decoration: InputDecoration(
            hintText: '이름으로 검색하기',
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.person_add_alt_1_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text('선택된 참여자', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$selectedCount',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.primaryPurple),
            ),
            const Spacer(),
            TextButton(
              onPressed: selectedCount == 0
                  ? null
                  : () => setState(_selectedMemberNames.clear),
              child: const Text('모두 해제'),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final member in selectedMembers)
              GestureDetector(
                key: ValueKey('selected-member-chip-${member.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleMember(member.name),
                child: OnmuChip(
                  label: member.name,
                  selected: true,
                  icon: Icons.close,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final member in mockMembers)
                _FriendRow(
                  member: member,
                  selected: _selectedMemberNames.contains(member.name),
                  onToggle: () => _toggleMember(member.name),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleMember(String name) {
    setState(() {
      if (!_selectedMemberNames.add(name)) {
        _selectedMemberNames.remove(name);
      }
    });
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.member,
    required this.selected,
    required this.onToggle,
  });

  final MeetupMember member;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          PixelAvatar(label: member.name),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              member.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _SelectionStateButton(
            memberName: member.name,
            selected: selected,
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}

class _SelectionStateButton extends StatelessWidget {
  const _SelectionStateButton({
    required this.memberName,
    required this.selected,
    required this.onPressed,
  });

  final String memberName;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: ValueKey('member-toggle-$memberName'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? AppColors.primaryPurple
            : AppColors.bgDefault,
        foregroundColor: selected
            ? AppColors.textInverse
            : AppColors.primaryPurple,
        side: BorderSide(
          color: selected ? AppColors.primaryPurple : AppColors.linePurple,
        ),
        minimumSize: const Size(84, 40),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(selected ? '선택해제' : '선택'),
    );
  }
}
