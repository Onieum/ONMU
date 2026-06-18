import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_remove_badge_button.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../my/domain/my_profile.dart';
import '../../../my/widgets/friend_picker_sheet.dart';
import '../../view_model/group_create_view_model.dart';

class GroupCreatePage extends StatefulWidget {
  const GroupCreatePage({super.key, this.initialMemberNames = const []});

  final List<String> initialMemberNames;

  @override
  State<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _invitedMemberNames = [];
  bool _makeFirstPlanLater = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_sync);
    _descriptionController.addListener(_sync);
    _invitedMemberNames.addAll(widget.initialMemberNames);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_sync)
      ..dispose();
    _descriptionController
      ..removeListener(_sync)
      ..dispose();
    super.dispose();
  }

  void _sync() => setState(() {});

  void _removeMember(String name) {
    setState(() {
      _invitedMemberNames.remove(name);
    });
  }

  Future<void> _openMemberAddSheet(
    BuildContext context,
    WidgetRef ref,
    GroupCreateState state,
  ) async {
    final currentMember = _currentMember(ref.read(authUserProvider));
    final currentNames = [currentMember.name, ..._invitedMemberNames];
    if (currentNames.length >= 20) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('멤버는 최대 20명까지 초대할 수 있어요.')));
      return;
    }

    final selectedFriend = await _showMemberAddSheet(
      context,
      state,
      currentNames,
    );
    if (!mounted || selectedFriend == null) {
      return;
    }

    final trimmedName = selectedFriend.name.trim();
    if (trimmedName.isEmpty) {
      return;
    }
    if (currentNames.contains(trimmedName)) {
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(const SnackBar(content: Text('이미 추가된 멤버예요.')));
      return;
    }

    setState(() {
      _invitedMemberNames.add(trimmedName);
    });
  }

  Future<FriendProfile?> _showMemberAddSheet(
    BuildContext context,
    GroupCreateState state,
    List<String> currentNames,
  ) async {
    return showModalBottomSheet<FriendProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDefault,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => FriendPickerSheet(
        friends: state.friendCandidates,
        excludedNames: currentNames.toSet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(groupCreateViewModelProvider);

        return state.when(
          data: (state) {
            final currentMember = _currentMember(ref.watch(authUserProvider));
            final displayMembers = [
              currentMember,
              for (final name in _invitedMemberNames)
                _InviteMember(name: name, removable: true),
            ];
            final memberNames = displayMembers
                .map((member) => member.name)
                .toList(growable: false);

            return OnmuScaffold(
              title: '온모임 만들기',
              showBackButton: true,
              onBack: () => context.popOrGo(RoutePaths.groups),
              useWarmBackground: false,
              bottom: OnmuPrimaryButton(
                label: '온모임 만들기',
                onPressed: _nameController.text.trim().isEmpty
                    ? null
                    : () async {
                        final created = await ref
                            .read(groupCreateViewModelProvider.notifier)
                            .createGroup(
                              name: _nameController.text,
                              description: _descriptionController.text,
                              memberNames: memberNames,
                            );
                        if (!context.mounted) {
                          return;
                        }
                        final nextRoute = _makeFirstPlanLater
                            ? RoutePaths.groupDetail(created.id)
                            : RoutePaths.planNew(created.id);
                        context.go(nextRoute);
                      },
              ),
              children: [
                OnmuCard(
                  backgroundColor: AppColors.bgDefault,
                  borderColor: AppColors.lineSoft,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabeledInput(
                        label: '모임 이름',
                        counter: '${_nameController.text.characters.length}/20',
                        child: TextField(
                          controller: _nameController,
                          maxLength: 20,
                          decoration: const InputDecoration(
                            hintText: '모임 이름을 입력하세요',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '멤버 초대',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InvitePreviewRow(
                        members: displayMembers,
                        onAddPressed: () =>
                            _openMemberAddSheet(context, ref, state),
                        onRemovePressed: _removeMember,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '함께할 멤버를 선택해 주세요 (최대 20명)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSub,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _LabeledInput(
                        label: '모임 설명',
                        counter:
                            '${_descriptionController.text.characters.length}/100',
                        child: TextField(
                          controller: _descriptionController,
                          maxLength: 100,
                          minLines: 5,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: '모임을 소개해 주세요',
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OnmuCard(
                  backgroundColor: AppColors.bgDefault,
                  borderColor: AppColors.lineSoft,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '첫 약속은 나중에 만들기',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              '지금은 모임만 만들고, 첫 약속은 나중에 만들 수 있어요.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSub),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _makeFirstPlanLater,
                        activeThumbColor: AppColors.primaryPink,
                        onChanged: (value) {
                          setState(() => _makeFirstPlanLater = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 72),
              ],
            );
          },
          loading: () => const OnmuScaffold(
            title: '온모임 만들기',
            children: [Center(child: CircularProgressIndicator())],
          ),
          error: (error, stackTrace) => OnmuScaffold(
            title: '온모임 만들기',
            children: [
              Text(
                '온모임 생성 정보를 불러오지 못했어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

_InviteMember _currentMember(AuthUser? user) {
  final nickname = user?.nickname.trim();
  return _InviteMember(
    name: nickname == null || nickname.isEmpty ? '나' : nickname,
    profileImageUrl: user?.profileImageUrl ?? '',
    removable: false,
  );
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.counter,
    required this.child,
  });

  final String label;
  final String counter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Text(
              counter,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _InvitePreviewRow extends StatelessWidget {
  const _InvitePreviewRow({
    required this.members,
    required this.onAddPressed,
    required this.onRemovePressed,
  });

  final List<_InviteMember> members;
  final VoidCallback onAddPressed;
  final ValueChanged<String> onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final member in members) ...[
            _InviteAvatar(
              member: member,
              onRemovePressed: member.removable
                  ? () => onRemovePressed(member.name)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Material(
            color: AppColors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: onAddPressed,
              child: Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bgDefault,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.lineBrown),
                    ),
                    child: const SizedBox.square(
                      dimension: 50,
                      child: Icon(Icons.add, color: AppColors.accentBrown),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('추가', style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteMember {
  const _InviteMember({
    required this.name,
    this.profileImageUrl = '',
    this.removable = true,
  });

  final String name;
  final String profileImageUrl;
  final bool removable;
}

class _InviteAvatar extends StatelessWidget {
  const _InviteAvatar({required this.member, required this.onRemovePressed});

  final _InviteMember member;
  final VoidCallback? onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Column(
        children: [
          SizedBox.square(
            dimension: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Center(
                    child: PixelAvatar(
                      label: member.name,
                      profileImageUrl: member.profileImageUrl,
                      size: 50,
                    ),
                  ),
                ),
                if (onRemovePressed != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: OnmuRemoveBadgeButton(
                      tooltip: '${member.name} 제거',
                      onPressed: onRemovePressed!,
                    ),
                  ),
              ],
            ),
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
