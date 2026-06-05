import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

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

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '모임 설정',
      showBackButton: true,
      onBack: () => context.go(RoutePaths.groupDetail(widget.onmoimId)),
      useWarmBackground: false,
      children: [
        _SettingsHeroCard(group: _group, groupName: _groupName),
        const SizedBox(height: AppSpacing.lg),
        _SettingActionCard(
          icon: Icons.drive_file_rename_outline,
          title: '모임 이름 변경',
          subtitle: '모임의 이름과 소개를 변경할 수 있어요.',
          onTap: _showRenameSheet,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingActionCard(
          icon: Icons.notifications_none,
          title: '알림',
          subtitle: '모임 알림을 설정하고 관리할 수 있어요.',
          onTap: _showNotificationSheet,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingActionCard(
          icon: Icons.groups_outlined,
          title: '멤버 목록',
          subtitle: '모임원 목록을 확인할 수 있어요.',
          onTap: () => context.go(RoutePaths.groupMembers(widget.onmoimId)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingActionCard(
          icon: Icons.logout,
          title: '모임 나가기',
          subtitle: '모임을 나가면 더 이상 활동할 수 없어요.',
          danger: true,
          onTap: _confirmLeaveGroup,
        ),
        const SizedBox(height: 72),
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

  Future<void> _showNotificationSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return const _NotificationSheet();
      },
    );
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

    context.go(RoutePaths.groups);
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({required this.group, required this.groupName});

  final OnMoimGroup group;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('모임 정보', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: PixelAvatar(label: group.members[0], size: 42),
                    ),
                    PixelAvatar(label: group.members[1], size: 46),
                    Positioned(
                      right: 0,
                      child: PixelAvatar(label: group.members[2], size: 42),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      group.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '멤버 ${group.members.length}명',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingActionCard extends StatelessWidget {
  const _SettingActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.accentRed : AppColors.primaryPink;

    return OnmuCard(
      onTap: onTap,
      backgroundColor: danger ? AppColors.primaryPinkSoft : AppColors.bgDefault,
      borderColor: danger ? AppColors.linePink : AppColors.lineSoft,
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: AppSpacing.md),
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
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
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
            Row(
              children: [
                Text(
                  '모임 이름 변경',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${controller.text.characters.length}/20',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              maxLength: 20,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '모임 이름',
                helperText: '모임원에게 보이는 이름이에요.',
                counterText: '',
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

class _NotificationSheet extends StatefulWidget {
  const _NotificationSheet();

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  bool _chat = true;
  bool _meetup = true;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('알림', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              value: _chat,
              onChanged: (value) => setState(() => _chat = value),
              title: const Text('새 채팅'),
              subtitle: const Text('모임 대화가 올라오면 알려드려요.'),
            ),
            SwitchListTile(
              value: _meetup,
              onChanged: (value) => setState(() => _meetup = value),
              title: const Text('약속 변경'),
              subtitle: const Text('약속 시간과 장소 변경을 알려드려요.'),
            ),
            const SizedBox(height: AppSpacing.md),
            OnmuPrimaryButton(
              label: '완료',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
