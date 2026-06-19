import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/place_models.dart';
import '../../../shared/models/plan_models.dart';
import '../../../shared/models/vote_models.dart';
import '../../place/repository/place_repository.dart';
import '../../plan/repository/plan_repository.dart';
import '../repository/group_repository.dart';

typedef GroupPlanBoardScope = ({String groupId, String planId});

final groupPlanBoardViewModelProvider =
    AsyncNotifierProvider.family<
      GroupPlanBoardViewModel,
      GroupPlanBoardState,
      GroupPlanBoardScope
    >(GroupPlanBoardViewModel.new);

class GroupPlanBoardState {
  const GroupPlanBoardState({
    required this.group,
    required this.currentPlan,
    required this.candidateResults,
    required this.vote,
    required this.participantResponses,
  });

  final GroupSummary group;
  final GroupPlanSummary? currentPlan;
  final List<GroupPlanBoardCandidateResult> candidateResults;
  final VoteSummary? vote;
  final List<GroupPlanParticipantResponse> participantResponses;

  List<PlaceCandidate> get candidates => candidateResults
      .map((result) => result.candidate)
      .toList(growable: false);

  int get voteId => vote?.id ?? 0;

  String get boardTitle {
    final title = currentPlan?.title.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }
    final fallback = group.pinnedPlanTitle.trim();
    return fallback.isEmpty ? '약속' : fallback;
  }

  String get subtitle {
    final parts = [
      group.name.trim(),
      currentPlan?.displayDateTimeLabel.trim() ?? '',
      currentPlan?.placeName.trim() ?? '',
    ].where((part) => part.isNotEmpty).toList(growable: false);
    return parts.isEmpty ? '' : parts.join(' · ');
  }

  String get noticeBadgeLabel {
    final voteStatus = vote?.statusLabel.trim();
    if (voteStatus != null && voteStatus.isNotEmpty) {
      return voteStatus;
    }
    return currentPlan?.displayStatusLabel ?? '';
  }

  String get voteDescription {
    final currentVote = vote;
    if (currentVote != null) {
      return currentVote.displayDescription;
    }
    return '이 약속에 연결된 투표가 아직 없어요.';
  }

  String get voteActionLabel {
    final actionLabel = vote?.actionLabel.trim();
    if (actionLabel != null && actionLabel.isNotEmpty) {
      return actionLabel;
    }
    return vote == null ? '연결된 투표 없음' : '투표 결과 보기';
  }
}

class GroupPlanBoardCandidateResult {
  const GroupPlanBoardCandidateResult({
    required this.candidate,
    required this.voteCount,
    required this.progress,
  });

  final PlaceCandidate candidate;
  final int voteCount;
  final double progress;

  String get voteCountLabel => '$voteCount표';
  String get progressLabel => '${(progress * 100).round()}%';
}

class GroupPlanParticipantResponse {
  const GroupPlanParticipantResponse({
    required this.label,
    required this.count,
    this.selected = false,
  });

  final String label;
  final int count;
  final bool selected;
}

class GroupPlanBoardViewModel extends AsyncNotifier<GroupPlanBoardState> {
  GroupPlanBoardViewModel(this.scope);

  final GroupPlanBoardScope scope;

  @override
  Future<GroupPlanBoardState> build() async {
    final groupRepository = ref.watch(groupRepositoryProvider);
    final placeRepository = ref.watch(placeRepositoryProvider);
    final planRepository = ref.watch(planRepositoryProvider);

    final group = await groupRepository.fetchGroup(scope.groupId);
    final plans = await groupRepository.fetchPlans(scope.groupId);
    final currentPlan = _findPlan(plans, scope.planId);
    final votes = await groupRepository.fetchVotes(
      scope.groupId,
      targetType: 'PLAN',
      targetId: scope.planId,
    );
    final vote = _findPlanVote(votes, scope.planId);
    final candidates = await placeRepository.fetchCandidates(
      groupId: scope.groupId,
      planId: scope.planId,
    );
    final participants = await _fetchParticipants(planRepository);
    return GroupPlanBoardState(
      group: group,
      currentPlan: currentPlan,
      candidateResults: _candidateResults(candidates, vote),
      vote: vote,
      participantResponses: _participantResponses(participants, currentPlan),
    );
  }

  GroupPlanSummary? _findPlan(List<GroupPlanSummary> plans, String planId) {
    for (final plan in plans) {
      if (plan.id.toString() == planId) {
        return plan;
      }
    }
    return null;
  }

