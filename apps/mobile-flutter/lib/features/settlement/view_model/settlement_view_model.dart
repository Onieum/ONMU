import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/observability/onmu_error_reporter.dart';
import '../../../shared/models/group_models.dart';
import '../../../shared/models/plan_models.dart';
import '../../../shared/models/settlement_models.dart';
import '../../plan/repository/plan_repository.dart';
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

final settlementDraftParticipantsProvider =
    FutureProvider.family<List<GroupMemberProfile>, SettlementScope>((
      ref,
      scope,
    ) async {
      final participants = await ref
          .watch(planRepositoryProvider)
          .fetchPlanParticipants(groupId: scope.groupId, planId: scope.planId);
      return participants
          .where(_isActiveSettlementParticipant)
          .map(_groupMemberFromParticipant)
          .toList(growable: false);
    });

bool _isActiveSettlementParticipant(PlanParticipantArrival participant) {
  if (participant.isFallback || participant.userId.trim().isEmpty) {
    return false;
  }
  final status = participant.participantStatus.trim().toLowerCase();
  return status != 'left' && status != 'declined';
}

GroupMemberProfile _groupMemberFromParticipant(
  PlanParticipantArrival participant,
) {
  return GroupMemberProfile(
    userId: participant.userId,
    name: participant.nickname,
    note: '',
    statusLabel: '참여 중',
    profileImageUrl: participant.profileImageUrl,
    character: participant.character,
    preferenceProfile: participant.preferenceProfile,
  );
}

class SettlementViewModel extends AsyncNotifier<SettlementSummary> {
  SettlementViewModel(this.scope);

  final SettlementScope scope;

