import 'character_model.dart';
import 'preference_profile.dart';
import 'vote_models.dart';

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.lastMessage,
    required this.unreadCount,
    required this.pinnedPlanTitle,
    this.memberAvatars = const [],
  });

  final int id;
  final String name;
  final String description;
  final List<String> members;
  final List<GroupPlanMemberAvatar> memberAvatars;
  final String lastMessage;
  final int unreadCount;
  final String pinnedPlanTitle;

  List<GroupPlanMemberAvatar> get displayMemberAvatars {
    if (memberAvatars.isNotEmpty) {
      return memberAvatars;
    }
    return members
        .map((name) => GroupPlanMemberAvatar(name: name))
        .toList(growable: false);
  }

  GroupSummary copyWith({
    int? id,
    String? name,
    String? description,
    List<String>? members,
    List<GroupPlanMemberAvatar>? memberAvatars,
    String? lastMessage,
    int? unreadCount,
    String? pinnedPlanTitle,
  }) {
    return GroupSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      memberAvatars: memberAvatars ?? this.memberAvatars,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      pinnedPlanTitle: pinnedPlanTitle ?? this.pinnedPlanTitle,
    );
  }
}

class GroupPinnedPlan {
  const GroupPinnedPlan({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.placeName,
    required this.statusLabel,
    required this.voteSummary,
  });

  final int id;
  final String title;
  final String dateLabel;
  final String placeName;
  final String statusLabel;
  final String voteSummary;

  PlanProgressStatus get progressStatus =>
      PlanProgressStatus.fromApi(statusLabel);

  bool get hasDisplayStatus => progressStatus.isDisplayable;

  String get displayStatusLabel => hasDisplayStatus ? progressStatus.label : '';
}

class GroupPlanSummary {
  const GroupPlanSummary({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.placeName,
    required this.statusLabel,
    required this.statusType,
    required this.memberCount,
    required this.extraMemberCount,
    required this.iconKind,
    required this.isPast,
    this.memberAvatars = const [],
    this.thumbnailImageUrl = '',
    this.startsAt,
    this.endsAt,
  });

  final int id;
  final String title;
  final String dateLabel;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String placeName;
  final String statusLabel;
  final String statusType;
  final int memberCount;
  final int extraMemberCount;
  final String iconKind;
  final bool isPast;
  final List<GroupPlanMemberAvatar> memberAvatars;
  final String thumbnailImageUrl;

  PlanProgressStatus get progressStatus {
    final source = statusType.trim().isNotEmpty ? statusType : statusLabel;
    return PlanProgressStatus.fromApi(source);
  }

  bool get hasDisplayStatus => progressStatus.isDisplayable;

  String get displayStatusLabel => hasDisplayStatus ? progressStatus.label : '';

  String get participantSummaryLabel =>
      memberCount > 0 ? '$memberCount명 참여' : '';

  String get displayDateTimeLabel {
    final startsAtLocal = startsAt?.toLocal();
    if (startsAtLocal == null) {
      return dateLabel;
    }

    return '${startsAtLocal.month}월 ${startsAtLocal.day}일 ${_formatTime(startsAtLocal)}';
  }

  String get displayTimeRangeLabel {
    final startsAtLocal = startsAt?.toLocal();
    if (startsAtLocal == null) {
      return '시간 미정';
    }

    final endsAtLocal = endsAt?.toLocal();
    if (endsAtLocal == null) {
      return _formatTime(startsAtLocal);
    }

    return '${_formatTime(startsAtLocal)}~${_formatTime(endsAtLocal)}';
  }

  String displayTimeRangeLabelFor(DateTime targetDate) {
    final startsAtLocal = startsAt?.toLocal();
    if (startsAtLocal == null) {
      return '시간 미정';
    }

    final endsAtLocal = endsAt?.toLocal();
    if (endsAtLocal == null || _isSameLocalDate(startsAtLocal, endsAtLocal)) {
      return displayTimeRangeLabel;
    }

    final targetLocalDate = targetDate.toLocal();
    if (_isSameLocalDate(targetLocalDate, startsAtLocal)) {
      return '${_formatTime(startsAtLocal)}~';
    }
    if (_isSameLocalDate(targetLocalDate, endsAtLocal)) {
      return '~${_formatTime(endsAtLocal)}';
    }
    if (_isBetweenLocalDates(targetLocalDate, startsAtLocal, endsAtLocal)) {
      return '하루종일';
    }
    return displayTimeRangeLabel;
  }

