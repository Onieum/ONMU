import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/settlement_models.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>(
  (ref) => const MockSettlementRepository(),
);

abstract interface class SettlementRepository {
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  });
}

class MockSettlementRepository implements SettlementRepository {
  const MockSettlementRepository();

  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) async {
    return mockSettlementSummary;
  }
}