  @override
  Future<SettlementSummary> build() async {
    try {
      return await ref
          .watch(settlementRepositoryProvider)
          .fetchSettlement(groupId: scope.groupId, planId: scope.planId);
    } catch (error, stackTrace) {
      _reportSettlementError(ref, error, stackTrace, 'settlement_load');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class SettlementDraftViewModel extends AsyncNotifier<SettlementSummary> {
  SettlementDraftViewModel(this.scope);

  final SettlementScope scope;

  @override
  Future<SettlementSummary> build() async {
    try {
      return await ref
          .watch(settlementRepositoryProvider)
          .fetchSettlementDraft(groupId: scope.groupId, planId: scope.planId);
    } catch (error, stackTrace) {
      _reportSettlementError(ref, error, stackTrace, 'settlement_draft_load');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> addDraftItem(SettlementDraftItemInput input) async {
    final previous = await future;
    final sections = _sectionInputsFrom(previous, appendedItem: input);
    try {
      final updated = await ref
          .read(settlementRepositoryProvider)
          .updateSettlementDraftSections(
            groupId: scope.groupId,
            planId: scope.planId,
            sections: sections,
            memo: 'Flutter settlement draft',
          );
      state = AsyncData(updated);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      _reportSettlementError(ref, error, stackTrace, 'settlement_draft_save');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updateDraftItemTargets({
    required Object itemId,
    required List<String> targetUserIds,
  }) async {
    final previous = await future;
    try {
      final updated = await ref
          .read(settlementRepositoryProvider)
          .updateSettlementDraftItemTargets(
            groupId: scope.groupId,
            planId: scope.planId,
            itemId: itemId,
            targetUserIds: targetUserIds,
          );
      state = AsyncData(updated);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      _reportSettlementError(ref, error, stackTrace, 'settlement_draft_save');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updateSectionPayer({
    required Object sectionId,
    required String payerUserId,
  }) async {
    final previous = await future;
    final normalizedSectionId = sectionId.toString().trim();
    final normalizedPayerUserId = payerUserId.trim();
    if (normalizedSectionId.isEmpty || normalizedPayerUserId.isEmpty) {
      return;
    }

    final sections = _sectionInputsFrom(previous)
        .map((section) {
          if (section.id.toString() != normalizedSectionId) {
            return section;
          }
          return SettlementDraftSectionInput(
            id: section.id,
            schedulePlaceId: section.schedulePlaceId,
            title: section.title,
            payerUserId: normalizedPayerUserId,
            items: section.items,
          );
        })
        .toList(growable: false);
    try {
      final updated = await ref
          .read(settlementRepositoryProvider)
          .updateSettlementDraftSections(
            groupId: scope.groupId,
            planId: scope.planId,
            sections: sections,
            memo: 'Flutter settlement draft',
          );
      state = AsyncData(updated);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      _reportSettlementError(ref, error, stackTrace, 'settlement_draft_save');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<SettlementSummary> previewCurrentDraft() async {
    final draft = await future;
    try {
      return await ref
          .read(settlementRepositoryProvider)
          .previewSettlement(
            groupId: scope.groupId,
            planId: scope.planId,
            items: _inputsFrom(draft),
          );
    } catch (error, stackTrace) {
      _reportSettlementError(ref, error, stackTrace, 'settlement_preview');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<SettlementSummary> createCurrentDraft() async {
    final draft = await future;
    try {
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
    } catch (error, stackTrace) {
      _reportSettlementError(ref, error, stackTrace, 'settlement_finalize');
      Error.throwWithStackTrace(error, stackTrace);
    }
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

    final appendedSectionId = appendedItem.sectionId?.toString().trim();
    if (appendedSectionId != null && appendedSectionId.isNotEmpty) {
      for (var index = 0; index < sections.length; index++) {
        final section = sections[index];
        if (section.id.toString() != appendedSectionId) {
          continue;
        }
        sections[index] = SettlementDraftSectionInput(
          id: section.id,
          schedulePlaceId: section.schedulePlaceId,
          title: section.title,
          payerUserId: appendedItem.payerUserId?.trim().isNotEmpty == true
              ? appendedItem.payerUserId!.trim()
              : section.payerUserId,
          items: [...section.items, appendedItem],
        );
        return sections;
      }
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
  Future<SettlementSummary> build() async {
    try {
      return await ref
          .watch(settlementRepositoryProvider)
          .fetchSettlementById(
            groupId: scope.groupId,
            planId: scope.planId,
            settlementId: scope.settlementId,
          );
    } catch (error, stackTrace) {
      _reportSettlementError(ref, error, stackTrace, 'settlement_detail_load');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> markTransferSent(String transferId) async {
    final previous = await future;
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await ref
            .read(settlementRepositoryProvider)
            .markTransferSent(
              groupId: scope.groupId,
              planId: scope.planId,
              settlementId: scope.settlementId,
              transferId: transferId,
            ),
      );
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      _reportSettlementError(
        ref,
        error,
        stackTrace,
        'settlement_transfer_sent',
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> markTransferReceived(String transferId) async {
    final previous = await future;
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await ref
            .read(settlementRepositoryProvider)
            .markTransferReceived(
              groupId: scope.groupId,
              planId: scope.planId,
              settlementId: scope.settlementId,
              transferId: transferId,
            ),
      );
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      _reportSettlementError(
        ref,
        error,
        stackTrace,
        'settlement_transfer_received',
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class SettlementBasisViewModel extends AsyncNotifier<SettlementBasis> {
  SettlementBasisViewModel(this.scope);

  final SettlementBasisScope scope;

  @override
  Future<SettlementBasis> build() async {
    try {
      return await ref
          .watch(settlementRepositoryProvider)
          .fetchSettlementBasis(
            groupId: scope.groupId,
            planId: scope.planId,
            settlementId: scope.settlementId,
          );
    } catch (error, stackTrace) {
      _reportSettlementError(ref, error, stackTrace, 'settlement_basis_load');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

void _reportSettlementError(
  Ref ref,
  Object error,
  StackTrace stackTrace,
  String feature,
) {
  ref
      .read(onmuErrorReporterProvider)
      .captureException(error, stackTrace, feature: feature);
}
