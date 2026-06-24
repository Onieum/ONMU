import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_empty_state_card.dart';
import '../../../../shared/widgets/onmu_plan_status_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../repository/media_repository.dart';
import '../../view_model/group_chat_view_model.dart';
import '../widgets/group_cards.dart';

class GroupChatPage extends ConsumerStatefulWidget {
  const GroupChatPage({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends ConsumerState<GroupChatPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _searchFocusNode = FocusNode();

  List<PickedChatImage> _selectedImages = const [];
  int _lastRenderedMessageCount = 0;
  String _lastRenderedLastMessageKey = '';
  bool _showJumpToLatest = false;
  bool _isSearchVisible = false;
  int _searchMatchIndex = 0;
  String? _highlightedMessageKey;
  String? _lastAutoFocusedMessageKey;
  final Map<String, GlobalKey> _messageItemKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScroll);
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_handleScroll);
    _searchController.removeListener(_handleSearchChanged);
    _messageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {
      return;
    }
    unawaited(
      ref
          .read(groupChatViewModelProvider(widget.groupId).notifier)
          .refreshVisibleState(),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final selectedImages = List<PickedChatImage>.of(_selectedImages);

    if (text.isEmpty && selectedImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메시지나 사진을 추가해 주세요.')));
      return;
    }

    _messageController.clear();
    if (selectedImages.isNotEmpty) {
      setState(() => _selectedImages = const []);
    }
    final chatViewModel = ref.read(
      groupChatViewModelProvider(widget.groupId).notifier,
    );
    final sendFuture = selectedImages.isEmpty
        ? chatViewModel.sendMessage(text)
        : chatViewModel.sendImageMessages(selectedImages, text: text);
    _setJumpToLatestVisible(false);
    _scheduleScrollToBottom();
    final sent = await sendFuture;
    if (!mounted) {
      return;
    }
    if (!sent) {
      _messageController.text = text;
      if (selectedImages.isNotEmpty) {
        setState(() => _selectedImages = selectedImages);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selectedImages.isEmpty ? '메시지를 보내지 못했어요.' : '사진을 올리지 못했어요.',
          ),
        ),
      );
      return;
    }
  }

  Future<void> _pickImagesForComposer() async {
    final remainingCount = maxChatImageAttachmentCount - _selectedImages.length;
    if (remainingCount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진은 한 번에 4장까지 보낼 수 있어요.')));
      return;
    }

    final pickedImages = await _imagePicker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (pickedImages.isEmpty) {
      return;
    }

    final selectedImages = pickedImages
        .take(remainingCount)
        .map(
          (picked) => PickedChatImage(
            path: picked.path,
            fileName: picked.name,
            contentType: picked.mimeType ?? 'image/jpeg',
          ),
        )
        .toList(growable: false);
    if (selectedImages.isEmpty) {
      return;
    }

    setState(() {
      _selectedImages = [
        ..._selectedImages,
        ...selectedImages,
      ].take(maxChatImageAttachmentCount).toList(growable: false);
    });

    if (pickedImages.length > remainingCount && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진은 한 번에 4장까지 보낼 수 있어요.')));
    }
  }

  void _removeSelectedImage(int index) {
    if (index < 0 || index >= _selectedImages.length) {
      return;
    }
    final nextImages = [..._selectedImages]..removeAt(index);
    setState(() => _selectedImages = nextImages);
  }

  void _clearSelectedImages() {
    setState(() => _selectedImages = const []);
  }

  void _handleSearchChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _searchMatchIndex = 0;
      _highlightedMessageKey = null;
      _lastAutoFocusedMessageKey = null;
    });
  }

  void _openSearch() {
    if (_isSearchVisible) {
      _searchFocusNode.requestFocus();
      return;
    }
    setState(() {
      _isSearchVisible = true;
      _searchMatchIndex = 0;
      _highlightedMessageKey = null;
      _lastAutoFocusedMessageKey = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    final hadQuery = _searchController.text.isNotEmpty;
    if (hadQuery) {
      _searchController.clear();
    }
    _lastAutoFocusedMessageKey = null;
    if (!_isSearchVisible &&
        _highlightedMessageKey == null &&
        _searchMatchIndex == 0 &&
        !hadQuery) {
      return;
    }
    setState(() {
      _isSearchVisible = false;
      _searchMatchIndex = 0;
      _highlightedMessageKey = null;
    });
  }

  List<String> _searchMatchKeys(List<GroupMessage> messages) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return const [];
    }
    return [
      for (final message in messages)
        if (_matchesSearch(message, query)) _messageKey(message),
    ];
  }

  bool _matchesSearch(GroupMessage message, String query) {
    final values = [
      message.sender,
      message.message,
      message.activityTitle,
      message.activityActionLabel,
    ];
    return values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .any((value) => value.contains(query));
  }

  void _showPreviousSearchMatch(List<String> matches) {
    _moveSearchMatch(matches, direction: -1);
  }

  void _showNextSearchMatch(List<String> matches) {
    _moveSearchMatch(matches, direction: 1);
  }

  void _moveSearchMatch(List<String> matches, {required int direction}) {
    if (matches.isEmpty) {
      return;
    }
    final currentIndex = _normalizedSearchMatchIndex(matches);
    final nextIndex =
        (currentIndex + direction + matches.length) % matches.length;
    setState(() {
      _searchMatchIndex = nextIndex;
      _highlightedMessageKey = null;
      _lastAutoFocusedMessageKey = null;
    });
  }

  int _normalizedSearchMatchIndex(List<String> matches) {
    if (matches.isEmpty) {
      return 0;
    }
    return _searchMatchIndex.clamp(0, matches.length - 1);
  }

  GlobalKey _messageItemKey(String messageKey) {
    return _messageItemKeys.putIfAbsent(
      messageKey,
      () => GlobalKey(debugLabel: 'chat-message-$messageKey'),
    );
  }

  void _scheduleFocusMessage(String? messageKey) {
    if (messageKey == null || _lastAutoFocusedMessageKey == messageKey) {
      return;
    }
    _lastAutoFocusedMessageKey = messageKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final targetContext = _messageItemKey(messageKey).currentContext;
      if (targetContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        alignment: 0.18,
      );
    });
  }

  GroupMessage? _lastFailedMessage(List<GroupMessage> messages) {
    for (var index = messages.length - 1; index >= 0; index -= 1) {
      final message = messages[index];
      if (message.canRetry) {
        return message;
      }
    }
    return null;
  }

  void _jumpToLatestFailedMessage(List<GroupMessage> messages) {
    final failed = _lastFailedMessage(messages);
    if (failed == null) {
      return;
    }
    _closeSearch();
    setState(() {
      _highlightedMessageKey = _messageKey(failed);
      _lastAutoFocusedMessageKey = null;
    });
  }

  Future<void> _retryFailedMessages(List<GroupMessage> messages) async {
    final failedMessageIds = [
      for (final message in messages)
        if (message.canRetry && message.id.trim().isNotEmpty) message.id,
    ];
    if (failedMessageIds.isEmpty) {
      return;
    }

    final notifier = ref.read(
      groupChatViewModelProvider(widget.groupId).notifier,
    );
    var successCount = 0;
    var failureCount = 0;
    for (final messageId in failedMessageIds) {
      final retried = await notifier.retryMessage(messageId);
      if (retried) {
        successCount += 1;
      } else {
        failureCount += 1;
      }
    }
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (failureCount == 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('전송 실패 메시지 $successCount개를 다시 보냈어요.')),
      );
      return;
    }
    if (successCount == 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('전송 실패 메시지를 다시 보내지 못했어요.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$successCount개는 다시 보냈고, $failureCount개는 아직 실패했어요.'),
        ),
      );
    }

    final latestState = ref
        .read(groupChatViewModelProvider(widget.groupId))
        .asData
        ?.value;
    if (latestState == null) {
      return;
    }
    final latestFailed = _lastFailedMessage(latestState.messages);
    if (latestFailed == null) {
      return;
    }
    setState(() {
      _highlightedMessageKey = _messageKey(latestFailed);
      _lastAutoFocusedMessageKey = null;
    });
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  void _jumpToLatestMessage() {
    _setJumpToLatestVisible(false);
    _scheduleScrollToBottom();
  }

  void _handleScroll() {
    if (_showJumpToLatest && _isNearTimelineBottom()) {
      _setJumpToLatestVisible(false);
    }
  }

  bool _isNearTimelineBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <= 180;
  }

  void _syncTimelineScrollState(List<GroupMessage> messages) {
    final messageCount = messages.length;
    final lastMessageKey = messages.isEmpty ? '' : _messageKey(messages.last);
    final appendedLatestMessage =
        messageCount > _lastRenderedMessageCount &&
        _lastRenderedLastMessageKey.isNotEmpty &&
        lastMessageKey != _lastRenderedLastMessageKey;

    _lastRenderedMessageCount = messageCount;
    _lastRenderedLastMessageKey = lastMessageKey;

    if (!appendedLatestMessage) {
      return;
    }
    if (_isNearTimelineBottom()) {
      _setJumpToLatestVisible(false);
      _scheduleScrollToBottom();
      return;
    }
    _setJumpToLatestVisible(true);
  }

  String _messageKey(GroupMessage message) {
    if (message.id.trim().isNotEmpty) {
      return 'id:${message.id}';
    }
    if (message.cursor.trim().isNotEmpty) {
      return 'cursor:${message.cursor}';
    }
    return '${message.sender}|${message.message}|${message.timeLabel}|'
        '${message.isMine}|${message.sendStatus.name}';
  }

  void _setJumpToLatestVisible(bool visible) {
    if (_showJumpToLatest == visible) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _showJumpToLatest == visible) {
        return;
      }
      setState(() => _showJumpToLatest = visible);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupChatViewModelProvider(widget.groupId));

    return state.when(
      data: (state) {
        _syncTimelineScrollState(state.messages);
        final searchMatches = _searchMatchKeys(state.messages);
        final searchMatchIndex = _normalizedSearchMatchIndex(searchMatches);
        final activeSearchMatchKey = searchMatches.isEmpty
            ? null
            : searchMatches[searchMatchIndex];
        final highlightedMessageKey =
            _isSearchVisible && activeSearchMatchKey != null
            ? activeSearchMatchKey
            : _highlightedMessageKey;
        _scheduleFocusMessage(highlightedMessageKey);
        return _ThreadContent(
          state: state,
          messageController: _messageController,
          scrollController: _scrollController,
          selectedImages: _selectedImages,
          showJumpToLatest: _showJumpToLatest,
          searchVisible: _isSearchVisible,
          searchController: _searchController,
          searchFocusNode: _searchFocusNode,
          searchResultCount: searchMatches.length,
          currentSearchPosition: searchMatches.isEmpty
              ? 0
              : searchMatchIndex + 1,
          highlightedMessageKey: highlightedMessageKey,
          messageLookupKey: _messageKey,
          messageItemKey: _messageItemKey,
          onJumpToLatest: _jumpToLatestMessage,
          onSend: _sendMessage,
          onPickImage: _pickImagesForComposer,
          onRemoveSelectedImage: _removeSelectedImage,
          onClearSelectedImages: _clearSelectedImages,
          onOpenSearch: _openSearch,
          onCloseSearch: _closeSearch,
          onSearchPrevious: () => _showPreviousSearchMatch(searchMatches),
          onSearchNext: () => _showNextSearchMatch(searchMatches),
          onLoadSettlementCandidatePlans: () => ref
              .read(groupChatViewModelProvider(widget.groupId).notifier)
              .loadSettlementCandidatePlans(),
          onLoadOlderMessages: () => ref
              .read(groupChatViewModelProvider(widget.groupId).notifier)
              .loadOlderMessages(),
          onRetryFailedMessages: () => _retryFailedMessages(state.messages),
          onJumpToLatestFailedMessage: () =>
              _jumpToLatestFailedMessage(state.messages),
          onRetryMessage: (messageId) async {
            final retried = await ref
                .read(groupChatViewModelProvider(widget.groupId).notifier)
                .retryMessage(messageId);
            if (!mounted || !context.mounted || retried) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('메시지를 다시 보내지 못했어요.')));
          },
        );
      },
      loading: () =>
          const OnmuScaffold(title: '채팅', children: [_ChatLoadingState()]),
      error: (error, stackTrace) => OnmuScaffold(
        title: '채팅',
        children: [
          _ChatErrorState(
            onRetry: () =>
                ref.invalidate(groupChatViewModelProvider(widget.groupId)),
          ),
        ],
      ),
    );
  }
}

