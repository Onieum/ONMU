import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/plan_models.dart';
import '../../../shared/repository/in_memory_onmu_store.dart';

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => MockPlanRepository(ref.watch(inMemoryOnmuStoreProvider)),
);

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