  bool isUpcomingFrom(DateTime now) {
    final startsAtLocal = startsAt?.toLocal();
    return !isPast &&
        progressStatus.isUpcomingCandidate &&
        (startsAtLocal == null || !startsAtLocal.isBefore(now.toLocal()));
  }

  bool isRemainingTodayAt(DateTime now) {
    final startsAtLocal = startsAt?.toLocal();
    if (startsAtLocal == null || !progressStatus.isUpcomingCandidate) {
      return false;
    }

    final localNow = now.toLocal();
    final endsAtLocal =
        endsAt?.toLocal() ?? startsAtLocal.add(const Duration(hours: 2));
    if (!_isLocalDateInRange(localNow, startsAtLocal, endsAtLocal)) {
      return false;
    }
    return localNow.isBefore(endsAtLocal);
  }

  bool isOngoingAt(DateTime now) {
    final startsAtLocal = startsAt?.toLocal();
    if (isPast ||
        startsAtLocal == null ||
        !progressStatus.isUpcomingCandidate) {
      return false;
    }

    final localNow = now.toLocal();
    final endsAtLocal =
        endsAt?.toLocal() ?? startsAtLocal.add(const Duration(hours: 2));
    return !localNow.isBefore(startsAtLocal) && localNow.isBefore(endsAtLocal);
  }

  static int compareUpcoming(GroupPlanSummary left, GroupPlanSummary right) {
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
    final compared = leftStartsAt.compareTo(rightStartsAt);
    return compared == 0 ? left.id.compareTo(right.id) : compared;
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isSameLocalDate(DateTime left, DateTime right) {
    final leftLocal = left.toLocal();
    final rightLocal = right.toLocal();
    return leftLocal.year == rightLocal.year &&
        leftLocal.month == rightLocal.month &&
        leftLocal.day == rightLocal.day;
  }

  bool _isBetweenLocalDates(DateTime target, DateTime start, DateTime end) {
    final targetDate = DateTime(target.year, target.month, target.day);
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return targetDate.isAfter(startDate) && targetDate.isBefore(endDate);
  }

  bool _isLocalDateInRange(DateTime target, DateTime start, DateTime end) {
    final targetDate = DateTime(target.year, target.month, target.day);
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return !targetDate.isBefore(startDate) && !targetDate.isAfter(endDate);
  }
}

enum PlanProgressStatus {
  scheduled('예정'),
  active('진행 중'),
  completed('완료'),
  cancelled('취소됨'),
  unknown('');

  const PlanProgressStatus(this.label);

  final String label;

  bool get isDisplayable => this != PlanProgressStatus.unknown;

  bool get isUpcomingCandidate {
    return switch (this) {
      PlanProgressStatus.completed || PlanProgressStatus.cancelled => false,
      _ => true,
    };
  }

  static PlanProgressStatus fromApi(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]'),
      '',
    );
    return switch (normalized) {
      'scheduled' || '예정' => PlanProgressStatus.scheduled,
      'active' || '진행중' => PlanProgressStatus.active,
      'completed' || '완료' => PlanProgressStatus.completed,
      'cancelled' || '취소됨' => PlanProgressStatus.cancelled,
      _ => PlanProgressStatus.unknown,
    };
  }
}

enum GroupMessageSendStatus {
  sent,
  sending,
  failed;

  bool get isPending => this == GroupMessageSendStatus.sending;

  bool get isFailed => this == GroupMessageSendStatus.failed;

  static GroupMessageSendStatus fromApi(String value) {
    return switch (value.trim().toLowerCase()) {
      'sending' || 'pending' => GroupMessageSendStatus.sending,
      'failed' || 'error' => GroupMessageSendStatus.failed,
      _ => GroupMessageSendStatus.sent,
    };
  }
}

