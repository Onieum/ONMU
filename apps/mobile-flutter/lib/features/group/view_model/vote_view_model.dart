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
    required this.optionCountsByCandidateId,
  });

  final VoteCard vote;
  final List<PlaceCandidate> candidates;
  final Map<int, List<String>> votersByCandidateId;
  final Map<int, int> optionCountsByCandidateId;

  List<String> votersFor(int candidateId) {
    return votersByCandidateId[candidateId] ?? const [];
  }

  int voteCountFor(int candidateId) {
    final voters = votersFor(candidateId);
    if (voters.isNotEmpty) {
      return voters.length;
    }
    return optionCountsByCandidateId[candidateId] ?? 0;
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
    final candidates = await placeRepository.fetchCandidates(
      groupId: scope.groupId,
      planId:
          targetPlanId ??
          pinnedPlan?.id ??
          (plans.isEmpty ? 0 : plans.first.id),
    );

    return VoteDetailState(
      vote: vote,
      candidates: _candidatesForVoteOptions(vote.options, candidates),
      votersByCandidateId: await groupRepository.fetchVoteVoters(
        groupId: scope.groupId,
        voteId: scope.voteId,
      ),
      optionCountsByCandidateId: _optionCountsByCandidateId(vote.options),
    );
  }

  Map<int, int> _optionCountsByCandidateId(List<VoteOptionSummary> options) {
    final counts = <int, int>{};
    for (final option in options) {
      final candidateId = _candidateIdForOption(option);
      if (candidateId == 0 || option.responseCount <= 0) {
        continue;
      }
      counts[candidateId] = option.responseCount;
    }
    return Map.unmodifiable(counts);
  }

  List<PlaceCandidate> _candidatesForVoteOptions(
    List<VoteOptionSummary> options,
    List<PlaceCandidate> candidates,
  ) {
    if (options.isEmpty || candidates.isEmpty) {
      return candidates;
    }

    final candidatesById = {
      for (final candidate in candidates) candidate.id: candidate,
    };
    final candidatesByName = <String, PlaceCandidate>{};
    for (final candidate in candidates) {
      final normalizedName = _normalizeOptionLabel(candidate.name);
      if (normalizedName.isNotEmpty) {
        candidatesByName.putIfAbsent(normalizedName, () => candidate);
      }
    }

    final hasCandidateIds = options.any(
      (option) => _candidateIdForOption(option) != 0,
    );
    final filtered = <PlaceCandidate>[];
    final addedIds = <int>{};
    for (final option in options) {
      final candidateId = _candidateIdForOption(option);
      final candidate =
          candidatesById[candidateId] ??
          candidatesByName[_normalizeOptionLabel(option.label)];
      if (candidate == null || !addedIds.add(candidate.id)) {
        continue;
      }
      filtered.add(candidate);
    }

    if (filtered.isNotEmpty || hasCandidateIds) {
      return List.unmodifiable(filtered);
    }
    return candidates;
  }

  int _candidateIdForOption(VoteOptionSummary option) {
    final candidateId = int.tryParse(option.candidateId.trim());
    if (candidateId != null && candidateId != 0) {
      return candidateId;
    }
    if (option.targetType.toUpperCase() == 'PLACE_CANDIDATE') {
      return int.tryParse(option.targetId.trim()) ?? 0;
    }
    return 0;
  }

  String _normalizeOptionLabel(String value) {
    return value.trim().toLowerCase();
  }
}
