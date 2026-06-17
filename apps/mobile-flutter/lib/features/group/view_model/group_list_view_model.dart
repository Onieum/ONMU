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
    final enrichedGroups = await Future.wait(
      groups.map((group) => _enrichGroup(repository, group)),
    );

    return GroupListState(groups: List.unmodifiable(enrichedGroups));
  }

  Future<GroupSummary> _enrichGroup(
    GroupRepository repository,
    GroupSummary group,
  ) async {
    final needsMembers = group.members.isEmpty || group.memberAvatars.isEmpty;
    final needsPinnedPlan = _needsPinnedPlanTitle(group.pinnedPlanTitle);

    List<GroupMemberProfile> members = const [];
    List<GroupPlanSummary> plans = const [];

    if (needsMembers) {
      try {
        members = await repository.fetchMembers(group.id);
      } catch (_) {
        members = const [];
      }
    }
    if (needsPinnedPlan) {
      try {
        plans = await repository.fetchPlans(group.id);
      } catch (_) {
        plans = const [];
      }
    }

    final memberNames = group.members.isNotEmpty
        ? group.members
        : members.map((member) => member.name).toList(growable: false);
    final memberAvatars = group.memberAvatars.isNotEmpty
        ? group.memberAvatars
        : members
              .map(
                (member) => GroupPlanMemberAvatar(
                  name: member.name,
                  profileImageUrl: member.profileImageUrl,
                ),
              )
              .toList(growable: false);
    final pinnedPlanTitle = needsPinnedPlan && plans.isNotEmpty
        ? plans.first.title
        : group.pinnedPlanTitle;

    return group.copyWith(
      members: memberNames,
      memberAvatars: memberAvatars,
      pinnedPlanTitle: pinnedPlanTitle,
    );
  }

  bool _needsPinnedPlanTitle(String value) {
    final normalized = value.trim();
    return normalized.isEmpty || normalized == '약속 준비 중';
  }
}
