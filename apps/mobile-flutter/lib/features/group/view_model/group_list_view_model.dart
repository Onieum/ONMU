import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../repository/group_repository.dart';

final groupListViewModelProvider =
    AsyncNotifierProvider<GroupListViewModel, GroupListState>(
      GroupListViewModel.new,
    );

class GroupListState {
  const GroupListState({required this.groups});

  final List<GroupSummary> groups;

  int get groupCount => groups.length;
}

class GroupListViewModel extends AsyncNotifier<GroupListState> {
  @override
  Future<GroupListState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final groups = await repository.fetchGroups();

    return GroupListState(groups: groups);
  }
}
