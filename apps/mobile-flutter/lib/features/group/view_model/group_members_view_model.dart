import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
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
  const GroupMembersState({
    required this.group,
    required this.members,
    required this.inviteCandidates,
  });

  final GroupSummary group;
  final List<GroupMemberProfile> members;
  final List<GroupMemberProfile> inviteCandidates;
}

class GroupMembersViewModel extends AsyncNotifier<GroupMembersState> {
  GroupMembersViewModel(this.groupId);

  final String groupId;

  @override
  Future<GroupMembersState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final group = await repository.fetchGroup(groupId);
    final members = await repository.fetchMembers(groupId);

    return GroupMembersState(
      group: group,
      members: members,
      inviteCandidates: members
          .where((profile) => profile.invited)
          .toList(growable: false),
    );
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
        GroupMembersState(
          group: updated,
          members: current.members,
          inviteCandidates: current.inviteCandidates,
        ),
      );
    }
    ref
      ..invalidate(groupListViewModelProvider)
      ..invalidate(groupHomeViewModelProvider(groupId));
    return updated;
  }
}
