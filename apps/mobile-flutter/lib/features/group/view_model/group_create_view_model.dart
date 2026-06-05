import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/group_repository.dart';

final groupCreateViewModelProvider =
    AsyncNotifierProvider<GroupCreateViewModel, GroupCreateState>(
      GroupCreateViewModel.new,
    );

class GroupCreateState {
  const GroupCreateState({
    required this.createdGroupId,
    required this.recommendedMemberNames,
  });

  final int createdGroupId;
  final List<String> recommendedMemberNames;
}

class GroupCreateViewModel extends AsyncNotifier<GroupCreateState> {
  @override
  Future<GroupCreateState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final groups = await repository.fetchGroups();
    final members = await repository.fetchMembers(groups.first.id);

    return GroupCreateState(
      createdGroupId: groups.first.id,
      recommendedMemberNames: members
          .map((member) => member.name)
          .take(4)
          .toList(growable: false),
    );
  }
}
