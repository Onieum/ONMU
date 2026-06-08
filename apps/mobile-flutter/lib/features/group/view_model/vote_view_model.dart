import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/place_models.dart';
import '../../../shared/models/vote_models.dart';
import '../../place/repository/place_repository.dart';
import '../repository/group_repository.dart';

typedef VoteScope = ({String groupId, String voteId});

final voteListViewModelProvider =
    AsyncNotifierProvider.family<VoteListViewModel, VoteListState, String>(
      VoteListViewModel.new,
    );

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
  VoteListViewModel(this.groupId);

  final String groupId;

  @override
  Future<VoteListState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final group = await repository.fetchGroup(groupId);
    final pinnedPlan = await repository.fetchPinnedPlan(groupId);
    final plans = await repository.fetchPlans(groupId);

    return VoteListState(
      group: group,
      planId: pinnedPlan?.id ?? (plans.isEmpty ? 0 : plans.first.id),
      votes: await repository.fetchVotes(groupId),
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
    final pinnedPlan = await groupRepository.fetchPinnedPlan(scope.groupId);
    final plans = await groupRepository.fetchPlans(scope.groupId);

    return VoteDetailState(
      vote: await groupRepository.fetchVoteCard(
        groupId: scope.groupId,
        voteId: scope.voteId,
      ),
      candidates: await placeRepository.fetchCandidates(
        groupId: scope.groupId,
        planId: pinnedPlan?.id ?? (plans.isEmpty ? 0 : plans.first.id),
      ),
      votersByCandidateId: await groupRepository.fetchVoteVoters(
        groupId: scope.groupId,
        voteId: scope.voteId,
      ),
    );
  }
}
