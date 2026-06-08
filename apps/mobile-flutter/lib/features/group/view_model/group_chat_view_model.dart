import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/settlement_models.dart';
import '../../settlement/repository/settlement_repository.dart';
import '../repository/group_repository.dart';

final groupChatViewModelProvider =
    AsyncNotifierProvider.family<GroupChatViewModel, GroupChatState, String>(
      GroupChatViewModel.new,
    );

class GroupChatState {
  const GroupChatState({
    required this.group,
    required this.messages,
    required this.vote,
    required this.voteId,
    required this.planId,
    required this.settlement,
    this.pinnedPlan,
  });

  final GroupSummary group;
  final GroupPinnedPlan? pinnedPlan;
  final List<GroupMessage> messages;
  final VoteCard vote;
  final int voteId;
  final int planId;
  final SettlementSummary settlement;

  GroupChatState copyWith({List<GroupMessage>? messages}) {
    return GroupChatState(
      group: group,
      pinnedPlan: pinnedPlan,
      messages: messages ?? this.messages,
      vote: vote,
      voteId: voteId,
      planId: planId,
      settlement: settlement,
    );
  }
}

class GroupChatViewModel extends AsyncNotifier<GroupChatState> {
  GroupChatViewModel(this.groupId);

  final String groupId;

  @override
  Future<GroupChatState> build() async {
    final groupRepository = ref.watch(groupRepositoryProvider);
    final settlementRepository = ref.watch(settlementRepositoryProvider);

    final pinnedPlan = await groupRepository.fetchPinnedPlan(groupId);
    final plans = await groupRepository.fetchPlans(groupId);
    final planId = pinnedPlan?.id ?? (plans.isEmpty ? 0 : plans.first.id);
    final votes = await groupRepository.fetchVotes(groupId);
    final voteId = votes.isEmpty ? 0 : votes.first.id;

    return GroupChatState(
      group: await groupRepository.fetchGroup(groupId),
      pinnedPlan: pinnedPlan,
      messages: await groupRepository.fetchMessages(groupId),
      vote: await groupRepository.fetchVoteCard(
        groupId: groupId,
        voteId: voteId,
      ),
      voteId: voteId,
      planId: planId,
      settlement: await settlementRepository.fetchSettlement(
        groupId: groupId,
        planId: planId,
      ),
    );
  }

  void sendMessage(String text) {
    final value = state.asData?.value;
    if (value == null) {
      return;
    }

    state = AsyncData(
      value.copyWith(
        messages: [
          ...value.messages,
          GroupMessage(
            sender: '나',
            message: text,
            timeLabel: '방금',
            isMine: true,
          ),
        ],
      ),
    );
  }
}