class GroupPlanMemberAvatar {
  const GroupPlanMemberAvatar({
    required this.name,
    this.profileImageUrl = '',
    this.character,
  });

  final String name;
  final String profileImageUrl;
  final CharacterDraft? character;
}

class GroupMessage {
  const GroupMessage({
    required this.sender,
    required this.message,
    required this.timeLabel,
    required this.isMine,
    this.id = '',
    this.cursor = '',
    this.messageType = '',
    this.cardType = '',
    this.targetType = '',
    this.targetId = '',
    this.planId = '',
    this.voteId = '',
    this.settlementId = '',
    this.sendStatus = GroupMessageSendStatus.sent,
    this.senderProfileImageUrl = '',
    this.senderCharacter,
    this.attachments = const [],
  });

  final String id;
  final String cursor;
  final String sender;
  final String message;
  final String timeLabel;
  final String messageType;
  final String cardType;
  final String targetType;
  final String targetId;
  final String planId;
  final String voteId;
  final String settlementId;
  final bool isMine;
  final GroupMessageSendStatus sendStatus;
  final String senderProfileImageUrl;
  final CharacterDraft? senderCharacter;
  final List<GroupMessageAttachment> attachments;

  bool get canRetry => isMine && sendStatus.isFailed;
  bool get hasAttachments => attachments.isNotEmpty;

  String get normalizedMessageType {
    final type = messageType.trim().toLowerCase();
    if (type.isNotEmpty) {
      return switch (type) {
        'plan' || 'plan_card' => 'plan_card',
        'vote' || 'vote_card' => 'vote_card',
        'settlement' || 'settlement_card' => 'settlement_card',
        'system' || 'notice' => 'system',
        _ => 'message',
      };
    }
    return switch (cardType.trim().toLowerCase()) {
      'plan' || 'plan_card' => 'plan_card',
      'vote' || 'vote_card' => 'vote_card',
      'settlement' || 'settlement_card' => 'settlement_card',
      'system' || 'notice' => 'system',
      _ => 'message',
    };
  }

  bool get isActivity => normalizedMessageType != 'message';
  bool get isPlanCard => normalizedMessageType == 'plan_card';
  bool get isVoteCard => normalizedMessageType == 'vote_card';
  bool get isSettlementCard => normalizedMessageType == 'settlement_card';
  bool get isSystemActivity => normalizedMessageType == 'system';
  bool get hasSettlementRoute => planId.isNotEmpty && settlementId.isNotEmpty;

  String get activityTitle {
    return switch (normalizedMessageType) {
      'plan_card' => '약속 업데이트',
      'vote_card' => '투표가 열렸어요',
      'settlement_card' => '정산이 만들어졌어요',
      'system' => 'ONMU 알림',
      _ => '',
    };
  }

  String get activityActionLabel {
    return switch (normalizedMessageType) {
      'plan_card' => '약속 보기',
      'vote_card' => '투표 보기',
      'settlement_card' => '정산 확인하기',
      'system' => '확인하기',
      _ => '',
    };
  }

  GroupMessage copyWith({
    String? id,
    String? cursor,
    String? sender,
    String? message,
    String? timeLabel,
    String? messageType,
    String? cardType,
    String? targetType,
    String? targetId,
    String? planId,
    String? voteId,
    String? settlementId,
    bool? isMine,
    GroupMessageSendStatus? sendStatus,
    String? senderProfileImageUrl,
    CharacterDraft? senderCharacter,
    List<GroupMessageAttachment>? attachments,
  }) {
    return GroupMessage(
      id: id ?? this.id,
      cursor: cursor ?? this.cursor,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      timeLabel: timeLabel ?? this.timeLabel,
      messageType: messageType ?? this.messageType,
      cardType: cardType ?? this.cardType,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      planId: planId ?? this.planId,
      voteId: voteId ?? this.voteId,
      settlementId: settlementId ?? this.settlementId,
      isMine: isMine ?? this.isMine,
      sendStatus: sendStatus ?? this.sendStatus,
      senderProfileImageUrl:
          senderProfileImageUrl ?? this.senderProfileImageUrl,
      senderCharacter: senderCharacter ?? this.senderCharacter,
      attachments: attachments ?? this.attachments,
    );
  }
}

