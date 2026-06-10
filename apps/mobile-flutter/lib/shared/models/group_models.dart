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
  });

  final int id;
  final String title;
  final String dateLabel;
  final DateTime? startsAt;
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

    final hour = startsAtLocal.hour.toString().padLeft(2, '0');
    final minute = startsAtLocal.minute.toString().padLeft(2, '0');
    return '${startsAtLocal.month}월 ${startsAtLocal.day}일 $hour:$minute';
  }

  bool isUpcomingFrom(DateTime now) {
    final startsAtLocal = startsAt?.toLocal();
    return !isPast &&
        progressStatus.isUpcomingCandidate &&
        (startsAtLocal == null || !startsAtLocal.isBefore(now.toLocal()));
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

class GroupMessage {
  const GroupMessage({
    required this.sender,
    required this.message,
    required this.timeLabel,
    required this.isMine,
  });

  final String sender;
  final String message;
  final String timeLabel;
  final bool isMine;
}

class GroupMemoryRecord {
  const GroupMemoryRecord({
    required this.id,
    required this.author,
    required this.title,
    required this.description,
    required this.dateLabel,
    required this.tags,
  });

  final int id;
  final String author;
  final String title;
  final String description;
  final String dateLabel;
  final List<String> tags;
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
  });

  final String name;
  final String note;
  final String statusLabel;
  final bool invited;
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
