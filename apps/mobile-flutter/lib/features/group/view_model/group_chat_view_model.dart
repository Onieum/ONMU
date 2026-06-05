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

class GroupChatViewModel extends FamilyAsyncNotifier<GroupChatState, String> {
  @override
  Future<GroupChatState> build(String arg) async {
    final groupRepository = ref.watch(groupRepositoryProvider);
    final settlementRepository = ref.watch(settlementRepositoryProvider);

    final pinnedPlan = await groupRepository.fetchPinnedPlan(arg);
    final plans = await groupRepository.fetchPlans(arg);
    final planId = pinnedPlan?.id ?? plans.first.id;

    return GroupChatState(
      group: await groupRepository.fetchGroup(arg),
      pinnedPlan: pinnedPlan,
      messages: await groupRepository.fetchMessages(arg),
      vote: await groupRepository.fetchVoteCard(arg),
      voteId: 501,
      planId: planId,
      settlement: await settlementRepository.fetchSettlement(
        groupId: arg,
        planId: planId,
      ),
    );
  }

  void sendMessage(String text) {
    final value = state.valueOrNull;
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
