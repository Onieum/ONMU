import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/settlement_models.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return ApiSettlementRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class SettlementRepository {
  Future<SettlementSummary> fetchSettlementDraft({
    required Object groupId,
    required Object planId,
  });

  Future<SettlementSummary> updateSettlementDraft({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
    String? memo,
  });

  Future<SettlementSummary> updateSettlementDraftItemTargets({
    required Object groupId,
    required Object planId,
    required Object itemId,
    required List<String> targetUserIds,
    required List<String> targetNames,
  });

  Future<SettlementSummary> previewSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  });

  Future<SettlementSummary> createSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  });

  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  });

  Future<SettlementSummary> fetchSettlementById({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  });
}

class SettlementDraftItemInput {
  const SettlementDraftItemInput({
    this.id,
    required this.title,
    required this.amount,
    this.payerUserId,
    required this.payerName,
    this.splitType = SettlementSplitType.equal,
    this.targetUserIds = const [],
    required this.targetNames,
  });

  final Object? id;
  final String title;
  final int amount;
  final String? payerUserId;
  final String payerName;
  final SettlementSplitType splitType;
  final List<String> targetUserIds;
  final List<String> targetNames;

  Map<String, Object?> toJson() {
    return {
      if (id != null) 'id': id.toString(),
      'title': title,
      'amount': amount,
      'amountWon': amount,
      if (payerUserId != null && payerUserId!.isNotEmpty)
        'payerUserId': payerUserId,
      'payerName': payerName,
      'splitType': splitType == SettlementSplitType.custom ? 'custom' : 'equal',
      if (targetUserIds.isNotEmpty) 'targetUserIds': targetUserIds,
      'targetNames': targetNames,
    };
  }
}

class ApiSettlementRepository implements SettlementRepository {
  ApiSettlementRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<SettlementSummary> fetchSettlementDraft({
    required Object groupId,
    required Object planId,
  }) async {
    final draft = await _client.getObject(
      '/api/v1/groups/$groupId/plans/$planId/settlement-draft',
    );
    return _settlement(OnmuJson.asMap(draft['preview']));
  }

  @override
  Future<SettlementSummary> updateSettlementDraft({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
    String? memo,
  }) async {
    final draft = await _client.patchObject(
      '/api/v1/groups/$groupId/plans/$planId/settlement-draft',
      body: {
        ..._itemsBody(items),
        if (memo != null && memo.trim().isNotEmpty) 'memo': memo.trim(),
      },
    );
    return _settlement(OnmuJson.asMap(draft['preview']));
  }

  @override
  Future<SettlementSummary> updateSettlementDraftItemTargets({
    required Object groupId,
    required Object planId,
    required Object itemId,
    required List<String> targetUserIds,
    required List<String> targetNames,
  }) async {
    final draft = await _client.patchObject(
      '/api/v1/groups/$groupId/plans/$planId/settlement-draft/items/$itemId/targets',
      body: {
        if (targetUserIds.isNotEmpty) 'targetUserIds': targetUserIds,
        'targetNames': targetNames,
      },
    );
    return _settlement(OnmuJson.asMap(draft['preview']));
  }

