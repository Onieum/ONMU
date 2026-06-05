import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../repository/group_repository.dart';

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

class GroupMembersViewModel
    extends FamilyAsyncNotifier<GroupMembersState, String> {
  @override
  Future<GroupMembersState> build(String arg) async {
    final repository = ref.watch(groupRepositoryProvider);
    final group = await repository.fetchGroup(arg);
    final members = await repository.fetchMembers(arg);

    return GroupMembersState(
      group: group,
      members: members,
      inviteCandidates: members
          .where((profile) => profile.invited || profile.name == '소연')
          .toList(growable: false),
    );
  }
}
