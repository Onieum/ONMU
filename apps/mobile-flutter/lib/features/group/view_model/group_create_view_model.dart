import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../my/domain/my_profile.dart';
import '../../my/repository/friend_repository.dart';
import '../repository/group_repository.dart';
import 'group_list_view_model.dart';

final groupCreateViewModelProvider =
    AsyncNotifierProvider<GroupCreateViewModel, GroupCreateState>(
      GroupCreateViewModel.new,
    );

class GroupCreateState {
  const GroupCreateState({
    required this.recommendedMemberNames,
    required this.friendCandidates,
  });

  final List<String> recommendedMemberNames;
  final List<FriendProfile> friendCandidates;
}

class GroupCreateViewModel extends AsyncNotifier<GroupCreateState> {
  @override
  Future<GroupCreateState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final friendRepository = ref.watch(friendRepositoryProvider);
    final friendCandidates = await friendRepository.fetchFriends();
    final groups = await repository.fetchGroups();
    if (groups.isEmpty) {
      return GroupCreateState(
        recommendedMemberNames: const [],
        friendCandidates: friendCandidates,
      );
    }

    final members = await repository.fetchMembers(groups.first.id);

    return GroupCreateState(
      recommendedMemberNames: members
          .map((member) => member.name)
          .take(4)
          .toList(growable: false),
      friendCandidates: friendCandidates,
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
