import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/observability/onmu_error_reporter.dart';
import '../../../shared/models/group_models.dart';
import '../../../shared/models/settlement_models.dart';
import '../../../shared/models/vote_models.dart';
import '../../home/view_model/home_notifications_view_model.dart';
import '../../settlement/repository/settlement_repository.dart';
import '../repository/group_repository.dart';
import '../repository/media_repository.dart';
import 'group_home_view_model.dart';
import 'group_list_view_model.dart';

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
    this.settlementCandidatePlans = const [],
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
  final List<GroupPlanSummary> settlementCandidatePlans;
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
    bool clearPinnedPlan = false,
    List<GroupMessage>? messages,
    List<GroupPlanSummary>? settlementCandidatePlans,
    VoteCard? vote,
    bool clearVote = false,
    int? voteId,
    int? planId,
    SettlementSummary? settlement,
    bool clearSettlement = false,
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
      pinnedPlan: clearPinnedPlan ? null : pinnedPlan ?? this.pinnedPlan,
      messages: messages ?? this.messages,
      settlementCandidatePlans:
          settlementCandidatePlans ?? this.settlementCandidatePlans,
      vote: clearVote ? null : vote ?? this.vote,
      voteId: voteId ?? this.voteId,
      planId: planId ?? this.planId,
      settlement: clearSettlement ? null : settlement ?? this.settlement,
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

  static const Duration _catchUpInterval = Duration(seconds: 15);

  final String groupId;
  StreamSubscription<GroupMessage>? _realtimeSubscription;
  Timer? _reconnectTimer;
  Timer? _catchUpTimer;
  Timer? _voteDeadlineTimer;
  bool _realtimeDisposed = false;
  bool _isCatchingUpLatestMessages = false;
  String? _lastReadSyncMessageId;

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
    _startCatchUpPolling(groupRepository);
    return chatState;
  }

  Future<void> _loadAuxiliaryChatState(
    GroupRepository groupRepository,
    SettlementRepository settlementRepository,
  ) async {
    List<GroupPlanSummary> plans = const [];

    try {
      plans = await groupRepository.fetchPlans(groupId);
    } catch (error, stackTrace) {
      _report(error, stackTrace, feature: 'group_chat_plans');
      // 약속 목록 실패는 채팅 본문 표시와 독립적으로 처리한다.
    }

    final now = DateTime.now();
    final selectedPlan = _selectPrimaryPlan(plans, now);
    final selectedPinnedPlan = selectedPlan == null
        ? null
        : _pinnedPlanFor(selectedPlan);
    final planId = selectedPlan?.id ?? 0;
    final settlementCandidatePlans = _settlementCandidatePlans(plans, now);
    List<VoteSummary> votes = const [];
    try {
      if (planId > 0) {
        votes = await groupRepository.fetchVotes(
          groupId,
          targetType: 'PLAN',
          targetId: planId,
        );
      }
    } catch (error, stackTrace) {
      _report(error, stackTrace, feature: 'group_chat_votes');
      // 투표 목록 실패는 투표 카드만 생략한다.
    }

    final selectedVote = _selectAuxiliaryVote(votes, planId, now);
    final voteId = selectedVote?.id ?? 0;
    VoteCard? vote;
    SettlementSummary? settlement;

    if (voteId > 0) {
      try {
        final fetchedVote = await groupRepository.fetchVoteCard(
          groupId: groupId,
          voteId: voteId,
        );
        vote = fetchedVote;
      } catch (error, stackTrace) {
        _report(error, stackTrace, feature: 'group_chat_vote_card');
        // 투표 카드 실패는 채팅 본문 표시와 독립적으로 처리한다.
      }
    }

    if (planId > 0) {
      try {
        final fetchedSettlement = await settlementRepository.fetchSettlement(
          groupId: groupId,
          planId: planId,
        );
        if (fetchedSettlement.isCreated) {
          settlement = fetchedSettlement;
        }
      } catch (error, stackTrace) {
        _report(error, stackTrace, feature: 'group_chat_settlement');
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
        clearPinnedPlan: selectedPinnedPlan == null,
        pinnedPlan: selectedPinnedPlan,
        settlementCandidatePlans: settlementCandidatePlans,
        planId: planId,
        clearVote: vote == null,
        vote: vote,
        voteId: vote == null ? 0 : voteId,
        clearSettlement: settlement == null,
        settlement: settlement,
      ),
    );
    _scheduleVoteDeadlineDismissal(selectedVote, voteId);
  }

  Future<List<GroupPlanSummary>> loadSettlementCandidatePlans() async {
    try {
      final plans = await ref.read(groupRepositoryProvider).fetchPlans(groupId);
      final candidates = _settlementCandidatePlans(plans, DateTime.now());
      final latest = state.asData?.value;
      if (latest != null && !_realtimeDisposed) {
        state = AsyncData(
          latest.copyWith(settlementCandidatePlans: candidates),
        );
      }
      return candidates;
    } catch (error, stackTrace) {
      _report(error, stackTrace, feature: 'group_chat_settlement_plans');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  List<GroupPlanSummary> _settlementCandidatePlans(
    List<GroupPlanSummary> plans,
    DateTime now,
  ) {
    final localNow = now.toLocal();
    final candidates = plans
        .where((plan) {
          final startsAt = plan.startsAt?.toLocal();
          return startsAt != null && !localNow.isBefore(startsAt);
        })
        .toList(growable: false);
    return candidates..sort((left, right) {
      final leftOngoing = left.isOngoingAt(localNow);
      final rightOngoing = right.isOngoingAt(localNow);
      if (leftOngoing != rightOngoing) {
        return leftOngoing ? -1 : 1;
      }
      final leftStartsAt = left.startsAt?.toLocal();
      final rightStartsAt = right.startsAt?.toLocal();
      if (leftStartsAt == null && rightStartsAt == null) {
        return left.id.compareTo(right.id);
      }
      if (leftStartsAt == null) {
        return 1;
      }
      if (rightStartsAt == null) {
        return -1;
      }
      return rightStartsAt.compareTo(leftStartsAt);
    });
  }

  GroupPlanSummary? _selectPrimaryPlan(
    List<GroupPlanSummary> plans,
    DateTime now,
  ) {
    final ongoingPlans =
        plans.where((plan) => plan.isOngoingAt(now)).toList(growable: false)
          ..sort(GroupPlanSummary.compareUpcoming);
    if (ongoingPlans.isNotEmpty) {
      return ongoingPlans.first;
    }
    final upcomingPlans =
        plans.where((plan) => plan.isUpcomingFrom(now)).toList(growable: false)
          ..sort(GroupPlanSummary.compareUpcoming);
    return upcomingPlans.isEmpty ? null : upcomingPlans.first;
  }

  GroupPinnedPlan _pinnedPlanFor(GroupPlanSummary plan) {
    return GroupPinnedPlan(
      id: plan.id,
      title: plan.title,
      dateLabel: plan.displayDateTimeLabel,
      placeName: plan.placeName,
      statusLabel: plan.statusType.trim().isNotEmpty
          ? plan.statusType
          : plan.statusLabel,
      voteSummary: '',
    );
  }

  VoteSummary? _selectAuxiliaryVote(
    List<VoteSummary> votes,
    int planId,
    DateTime now,
  ) {
    if (votes.isEmpty) {
      return null;
    }
    for (final vote in votes) {
      if (_voteSummaryMatchesPlan(vote, planId) && !vote.isClosedAt(now)) {
        return vote;
      }
    }
    return null;
  }

  void _scheduleVoteDeadlineDismissal(VoteSummary? vote, int voteId) {
    _voteDeadlineTimer?.cancel();
    _voteDeadlineTimer = null;
    final deadline = vote?.deadlineAt?.toLocal();
    if (vote == null || deadline == null) {
      return;
    }

    final duration = deadline.difference(DateTime.now().toLocal());
    if (duration <= Duration.zero) {
      return;
    }
    _voteDeadlineTimer = Timer(duration, () {
      if (_realtimeDisposed) {
        return;
      }
      final latest = state.asData?.value;
      if (latest == null || latest.voteId != voteId) {
        return;
      }
      state = AsyncData(latest.copyWith(clearVote: true, voteId: 0));
    });
  }

  bool _voteSummaryMatchesPlan(VoteSummary vote, int planId) {
    return vote.targetType.trim().toUpperCase() == 'PLAN' &&
        vote.targetId.trim() == planId.toString();
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
    } catch (error, stackTrace) {
      _report(error, stackTrace, feature: 'group_chat_send');
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

  Future<bool> sendImageMessage(PickedChatImage image, {String text = ''}) {
    return sendImageMessages([image], text: text);
  }

  Future<bool> sendImageMessages(
    List<PickedChatImage> images, {
    String text = '',
  }) async {
    final value = state.asData?.value;
    if (value == null) {
      return false;
    }

    final message = text.trim();
    final imagesToUpload = images
        .take(maxChatImageAttachmentCount)
        .toList(growable: false);
    if (imagesToUpload.isEmpty && message.isEmpty) {
      return false;
    }

    List<GroupMessageAttachment> attachments;
    try {
      attachments = await Future.wait(
        imagesToUpload.map(
          (image) => ref.read(mediaRepositoryProvider).uploadChatImage(image),
        ),
      );
    } catch (error, stackTrace) {
      _report(error, stackTrace, feature: 'group_chat_media');
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
      attachments: attachments,
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
            attachments: attachments,
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
    } catch (error, stackTrace) {
      _report(error, stackTrace, feature: 'group_chat_send');
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
    } catch (error, stackTrace) {
      _report(error, stackTrace, feature: 'group_chat_retry');
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
    } catch (error, stackTrace) {
      _report(error, stackTrace, feature: 'group_chat_history');
      final latest = state.asData?.value ?? value;
      state = AsyncData(
        latest.copyWith(
          isLoadingOlderMessages: false,
          sendErrorMessage: '이전 메시지를 불러오지 못했어요.',
        ),
      );
    }
  }

  Future<void> refreshLatestMessages() {
    return _catchUpLatestMessages(
      ref.read(groupRepositoryProvider),
      feature: 'group_chat_refresh',
    );
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
          onError: (Object error, StackTrace stackTrace) {
            _report(error, stackTrace, feature: 'group_chat_realtime');
            _scheduleRealtimeReconnect();
          },
          onDone: _scheduleRealtimeReconnect,
        );
  }

  void _startCatchUpPolling(GroupRepository repository) {
    _catchUpTimer?.cancel();
    _catchUpTimer = Timer.periodic(_catchUpInterval, (_) {
      unawaited(
        _catchUpLatestMessages(repository, feature: 'group_chat_polling'),
      );
    });
  }

  Future<void> _catchUpLatestMessages(
    GroupRepository repository, {
    required String feature,
  }) async {
    if (_realtimeDisposed || _isCatchingUpLatestMessages) {
      return;
    }
    _isCatchingUpLatestMessages = true;
    try {
      final page = await repository.fetchMessagePage(groupId, limit: 50);
      if (_realtimeDisposed) {
        return;
      }
      final value = state.asData?.value;
      if (value == null) {
        return;
      }
      final merged = _appendIncomingMessages(value.messages, page.messages);
      if (!identical(merged, value.messages)) {
        state = AsyncData(value.copyWith(messages: merged));
      }
      final latestMessage = page.messages.lastOrNull;
      if (latestMessage != null) {
        await _markMessageRead(repository, latestMessage);
      }
    } catch (error, stackTrace) {
      _report(error, stackTrace, feature: feature);
    } finally {
      _isCatchingUpLatestMessages = false;
    }
  }

  void _handleRealtimeMessage(GroupMessage message) {
    final value = state.asData?.value;
    if (value == null) {
      return;
    }
    final messages = _appendRealtimeMessage(value.messages, message);
    state = AsyncData(value.copyWith(messages: messages));
    unawaited(_markSentMessageRead(message));
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
    _catchUpTimer?.cancel();
    _voteDeadlineTimer?.cancel();
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
    await _markMessageRead(repository, messages.last);
  }

  Future<void> _markSentMessageRead(GroupMessage message) async {
    await _markMessageRead(ref.read(groupRepositoryProvider), message);
  }

  Future<void> _markMessageRead(
    GroupRepository repository,
    GroupMessage message,
  ) async {
    if (message.id.isEmpty) {
      return;
    }
    if (_lastReadSyncMessageId == message.id) {
      return;
    }
    try {
      await repository.markMessagesRead(
        groupId: groupId,
        lastReadMessageId: message.id,
      );
      _lastReadSyncMessageId = message.id;
      if (_realtimeDisposed) {
        return;
      }
      _invalidateReadDependentProviders();
    } catch (error, stackTrace) {
      _report(error, stackTrace, feature: 'group_chat_read_sync');
      // 읽음 동기화 실패는 말풍선 전송 성공을 되돌리지 않는다.
    }
  }

  void _report(Object error, StackTrace stackTrace, {required String feature}) {
    ref
        .read(onmuErrorReporterProvider)
        .captureException(error, stackTrace, feature: feature);
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

  List<GroupMessage> _appendIncomingMessages(
    List<GroupMessage> currentMessages,
    List<GroupMessage> incomingMessages,
  ) {
    var nextMessages = currentMessages;
    for (final message in incomingMessages) {
      nextMessages = _appendRealtimeMessage(nextMessages, message);
    }
    if (identical(nextMessages, currentMessages)) {
      return currentMessages;
    }
    return _sortTimelineMessages(nextMessages);
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

  List<GroupMessage> _sortTimelineMessages(List<GroupMessage> messages) {
    final withCursor = <GroupMessage>[];
    final withoutCursor = <GroupMessage>[];
    for (final message in messages) {
      if (DateTime.tryParse(message.cursor) == null) {
        withoutCursor.add(message);
      } else {
        withCursor.add(message);
      }
    }
    withCursor.sort((left, right) {
      final leftCursor = DateTime.parse(left.cursor);
      final rightCursor = DateTime.parse(right.cursor);
      final compared = leftCursor.compareTo(rightCursor);
      return compared == 0 ? left.id.compareTo(right.id) : compared;
    });
    return [...withCursor, ...withoutCursor];
  }

  void _invalidateReadDependentProviders() {
    ref.invalidate(groupListViewModelProvider);
    ref.invalidate(groupHomeViewModelProvider(groupId));
    ref.invalidate(notificationUnreadCountProvider);
  }
}
