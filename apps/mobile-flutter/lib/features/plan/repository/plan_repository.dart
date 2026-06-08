import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/plan_models.dart';
import '../../../shared/repository/in_memory_onmu_store.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  if (ref.watch(onmuApiEnabledProvider)) {
    return ApiPlanRepository(ref.watch(onmuApiClientProvider));
  }
  return MockPlanRepository(ref.watch(inMemoryOnmuStoreProvider));
});

abstract interface class PlanRepository {
  Future<Plan> fetchPlan({required Object groupId, required Object planId});

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

class MockPlanRepository implements PlanRepository {
  MockPlanRepository(this._store);

  final InMemoryOnmuStore _store;

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchPlan(groupId: groupId, planId: planId);
  }

  @override
  Future<Plan> createPlan(PlanCreateInput input) async {
    return _store.createPlan(input);
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) async {
    return _store.updatePlan(planId: planId, input: input);
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchVisitPlansByDate(groupId: groupId, planId: planId);
  }
}

class ApiPlanRepository implements PlanRepository {
  ApiPlanRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    final plan = await _client.getObject('/api/v1/groups/$groupId/plans/$planId');
    return _plan(plan);
  }

  @override
  Future<Plan> createPlan(PlanCreateInput input) async {
    final plan = await _client.postObject(
      '/api/v1/groups/${input.groupId}/plans',
      body: {
        'title': input.title,
        'startsAt': _startsAtOrNull(input.dateTime),
      },
    );
    return _plan(plan);
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) async {
    return fetchPlan(groupId: input.groupId, planId: planId);
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async {
    return const [];
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
      memo: OnmuJson.readString(json, 'memo', 'Spring API에서 불러온 약속입니다.'),
      members: const [
        PlanMember(
          name: 'ONMU Dev User',
          message: 'Spring API smoke 참여자',
          badge: '참여 중',
          selected: true,
        ),
      ],
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
