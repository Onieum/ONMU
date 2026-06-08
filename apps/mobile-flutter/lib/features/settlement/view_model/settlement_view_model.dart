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

class SettlementViewModel extends AsyncNotifier<SettlementSummary> {
  SettlementViewModel(this.scope);

  final SettlementScope scope;

  @override
  Future<SettlementSummary> build() {
    return ref
        .watch(settlementRepositoryProvider)
        .fetchSettlement(groupId: scope.groupId, planId: scope.planId);
  }
}
