import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../my/domain/my_profile.dart';
import '../../plan/view_model/plan_create_view_model.dart';
import '../repository/group_repository.dart';
import 'group_home_view_model.dart';
import 'group_list_view_model.dart';

final groupMembersViewModelProvider =
    AsyncNotifierProvider.family<
      GroupMembersViewModel,
      GroupMembersState,
      String
    >(GroupMembersViewModel.new);

class GroupMembersState {
  const GroupMembersState({required this.group, required this.members});

  final GroupSummary group;
  final List<GroupMemberProfile> members;
}

class GroupMembersViewModel extends AsyncNotifier<GroupMembersState> {
  GroupMembersViewModel(this.groupId);

  final String groupId;

  @override
  Future<GroupMembersState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final group = await repository.fetchGroup(groupId);
    final members = await repository.fetchMembers(groupId);

    return GroupMembersState(group: group, members: members);
  }

  Future<GroupSummary> updateGroup({
    required String name,
    required String description,
  }) async {
    final repository = ref.read(groupRepositoryProvider);
    final updated = await repository.updateGroup(
      groupId: groupId,
      name: name,
      description: description,
    );
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        GroupMembersState(group: updated, members: current.members),
      );
    }
    ref
      ..invalidate(groupListViewModelProvider)
      ..invalidate(groupHomeViewModelProvider(groupId));
    return updated;
  }

  Future<void> addMembers(List<FriendProfile> friends) async {
    final current = state.asData?.value;
    if (current == null || friends.isEmpty) {
      return;
    }

    final repository = ref.read(groupRepositoryProvider);
    final existingUserIds = {
      for (final member in current.members)
        if (member.userId.trim().isNotEmpty) member.userId.trim(),
    };
    final addedMembers = <GroupMemberProfile>[];
    for (final friend in friends) {
      final userId = friend.userId.trim();
      if (userId.isEmpty || existingUserIds.contains(userId)) {
        continue;
      }
      final member = await repository.addMember(
        groupId: groupId,
        userId: userId,
      );
      existingUserIds.add(userId);
      addedMembers.add(member);
    }
    if (addedMembers.isEmpty) {
      return;
    }

    final nextMembers = [...current.members, ...addedMembers];
    state = AsyncData(
      GroupMembersState(
        group: current.group.copyWith(
          members: nextMembers.map((member) => member.name).toList(),
        ),
        members: List.unmodifiable(nextMembers),
      ),
    );
    ref
      ..invalidate(groupListViewModelProvider)
      ..invalidate(groupHomeViewModelProvider(groupId))
      ..invalidate(groupPlanMemberOptionsProvider(groupId));
  }
}