class _ThreadContent extends StatelessWidget {
  const _ThreadContent({
    required this.state,
    required this.messageController,
    required this.scrollController,
    required this.selectedImages,
    required this.showJumpToLatest,
    required this.searchVisible,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchResultCount,
    required this.currentSearchPosition,
    required this.highlightedMessageKey,
    required this.messageLookupKey,
    required this.messageItemKey,
    required this.onJumpToLatest,
    required this.onSend,
    required this.onPickImage,
    required this.onRemoveSelectedImage,
    required this.onClearSelectedImages,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onSearchPrevious,
    required this.onSearchNext,
    required this.onLoadSettlementCandidatePlans,
    required this.onLoadOlderMessages,
    required this.onRetryFailedMessages,
    required this.onJumpToLatestFailedMessage,
    required this.onRetryMessage,
  });

  final GroupChatState state;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final List<PickedChatImage> selectedImages;
  final bool showJumpToLatest;
  final bool searchVisible;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final int searchResultCount;
  final int currentSearchPosition;
  final String? highlightedMessageKey;
  final String Function(GroupMessage message) messageLookupKey;
  final GlobalKey Function(String messageKey) messageItemKey;
  final VoidCallback onJumpToLatest;
  final Future<void> Function() onSend;
  final Future<void> Function() onPickImage;
  final ValueChanged<int> onRemoveSelectedImage;
  final VoidCallback onClearSelectedImages;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final VoidCallback onSearchPrevious;
  final VoidCallback onSearchNext;
  final Future<List<GroupPlanSummary>> Function()
  onLoadSettlementCandidatePlans;
  final Future<void> Function() onLoadOlderMessages;
  final Future<void> Function() onRetryFailedMessages;
  final VoidCallback onJumpToLatestFailedMessage;
  final Future<void> Function(String messageId) onRetryMessage;

