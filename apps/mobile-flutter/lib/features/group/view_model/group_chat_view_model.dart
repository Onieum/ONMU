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
    this.nextCursor,
    this.hasMoreOlderMessages = false,
    this.isLoadingOlderMessages = false,
    this.unreadCount = 0,
  });

  final GroupSummary group;
  final GroupPinnedPlan? pinnedPlan;
  final List<GroupMessage> messages;
  final VoteCard vote;
  final int voteId;
  final int planId;
  final SettlementSummary settlement;
  final String? sendErrorMessage;
  final String? nextCursor;
  final bool hasMoreOlderMessages;
  final bool isLoadingOlderMessages;
  final int unreadCount;

  GroupChatState copyWith({
    List<GroupMessage>? messages,
    String? sendErrorMessage,
    bool clearSendErrorMessage = false,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? hasMoreOlderMessages,
    bool? isLoadingOlderMessages,
    int? unreadCount,
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
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      hasMoreOlderMessages: hasMoreOlderMessages ?? this.hasMoreOlderMessages,
      isLoadingOlderMessages:
          isLoadingOlderMessages ?? this.isLoadingOlderMessages,
      unreadCount: unreadCount ?? this.unreadCount,
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
    final messagePage = await groupRepository.fetchMessagePage(groupId);
    final unreadCount = await _markNewestMessageRead(
      groupRepository,
      messagePage.messages,
      fallbackUnreadCount: messagePage.unreadCount,
    );

    return GroupChatState(
      group: await groupRepository.fetchGroup(groupId),
      pinnedPlan: pinnedPlan,
      messages: messagePage.messages,
      nextCursor: messagePage.nextCursor,
      hasMoreOlderMessages: messagePage.hasMore,
      unreadCount: unreadCount,
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

    final localId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final pending = GroupMessage(
      id: localId,
      sender: '나',
      message: message,
      timeLabel: '전송 중',
      isMine: true,
      sendStatus: GroupMessageSendStatus.sending,
    );
    state = AsyncData(
      value.copyWith(
        messages: [...value.messages, pending],
        clearSendErrorMessage: true,
      ),
    );

    try {
      final sent = await ref
          .read(groupRepositoryProvider)
          .sendMessage(groupId: groupId, message: message);
      final latest = state.asData?.value ?? value;
      state = AsyncData(
        latest.copyWith(
          messages: _replaceMessage(
            latest.messages,
            localId,
            sent.copyWith(sendStatus: GroupMessageSendStatus.sent),
          ),
          clearSendErrorMessage: true,
        ),
      );
      await _markSentMessageRead(sent);
      return true;
    } catch (_) {
      final latest = state.asData?.value ?? value;
      state = AsyncData(
        latest.copyWith(
          messages: _replaceMessage(
            latest.messages,
            localId,
            pending.copyWith(
              timeLabel: '전송 실패',
              sendStatus: GroupMessageSendStatus.failed,
            ),
          ),
          sendErrorMessage: '메시지를 보내지 못했어요.',
        ),
      );
      return true;
    }
  }

  Future<bool> retryMessage(String messageId) async {
    final value = state.asData?.value;
    if (value == null || messageId.isEmpty) {
      return false;
    }
    final failed = value.messages
        .where((message) => message.id == messageId && message.canRetry)
        .firstOrNull;
    if (failed == null) {
      return false;
    }

    state = AsyncData(
      value.copyWith(
        messages: _replaceMessage(
          value.messages,
          messageId,
          failed.copyWith(
            timeLabel: '전송 중',
            sendStatus: GroupMessageSendStatus.sending,
          ),
        ),
        clearSendErrorMessage: true,
      ),
    );

    try {
      final sent = await ref
          .read(groupRepositoryProvider)
          .sendMessage(groupId: groupId, message: failed.message);
      final latest = state.asData?.value ?? value;
      state = AsyncData(
        latest.copyWith(
          messages: _replaceMessage(
            latest.messages,
            messageId,
            sent.copyWith(sendStatus: GroupMessageSendStatus.sent),
          ),
          clearSendErrorMessage: true,
        ),
      );
      await _markSentMessageRead(sent);
      return true;
    } catch (_) {
      final latest = state.asData?.value ?? value;
      state = AsyncData(
        latest.copyWith(
          messages: _replaceMessage(
            latest.messages,
            messageId,
            failed.copyWith(
              timeLabel: '전송 실패',
              sendStatus: GroupMessageSendStatus.failed,
            ),
          ),
          sendErrorMessage: '메시지를 보내지 못했어요.',
        ),
      );
      return false;
    }
  }

  Future<void> loadOlderMessages() async {
    final value = state.asData?.value;
    if (value == null ||
        value.isLoadingOlderMessages ||
        !value.hasMoreOlderMessages ||
        value.nextCursor == null) {
      return;
    }

    state = AsyncData(
      value.copyWith(isLoadingOlderMessages: true, clearSendErrorMessage: true),
    );

    try {
      final page = await ref
          .read(groupRepositoryProvider)
          .fetchMessagePage(groupId, beforeCursor: value.nextCursor);
      final latest = state.asData?.value ?? value;
      state = AsyncData(
        latest.copyWith(
          messages: _prependUnique(page.messages, latest.messages),
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          hasMoreOlderMessages: page.hasMore,
          isLoadingOlderMessages: false,
          unreadCount: page.unreadCount,
        ),
      );
    } catch (_) {
      final latest = state.asData?.value ?? value;
      state = AsyncData(
        latest.copyWith(
          isLoadingOlderMessages: false,
          sendErrorMessage: '이전 메시지를 불러오지 못했어요.',
        ),
      );
    }
  }

  Future<int> _markNewestMessageRead(
    GroupRepository repository,
    List<GroupMessage> messages, {
    required int fallbackUnreadCount,
  }) async {
    final lastReadMessageId = messages.lastOrNull?.id;
    if (lastReadMessageId == null || lastReadMessageId.isEmpty) {
      return fallbackUnreadCount;
    }
    try {
      return repository.markMessagesRead(
        groupId: groupId,
        lastReadMessageId: lastReadMessageId,
      );
    } catch (_) {
      return fallbackUnreadCount;
    }
  }

  Future<void> _markSentMessageRead(GroupMessage message) async {
    if (message.id.isEmpty) {
      return;
    }
    try {
      final unreadCount = await ref
          .read(groupRepositoryProvider)
          .markMessagesRead(groupId: groupId, lastReadMessageId: message.id);
      final latest = state.asData?.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(unreadCount: unreadCount));
      }
    } catch (_) {
      // 읽음 동기화 실패는 말풍선 전송 성공을 되돌리지 않는다.
    }
  }

  List<GroupMessage> _replaceMessage(
    List<GroupMessage> messages,
    String id,
    GroupMessage replacement,
  ) {
    return [
      for (final message in messages)
        if (message.id == id) replacement else message,
    ];
  }

  List<GroupMessage> _prependUnique(
    List<GroupMessage> olderMessages,
    List<GroupMessage> currentMessages,
  ) {
    final knownKeys = currentMessages.map(_messageKey).toSet();
    final uniqueOlder = olderMessages
        .where((message) => knownKeys.add(_messageKey(message)))
        .toList(growable: false);
    return [...uniqueOlder, ...currentMessages];
  }

  String _messageKey(GroupMessage message) {
    if (message.id.isNotEmpty) {
      return 'id:${message.id}';
    }
    if (message.cursor.isNotEmpty) {
      return 'cursor:${message.cursor}';
    }
    return '${message.sender}|${message.message}|${message.timeLabel}|${message.isMine}';
  }
}
