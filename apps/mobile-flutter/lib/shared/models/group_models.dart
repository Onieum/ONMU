class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.lastMessage,
    required this.unreadCount,
    required this.pinnedPlanTitle,
  });

  final int id;
  final String name;
  final String description;
  final List<String> members;
  final String lastMessage;
  final int unreadCount;
  final String pinnedPlanTitle;
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

  String get displayStatusLabel => progressStatus.label;
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

  PlanProgressStatus get progressStatus {
    final source = statusType.trim().isNotEmpty ? statusType : statusLabel;
    return PlanProgressStatus.fromApi(source);
  }

  String get displayStatusLabel => progressStatus.label;

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
    final isToday =
        startsAtLocal.year == localNow.year &&
        startsAtLocal.month == localNow.month &&
        startsAtLocal.day == localNow.day;
    if (!isToday) {
      return false;
    }

    final endsAtLocal =
        endsAt?.toLocal() ?? startsAtLocal.add(const Duration(hours: 2));
    return localNow.isBefore(endsAtLocal);
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
}

enum PlanProgressStatus {
  draft('초안'),
  scheduled('예정'),
  active('진행 중'),
  completed('완료'),
  cancelled('취소됨'),
  unknown('확인 필요');

  const PlanProgressStatus(this.label);

  final String label;

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
      'draft' || '초안' => PlanProgressStatus.draft,
      'scheduled' ||
      'planned' ||
      'upcoming' ||
      '예정' => PlanProgressStatus.scheduled,
      'active' ||
      'ongoing' ||
      'inprogress' ||
      '진행중' => PlanProgressStatus.active,
      'completed' ||
      'complete' ||
      'done' ||
      '완료' => PlanProgressStatus.completed,
      'cancelled' ||
      'canceled' ||
      'cancel' ||
      '취소' ||
      '취소됨' => PlanProgressStatus.cancelled,
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

class GroupMessage {
  const GroupMessage({
    required this.sender,
    required this.message,
    required this.timeLabel,
    required this.isMine,
    this.id = '',
    this.cursor = '',
    this.sendStatus = GroupMessageSendStatus.sent,
    this.senderProfileImageUrl = '',
  });

  final String id;
  final String cursor;
  final String sender;
  final String message;
  final String timeLabel;
  final bool isMine;
  final GroupMessageSendStatus sendStatus;
  final String senderProfileImageUrl;

  bool get canRetry => isMine && sendStatus.isFailed;

  GroupMessage copyWith({
    String? id,
    String? cursor,
    String? sender,
    String? message,
    String? timeLabel,
    bool? isMine,
    GroupMessageSendStatus? sendStatus,
    String? senderProfileImageUrl,
  }) {
    return GroupMessage(
      id: id ?? this.id,
      cursor: cursor ?? this.cursor,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      timeLabel: timeLabel ?? this.timeLabel,
      isMine: isMine ?? this.isMine,
      sendStatus: sendStatus ?? this.sendStatus,
      senderProfileImageUrl:
          senderProfileImageUrl ?? this.senderProfileImageUrl,
    );
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
  });

  final String title;
  final String summary;
  final String statusLabel;
  final String actionLabel;
}

class GroupMemberProfile {
  const GroupMemberProfile({
    required this.name,
    required this.note,
    required this.statusLabel,
    this.invited = false,
    this.profileImageUrl = '',
  });

  final String name;
  final String note;
  final String statusLabel;
  final bool invited;
  final String profileImageUrl;
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