  @override
  Future<SettlementSummary> previewSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) async {
    final settlement = await _client.postObject(
      '/api/v1/groups/$groupId/plans/$planId/settlements/preview',
      body: _itemsBody(items),
    );
    return _settlement(settlement);
  }

  @override
  Future<SettlementSummary> createSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) async {
    final settlement = await _client.postObject(
      '/api/v1/groups/$groupId/plans/$planId/settlements',
      body: _itemsBody(items),
    );
    return _settlement(settlement);
  }

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

  @override
  Future<SettlementSummary> fetchSettlementById({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  }) async {
    final settlement = await _client.getObject(
      '/api/v1/groups/$groupId/plans/$planId/settlements/$settlementId',
    );
    return _settlement(settlement);
  }

  Map<String, Object?> _itemsBody(List<SettlementDraftItemInput> items) {
    return {'items': items.map((item) => item.toJson()).toList()};
  }

  SettlementSummary _settlement(Map<String, dynamic> json) {
    return SettlementSummary(
      id: _readId(json, 'id'),
      planTitle: OnmuJson.readString(json, 'planTitle', '약속 정산'),
      totalAmountLabel: OnmuJson.readString(json, 'totalAmountLabel', '0원'),
      createdDateLabel: OnmuJson.readString(json, 'createdDateLabel', '미리보기'),
      itemCountLabel: OnmuJson.readString(json, 'itemCountLabel', '결제 항목 0개'),
      finalSummaryLabel: OnmuJson.readString(json, 'finalSummaryLabel'),
      mySummaryLabel: OnmuJson.readString(json, 'mySummaryLabel', '내 정산 없음'),
      paymentItems: OnmuJson.asMapList(
        json['paymentItems'],
      ).map(_paymentItem).toList(growable: false),
      memberResults: OnmuJson.asMapList(
        json['memberResults'],
      ).map(_memberResult).toList(growable: false),
      transfers: OnmuJson.asMapList(
        json['transfers'],
      ).map(_transfer).toList(growable: false),
      shareMessage: OnmuJson.readString(json, 'shareMessage', '약속 정산입니다.'),
    );
  }

  SettlementPaymentItem _paymentItem(Map<String, dynamic> json) {
    final splitType = OnmuJson.readString(json, 'splitType', 'equal');
    return SettlementPaymentItem(
      id: _readId(json, 'id'),
      title: OnmuJson.readString(json, 'title', '결제 항목'),
      amount: OnmuJson.readInt(
        json,
        'amountWon',
        OnmuJson.readInt(json, 'amount'),
      ),
      amountLabel: OnmuJson.readString(json, 'amountLabel', '0원'),
      payerShares: OnmuJson.asMapList(json['payerShares'])
          .map(
            (payer) => SettlementPayerShare(
              userId: OnmuJson.readString(payer, 'userId'),
              name: OnmuJson.readString(payer, 'name', '결제자'),
              amountLabel: OnmuJson.readString(payer, 'amountLabel', '0원'),
              profileImageUrl: _profileImageUrl(payer),
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
              userId: OnmuJson.readString(participant, 'userId'),
              name: OnmuJson.readString(participant, 'name', '참여자'),
              owedAmountLabel: OnmuJson.readString(
                participant,
                'owedAmountLabel',
                '0원',
              ),
              included: OnmuJson.readBool(participant, 'included', true),
              profileImageUrl: _profileImageUrl(participant),
            ),
          )
          .toList(growable: false),
    );
  }

  String _readId(Map<String, dynamic> json, String key) {
    final value = OnmuJson.readString(json, key);
    if (value.isNotEmpty) {
      return value;
    }
    return OnmuJson.readInt(json, key).toString();
  }

  SettlementMemberResult _memberResult(Map<String, dynamic> json) {
    return SettlementMemberResult(
      name: OnmuJson.readString(json, 'name', '참여자'),
      finalShareLabel: OnmuJson.readString(json, 'finalShareLabel', '0원'),
      paidAmountLabel: OnmuJson.readString(json, 'paidAmountLabel', '0원'),
      resultLabel: OnmuJson.readString(json, 'resultLabel', '정산 없음'),
      isMe: OnmuJson.readBool(json, 'isMe'),
      willReceive: OnmuJson.readBool(json, 'willReceive'),
      profileImageUrl: _profileImageUrl(json),
    );
  }

  SettlementTransferSummary _transfer(Map<String, dynamic> json) {
    return SettlementTransferSummary(
      fromName: OnmuJson.readString(json, 'fromName', '보내는 사람'),
      toName: OnmuJson.readString(json, 'toName', '받는 사람'),
      amountLabel: OnmuJson.readString(json, 'amountLabel', '0원'),
      fromProfileImageUrl: _profileImageUrl(json, 'fromProfileImageUrl'),
      toProfileImageUrl: _profileImageUrl(json, 'toProfileImageUrl'),
    );
  }

  String _profileImageUrl(
    Map<String, dynamic> json, [
    String primaryKey = 'profileImageUrl',
  ]) {
    return OnmuJson.readString(
      json,
      primaryKey,
      OnmuJson.readString(
        json,
        'profileImageUrl',
        OnmuJson.readString(
          json,
          'profilePhotoUrl',
          OnmuJson.readString(json, 'avatarUrl'),
        ),
      ),
    );
  }
}
