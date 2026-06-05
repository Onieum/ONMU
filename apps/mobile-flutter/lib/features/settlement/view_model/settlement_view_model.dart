import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/settlement_models.dart';
import '../repository/settlement_repository.dart';

typedef SettlementScope = ({String groupId, String planId});

final settlementViewModelProvider =
    AsyncNotifierProvider.family<
      SettlementViewModel,
      SettlementSummary,
      SettlementScope
    >(SettlementViewModel.new);

class SettlementViewModel
    extends FamilyAsyncNotifier<SettlementSummary, SettlementScope> {
  @override
  Future<SettlementSummary> build(SettlementScope arg) {
    return ref
        .watch(settlementRepositoryProvider)
        .fetchSettlement(groupId: arg.groupId, planId: arg.planId);
  }
}