  @override
  Widget build(BuildContext context) {
    final group = state.group;

    return OnmuScaffold(
      title: group.name,
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.groupDetail(group.id)),
      pinnedHeader: searchVisible
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: _ChatSearchCard(
                controller: searchController,
                focusNode: searchFocusNode,
                resultCount: searchResultCount,
                currentPosition: currentSearchPosition,
                onPrevious: searchResultCount > 1 ? onSearchPrevious : null,
                onNext: searchResultCount > 1 ? onSearchNext : null,
                onClose: onCloseSearch,
              ),
            )
          : null,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: searchVisible ? '채팅 검색 닫기' : '채팅 검색',
            onPressed: searchVisible ? onCloseSearch : onOpenSearch,
            icon: Icon(searchVisible ? Icons.close : Icons.search),
          ),
          PopupMenuButton<_ChatMenuAction>(
            tooltip: '채팅 메뉴',
            icon: const Icon(Icons.more_vert),
            color: AppColors.bgDefault,
            onSelected: (action) {
              switch (action) {
                case _ChatMenuAction.votes:
                  context.push(RoutePaths.groupVotes(group.id));
                case _ChatMenuAction.plan:
                  context.push(
                    state.planId > 0
                        ? RoutePaths.planDetail(group.id, state.planId)
                        : RoutePaths.planNew(group.id),
                  );
                case _ChatMenuAction.settings:
                  context.push(RoutePaths.groupSettings(group.id));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _ChatMenuAction.votes,
                child: _ChatMenuItem(
                  icon: Icons.how_to_vote_outlined,
                  label: '투표 목록',
                ),
              ),
              const PopupMenuItem(
                value: _ChatMenuAction.plan,
                child: _ChatMenuItem(
                  icon: Icons.event_note_outlined,
                  label: '약속 일정',
                ),
              ),
              const PopupMenuItem(
                value: _ChatMenuAction.settings,
                child: _ChatMenuItem(icon: Icons.tune_outlined, label: '모임 설정'),
              ),
            ],
          ),
        ],
      ),
      bottom: _MessageInput(
        controller: messageController,
        selectedImages: selectedImages,
        isConversationEmpty: state.messages.isEmpty,
        onSend: onSend,
        onOpenActions: () => _showChatActions(context),
        onAddImage: onPickImage,
        onRemoveImage: onRemoveSelectedImage,
        onClearImages: onClearSelectedImages,
      ),
      floatingActionButton: showJumpToLatest
          ? FloatingActionButton.small(
              tooltip: '최신 메시지로 이동',
              backgroundColor: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              onPressed: onJumpToLatest,
              child: const Icon(Icons.arrow_downward),
            )
          : null,
      scrollController: scrollController,
      children: [
        _ChatRoomContextCard(
          group: group,
          onMembersTap: () => context.push(RoutePaths.groupMembers(group.id)),
          onPlansTap: () => context.push(RoutePaths.groupPlans(group.id)),
          onSettingsTap: () => context.push(RoutePaths.groupSettings(group.id)),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.pinnedPlan != null)
          _PlanChatAnchor(
            plan: state.pinnedPlan!,
            onTap: () => context.push(
              state.planId > 0
                  ? RoutePaths.planDetail(group.id, state.planId)
                  : RoutePaths.planNew(group.id),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (state.vote != null && state.voteId > 0) ...[
          _VoteNoticeCard(
            vote: state.vote!,
            onTap: () =>
                context.push(RoutePaths.groupVote(group.id, state.voteId)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.settlement != null && state.planId > 0) ...[
          _SettlementNoticeCard(
            settlement: state.settlement!,
            onTap: () => context.push(
              state.settlement!.isDraft
                  ? RoutePaths.planSettlementNew(group.id, state.planId)
                  : RoutePaths.planSettlementDetail(
                      group.id,
                      state.planId,
                      state.settlement!.id,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.hasMoreOlderMessages) ...[
          _LoadOlderMessagesButton(
            loading: state.isLoadingOlderMessages,
            onPressed: state.isLoadingOlderMessages
                ? null
                : onLoadOlderMessages,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_failedMessageCount > 0) ...[
          _FailedMessagesNoticeCard(
            count: _failedMessageCount,
            onRetryAll: onRetryFailedMessages,
            onJumpToLatestFailed: onJumpToLatestFailedMessage,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.sendErrorMessage?.trim().isNotEmpty ?? false) ...[
          _ChatInlineNotice(message: state.sendErrorMessage!.trim()),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.messages.isEmpty) ...[
          const _ChatEmptyState(),
        ] else ...[
          ..._timelineChildren(context),
        ],
      ],
    );
  }

  List<Widget> _timelineChildren(BuildContext context) {
    final children = <Widget>[];
    final fallbackDate = DateTime.now();
    final messages = state.messages;
    final unreadStartIndex = _unreadStartIndex(
      messages.length,
      state.unreadCount,
    );
    String? previousDateKey;

    for (var index = 0; index < messages.length; index += 1) {
      final message = messages[index];
      final messageDate = _localDateForMessage(message, fallbackDate);
      final dateKey = _dateKey(messageDate);
      final previousMessage = index > 0 ? messages[index - 1] : null;
      final previousMessageDate = previousMessage == null
          ? null
          : _localDateForMessage(previousMessage, fallbackDate);
      final nextMessage = index + 1 < messages.length
          ? messages[index + 1]
          : null;
      final nextMessageDate = nextMessage == null
          ? null
          : _localDateForMessage(nextMessage, fallbackDate);
      final groupedWithPrevious = _canGroupTimelineMessages(
        previousMessage,
        message,
        previousDate: previousMessageDate,
        currentDate: messageDate,
      );
      final groupedWithNext = _canGroupTimelineMessages(
        message,
        nextMessage,
        previousDate: messageDate,
        currentDate: nextMessageDate,
      );
      if (dateKey != previousDateKey) {
        children
          ..add(_DateDivider(label: _dateDividerLabel(messageDate)))
          ..add(const SizedBox(height: AppSpacing.md));
        previousDateKey = dateKey;
      }
      if (index == unreadStartIndex) {
        children
          ..add(_UnreadDivider(count: state.unreadCount))
          ..add(const SizedBox(height: AppSpacing.md));
      }
      children
        ..add(
          _messageWidget(
            context,
            message,
            showAvatar: !groupedWithPrevious,
            showSenderName: !groupedWithPrevious,
            showTimestamp: !groupedWithNext,
          ),
        )
        ..add(
          SizedBox(height: groupedWithNext ? AppSpacing.xxs : AppSpacing.sm),
        );
    }

    return children;
  }

  Widget _messageWidget(
    BuildContext context,
    GroupMessage message, {
    required bool showAvatar,
    required bool showSenderName,
    required bool showTimestamp,
  }) {
    final messageKey = messageLookupKey(message);
    final highlighted = highlightedMessageKey == messageKey;
    if (message.isActivity) {
      return KeyedSubtree(
        key: messageItemKey(messageKey),
        child: _TimelineHighlightFrame(
          highlighted: highlighted,
          child: ChatActivityCard(
            message: message,
            onTap: () => _openActivityMessage(context, message),
          ),
        ),
      );
    }
    final displayMessage = showTimestamp
        ? message
        : message.copyWith(timeLabel: '');
    return KeyedSubtree(
      key: messageItemKey(messageKey),
      child: _TimelineHighlightFrame(
        highlighted: highlighted,
        child: ChatMessageBubble(
          message: displayMessage,
          showAvatar: showAvatar,
          showSenderName: showSenderName,
          onRetry: message.canRetry ? () => onRetryMessage(message.id) : null,
        ),
      ),
    );
  }

  int get _failedMessageCount {
    var count = 0;
    for (final message in state.messages) {
      if (message.canRetry) {
        count += 1;
      }
    }
    return count;
  }

  bool _canGroupTimelineMessages(
    GroupMessage? previous,
    GroupMessage? current, {
    required DateTime? previousDate,
    required DateTime? currentDate,
  }) {
    if (previous == null ||
        current == null ||
        previousDate == null ||
        currentDate == null) {
      return false;
    }
    if (previous.isActivity || current.isActivity) {
      return false;
    }
    if (!_isSameLocalDate(previousDate, currentDate)) {
      return false;
    }
    if (previous.isMine != current.isMine) {
      return false;
    }
    if (current.isMine) {
      return true;
    }
    final previousSender = previous.sender.trim();
    final currentSender = current.sender.trim();
    return previousSender.isNotEmpty && previousSender == currentSender;
  }

  bool _isSameLocalDate(DateTime left, DateTime right) {
    final leftLocal = left.toLocal();
    final rightLocal = right.toLocal();
    return leftLocal.year == rightLocal.year &&
        leftLocal.month == rightLocal.month &&
        leftLocal.day == rightLocal.day;
  }

  int _unreadStartIndex(int messageCount, int unreadCount) {
    if (messageCount <= 0 || unreadCount <= 0) {
      return -1;
    }
    final startIndex = messageCount - unreadCount;
    if (startIndex <= 0) {
      return 0;
    }
    if (startIndex >= messageCount) {
      return -1;
    }
    return startIndex;
  }

  DateTime _localDateForMessage(GroupMessage message, DateTime fallbackDate) {
    final cursorDate = DateTime.tryParse(message.cursor.trim());
    if (cursorDate != null) {
      return cursorDate.toLocal();
    }
    final localMessageDate = _localPendingDate(message.id);
    return localMessageDate ?? fallbackDate;
  }

  DateTime? _localPendingDate(String messageId) {
    final match = RegExp(r'^local-(\d+)').firstMatch(messageId.trim());
    final microseconds = int.tryParse(match?.group(1) ?? '');
    if (microseconds == null) {
      return null;
    }
    return DateTime.fromMicrosecondsSinceEpoch(microseconds);
  }

  String _dateKey(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month}-${local.day}';
  }

  String _dateDividerLabel(DateTime date) {
    final local = date.toLocal();
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[local.weekday - 1];
    return '${local.year}년 ${local.month}월 ${local.day}일 $weekday요일';
  }

  void _openActivityMessage(BuildContext context, GroupMessage message) {
    final groupId = state.group.id;
    if (message.isPlanCard) {
      final planId = _planIdFor(message);
      context.push(
        planId == null
            ? RoutePaths.planNew(groupId)
            : RoutePaths.planDetail(groupId, planId),
      );
      return;
    }
    if (message.isVoteCard) {
      final voteId = message.voteId.trim();
      context.push(
        voteId.isEmpty
            ? RoutePaths.groupVotes(groupId)
            : RoutePaths.groupVote(groupId, voteId),
      );
      return;
    }
    if (message.isSettlementCard) {
      final planId = _planIdFor(message);
      final settlementId = message.settlementId.trim();
      context.push(
        planId != null && settlementId.isNotEmpty
            ? RoutePaths.planSettlementDetail(groupId, planId, settlementId)
            : planId != null
            ? RoutePaths.planSettlementCurrent(groupId, planId)
            : RoutePaths.planNew(groupId),
      );
      return;
    }
    if (message.isSystemActivity) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이 알림은 채팅 안에서 확인했어요.')));
      return;
    }
  }

  String? _planIdFor(GroupMessage message) {
    final planId = message.planId.trim();
    if (planId.isNotEmpty) {
      return planId;
    }
    if (message.targetType.trim().toUpperCase() != 'PLAN') {
      return null;
    }
    final targetId = message.targetId.trim();
    return targetId.isEmpty ? null : targetId;
  }

  Future<void> _showChatActions(BuildContext context) async {
    final group = state.group;
    final action = await showModalBottomSheet<_ChatActionCommand>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => const _ChatActionSheet(),
    );
    if (action == null || !context.mounted) {
      return;
    }

    switch (action) {
      case _ChatActionCommand.image:
        await onPickImage();
      case _ChatActionCommand.plan:
        context.push(RoutePaths.planNew(group.id));
      case _ChatActionCommand.place:
        context.push(
          state.planId > 0
              ? RoutePaths.planPlaceSearch(group.id, state.planId)
              : RoutePaths.planNew(group.id),
        );
      case _ChatActionCommand.vote:
        context.push(
          state.planId > 0
              ? RoutePaths.planVoteNew(group.id, state.planId)
              : RoutePaths.groupVotes(group.id),
        );
      case _ChatActionCommand.settlement:
        await _openSettlementPlanPicker(context);
    }
  }

  Future<void> _openSettlementPlanPicker(BuildContext context) async {
    final group = state.group;
    var plans = state.settlementCandidatePlans;
    if (plans.isEmpty) {
      plans = await _reloadSettlementCandidatePlans(context);
      if (!context.mounted) {
        return;
      }
    }
    if (plans.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정산할 수 있는 진행중/지난 약속이 없어요.')));
      return;
    }

    final selectedPlan = await showModalBottomSheet<GroupPlanSummary>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => _SettlementPlanPickerSheet(plans: plans),
    );
    if (selectedPlan == null || !context.mounted) {
      return;
    }
    context.push(RoutePaths.planSettlementNew(group.id, selectedPlan.id));
  }

  Future<List<GroupPlanSummary>> _reloadSettlementCandidatePlans(
    BuildContext context,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      return await onLoadSettlementCandidatePlans();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('약속 목록을 불러오지 못했어요.')));
      }
      return const [];
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}

