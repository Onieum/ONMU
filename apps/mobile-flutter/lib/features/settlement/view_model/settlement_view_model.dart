import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/settlement_models.dart';
import '../repository/settlement_repository.dart';

typedef SettlementScope = ({String groupId, String planId});
typedef SettlementDetailScope = ({
  String groupId,
  String planId,
  String settlementId,
});
typedef SettlementBasisScope = ({
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

final settlementBasisViewModelProvider =
    AsyncNotifierProvider.family<
      SettlementBasisViewModel,
      SettlementBasis,
      SettlementBasisScope
    >(SettlementBasisViewModel.new);

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
    final sections = _sectionInputsFrom(previous, appendedItem: input);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(settlementRepositoryProvider)
          .updateSettlementDraftSections(
            groupId: scope.groupId,
            planId: scope.planId,
            sections: sections,
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
    final sectionsById = {
      for (final section in settlement.sections) section.id: section,
    };
    return settlement.paymentItems
        .map((item) {
          final section = sectionsById[item.sectionId];
          final payer = item.payerShares.isEmpty
              ? null
              : item.payerShares.first;
          return SettlementDraftItemInput(
            id: item.id,
            sectionId: item.sectionId.isEmpty ? section?.id : item.sectionId,
            sectionTitle: section?.title,
            schedulePlaceId: section?.schedulePlaceId,
            title: item.title,
            amount: item.amount,
            payerUserId: payer?.userId ?? section?.payerUserId,
            payerName: payer?.name ?? section?.payerName ?? '결제자',
            splitType: item.splitType,
            targetUserIds: item.includedParticipants
                .map((participant) => participant.userId)
                .where((userId) => userId.isNotEmpty)
                .toList(growable: false),
            targetNames: item.includedParticipants
                .map((participant) => participant.name)
                .toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  List<SettlementDraftSectionInput> _sectionInputsFrom(
    SettlementSummary settlement, {
    SettlementDraftItemInput? appendedItem,
  }) {
    final itemInputs = _inputsFrom(settlement);
    final itemsBySectionId = <String, List<SettlementDraftItemInput>>{};
    for (final item in itemInputs) {
      final sectionId = item.sectionId?.toString().trim();
      if (sectionId == null || sectionId.isEmpty) {
        continue;
      }
      itemsBySectionId.putIfAbsent(sectionId, () => []).add(item);
    }

    final sections = <SettlementDraftSectionInput>[];
    for (final section in settlement.sections) {
      sections.add(
        SettlementDraftSectionInput(
          id: section.id,
          schedulePlaceId: section.schedulePlaceId.isEmpty
              ? null
              : section.schedulePlaceId,
          title: section.title,
          payerUserId: section.payerUserId,
          items: List.of(itemsBySectionId[section.id] ?? const []),
        ),
      );
    }

    if (sections.isEmpty && itemInputs.isNotEmpty) {
      return [
        SettlementDraftSectionInput(
          id: 'extra',
          title: '기타 비용',
          payerUserId: itemInputs.first.payerUserId ?? '',
          items: itemInputs,
        ),
      ];
    }

    if (appendedItem == null) {
      return sections;
    }

    final appendedPayerId = appendedItem.payerUserId ?? '';
    for (var index = 0; index < sections.length; index++) {
      final section = sections[index];
      if (section.payerUserId == appendedPayerId) {
        sections[index] = SettlementDraftSectionInput(
          id: section.id,
          schedulePlaceId: section.schedulePlaceId,
          title: section.title,
          payerUserId: section.payerUserId,
          items: [...section.items, appendedItem],
        );
        return sections;
      }
    }

    sections.add(
      SettlementDraftSectionInput(
        id: 'extra-${appendedPayerId.isEmpty ? appendedItem.payerName : appendedPayerId}',
        title: '기타 비용',
        payerUserId: appendedPayerId,
        items: [appendedItem],
      ),
    );
    return sections;
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

  Future<void> markTransferSent(String transferId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(settlementRepositoryProvider)
          .markTransferSent(
            groupId: scope.groupId,
            planId: scope.planId,
            settlementId: scope.settlementId,
            transferId: transferId,
          ),
    );
  }

  Future<void> markTransferReceived(String transferId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(settlementRepositoryProvider)
          .markTransferReceived(
            groupId: scope.groupId,
            planId: scope.planId,
            settlementId: scope.settlementId,
            transferId: transferId,
          ),
    );
  }
}

class SettlementBasisViewModel extends AsyncNotifier<SettlementBasis> {
  SettlementBasisViewModel(this.scope);

  final SettlementBasisScope scope;

  @override
  Future<SettlementBasis> build() {
    return ref
        .watch(settlementRepositoryProvider)
        .fetchSettlementBasis(
          groupId: scope.groupId,
          planId: scope.planId,
          settlementId: scope.settlementId,
        );
  }
}
