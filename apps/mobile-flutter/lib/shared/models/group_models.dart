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
  });

  final int id;
  final String title;
  final String dateLabel;
  final String placeName;
  final String statusLabel;
  final String statusType;
  final int memberCount;
  final int extraMemberCount;
  final String iconKind;
  final bool isPast;
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
