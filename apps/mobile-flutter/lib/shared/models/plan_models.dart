class PlanMember {
  const PlanMember({
    required this.name,
    required this.message,
    required this.badge,
    required this.selected,
    this.profileImageUrl = '',
  });

  final String name;
  final String message;
  final String badge;
  final bool selected;
  final String profileImageUrl;
}

enum PlanArrivalStatus {
  none('', '상태 없음'),
  departed('departed', '출발'),
  arrived('arrived', '도착'),
  late('late', '지각');

  const PlanArrivalStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PlanArrivalStatus fromApi(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]'),
      '',
    );
    return switch (normalized) {
      'departed' ||
      'departure' ||
      'left' ||
      'start' ||
      '출발' => PlanArrivalStatus.departed,
      'arrived' || 'arrival' || '도착' => PlanArrivalStatus.arrived,
      'late' || 'delayed' || '지각' => PlanArrivalStatus.late,
      _ => PlanArrivalStatus.none,
    };
  }
}

class PlanParticipantArrival {
  const PlanParticipantArrival({
    required this.id,
    this.userId = '',
    required this.displayName,
    required this.participantStatus,
    required this.arrivalStatus,
    required this.isFallback,
    this.profileImageUrl = '',
  });

  final String id;
  final String userId;
  final String displayName;
  final String participantStatus;
  final PlanArrivalStatus arrivalStatus;
  final bool isFallback;
  final String profileImageUrl;
}

extension PlanParticipantArrivalListX on Iterable<PlanParticipantArrival> {
  PlanParticipantArrival? activeParticipantFor(Set<String> userIds) {
    final normalizedUserIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (normalizedUserIds.isEmpty) {
      return null;
    }

    for (final participant in this) {
      if (participant.isFallback) {
        continue;
      }
      final status = participant.participantStatus.trim().toLowerCase();
      if (status == 'left' || status == 'declined') {
        continue;
      }
      if (normalizedUserIds.contains(participant.userId.trim())) {
        return participant;
      }
    }
    return null;
  }
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
    this.startsAt,
    this.endsAt,
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
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool isInProgressAt(DateTime now) {
    final start = startsAt?.toLocal() ?? DateTime.tryParse(dateTime)?.toLocal();
    if (start == null) {
      return false;
    }
    final end = (endsAt?.toLocal() ?? start.add(const Duration(hours: 2)));
    final localNow = now.toLocal();
    return !localNow.isBefore(start) && localNow.isBefore(end);
  }
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
