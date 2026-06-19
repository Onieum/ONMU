class VoteSummary {
  VoteSummary({
    required this.id,
    required this.title,
    required this.statusLabel,
    required this.description,
    required this.planLabel,
    required this.planMeta,
    required this.participants,
    required this.participantCount,
    required this.options,
    required this.closed,
    required this.joinedByMe,
    required this.actionLabel,
    this.participantAvatars = const [],
    this.targetType = '',
    this.targetId = '',
  });

  final int id;
  final String title;
  final String statusLabel;
  final String description;
  final String planLabel;
  final String planMeta;
  final List<String> participants;
  final List<VoteParticipantAvatar> participantAvatars;
  final int participantCount;
  final List<VoteOptionSummary> options;
  final bool closed;
  final bool joinedByMe;
  final String actionLabel;
  final String targetType;
  final String targetId;

  String get participantCountLabel => '$participantCount명 참여';

  List<VoteParticipantAvatar> get displayParticipantAvatars {
    if (participantAvatars.isNotEmpty) {
      return participantAvatars;
    }
    return participants
        .map((name) => VoteParticipantAvatar(name: name))
        .toList(growable: false);
  }

  String get displayDescription {
    final trimmed = description.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return '등록된 투표 후보가 없어요';
  }
}

class VoteParticipantAvatar {
  const VoteParticipantAvatar({required this.name, this.profileImageUrl = ''});

  final String name;
  final String profileImageUrl;
}

class VoteOptionSummary {
  VoteOptionSummary({
    required this.label,
    required this.countLabel,
    required this.progress,
    this.id = '',
    this.targetType = '',
    this.targetId = '',
    this.candidateId = '',
    this.responseCount = 0,
    this.selectedByMe = false,
  });

  final String label;
  final String countLabel;
  final double progress;
  final String id;
  final String targetType;
  final String targetId;
  final String candidateId;
  final int responseCount;
  final bool selectedByMe;
}

class VoteCreateInput {
  VoteCreateInput({
    required this.groupId,
    required this.planId,
    required this.title,
    required this.modeLabel,
    required this.deadlineDate,
    required this.deadlineTime,
    required this.candidateNames,
    this.placeCandidateIds = const [],
  });

  final Object groupId;
  final Object planId;
  final String title;
  final String modeLabel;
  final String deadlineDate;
  final String deadlineTime;
  final List<String> candidateNames;
  final List<String> placeCandidateIds;
}