enum _ChatMenuAction { votes, plan, settings }

enum _ChatActionCommand { image, plan, place, vote, settlement }

class _ChatActionSheet extends StatelessWidget {
  const _ChatActionSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lineSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('채팅 액션', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _ChatActionTile(
                icon: Icons.add_photo_alternate_outlined,
                label: '사진 첨부',
                command: _ChatActionCommand.image,
                onSelected: (command) => Navigator.of(context).pop(command),
              ),
              _ChatActionTile(
                icon: Icons.event_available_outlined,
                label: '약속 만들기',
                command: _ChatActionCommand.plan,
                onSelected: (command) => Navigator.of(context).pop(command),
              ),
              _ChatActionTile(
                icon: Icons.place_outlined,
                label: '장소 후보 찾기',
                command: _ChatActionCommand.place,
                onSelected: (command) => Navigator.of(context).pop(command),
              ),
              _ChatActionTile(
                icon: Icons.how_to_vote_outlined,
                label: '투표 만들기',
                command: _ChatActionCommand.vote,
                onSelected: (command) => Navigator.of(context).pop(command),
              ),
              _ChatActionTile(
                icon: Icons.receipt_long_outlined,
                label: '정산 시작',
                command: _ChatActionCommand.settlement,
                onSelected: (command) => Navigator.of(context).pop(command),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatActionTile extends StatelessWidget {
  const _ChatActionTile({
    required this.icon,
    required this.label,
    required this.command,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final _ChatActionCommand command;
  final ValueChanged<_ChatActionCommand> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 32,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      leading: Icon(icon, color: AppColors.primaryPink),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      onTap: () => onSelected(command),
    );
  }
}

class _ChatMenuItem extends StatelessWidget {
  const _ChatMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryPink),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _SettlementPlanPickerSheet extends StatelessWidget {
  const _SettlementPlanPickerSheet({required this.plans});

  final List<GroupPlanSummary> plans;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lineSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('정산할 약속 선택', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '진행중이거나 이미 지난 약속만 정산을 시작할 수 있어요.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final plan in plans) ...[
                _SettlementPlanTile(
                  plan: plan,
                  statusLabel: plan.isOngoingAt(now) ? '진행중' : '지난 약속',
                  onTap: () => Navigator.of(context).pop(plan),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettlementPlanTile extends StatelessWidget {
  const _SettlementPlanTile({
    required this.plan,
    required this.statusLabel,
    required this.onTap,
  });

  final GroupPlanSummary plan;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${plan.displayDateTimeLabel} · ${plan.placeName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OnmuChip(
            label: statusLabel,
            selected: plan.isOngoingAt(DateTime.now()),
          ),
        ],
      ),
    );
  }
}

class _LoadOlderMessagesButton extends StatelessWidget {
  const _LoadOlderMessagesButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.history_outlined, size: 18),
        label: Text(loading ? '불러오는 중' : '이전 메시지 더 보기'),
      ),
    );
  }
}