class GroupMessageAttachment {
  const GroupMessageAttachment({
    required this.type,
    required this.publicUrl,
    required this.storageKey,
    this.contentType = '',
    this.fileName = '',
    this.width,
    this.height,
  });

  final String type;
  final String publicUrl;
  final String storageKey;
  final String contentType;
  final String fileName;
  final int? width;
  final int? height;

  Map<String, Object?> toApiJson() {
    return {
      'type': type,
      'storageKey': storageKey,
      'publicUrl': publicUrl,
      'contentType': contentType.isEmpty ? null : contentType,
      'fileName': fileName.isEmpty ? null : fileName,
      'width': width,
      'height': height,
    };
  }
}

class GroupMessagePage {
  const GroupMessagePage({
    required this.messages,
    this.nextCursor,
    this.hasMore = false,
    this.unreadCount = 0,
  });

  final List<GroupMessage> messages;
  final String? nextCursor;
  final bool hasMore;
  final int unreadCount;
}

class GroupMemoryRecord {
  const GroupMemoryRecord({
    required this.id,
    required this.author,
    required this.title,
    required this.description,
    required this.dateLabel,
    required this.tags,
    this.apiId = '',
    this.imageUrls = const [],
    this.authorProfileImageUrl = '',
  });

  final int id;
  final String apiId;
  final String author;
  final String title;
  final String description;
  final String dateLabel;
  final List<String> tags;
  final List<String> imageUrls;
  final String authorProfileImageUrl;

  String get routeId => apiId.isEmpty ? id.toString() : apiId;

  String? get primaryImageUrl => imageUrls.isEmpty ? null : imageUrls.first;
}

class VoteCard {
  const VoteCard({
    required this.title,
    required this.summary,
    required this.statusLabel,
    required this.actionLabel,
    this.participantCount = 0,
    this.targetType = '',
    this.targetId = '',
    this.options = const [],
    this.myOptionId = '',
    this.deadlineAt,
  });

  final String title;
  final String summary;
  final String statusLabel;
  final String actionLabel;
  final int participantCount;
  final String targetType;
  final String targetId;
  final List<VoteOptionSummary> options;
  final String myOptionId;
  final DateTime? deadlineAt;

  String get participantCountLabel => '$participantCount명 참여';

  bool get joinedByMe {
    if (myOptionId.trim().isNotEmpty) {
      return true;
    }
    return options.any((option) => option.selectedByMe);
  }

  String get displayStatusLabel {
    if (isClosedAt(DateTime.now())) {
      return '마감';
    }
    final trimmed = statusLabel.trim();
    final normalized = trimmed.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    return switch (normalized) {
      'open' || 'opened' || 'ongoing' || 'active' || 'inprogress' => '진행 중',
      'closed' || 'close' || 'completed' || 'complete' || 'done' => '마감',
      _ => trimmed.isEmpty ? '확인 필요' : trimmed,
    };
  }

  bool isClosedAt(DateTime now) {
    final normalized = statusLabel.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]'),
      '',
    );
    if (normalized == 'closed' ||
        normalized == 'close' ||
        normalized == 'completed' ||
        normalized == 'complete' ||
        normalized == 'done') {
      return true;
    }
    final deadline = deadlineAt?.toLocal();
    return deadline != null && !now.toLocal().isBefore(deadline);
  }
}

class GroupMemberProfile {
  const GroupMemberProfile({
    this.userId = '',
    required this.name,
    required this.note,
    required this.statusLabel,
    this.invited = false,
    this.profileImageUrl = '',
    this.character,
    this.preferenceProfile,
  });

  final String userId;
  final String name;
  final String note;
  final String statusLabel;
  final bool invited;
  final String profileImageUrl;
  final CharacterDraft? character;
  final PreferenceProfile? preferenceProfile;
}

class GroupCreateInput {
  GroupCreateInput({
    required this.name,
    required this.description,
    required this.memberNames,
  });

  final String name;
  final String description;
  final List<String> memberNames;
}
