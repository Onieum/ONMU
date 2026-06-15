import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/place_models.dart';
import '../../../shared/models/vote_models.dart';
import '../../place/repository/place_repository.dart';
import '../repository/group_repository.dart';

typedef VoteListScope = ({String groupId, String? planId});
typedef VoteScope = ({String groupId, String voteId, String? planId});

final voteListViewModelProvider =
    AsyncNotifierProvider.family<
      VoteListViewModel,
      VoteListState,
      VoteListScope
    >(VoteListViewModel.new);

final voteDetailViewModelProvider =
    AsyncNotifierProvider.family<
      VoteDetailViewModel,
      VoteDetailState,
      VoteScope
    >(VoteDetailViewModel.new);

class VoteListState {
  const VoteListState({
    required this.group,
    required this.planId,
    required this.votes,
  });

  final GroupSummary group;
  final int planId;
  final List<VoteSummary> votes;
}

class VoteDetailState {
  const VoteDetailState({
    required this.vote,
    required this.candidates,
    required this.votersByCandidateId,
  });

  final VoteCard vote;
  final List<PlaceCandidate> candidates;
  final Map<int, List<String>> votersByCandidateId;

  List<String> votersFor(int candidateId) {
    return votersByCandidateId[candidateId] ?? const [];
  }
}

enum VoteFilter {
  all('전체', Icons.favorite_outlined),
  ongoing('진행 중', Icons.hourglass_bottom_outlined),
  closed('마감', Icons.check_circle_outline),
  mine('내가 참여', Icons.person_outline);

  const VoteFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  bool matches(VoteSummary vote) {
    return switch (this) {
      VoteFilter.all => true,
      VoteFilter.ongoing => !vote.closed,
      VoteFilter.closed => vote.closed,
      VoteFilter.mine => vote.joinedByMe,
    };
  }
}

class VoteListViewModel extends AsyncNotifier<VoteListState> {
  VoteListViewModel(this.scope);

  final VoteListScope scope;

  @override
  Future<VoteListState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final groupId = scope.groupId;
    final group = await repository.fetchGroup(groupId);
    final scopedPlanId = scope.planId;

    return VoteListState(
      group: group,
      planId: int.tryParse(scopedPlanId ?? '') ?? 0,
      votes: await repository.fetchVotes(
        groupId,
        targetType: scopedPlanId == null ? null : 'PLAN',
        targetId: scopedPlanId,
      ),
    );
  }
}

class VoteDetailViewModel extends AsyncNotifier<VoteDetailState> {
  VoteDetailViewModel(this.scope);

  final VoteScope scope;

  @override
  Future<VoteDetailState> build() async {
    final groupRepository = ref.watch(groupRepositoryProvider);
    final placeRepository = ref.watch(placeRepositoryProvider);
    final vote = await groupRepository.fetchVoteCard(
      groupId: scope.groupId,
      voteId: scope.voteId,
    );
    final targetPlanId =
        scope.planId ??
        (vote.targetType.toUpperCase() == 'PLAN' &&
                vote.targetId.trim().isNotEmpty
            ? vote.targetId.trim()
            : null);
    final pinnedPlan = targetPlanId == null
        ? await groupRepository.fetchPinnedPlan(scope.groupId)
        : null;
    final plans = targetPlanId == null
        ? await groupRepository.fetchPlans(scope.groupId)
        : const <GroupPlanSummary>[];

    return VoteDetailState(
      vote: vote,
      candidates: await placeRepository.fetchCandidates(
        groupId: scope.groupId,
        planId:
            targetPlanId ??
            pinnedPlan?.id ??
            (plans.isEmpty ? 0 : plans.first.id),
      ),
      votersByCandidateId: await groupRepository.fetchVoteVoters(
        groupId: scope.groupId,
        voteId: scope.voteId,
      ),
    );
  }
}