class _UnreadDivider extends StatelessWidget {
  const _UnreadDivider({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.linePink)),
        const SizedBox(width: AppSpacing.sm),
        OnmuChip(label: '$count개의 새 메시지', selected: true),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(child: Divider(color: AppColors.linePink)),
      ],
    );
  }
}

class _ChatRoomContextCard extends StatelessWidget {
  const _ChatRoomContextCard({
    required this.group,
    required this.onMembersTap,
    required this.onPlansTap,
    required this.onSettingsTap,
  });

  final GroupSummary group;
  final VoidCallback onMembersTap;
  final VoidCallback onPlansTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final description = group.description.trim();
    final pinnedPlanTitle = group.pinnedPlanTitle.trim();
    final lastMessage = group.lastMessage.trim();

    return Semantics(
      container: true,
      label: '${group.name} 채팅방 정보',
      child: OnmuCard(
        backgroundColor: AppColors.bgDefault,
        borderColor: AppColors.lineSoft,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GroupAvatarCluster(
                  members: group.displayMemberAvatars,
                  avatarSize: 36,
                  overlap: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description.isEmpty ? '함께 대화를 이어가 보세요.' : description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (pinnedPlanTitle.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        _ChatRoomMetaLine(
                          icon: Icons.event_note_outlined,
                          label: pinnedPlanTitle,
                        ),
                      ],
                      if (lastMessage.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        _ChatRoomMetaLine(
                          icon: Icons.chat_bubble_outline,
                          label: lastMessage,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OnmuChip(
                  label: '멤버 ${group.members.length}명',
                  icon: Icons.groups_2_outlined,
                  onTap: onMembersTap,
                ),
                OnmuChip(
                  label: '약속 보기',
                  icon: Icons.event_note_outlined,
                  onTap: onPlansTap,
                ),
                OnmuChip(
                  label: '모임 설정',
                  icon: Icons.tune_outlined,
                  onTap: onSettingsTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatSearchCard extends StatelessWidget {
  const _ChatSearchCard({
    required this.controller,
    required this.focusNode,
    required this.resultCount,
    required this.currentPosition,
    required this.onClose,
    this.onPrevious,
    this.onNext,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int resultCount;
  final int currentPosition;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final summaryLabel = resultCount <= 0
        ? '결과 없음'
        : '$currentPosition / $resultCount';

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('대화 검색', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('group-chat-search-field'),
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '메시지나 보낸 사람을 검색해보세요',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '검색어 지우기',
                            onPressed: controller.clear,
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: '이전 검색 결과',
                onPressed: onPrevious,
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: '다음 검색 결과',
                onPressed: onNext,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              IconButton(
                tooltip: '검색 닫기',
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summaryLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

class _ChatRoomMetaLine extends StatelessWidget {
  const _ChatRoomMetaLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
          ),
        ),
      ],
    );
  }
}

class _FailedMessagesNoticeCard extends StatelessWidget {
  const _FailedMessagesNoticeCard({
    required this.count,
    required this.onRetryAll,
    required this.onJumpToLatestFailed,
  });

  final int count;
  final Future<void> Function() onRetryAll;
  final VoidCallback onJumpToLatestFailed;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.linePink,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.primaryPink),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '전송 실패한 메시지 $count개',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '개별 재시도도 가능하고, 여기서 한 번에 다시 보낼 수도 있어요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OnmuSecondaryButton(
                  label: '마지막 실패로 이동',
                  onPressed: onJumpToLatestFailed,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OnmuPrimaryButton(
                  label: '전체 재시도',
                  onPressed: () => unawaited(onRetryAll()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineHighlightFrame extends StatelessWidget {
  const _TimelineHighlightFrame({
    required this.highlighted,
    required this.child,
  });

  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!highlighted) {
      return child;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primaryPink, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PlanChatAnchor extends StatelessWidget {
  const _PlanChatAnchor({required this.plan, required this.onTap});

  final GroupPinnedPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.event_note_outlined, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${plan.dateLabel} · ${plan.placeName}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          if (plan.hasDisplayStatus) ...[
            OnmuPlanStatusChip(
              status: plan.progressStatus,
              label: plan.displayStatusLabel,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _VoteNoticeCard extends StatelessWidget {
  const _VoteNoticeCard({required this.vote, required this.onTap});

  final VoteCard vote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 336),
        child: OnmuCard(
          backgroundColor: AppColors.bgPaper,
          borderColor: AppColors.linePink,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 18,
                    color: AppColors.primaryPink,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'ONMU 알림',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                vote.summary,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: AppColors.textInverse,
                  minimumSize: const Size.fromHeight(36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                onPressed: onTap,
                icon: const Icon(Icons.place_outlined, size: 16),
                label: Text(vote.actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettlementNoticeCard extends StatelessWidget {
  const _SettlementNoticeCard({required this.settlement, required this.onTap});

  final SettlementSummary settlement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 336),
        child: OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.lineWarm,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: AppColors.primaryPink,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'ONMU 정산',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                settlement.isDraft
                    ? '${settlement.planTitle} 정산을 입력 중이에요.'
                    : '${settlement.planTitle} 정산이 확정됐어요.',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                settlement.isDraft
                    ? '${settlement.itemCountLabel} · 이어서 입력할 수 있어요.'
                    : '총 ${settlement.totalAmountLabel} · ${settlement.displayFinalSummaryLabel}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: AppColors.textInverse,
                  minimumSize: const Size.fromHeight(36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                onPressed: onTap,
                icon: const Icon(Icons.payments_outlined, size: 16),
                label: Text(settlement.isDraft ? '정산 이어쓰기' : '정산 확인하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.lineSoft)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(child: Divider(color: AppColors.lineSoft)),
      ],
    );
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.selectedImages,
    required this.isConversationEmpty,
    required this.onSend,
    required this.onOpenActions,
    required this.onAddImage,
    required this.onRemoveImage,
    required this.onClearImages,
  });

  final TextEditingController controller;
  final List<PickedChatImage> selectedImages;
  final bool isConversationEmpty;
  final Future<void> Function() onSend;
  final VoidCallback onOpenActions;
  final VoidCallback onAddImage;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onClearImages;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasText = value.text.trim().isNotEmpty;
        final canSend = hasText || selectedImages.isNotEmpty;
        final hintText = selectedImages.isNotEmpty
            ? '사진에 메시지를 더해보세요'
            : isConversationEmpty
            ? '첫 메시지를 입력해보세요'
            : '메시지를 입력해보세요';

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: canSend ? AppColors.linePink : AppColors.lineSoft,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedImages.isNotEmpty) ...[
                ChatComposerImageTray(
                  images: selectedImages,
                  onAddImage: onAddImage,
                  onRemoveImage: onRemoveImage,
                  onClearImages: onClearImages,
                ),
                const Divider(height: 1, color: AppColors.lineSoft),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: '채팅 액션',
                    onPressed: onOpenActions,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primaryPink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: hintText,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                    ),
                    child: IconButton.filled(
                      tooltip: '전송',
                      onPressed: canSend ? onSend : null,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        disabledBackgroundColor: AppColors.lineSoft,
                        foregroundColor: AppColors.textInverse,
                        disabledForegroundColor: AppColors.textMuted,
                      ),
                      icon: Icon(
                        selectedImages.isEmpty
                            ? Icons.send_outlined
                            : Icons.send_rounded,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatLoadingState extends StatelessWidget {
  const _ChatLoadingState();

  @override
  Widget build(BuildContext context) {
    return const OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('채팅을 불러오는 중이에요.'),
        ],
      ),
    );
  }
}

class _ChatErrorState extends StatelessWidget {
  const _ChatErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.accentRed,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '채팅을 불러오지 못했어요.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '네트워크 상태를 확인한 뒤 다시 시도해 주세요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OnmuSecondaryButton(
            label: '다시 불러오기',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return const OnmuEmptyStateCard(
      title: '아직 대화가 없어요.',
      description: '첫 메시지나 사진으로 이 모임의 이야기를 시작해보세요.',
      icon: Icons.chat_bubble_outline_rounded,
    );
  }
}

class _ChatInlineNotice extends StatelessWidget {
  const _ChatInlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.linePink,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.primaryPink,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
          ),
        ],
      ),
    );
  }
}
