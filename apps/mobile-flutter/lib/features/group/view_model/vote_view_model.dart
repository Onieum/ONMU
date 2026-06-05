import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/place_models.dart';
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

class VoteSummary {
  const VoteSummary({
    required this.id,
    required this.title,
    required this.statusLabel,
    required this.description,
    required this.planLabel,
    required this.planMeta,
    required this.participants,
    required this.options,
    required this.closed,
    required this.joinedByMe,
    required this.actionLabel,
  });

  final int id;
  final String title;
  final String statusLabel;
  final String description;
  final String planLabel;
  final String planMeta;
  final List<String> participants;
  final List<VoteOptionSummary> options;
  final bool closed;
  final bool joinedByMe;
  final String actionLabel;
}

class VoteOptionSummary {
  const VoteOptionSummary({
    required this.label,
    required this.countLabel,
    required this.progress,
  });

  final String label;
  final String countLabel;
  final double progress;
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

class VoteListViewModel extends FamilyAsyncNotifier<VoteListState, String> {
  @override
  Future<VoteListState> build(String arg) async {
    final repository = ref.watch(groupRepositoryProvider);
    final group = await repository.fetchGroup(arg);
    final pinnedPlan = await repository.fetchPinnedPlan(arg);
    final plans = await repository.fetchPlans(arg);

    return VoteListState(
      group: group,
      planId: pinnedPlan?.id ?? plans.first.id,
      votes: _mockVoteSummaries,
    );
  }
}

class VoteDetailViewModel
    extends FamilyAsyncNotifier<VoteDetailState, VoteScope> {
  @override
  Future<VoteDetailState> build(VoteScope arg) async {
    final groupRepository = ref.watch(groupRepositoryProvider);
    final placeRepository = ref.watch(placeRepositoryProvider);
    final pinnedPlan = await groupRepository.fetchPinnedPlan(arg.groupId);
    final plans = await groupRepository.fetchPlans(arg.groupId);

    return VoteDetailState(
      vote: await groupRepository.fetchVoteCard(arg.groupId),
      candidates: await placeRepository.fetchCandidates(
        groupId: arg.groupId,
        planId: pinnedPlan?.id ?? plans.first.id,
      ),
      votersByCandidateId: const {
        201: ['민서', '하린'],
        202: ['지훈'],
      },
    );
  }
}

const _mockVoteSummaries = [
  VoteSummary(
    id: 501,
    title: '제주도 여행 장소 투표',
    statusLabel: '진행 중',
    description: '카페 오션뷰 외 2곳 · 4명 참여',
    planLabel: '제주도 여행',
    planMeta: '6.7 - 6.9 · 제주도 일대',
    participants: ['지민', '민수', '하린', '현우'],
    options: [
      VoteOptionSummary(label: '카페 오션뷰', countLabel: '3표', progress: 0.78),
      VoteOptionSummary(label: '흑돼지 맛집 돈사돈', countLabel: '2표', progress: 0.56),
      VoteOptionSummary(label: '협재 해수욕장', countLabel: '1표', progress: 0.32),
    ],
    closed: false,
    joinedByMe: true,
    actionLabel: '투표 확인하기',
  ),
  VoteSummary(
    id: 502,
    title: '성수 카페 투어 시간 정하기',
    statusLabel: '오늘 마감',
    description: '오후 2시 / 4시 / 6시 · 5명 참여',
    planLabel: '성수 카페 투어',
    planMeta: '6.5 오후 2:00 · 성수동 일대',
    participants: ['지연', '민수', '하린'],
    options: [
      VoteOptionSummary(label: '오후 2시', countLabel: '3표', progress: 0.64),
      VoteOptionSummary(label: '오후 4시', countLabel: '2표', progress: 0.46),
    ],
    closed: false,
    joinedByMe: false,
    actionLabel: '결과 보기',
  ),
  VoteSummary(
    id: 503,
    title: '한강 피크닉 메뉴',
    statusLabel: '마감',
    description: '김밥과 샌드위치가 최종 선택됐어요',
    planLabel: '한강 피크닉',
    planMeta: '5.10 오후 1:00 · 여의도 한강공원',
    participants: ['지민', '하린', '현우'],
    options: [
      VoteOptionSummary(label: '김밥', countLabel: '4표', progress: 0.86),
      VoteOptionSummary(label: '샌드위치', countLabel: '3표', progress: 0.68),
    ],
    closed: true,
    joinedByMe: true,
    actionLabel: '결과 보기',
  ),
  VoteSummary(
    id: 504,
    title: '보드게임 모임 장소',
    statusLabel: '마감',
    description: '홍대 보드게임카페로 정했어요',
    planLabel: '보드게임 모임',
    planMeta: '5.5 오후 6:00 · 홍대 일대',
    participants: ['민서', '지훈'],
    options: [
      VoteOptionSummary(label: '홍대 보드게임카페', countLabel: '5표', progress: 0.92),
      VoteOptionSummary(label: '연남동 카페', countLabel: '2표', progress: 0.34),
    ],
    closed: true,
    joinedByMe: false,
    actionLabel: '결과 보기',
  ),
];
