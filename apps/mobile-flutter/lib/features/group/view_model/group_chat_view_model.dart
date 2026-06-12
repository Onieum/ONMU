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
    this.sendErrorMessage,
  });

  final GroupSummary group;
  final GroupPinnedPlan? pinnedPlan;
  final List<GroupMessage> messages;
  final VoteCard vote;
  final int voteId;
  final int planId;
  final SettlementSummary settlement;
  final String? sendErrorMessage;

  GroupChatState copyWith({
    List<GroupMessage>? messages,
    String? sendErrorMessage,
    bool clearSendErrorMessage = false,
  }) {
    return GroupChatState(
      group: group,
      pinnedPlan: pinnedPlan,
      messages: messages ?? this.messages,
      vote: vote,
      voteId: voteId,
      planId: planId,
      settlement: settlement,
      sendErrorMessage: clearSendErrorMessage
          ? null
          : sendErrorMessage ?? this.sendErrorMessage,
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

  Future<bool> sendMessage(String text) async {
    final value = state.asData?.value;
    if (value == null) {
      return false;
    }

    final message = text.trim();
    if (message.isEmpty) {
      return false;
    }

    try {
      final sent = await ref
          .read(groupRepositoryProvider)
          .sendMessage(groupId: groupId, message: message);
      state = AsyncData(
        value.copyWith(
          messages: [...value.messages, sent],
          clearSendErrorMessage: true,
        ),
      );
      return true;
    } catch (_) {
      state = AsyncData(value.copyWith(sendErrorMessage: '메시지를 보내지 못했어요.'));
      return false;
    }
  }
}
