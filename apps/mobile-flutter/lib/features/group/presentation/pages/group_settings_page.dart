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
import '../../../home/view_model/notification_preferences_view_model.dart';
import '../../view_model/group_members_view_model.dart';

class GroupSettingsPage extends StatefulWidget {
  const GroupSettingsPage({required this.groupId, super.key});

  final String groupId;

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  String? _groupName;
  String? _groupDescription;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(groupMembersViewModelProvider(widget.groupId));

        return state.when(
          data: (state) {
            _groupName ??= state.group.name;
            _groupDescription ??= state.group.description;
            return _GroupSettingsContent(
              groupId: widget.groupId,
              group: state.group,
              groupName: _groupName!,
              groupDescription: _groupDescription!,
              onRename: () => _showRenameSheet(ref),
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

  Future<void> _showRenameSheet(WidgetRef ref) async {
    final result = await showModalBottomSheet<_GroupEditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: _RenameGroupSheet(
            initialName: _groupName ?? '',
            initialDescription: _groupDescription ?? '',
          ),
        );
      },
    );

    if (!mounted || result == null || result.name.isEmpty) {
      return;
    }

    final updated = await ref
        .read(groupMembersViewModelProvider(widget.groupId).notifier)
        .updateGroup(name: result.name, description: result.description);
    if (!mounted) {
      return;
    }
    setState(() {
      _groupName = updated.name;
      _groupDescription = updated.description;
    });
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
    required this.groupDescription,
    required this.onRename,
    required this.onNotification,
    required this.onLeave,
  });

  final String groupId;
  final GroupSummary group;
  final String groupName;
  final String groupDescription;
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
        _SettingsHeroCard(
          group: group,
          groupName: groupName,
          groupDescription: groupDescription,
        ),
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
  const _SettingsHeroCard({
    required this.group,
    required this.groupName,
    required this.groupDescription,
  });

  final GroupSummary group;
  final String groupName;
  final String groupDescription;

  @override
  Widget build(BuildContext context) {
    final displayMembers = group.displayMemberAvatars.isEmpty
        ? const [GroupPlanMemberAvatar(name: '온')]
        : group.displayMemberAvatars.take(3).toList(growable: false);

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
                    for (
                      var index = 0;
                      index < displayMembers.length;
                      index += 1
                    )
                      Positioned(
                        left: _avatarLeftOffset(index, displayMembers.length),
                        child: PixelAvatar(
                          label: displayMembers[index].name,
                          profileImageUrl:
                              displayMembers[index].profileImageUrl,
                          character: displayMembers[index].character,
                          size: index == 1 ? 46 : 42,
                        ),
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
                      groupDescription,
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

  double _avatarLeftOffset(int index, int count) {
    if (count == 1) {
      return 17;
    }
    if (count == 2) {
      return index == 0 ? 6 : 30;
    }
    return index == 0 ? 0 : (index == 1 ? 15 : 34);
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

class _GroupEditResult {
  const _GroupEditResult({required this.name, required this.description});

  final String name;
  final String description;
}

class _RenameGroupSheet extends StatefulWidget {
  const _RenameGroupSheet({
    required this.initialName,
    required this.initialDescription,
  });

  final String initialName;
  final String initialDescription;

  @override
  State<_RenameGroupSheet> createState() => _RenameGroupSheetState();
}

class _RenameGroupSheetState extends State<_RenameGroupSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late int _nameLength;
  late int _descriptionLength;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _nameLength = _nameController.text.characters.length;
    _descriptionLength = _descriptionController.text.characters.length;
    _nameController.addListener(_syncLengths);
    _descriptionController.addListener(_syncLengths);
  }

  @override
  void dispose() {
    _nameController.removeListener(_syncLengths);
    _descriptionController.removeListener(_syncLengths);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncLengths() {
    final nextNameLength = _nameController.text.characters.length;
    final nextDescriptionLength = _descriptionController.text.characters.length;
    if ((nextNameLength == _nameLength &&
            nextDescriptionLength == _descriptionLength) ||
        !mounted) {
      return;
    }
    setState(() {
      _nameLength = nextNameLength;
      _descriptionLength = nextDescriptionLength;
    });
  }

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
                  '모임 정보 변경',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '$_nameLength/20',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameController,
              maxLength: 20,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '모임 이름',
                helperText: '모임원에게 보이는 이름이에요.',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text('모임 소개', style: Theme.of(context).textTheme.labelMedium),
                const Spacer(),
                Text(
                  '$_descriptionLength/100',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _descriptionController,
              maxLength: 100,
              minLines: 3,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '모임 소개',
                helperText: '모임의 분위기나 메모를 적어둘 수 있어요.',
                counterText: '',
              ),
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
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _GroupEditResult(
        name: name,
        description: _descriptionController.text.trim(),
      ),
    );
  }
}

class _NotificationSheet extends ConsumerStatefulWidget {
  const _NotificationSheet();

  @override
  ConsumerState<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends ConsumerState<_NotificationSheet> {
  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(notificationPreferencesViewModelProvider);
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
            preferences.when(
              data: (state) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: state.enabledFor('chat_message', 'in_app'),
                    onChanged: (value) => _setEnabled(
                      notificationType: 'chat_message',
                      channel: 'in_app',
                      enabled: value,
                    ),
                    title: const Text('새 채팅'),
                    subtitle: const Text('모임 대화가 올라오면 알려드려요.'),
                  ),
                  SwitchListTile(
                    value: state.enabledFor('plan_reminder', 'push'),
                    onChanged: (value) => _setEnabled(
                      notificationType: 'plan_reminder',
                      channel: 'push',
                      enabled: value,
                    ),
                    title: const Text('약속 알림'),
                    subtitle: const Text('약속 시간과 장소 알림을 받을게요.'),
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '알림 설정을 불러오지 못했어요.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OnmuSecondaryButton(
                    label: '다시 불러오기',
                    icon: Icons.refresh_rounded,
                    onPressed: () => ref.invalidate(
                      notificationPreferencesViewModelProvider,
                    ),
                  ),
                ],
              ),
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

  Future<void> _setEnabled({
    required String notificationType,
    required String channel,
    required bool enabled,
  }) async {
    try {
      await ref
          .read(notificationPreferencesViewModelProvider.notifier)
          .setEnabled(
            notificationType: notificationType,
            channel: channel,
            enabled: enabled,
          );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('알림 설정을 저장하지 못했어요.')));
    }
  }
}
