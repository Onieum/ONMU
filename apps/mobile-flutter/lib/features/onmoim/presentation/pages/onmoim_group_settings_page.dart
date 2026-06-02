import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class OnMoimGroupSettingsPage extends StatefulWidget {
  const OnMoimGroupSettingsPage({required this.onmoimId, super.key});

  final String onmoimId;

  @override
  State<OnMoimGroupSettingsPage> createState() =>
      _OnMoimGroupSettingsPageState();
}

class _OnMoimGroupSettingsPageState extends State<OnMoimGroupSettingsPage> {
  late final OnMoimGroup _group = demoOnMoimGroups.firstWhere(
    (group) => group.id == widget.onmoimId,
    orElse: () => demoOnMoimGroups.first,
  );
  late String _groupName = _group.name;
  bool _chatNotificationEnabled = true;
  bool _meetupNotificationEnabled = true;
  bool _memoryNotificationEnabled = false;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '모임 설정',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go(RoutePaths.onmoimDetail(widget.onmoimId));
      },
      children: [
        _GroupHeader(name: _groupName, group: _group),
        const SizedBox(height: AppSpacing.lg),
        _SettingsSection(
          title: '모임 정보',
          children: [
            _NameSettingCard(
              groupName: _groupName,
              description: _group.description,
              onRenamePressed: _showRenameSheet,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsSection(
          title: '알림',
          children: [
            _SwitchSettingCard(
              icon: Icons.chat_bubble_outline,
              title: '새 채팅',
              subtitle: '친구들이 남긴 이야기를 놓치지 않아요.',
              value: _chatNotificationEnabled,
              onChanged: (value) {
                setState(() => _chatNotificationEnabled = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _SwitchSettingCard(
              icon: Icons.calendar_month_outlined,
              title: '약속 변경',
              subtitle: '시간, 장소, 후보 변경을 알려드려요.',
              value: _meetupNotificationEnabled,
              onChanged: (value) {
                setState(() => _meetupNotificationEnabled = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _SwitchSettingCard(
              icon: Icons.photo_library_outlined,
              title: '추억 업로드',
              subtitle: '사진과 기록이 올라오면 살짝 알려드려요.',
              value: _memoryNotificationEnabled,
              onChanged: (value) {
                setState(() => _memoryNotificationEnabled = value);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsSection(
          title: '함께하는 멤버',
          children: [_MemberSummaryCard(members: _group.members)],
        ),
        const SizedBox(height: AppSpacing.lg),
        _LeaveGroupCard(onLeavePressed: _confirmLeaveGroup),
      ],
    );
  }

  Future<void> _showRenameSheet() async {
    final controller = TextEditingController(text: _groupName);

    try {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.transparent,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: _RenameGroupSheet(controller: controller),
          );
        },
      );

      if (!mounted || result == null || result.isEmpty) {
        return;
      }

      setState(() => _groupName = result);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmLeaveGroup() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgDefault,
          title: const Text('모임을 나갈까요?'),
          content: Text('$_groupName에서 나가면 이 모임의 채팅과 약속을 더 이상 볼 수 없어요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: AppColors.textInverse,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('나가기'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldLeave != true) {
      return;
    }

    context.go(RoutePaths.onmoim);
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.name, required this.group});

  final String name;
  final OnMoimGroup group;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.linePurple,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleSoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const SizedBox.square(
              dimension: 64,
              child: Icon(
                Icons.groups_2_outlined,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  group.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OnmuChip(label: '${group.members.length}명'),
                    const OnmuChip(label: '공동 모임'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    );
  }
}

class _NameSettingCard extends StatelessWidget {
  const _NameSettingCard({
    required this.groupName,
    required this.description,
    required this.onRenamePressed,
  });

  final String groupName;
  final String description;
  final VoidCallback onRenamePressed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.edit_note, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(groupName, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.outlined(
            tooltip: '모임 이름 변경',
            onPressed: onRenamePressed,
            icon: const Icon(Icons.drive_file_rename_outline),
          ),
        ],
      ),
    );
  }
}

class _SwitchSettingCard extends StatelessWidget {
  const _SwitchSettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: value
                ? AppColors.primaryPinkSoft
                : AppColors.bgPaper,
            foregroundColor: value
                ? AppColors.primaryPink
                : AppColors.textMuted,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primaryPurple,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MemberSummaryCard extends StatelessWidget {
  const _MemberSummaryCard({required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '모두 같은 권한으로 약속과 기록을 함께 관리해요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [for (final member in members) OnmuChip(label: member)],
          ),
        ],
      ),
    );
  }
}

class _LeaveGroupCard extends StatelessWidget {
  const _LeaveGroupCard({required this.onLeavePressed});

  final VoidCallback onLeavePressed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.linePink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.logout, color: AppColors.accentRed),
              const SizedBox(width: AppSpacing.sm),
              Text('모임 나가기', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '나간 뒤에는 온모임 목록에서 이 모임이 보이지 않아요.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentRed,
                side: const BorderSide(color: AppColors.linePink),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              onPressed: onLeavePressed,
              icon: const Icon(Icons.logout),
              label: const Text('모임 나가기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenameGroupSheet extends StatelessWidget {
  const _RenameGroupSheet({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.lineBrown,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const SizedBox(width: 44, height: 5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('모임 이름 변경', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '모임 이름',
                hintText: '새 모임 이름을 입력해 주세요',
              ),
              onSubmitted: (_) => _submit(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OnmuSecondaryButton(
                    label: '취소',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OnmuPrimaryButton(
                    label: '저장',
                    icon: Icons.check,
                    color: AppColors.primaryPurple,
                    foregroundColor: AppColors.textInverse,
                    onPressed: () => _submit(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final value = controller.text.trim();
    if (value.isEmpty) {
      return;
    }

    Navigator.of(context).pop(value);
  }
}
