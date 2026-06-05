class PlanMember {
  const PlanMember({
    required this.name,
    required this.message,
    required this.badge,
    required this.selected,
  });

  final String name;
  final String message;
  final String badge;
  final bool selected;
}

class TimeCandidate {
  const TimeCandidate({
    required this.time,
    required this.range,
    required this.status,
    required this.description,
    required this.countLabel,
    required this.recommended,
  });

  final String time;
  final String range;
  final String status;
  final String description;
  final String countLabel;
  final bool recommended;
}

class VisitPlan {
  const VisitPlan({
    required this.time,
    required this.endTime,
    required this.place,
    required this.kind,
    required this.duration,
  });

  final String time;
  final String endTime;
  final String place;
  final String kind;
  final String duration;
}

class Plan {
  const Plan({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.status,
    required this.memo,
    required this.members,
    required this.timeCandidates,
    required this.visitPlan,
  });

  final int id;
  final String title;
  final String dateTime;
  final String location;
  final String status;
  final String memo;
  final List<PlanMember> members;
  final List<TimeCandidate> timeCandidates;
  final List<VisitPlan> visitPlan;
}

class PlanCreateInput {
  PlanCreateInput({
    required this.groupId,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.memo,
    required this.members,
  });

  final Object groupId;
  final String title;
  final String dateTime;
  final String location;
  final String memo;
  final List<PlanMember> members;
}
