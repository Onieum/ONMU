class VoteSummary {
  VoteSummary({
    required this.id,
    required this.title,
    required this.statusLabel,
    required this.description,
    required this.planLabel,
    required this.planMeta,
    required this.participants,
    required this.options,
    required this.closed,
    required this.joinedByMe,
    required this.actionLabel,
  });

  final int id;
  final String title;
  final String statusLabel;
  final String description;
  final String planLabel;
  final String planMeta;
  final List<String> participants;
  final List<VoteOptionSummary> options;
  final bool closed;
  final bool joinedByMe;
  final String actionLabel;
}

class VoteOptionSummary {
  VoteOptionSummary({
    required this.label,
    required this.countLabel,
    required this.progress,
  });

  final String label;
  final String countLabel;
  final double progress;
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
  });

  final Object groupId;
  final Object planId;
  final String title;
  final String modeLabel;
  final String deadlineDate;
  final String deadlineTime;
  final List<String> candidateNames;
}
