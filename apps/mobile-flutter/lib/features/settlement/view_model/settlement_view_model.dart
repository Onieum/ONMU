import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/settlement_models.dart';
import '../repository/settlement_repository.dart';

typedef SettlementScope = ({String groupId, String planId});
typedef SettlementDetailScope = ({
  String groupId,
  String planId,
  String settlementId,
});

final settlementViewModelProvider =
    AsyncNotifierProvider.family<
      SettlementViewModel,
      SettlementSummary,
      SettlementScope
    >(SettlementViewModel.new);

final settlementDraftViewModelProvider =
    AsyncNotifierProvider.family<
      SettlementDraftViewModel,
      SettlementSummary,
      SettlementScope
    >(SettlementDraftViewModel.new);

final settlementByIdViewModelProvider =
    AsyncNotifierProvider.family<
      SettlementByIdViewModel,
      SettlementSummary,
      SettlementDetailScope
    >(SettlementByIdViewModel.new);

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

class SettlementDraftViewModel extends AsyncNotifier<SettlementSummary> {
  SettlementDraftViewModel(this.scope);

  final SettlementScope scope;

  @override
  Future<SettlementSummary> build() {
    return ref
        .watch(settlementRepositoryProvider)
        .fetchSettlementDraft(groupId: scope.groupId, planId: scope.planId);
  }

  Future<void> addDraftItem(SettlementDraftItemInput input) async {
    final previous = await future;
    final items = [..._inputsFrom(previous), input];
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(settlementRepositoryProvider)
          .updateSettlementDraft(
            groupId: scope.groupId,
            planId: scope.planId,
            items: items,
            memo: 'Flutter settlement draft',
          ),
    );
  }

  Future<void> updateDraftItemTargets({
    required Object itemId,
    required List<String> targetUserIds,
    required List<String> targetNames,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(settlementRepositoryProvider)
          .updateSettlementDraftItemTargets(
            groupId: scope.groupId,
            planId: scope.planId,
            itemId: itemId,
            targetUserIds: targetUserIds,
            targetNames: targetNames,
          ),
    );
  }

  Future<SettlementSummary> previewCurrentDraft() async {
    final draft = await future;
    return ref
        .read(settlementRepositoryProvider)
        .previewSettlement(
          groupId: scope.groupId,
          planId: scope.planId,
          items: _inputsFrom(draft),
        );
  }

  Future<SettlementSummary> createCurrentDraft() async {
    final draft = await future;
    final created = await ref
        .read(settlementRepositoryProvider)
        .createSettlement(
          groupId: scope.groupId,
          planId: scope.planId,
          items: _inputsFrom(draft),
        );
    state = AsyncData(created);
    ref.invalidate(settlementViewModelProvider(scope));
    return created;
  }

  List<SettlementDraftItemInput> _inputsFrom(SettlementSummary settlement) {
    return settlement.paymentItems
        .map(
          (item) => SettlementDraftItemInput(
            id: item.id,
            title: item.title,
            amount: item.amount,
            payerUserId: item.payerShares.isEmpty
                ? null
                : item.payerShares.first.userId,
            payerName: item.payerShares.isEmpty
                ? '결제자'
                : item.payerShares.first.name,
            splitType: item.splitType,
            targetUserIds: item.includedParticipants
                .map((participant) => participant.userId)
                .where((userId) => userId.isNotEmpty)
                .toList(growable: false),
            targetNames: item.includedParticipants
                .map((participant) => participant.name)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }
}

class SettlementByIdViewModel extends AsyncNotifier<SettlementSummary> {
  SettlementByIdViewModel(this.scope);

  final SettlementDetailScope scope;

  @override
  Future<SettlementSummary> build() {
    return ref
        .watch(settlementRepositoryProvider)
        .fetchSettlementById(
          groupId: scope.groupId,
          planId: scope.planId,
          settlementId: scope.settlementId,
        );
  }
}
