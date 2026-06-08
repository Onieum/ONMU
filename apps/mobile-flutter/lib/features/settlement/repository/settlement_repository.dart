import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/settlement_models.dart';
import '../../../shared/repository/in_memory_onmu_store.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  if (ref.watch(onmuApiEnabledProvider)) {
    return ApiSettlementRepository(ref.watch(onmuApiClientProvider));
  }
  return MockSettlementRepository(ref.watch(inMemoryOnmuStoreProvider));
});

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

class ApiSettlementRepository implements SettlementRepository {
  ApiSettlementRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) async {
    final settlement = await _client.getObject(
      '/api/v1/groups/$groupId/plans/$planId/settlements',
    );
    return _settlement(settlement);
  }

  SettlementSummary _settlement(Map<String, dynamic> json) {
    return SettlementSummary(
      id: OnmuJson.readInt(json, 'id'),
      planTitle: OnmuJson.readString(json, 'planTitle', '약속 정산'),
      totalAmountLabel: OnmuJson.readString(json, 'totalAmountLabel', '0원'),
      createdDateLabel: OnmuJson.readString(json, 'createdDateLabel', '미리보기'),
      itemCountLabel: OnmuJson.readString(json, 'itemCountLabel', '결제 항목 0개'),
      finalSummaryLabel: OnmuJson.readString(json, 'finalSummaryLabel', '정산 준비 중'),
      mySummaryLabel: OnmuJson.readString(json, 'mySummaryLabel', '내 정산 없음'),
      paymentItems: OnmuJson.asMapList(json['paymentItems'])
          .map(_paymentItem)
          .toList(growable: false),
      memberResults: OnmuJson.asMapList(json['memberResults'])
          .map(_memberResult)
          .toList(growable: false),
      transfers: OnmuJson.asMapList(json['transfers'])
          .map(_transfer)
          .toList(growable: false),
      shareMessage: OnmuJson.readString(json, 'shareMessage', '약속 정산입니다.'),
    );
  }

  SettlementPaymentItem _paymentItem(Map<String, dynamic> json) {
    final splitType = OnmuJson.readString(json, 'splitType', 'equal');
    return SettlementPaymentItem(
      id: OnmuJson.readInt(json, 'id'),
      title: OnmuJson.readString(json, 'title', '결제 항목'),
      amountLabel: OnmuJson.readString(json, 'amountLabel', '0원'),
      payerShares: OnmuJson.asMapList(json['payerShares'])
          .map(
            (payer) => SettlementPayerShare(
              name: OnmuJson.readString(payer, 'name', '결제자'),
              amountLabel: OnmuJson.readString(payer, 'amountLabel', '0원'),
            ),
          )
          .toList(growable: false),
      targetLabel: OnmuJson.readString(json, 'targetLabel', '0명'),
      splitType: splitType == 'custom'
          ? SettlementSplitType.custom
          : SettlementSplitType.equal,
      participants: OnmuJson.asMapList(json['participants'])
          .map(
            (participant) => SettlementPaymentParticipant(
              name: OnmuJson.readString(participant, 'name', '참여자'),
              owedAmountLabel: OnmuJson.readString(
                participant,
                'owedAmountLabel',
                '0원',
              ),
              included: OnmuJson.readBool(participant, 'included', true),
            ),
          )
          .toList(growable: false),
    );
  }

  SettlementMemberResult _memberResult(Map<String, dynamic> json) {
    return SettlementMemberResult(
      name: OnmuJson.readString(json, 'name', '참여자'),
      finalShareLabel: OnmuJson.readString(json, 'finalShareLabel', '0원'),
      paidAmountLabel: OnmuJson.readString(json, 'paidAmountLabel', '0원'),
      resultLabel: OnmuJson.readString(json, 'resultLabel', '정산 없음'),
      isMe: OnmuJson.readBool(json, 'isMe'),
      willReceive: OnmuJson.readBool(json, 'willReceive'),
    );
  }

  SettlementTransferSummary _transfer(Map<String, dynamic> json) {
    return SettlementTransferSummary(
      fromName: OnmuJson.readString(json, 'fromName', '보내는 사람'),
      toName: OnmuJson.readString(json, 'toName', '받는 사람'),
      amountLabel: OnmuJson.readString(json, 'amountLabel', '0원'),
    );
  }
}
