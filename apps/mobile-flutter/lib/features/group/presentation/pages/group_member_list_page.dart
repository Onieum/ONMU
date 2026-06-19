import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../../my/domain/my_profile.dart';
import '../../../my/repository/friend_repository.dart';
import '../../view_model/group_members_view_model.dart';

class GroupMemberListPage extends ConsumerWidget {
  const GroupMemberListPage({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupMembersViewModelProvider(groupId));

    return state.when(
      data: (state) => _GroupMemberListContent(groupId: groupId, state: state),
      loading: () => const OnmuScaffold(
        title: '모임원',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '모임원',
        children: [
          Text(
            '모임원 목록을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GroupMemberListContent extends StatelessWidget {
  const _GroupMemberListContent({required this.groupId, required this.state});

  final String groupId;
  final GroupMembersState state;

  @override
  Widget build(BuildContext context) {
    final group = state.group;

    return OnmuScaffold(
      title: '모임원',
      subtitle: '${group.name} · ${group.members.length}명',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupDetail(groupId)),
      useWarmBackground: false,
      children: [
        const _MemberSearchField(),
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.lineSoft,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < state.members.length; index += 1) ...[
                _MemberRow(profile: state.members[index]),
                if (index < state.members.length - 1)
                  const Divider(height: 1, color: AppColors.lineSoft),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _InviteCard(onTap: () => context.push(RoutePaths.groupInvite(groupId))),
        const SizedBox(height: 72),
      ],
    );
  }
}

class GroupInvitePage extends StatefulWidget {
  const GroupInvitePage({required this.groupId, super.key});

  final String groupId;

  @override
  State<GroupInvitePage> createState() => _GroupInvitePageState();
}

class _GroupInvitePageState extends State<GroupInvitePage> {
  final Set<String> _selectedUserIds = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(groupMembersViewModelProvider(widget.groupId));
        final friends = ref.watch(friendsProvider);

        return state.when(
          data: (state) => friends.when(
            data: (friends) => _GroupInviteContent(
              groupId: widget.groupId,
              members: state.members,
              friends: friends,
              query: _query,
              selectedUserIds: _selectedUserIds,
              onQueryChanged: (value) => setState(() => _query = value),
              onToggle: (userId) {
                setState(() {
                  if (!_selectedUserIds.add(userId)) {
                    _selectedUserIds.remove(userId);
                  }
                });
              },
              onInvite: (selectedFriends) =>
                  _inviteSelectedFriends(context, ref, selectedFriends),
            ),
            loading: () => const OnmuScaffold(
              title: '친구 초대하기',
              children: [Center(child: CircularProgressIndicator())],
            ),
            error: (error, stackTrace) => OnmuScaffold(
              title: '친구 초대하기',
              children: [
                Text(
                  '친구 목록을 불러오지 못했어요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          loading: () => const OnmuScaffold(
            title: '친구 초대하기',
            children: [Center(child: CircularProgressIndicator())],
          ),
          error: (error, stackTrace) => OnmuScaffold(
            title: '친구 초대하기',
            children: [
              Text(
                '모임원 정보를 불러오지 못했어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _inviteSelectedFriends(
    BuildContext context,
    WidgetRef ref,
    List<FriendProfile> selectedFriends,
  ) async {
    try {
      await ref
          .read(groupMembersViewModelProvider(widget.groupId).notifier)
          .addMembers(selectedFriends);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('친구를 초대하지 못했어요.')));
      return;
    }
    if (!context.mounted) {
      return;
    }
    context.popOrGo(RoutePaths.groupMembers(widget.groupId));
  }
}

class _GroupInviteContent extends StatelessWidget {
  const _GroupInviteContent({
    required this.groupId,
    required this.members,
    required this.friends,
    required this.query,
    required this.selectedUserIds,
    required this.onQueryChanged,
    required this.onToggle,
    required this.onInvite,
  });

  final String groupId;
  final List<GroupMemberProfile> members;
  final List<FriendProfile> friends;
  final String query;
  final Set<String> selectedUserIds;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onToggle;
  final Future<void> Function(List<FriendProfile> selectedFriends) onInvite;

  @override
  Widget build(BuildContext context) {
    final memberUserIds = {
      for (final member in members)
        if (member.userId.trim().isNotEmpty) member.userId.trim(),
    };
    final candidates = friends
        .where((friend) {
          final userId = friend.userId.trim();
          return userId.isNotEmpty && !memberUserIds.contains(userId);
        })
        .where((friend) => _matchesQuery(friend, query))
        .toList(growable: false);
    final selectedFriends = friends
        .where((friend) => selectedUserIds.contains(friend.userId.trim()))
        .toList(growable: false);

    return OnmuScaffold(
      title: '친구 초대하기',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupMembers(groupId)),
      useWarmBackground: false,
      bottom: FilledButton.icon(
        onPressed: selectedFriends.isEmpty
            ? null
            : () => onInvite(selectedFriends),
        icon: const Icon(Icons.person_add_outlined),
        label: Text('선택한 친구 초대하기 ${selectedFriends.length}명'),
      ),
      children: [
        _SelectedInviteStrip(
          selectedFriends: selectedFriends,
          onRemove: onToggle,
        ),
        const SizedBox(height: AppSpacing.md),
        _FriendSearchField(query: query, onChanged: onQueryChanged),
        const SizedBox(height: AppSpacing.lg),
        Text('내 친구', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (candidates.isEmpty)
          OnmuCard(
            backgroundColor: AppColors.bgDefault,
            borderColor: AppColors.lineSoft,
            child: Text(
              friends.isEmpty ? '아직 추가된 친구가 없어요.' : '초대할 수 있는 친구가 없어요.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
            ),
          )
        else
          OnmuCard(
            backgroundColor: AppColors.bgDefault,
            borderColor: AppColors.lineSoft,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < candidates.length; index += 1) ...[
                  _InviteCandidateRow(
                    profile: candidates[index],
                    selected: selectedUserIds.contains(
                      candidates[index].userId.trim(),
                    ),
                    onTap: () => onToggle(candidates[index].userId.trim()),
                  ),
                  if (index < candidates.length - 1)
                    const Divider(height: 1, color: AppColors.lineSoft),
                ],
              ],
            ),
          ),
        const SizedBox(height: 72),
      ],
    );
  }

  bool _matchesQuery(FriendProfile friend, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    final haystack = [
      friend.name,
      friend.memo,
      friend.introText,
      friend.userCode,
    ].join(' ').toLowerCase();
    return haystack.contains(normalized);
  }
}

class _MemberSearchField extends StatelessWidget {
  const _MemberSearchField();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '멤버 검색',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _FriendSearchField extends StatelessWidget {
  const _FriendSearchField({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              initialValue: query,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: '친구 이름 검색',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.profile});

  final GroupMemberProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          PixelAvatar(
            label: profile.name,
            size: 48,
            profileImageUrl: profile.profileImageUrl,
            character: profile.character,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  profile.note,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OnmuChip(label: profile.statusLabel, selected: !profile.invited),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          side: const BorderSide(color: AppColors.linePink),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        icon: const Icon(Icons.person_add_outlined, size: 18),
        label: const Text('친구 초대하기'),
      ),
    );
  }
}

class _SelectedInviteStrip extends StatelessWidget {
  const _SelectedInviteStrip({
    required this.selectedFriends,
    required this.onRemove,
  });

  final List<FriendProfile> selectedFriends;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (selectedFriends.isEmpty) {
      return Text(
        '초대할 친구를 선택해 주세요.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final friend in selectedFriends) ...[
            OnmuCard(
              backgroundColor: AppColors.primaryPinkSoft,
              borderColor: AppColors.linePink,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  PixelAvatar(
                    label: friend.name,
                    size: 28,
                    profileImageUrl: friend.profileImageUrl,
                    character: friend.character,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    friend.name,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  InkResponse(
                    onTap: () => onRemove(friend.userId.trim()),
                    radius: 14,
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _InviteCandidateRow extends StatelessWidget {
  const _InviteCandidateRow({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final FriendProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            PixelAvatar(
              label: profile.name,
              size: 48,
              profileImageUrl: profile.profileImageUrl,
              character: profile.character,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _friendSubtitle(profile),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryPink : AppColors.bgDefault,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected ? AppColors.primaryPink : AppColors.lineBrown,
                ),
              ),
              child: SizedBox.square(
                dimension: 28,
                child: Icon(
                  selected ? Icons.check : Icons.add,
                  color: selected ? AppColors.textInverse : AppColors.textSub,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _friendSubtitle(FriendProfile profile) {
    final memo = profile.memo.trim();
    if (memo.isNotEmpty) {
      return memo;
    }
    final intro = profile.introText.trim();
    if (intro.isNotEmpty) {
      return intro;
    }
    return profile.memoOrCode;
  }
}
