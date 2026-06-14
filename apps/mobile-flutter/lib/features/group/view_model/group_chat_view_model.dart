import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../../../shared/models/settlement_models.dart';
import '../../../shared/models/vote_models.dart';
import '../../settlement/repository/settlement_repository.dart';
import '../repository/group_repository.dart';
import '../repository/media_repository.dart';

final groupChatViewModelProvider =
    AsyncNotifierProvider.family<GroupChatViewModel, GroupChatState, String>(
      GroupChatViewModel.new,
    );

class GroupChatState {
  const GroupChatState({
    required this.group,
    required this.messages,
    required this.voteId,
    required this.planId,
    this.vote,
    this.settlement,
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
  final VoteCard? vote;
  final int voteId;
  final int planId;
  final SettlementSummary? settlement;
  final String? sendErrorMessage;
  final String? nextCursor;
  final bool hasMoreOlderMessages;
  final bool isLoadingOlderMessages;
  final int unreadCount;

  GroupChatState copyWith({
    GroupPinnedPlan? pinnedPlan,
    List<GroupMessage>? messages,
    VoteCard? vote,
    int? voteId,
    int? planId,
    SettlementSummary? settlement,
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
      pinnedPlan: pinnedPlan ?? this.pinnedPlan,
      messages: messages ?? this.messages,
      vote: vote ?? this.vote,
      voteId: voteId ?? this.voteId,
      planId: planId ?? this.planId,
      settlement: settlement ?? this.settlement,
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
  StreamSubscription<GroupMessage>? _realtimeSubscription;
  Timer? _reconnectTimer;
  bool _realtimeDisposed = false;

  @override
  Future<GroupChatState> build() async {
    ref.onDispose(_disposeRealtime);
    final groupRepository = ref.watch(groupRepositoryProvider);
    final settlementRepository = ref.watch(settlementRepositoryProvider);

    final groupFuture = groupRepository.fetchGroup(groupId);
    final messagePageFuture = groupRepository.fetchMessagePage(groupId);
    final group = await groupFuture;
    final messagePage = await messagePageFuture;
    unawaited(_markNewestMessageRead(groupRepository, messagePage.messages));

    final chatState = GroupChatState(
      group: group,
      messages: messagePage.messages,
      nextCursor: messagePage.nextCursor,
      hasMoreOlderMessages: messagePage.hasMore,
      unreadCount: messagePage.unreadCount,
      voteId: 0,
      planId: 0,
    );
    unawaited(_loadAuxiliaryChatState(groupRepository, settlementRepository));
    _startRealtimeSubscription(
      groupRepository,
      afterCursor: _latestCursor(chatState.messages),
    );
    return chatState;
  }

  Future<void> _loadAuxiliaryChatState(
    GroupRepository groupRepository,
    SettlementRepository settlementRepository,
  ) async {
    GroupPinnedPlan? pinnedPlan;
    List<GroupPlanSummary> plans = const [];
    List<VoteSummary> votes = const [];

    try {
      pinnedPlan = await groupRepository.fetchPinnedPlan(groupId);
    } catch (_) {
      // 보조 카드 실패는 메시지와 입력창 표시를 막지 않는다.
    }

    try {
      plans = await groupRepository.fetchPlans(groupId);
    } catch (_) {
      // 약속 목록 실패는 채팅 본문 표시와 독립적으로 처리한다.
    }

    try {
      votes = await groupRepository.fetchVotes(groupId);
    } catch (_) {
      // 투표 목록 실패는 투표 카드만 생략한다.
    }

    final planId = pinnedPlan?.id ?? (plans.isEmpty ? 0 : plans.first.id);
    final voteId = votes.isEmpty ? 0 : votes.first.id;
    VoteCard? vote;
    SettlementSummary? settlement;

    if (voteId > 0) {
      try {
        vote = await groupRepository.fetchVoteCard(
          groupId: groupId,
          voteId: voteId,
        );
      } catch (_) {
        // 투표 카드 실패는 채팅 본문 표시와 독립적으로 처리한다.
      }
    }

    if (planId > 0) {
      try {
        settlement = await settlementRepository.fetchSettlement(
          groupId: groupId,
          planId: planId,
        );
      } catch (_) {
        // 정산 카드 실패는 채팅 본문 표시와 독립적으로 처리한다.
      }
    }

    if (_realtimeDisposed) {
      return;
    }
    final latest = state.asData?.value;
    if (latest == null) {
      return;
    }
    state = AsyncData(
      latest.copyWith(
        pinnedPlan: pinnedPlan,
        planId: planId,
        vote: vote,
        voteId: voteId,
        settlement: settlement,
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

  Future<bool> sendImageMessage(
    PickedChatImage image, {
    String text = '',
  }) async {
    final value = state.asData?.value;
    if (value == null) {
      return false;
    }

    final message = text.trim();
    GroupMessageAttachment attachment;
    try {
      attachment = await ref
          .read(mediaRepositoryProvider)
          .uploadChatImage(image);
    } catch (_) {
      final latest = state.asData?.value ?? value;
      state = AsyncData(latest.copyWith(sendErrorMessage: '사진을 올리지 못했어요.'));
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
      attachments: [attachment],
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
          .sendMessage(
            groupId: groupId,
            message: message,
            attachments: [attachment],
          );
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
          sendErrorMessage: '사진 메시지를 보내지 못했어요.',
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
          .sendMessage(
            groupId: groupId,
            message: failed.message,
            attachments: failed.attachments,
          );
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

  void _startRealtimeSubscription(
    GroupRepository repository, {
    String? afterCursor,
  }) {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = repository
        .watchMessages(groupId, afterCursor: afterCursor)
        .listen(
          _handleRealtimeMessage,
          onError: (_) => _scheduleRealtimeReconnect(),
          onDone: _scheduleRealtimeReconnect,
        );
  }

  void _handleRealtimeMessage(GroupMessage message) {
    final value = state.asData?.value;
    if (value == null) {
      return;
    }
    final messages = _appendRealtimeMessage(value.messages, message);
    state = AsyncData(value.copyWith(messages: messages));
    _markSentMessageRead(message);
  }

  void _scheduleRealtimeReconnect() {
    if (_realtimeDisposed || (_reconnectTimer?.isActive ?? false)) {
      return;
    }
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_realtimeDisposed) {
        return;
      }
      _startRealtimeSubscription(
        ref.read(groupRepositoryProvider),
        afterCursor: _latestCursor(state.asData?.value.messages ?? const []),
      );
    });
  }

  void _disposeRealtime() {
    _realtimeDisposed = true;
    _reconnectTimer?.cancel();
    _realtimeSubscription?.cancel();
  }

  Future<void> _markNewestMessageRead(
    GroupRepository repository,
    List<GroupMessage> messages,
  ) async {
    final lastReadMessageId = messages.lastOrNull?.id;
    if (lastReadMessageId == null || lastReadMessageId.isEmpty) {
      return;
    }
    try {
      await repository.markMessagesRead(
        groupId: groupId,
        lastReadMessageId: lastReadMessageId,
      );
    } catch (_) {
      // 읽음 동기화 실패는 초기 메시지 표시를 막지 않는다.
    }
  }

  Future<void> _markSentMessageRead(GroupMessage message) async {
    if (message.id.isEmpty) {
      return;
    }
    try {
      await ref
          .read(groupRepositoryProvider)
          .markMessagesRead(groupId: groupId, lastReadMessageId: message.id);
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

  List<GroupMessage> _appendRealtimeMessage(
    List<GroupMessage> currentMessages,
    GroupMessage incoming,
  ) {
    final incomingKey = _messageKey(incoming);
    final knownKeys = currentMessages.map(_messageKey).toSet();
    if (knownKeys.contains(incomingKey)) {
      return currentMessages;
    }

    final pendingIndex = currentMessages.indexWhere((message) {
      return message.isMine &&
          message.sendStatus.isPending &&
          incoming.isMine &&
          message.message == incoming.message &&
          _attachmentSignature(message) == _attachmentSignature(incoming);
    });
    if (pendingIndex < 0) {
      return [...currentMessages, incoming];
    }
    return [
      for (var index = 0; index < currentMessages.length; index += 1)
        if (index == pendingIndex) incoming else currentMessages[index],
    ];
  }

  String? _latestCursor(List<GroupMessage> messages) {
    for (final message in messages.reversed) {
      if (message.cursor.isNotEmpty) {
        return message.cursor;
      }
    }
    return null;
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

  String _attachmentSignature(GroupMessage message) {
    return message.attachments
        .map((attachment) => attachment.storageKey.trim())
        .where((storageKey) => storageKey.isNotEmpty)
        .join('|');
  }
}
