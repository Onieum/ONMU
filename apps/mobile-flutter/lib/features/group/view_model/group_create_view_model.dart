import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../repository/group_repository.dart';
import 'group_list_view_model.dart';

final groupCreateViewModelProvider =
    AsyncNotifierProvider<GroupCreateViewModel, GroupCreateState>(
      GroupCreateViewModel.new,
    );

class GroupCreateState {
  const GroupCreateState({required this.recommendedMemberNames});

  final List<String> recommendedMemberNames;
}

class GroupCreateViewModel extends AsyncNotifier<GroupCreateState> {
  @override
  Future<GroupCreateState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final groups = await repository.fetchGroups();
    final members = await repository.fetchMembers(groups.first.id);

    return GroupCreateState(
      recommendedMemberNames: members
          .map((member) => member.name)
          .take(4)
          .toList(growable: false),
    );
  }

  Future<GroupSummary> createGroup({
    required String name,
    required String description,
    required List<String> memberNames,
  }) async {
    final repository = ref.read(groupRepositoryProvider);
    final created = await repository.createGroup(
      GroupCreateInput(
        name: name,
        description: description,
        memberNames: memberNames,
      ),
    );
    ref.invalidate(groupListViewModelProvider);
    return created;
  }
}