  VoteSummary? _findPlanVote(List<VoteSummary> votes, String planId) {
    for (final vote in votes) {
      if (_isPlanVote(vote, planId)) {
        return vote;
      }
    }
    if (votes.length == 1 && _hasNoTarget(votes.single)) {
      return votes.single;
    }
    return null;
  }

  bool _isPlanVote(VoteSummary vote, String planId) {
    return vote.targetType.trim().toUpperCase() == 'PLAN' &&
        vote.targetId.trim() == planId;
  }

  bool _hasNoTarget(VoteSummary vote) {
    return vote.targetType.trim().isEmpty && vote.targetId.trim().isEmpty;
  }

  Future<List<PlanParticipantArrival>> _fetchParticipants(
    PlanRepository repository,
  ) async {
    try {
      return await repository.fetchPlanParticipants(
        groupId: scope.groupId,
        planId: scope.planId,
      );
    } catch (_) {
      return const [];
    }
  }

  List<GroupPlanBoardCandidateResult> _candidateResults(
    List<PlaceCandidate> candidates,
    VoteSummary? vote,
  ) {
    if (candidates.isEmpty) {
      return const [];
    }
    if (vote == null || vote.options.isEmpty) {
      return candidates
          .map(
            (candidate) => GroupPlanBoardCandidateResult(
              candidate: candidate,
              voteCount: 0,
              progress: 0,
            ),
          )
          .toList(growable: false);
    }

    final candidatesById = {
      for (final candidate in candidates) candidate.id: candidate,
    };
    final candidatesByName = <String, PlaceCandidate>{};
    for (final candidate in candidates) {
      candidatesByName.putIfAbsent(_normalize(candidate.name), () => candidate);
    }

    final results = <GroupPlanBoardCandidateResult>[];
    final addedCandidateIds = <int>{};
    for (final option in vote.options) {
      final candidateId = _candidateIdForOption(option);
      final candidate =
          candidatesById[candidateId] ??
          candidatesByName[_normalize(option.label)];
      if (candidate == null || !addedCandidateIds.add(candidate.id)) {
        continue;
      }
      results.add(
        GroupPlanBoardCandidateResult(
          candidate: candidate,
          voteCount: _voteCount(option),
          progress: option.progress.clamp(0, 1).toDouble(),
        ),
      );
    }

    for (final candidate in candidates) {
      if (!addedCandidateIds.add(candidate.id)) {
        continue;
      }
      results.add(
        GroupPlanBoardCandidateResult(
          candidate: candidate,
          voteCount: 0,
          progress: 0,
        ),
      );
    }
    return List.unmodifiable(results);
  }

  int _candidateIdForOption(VoteOptionSummary option) {
    final candidateId = int.tryParse(option.candidateId.trim());
    if (candidateId != null && candidateId != 0) {
      return candidateId;
    }
    if (option.targetType.trim().toUpperCase() == 'PLACE_CANDIDATE') {
      return int.tryParse(option.targetId.trim()) ?? 0;
    }
    return 0;
  }

  int _voteCount(VoteOptionSummary option) {
    if (option.responseCount > 0) {
      return option.responseCount;
    }
    return int.tryParse(option.countLabel.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
  }

  String _normalize(String value) => value.trim().toLowerCase();

  List<GroupPlanParticipantResponse> _participantResponses(
    List<PlanParticipantArrival> participants,
    GroupPlanSummary? plan,
  ) {
    if (participants.isEmpty) {
      final fallbackCount =
          (plan?.memberCount ?? 0) + (plan?.extraMemberCount ?? 0);
      return fallbackCount <= 0
          ? const []
          : [
              GroupPlanParticipantResponse(
                label: '참석',
                count: fallbackCount,
                selected: true,
              ),
            ];
    }

    var attending = 0;
    var pending = 0;
    var declined = 0;
    for (final participant in participants) {
      if (participant.isFallback) {
        continue;
      }
      final status = participant.participantStatus
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[\s_-]'), '');
      switch (status) {
        case 'joined':
        case 'accepted':
        case 'attending':
        case 'participant':
          attending += 1;
        case 'left':
        case 'declined':
        case 'rejected':
        case 'cancelled':
          declined += 1;
        default:
          pending += 1;
      }
    }

    return [
      GroupPlanParticipantResponse(
        label: '참석',
        count: attending,
        selected: true,
      ),
      GroupPlanParticipantResponse(label: '미정', count: pending),
      GroupPlanParticipantResponse(label: '불참', count: declined),
    ];
  }
}
