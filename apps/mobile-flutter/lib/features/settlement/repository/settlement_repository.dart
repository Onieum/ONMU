import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/settlement_models.dart';
import '../../../shared/repository/in_memory_onmu_store.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>(
  (ref) => MockSettlementRepository(ref.watch(inMemoryOnmuStoreProvider)),
);

abstract interface class SettlementRepository {
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  });
}

class MockSettlementRepository implements SettlementRepository {
  MockSettlementRepository(this._store);

  final InMemoryOnmuStore _store;

  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchSettlement(groupId: groupId, planId: planId);
  }
}
