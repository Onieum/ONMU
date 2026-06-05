import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../view_model/group_members_view_model.dart';

class GroupSettingsPage extends StatefulWidget {
  const GroupSettingsPage({required this.groupId, super.key});

  final String groupId;

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  String? _groupName;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(groupMembersViewModelProvider(widget.groupId));

        return state.when(
          data: (state) {
            _groupName ??= state.group.name;
            return _GroupSettingsContent(
              groupId: widget.groupId,
              group: state.group,
              groupName: _groupName!,
              onRename: _showRenameSheet,
              onNotification: _showNotificationSheet,
              onLeave: _confirmLeaveGroup,
            );
          },
          loading: () => const OnmuScaffold(
            title: '모임 설정',
            children: [Center(child: CircularProgressIndicator())],
          ),
          error: (error, stackTrace) => OnmuScaffold(
            title: '모임 설정',
            children: [
              Text(
                '모임 설정을 불러오지 못했어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
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
          content: Text(
            '${_groupName ?? '이 모임'}에서 나가면 이 모임의 채팅과 약속을 더 이상 볼 수 없어요.',
          ),
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

class _GroupSettingsContent extends StatelessWidget {
  const _GroupSettingsContent({
    required this.groupId,
    required this.group,
    required this.groupName,
    required this.onRename,
    required this.onNotification,
    required this.onLeave,
  });

  final String groupId;
  final GroupSummary group;
  final String groupName;
  final VoidCallback onRename;
  final VoidCallback onNotification;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '모임 설정',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupDetail(groupId)),
      useWarmBackground: false,
      children: [
        _SettingsHeroCard(group: group, groupName: groupName),
        const SizedBox(height: AppSpacing.lg),
        _SettingActionCard(
          icon: Icons.drive_file_rename_outline,
          title: '모임 이름 변경',
          subtitle: '모임의 이름과 소개를 변경할 수 있어요.',
          onTap: onRename,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingActionCard(
          icon: Icons.notifications_none,
          title: '알림',
          subtitle: '모임 알림을 설정하고 관리할 수 있어요.',
          onTap: onNotification,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingActionCard(
          icon: Icons.groups_outlined,
          title: '멤버 목록',
          subtitle: '모임원 목록을 확인할 수 있어요.',
          onTap: () => context.push(RoutePaths.groupMembers(groupId)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingActionCard(
          icon: Icons.logout,
          title: '모임 나가기',
          subtitle: '모임을 나가면 더 이상 활동할 수 없어요.',
          danger: true,
          onTap: onLeave,
        ),
        const SizedBox(height: 72),
      ],
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({required this.group, required this.groupName});

  final GroupSummary group;
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
  bool _plan = true;

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
              value: _plan,
              onChanged: (value) => setState(() => _plan = value),
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
