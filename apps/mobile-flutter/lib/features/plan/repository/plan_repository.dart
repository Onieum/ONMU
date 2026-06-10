import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/plan_models.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return ApiPlanRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class PlanRepository {
  Future<Plan> fetchPlan({required Object groupId, required Object planId});

  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  });

  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  });

  Future<Plan> createPlan(PlanCreateInput input);

  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  });

  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  });
}

class ApiPlanRepository implements PlanRepository {
  ApiPlanRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    final plan = await _client.getObject(
      '/api/v1/groups/$groupId/plans/$planId',
    );
    return _plan(plan);
  }

  @override
  Future<Plan> createPlan(PlanCreateInput input) async {
    final plan = await _client.postObject(
      '/api/v1/groups/${input.groupId}/plans',
      body: {'title': input.title, 'startsAt': _startsAtOrNull(input.dateTime)},
    );
    return _plan(plan);
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) async {
    final plan = await _client.patchObject(
      '/api/v1/groups/${input.groupId}/plans/$planId',
      body: {
        'title': input.title.trim(),
        'startsAt': _startsAtOrNull(input.dateTime),
        'status': 'draft',
      },
    );
    return _plan(plan);
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async {
    return const [];
  }

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async {
    final participants = await _client.getList(
      '/api/v1/groups/$groupId/plans/$planId/participants',
    );
    return participants.map(_participantArrival).toList(growable: false);
  }

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) async {
    final participant = await _client.patchObject(
      '/api/v1/groups/$groupId/plans/$planId/participants/me',
      body: {'status': 'joined', 'response': status.apiValue},
    );
    return _participantArrival(participant);
  }

  Plan _plan(Map<String, dynamic> json) {
    final title = OnmuJson.readString(json, 'title', '약속');
    final location = OnmuJson.readString(json, 'placeName', '장소 미정');
    return Plan(
      id: OnmuJson.readInt(json, 'id'),
      title: title,
      dateTime: OnmuJson.readString(json, 'dateLabel', '일정 미정'),
      location: location,
      status: OnmuJson.readString(json, 'status', '예정'),
      memo: OnmuJson.readString(json, 'memo'),
      members: const [],
      timeCandidates: const [],
      visitPlan: [
        VisitPlan(
          time: '미정',
          endTime: '',
          place: location,
          kind: '장소',
          duration: title,
        ),
      ],
      startsAt: DateTime.tryParse(OnmuJson.readString(json, 'startsAt')),
      endsAt: DateTime.tryParse(OnmuJson.readString(json, 'endsAt')),
    );
  }

  PlanParticipantArrival _participantArrival(Map<String, dynamic> json) {
    return PlanParticipantArrival(
      id: OnmuJson.readString(json, 'id'),
      displayName: OnmuJson.readString(json, 'displayName', '참여자'),
      participantStatus: OnmuJson.readString(json, 'status', 'joined'),
      arrivalStatus: PlanArrivalStatus.fromApi(
        OnmuJson.readString(json, 'response'),
      ),
      isFallback: OnmuJson.readBool(json, 'fallback'),
    );
  }

  String? _startsAtOrNull(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return DateTime.tryParse(trimmed)?.toUtc().toIso8601String();
  }
}
