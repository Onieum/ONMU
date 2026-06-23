import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/settlement_models.dart';
import '../../../shared/utils/character_draft_json.dart';
import '../../../shared/utils/onmu_profile_image.dart';

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

  Future<SettlementSummary> updateSettlementDraftSections({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftSectionInput> sections,
    String? memo,
  });

  Future<SettlementSummary> updateSettlementDraftItemTargets({
    required Object groupId,
    required Object planId,
    required Object itemId,
    List<String> targetUserIds = const [],
    List<SettlementTargetShareInput> targetShares = const [],
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

  Future<SettlementBasis> fetchSettlementBasis({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  });

  Future<SettlementSummary> markTransferSent({
    required Object groupId,
    required Object planId,
    required Object settlementId,
    required Object transferId,
  });

  Future<SettlementSummary> markTransferReceived({
    required Object groupId,
    required Object planId,
    required Object settlementId,
    required Object transferId,
  });
}

class SettlementDraftSectionInput {
  const SettlementDraftSectionInput({
    required this.id,
    required this.title,
    required this.payerUserId,
    this.schedulePlaceId,
    this.items = const [],
  });

  final Object id;
  final String? schedulePlaceId;
  final String title;
  final String payerUserId;
  final List<SettlementDraftItemInput> items;

  Map<String, Object?> toJson() {
    return {
      'id': id.toString(),
      if (schedulePlaceId != null && schedulePlaceId!.isNotEmpty)
        'schedulePlaceId': schedulePlaceId,
      'title': title,
      if (payerUserId.isNotEmpty) 'payerUserId': payerUserId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class SettlementDraftItemInput {
  const SettlementDraftItemInput({
    this.id,
    required this.title,
    required this.amount,
    this.sectionId,
    this.sectionTitle,
    this.schedulePlaceId,
    this.payerUserId,
    required this.payerName,
    this.splitType = SettlementSplitType.equal,
    this.targetUserIds = const [],
    this.targetShares = const [],
  });

  final Object? id;
  final Object? sectionId;
  final String? sectionTitle;
  final String? schedulePlaceId;
  final String title;
  final int amount;
  final String? payerUserId;
  final String payerName;
  final SettlementSplitType splitType;
  final List<String> targetUserIds;
  final List<SettlementTargetShareInput> targetShares;

  Map<String, Object?> toJson() {
    return {
      if (id != null) 'id': id.toString(),
      'title': title,
      'amountWon': amount,
      'splitType': splitType == SettlementSplitType.equal ? 'equal' : 'menu',
      if (targetShares.isNotEmpty)
        'targetShares': targetShares.map((share) => share.toJson()).toList()
      else if (targetUserIds.isNotEmpty)
        'targetUserIds': targetUserIds,
    };
  }
}

class SettlementTargetShareInput {
  const SettlementTargetShareInput({
    required this.userId,
    required this.amountWon,
  });

  final String userId;
  final int amountWon;

  Map<String, Object?> toJson() {
    return {'userId': userId, 'amountWon': amountWon};
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
    final draft = await _client.postObject(
      '/api/v1/groups/$groupId/plans/$planId/settlement-draft',
      body: const {},
    );
    final preview = _settlement(OnmuJson.asMap(draft['preview']));
    final topLevelSections = _sections(OnmuJson.asMapList(draft['sections']));
    return preview.copyWith(
      id: _readId(draft, 'id'),
      status: OnmuJson.readString(draft, 'status', 'draft'),
      sections: topLevelSections.isEmpty ? preview.sections : topLevelSections,
      preview: true,
    );
  }

  @override
  Future<SettlementSummary> updateSettlementDraft({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
    String? memo,
  }) {
    return updateSettlementDraftSections(
      groupId: groupId,
      planId: planId,
      sections: _sectionsFromItems(items),
      memo: memo,
    );
  }

  @override
  Future<SettlementSummary> updateSettlementDraftSections({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftSectionInput> sections,
    String? memo,
  }) async {
    final draft = await _client.patchObject(
      '/api/v1/groups/$groupId/plans/$planId/settlement-draft',
      body: {
        'sections': sections.map((section) => section.toJson()).toList(),
        if (memo != null && memo.trim().isNotEmpty) 'memo': memo.trim(),
      },
    );
    final preview = _settlement(OnmuJson.asMap(draft['preview']));
    final topLevelSections = _sections(OnmuJson.asMapList(draft['sections']));
    return preview.copyWith(
      id: _readId(draft, 'id'),
      status: OnmuJson.readString(draft, 'status', 'draft'),
      sections: topLevelSections.isEmpty ? preview.sections : topLevelSections,
      preview: true,
    );
  }

  @override
  Future<SettlementSummary> updateSettlementDraftItemTargets({
    required Object groupId,
    required Object planId,
    required Object itemId,
    List<String> targetUserIds = const [],
    List<SettlementTargetShareInput> targetShares = const [],
  }) async {
    final draft = await _client.patchObject(
      '/api/v1/groups/$groupId/plans/$planId/settlement-draft/items/$itemId/targets',
      body: {
        if (targetShares.isNotEmpty)
          'targetShares': targetShares.map((share) => share.toJson()).toList()
        else if (targetUserIds.isNotEmpty)
          'targetUserIds': targetUserIds,
      },
    );
    final preview = _settlement(OnmuJson.asMap(draft['preview']));
    final topLevelSections = _sections(OnmuJson.asMapList(draft['sections']));
    return preview.copyWith(
      id: _readId(draft, 'id'),
      status: OnmuJson.readString(draft, 'status', 'draft'),
      sections: topLevelSections.isEmpty ? preview.sections : topLevelSections,
      preview: true,
    );
  }

  @override
  Future<SettlementSummary> previewSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) async {
    final settlement = await _client.postObject(
      '/api/v1/groups/$groupId/plans/$planId/settlements/preview',
      body: _sectionsBody(_sectionsFromItems(items)),
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
      body: _sectionsBody(_sectionsFromItems(items)),
    );
    return _settlement(settlement);
  }

  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) async {
    final settlement = await _client.getObject(
      '/api/v1/groups/$groupId/plans/$planId/settlements/current',
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

  @override
  Future<SettlementBasis> fetchSettlementBasis({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  }) async {
    final basis = await _client.getObject(
      '/api/v1/groups/$groupId/plans/$planId/settlements/$settlementId/basis',
    );
    return _basis(basis);
  }

  @override
  Future<SettlementSummary> markTransferSent({
    required Object groupId,
    required Object planId,
    required Object settlementId,
    required Object transferId,
  }) async {
    final settlement = await _client.postObject(
      '/api/v1/groups/$groupId/plans/$planId/settlements/$settlementId/transfers/$transferId/sent',
      body: const {},
    );
    return _settlement(settlement);
  }

  @override
  Future<SettlementSummary> markTransferReceived({
    required Object groupId,
    required Object planId,
    required Object settlementId,
    required Object transferId,
  }) async {
    final settlement = await _client.postObject(
      '/api/v1/groups/$groupId/plans/$planId/settlements/$settlementId/transfers/$transferId/received',
      body: const {},
    );
    return _settlement(settlement);
  }

  Map<String, Object?> _sectionsBody(
    List<SettlementDraftSectionInput> sections,
  ) {
    return {'sections': sections.map((section) => section.toJson()).toList()};
  }

  List<SettlementDraftSectionInput> _sectionsFromItems(
    List<SettlementDraftItemInput> items,
  ) {
    final sections = <String, _MutableSectionInput>{};
    for (final item in items) {
      final payerKey = item.payerUserId?.trim().isNotEmpty == true
          ? item.payerUserId!.trim()
          : 'payer:${item.payerName.trim()}';
      final sectionKey = item.sectionId?.toString().trim().isNotEmpty == true
          ? item.sectionId.toString().trim()
          : 'extra-$payerKey';
      final key = '$sectionKey|$payerKey';
      final section = sections.putIfAbsent(
        key,
        () => _MutableSectionInput(
          id: sectionKey,
          schedulePlaceId: item.schedulePlaceId,
          title: item.sectionTitle?.trim().isNotEmpty == true
              ? item.sectionTitle!.trim()
              : '기타 비용',
          payerUserId: item.payerUserId?.trim() ?? '',
        ),
      );
      section.items.add(item);
    }
    return sections.values
        .map(
          (section) => SettlementDraftSectionInput(
            id: section.id,
            schedulePlaceId: section.schedulePlaceId,
            title: section.title,
            payerUserId: section.payerUserId,
            items: List.unmodifiable(section.items),
          ),
        )
        .toList(growable: false);
  }

  SettlementSummary _settlement(Map<String, dynamic> json) {
    final sections = _sections(OnmuJson.asMapList(json['sections']));
    final paymentItems = OnmuJson.asMapList(
      json['paymentItems'],
    ).map(_paymentItem).toList(growable: false);
    return SettlementSummary(
      id: _readId(json, 'id'),
      status: OnmuJson.readString(json, 'status'),
      planTitle: OnmuJson.readString(json, 'planTitle', '약속 정산'),
      totalAmountWon: OnmuJson.readInt(json, 'totalAmountWon'),
      totalAmountLabel: OnmuJson.readString(json, 'totalAmountLabel', '0원'),
      createdDateLabel: OnmuJson.readString(json, 'createdDateLabel', '미리보기'),
      itemCountLabel: OnmuJson.readString(json, 'itemCountLabel', '결제 항목 0개'),
      finalSummaryLabel: OnmuJson.readString(json, 'finalSummaryLabel'),
      mySummaryLabel: OnmuJson.readString(json, 'mySummaryLabel', '내 정산 없음'),
      paymentItems: paymentItems.isEmpty
          ? sections.expand((section) => section.items).toList(growable: false)
          : paymentItems,
      sections: sections,
      memberResults: OnmuJson.asMapList(
        json['memberResults'],
      ).map(_memberResult).toList(growable: false),
      participantStatuses: OnmuJson.asMapList(
        json['participantStatuses'],
      ).map(_participantStatus).toList(growable: false),
      transfers: OnmuJson.asMapList(
        json['transfers'],
      ).map(_transfer).toList(growable: false),
      shareMessage: OnmuJson.readString(json, 'shareMessage', '약속 정산입니다.'),
      preview: OnmuJson.readBool(json, 'preview'),
    );
  }

  SettlementBasis _basis(Map<String, dynamic> json) {
    return SettlementBasis(
      settlementId: _readId(json, 'settlementId'),
      planTitle: OnmuJson.readString(json, 'planTitle', '약속 정산'),
      totalAmountLabel: OnmuJson.readString(json, 'totalAmountLabel', '0원'),
      sections: _sections(OnmuJson.asMapList(json['sections'])),
      participants: OnmuJson.asMapList(
        json['participants'],
      ).map(_memberResult).toList(growable: false),
      transfers: OnmuJson.asMapList(
        json['transfers'],
      ).map(_transfer).toList(growable: false),
      summary: OnmuJson.readString(json, 'summary'),
    );
  }

  SettlementSection _section(Map<String, dynamic> json) {
    return SettlementSection(
      id: _readId(json, 'id'),
      schedulePlaceId: OnmuJson.readString(json, 'schedulePlaceId'),
      title: OnmuJson.readString(json, 'title', '기타 비용'),
      payerUserId: OnmuJson.readString(json, 'payerUserId'),
      payerName: OnmuJson.readString(json, 'payerName', '결제자'),
      payerProfileImageUrl: _profileImageUrl(json, 'payerProfileImageUrl'),
      payerCharacter: characterDraftFromJson(
        json['payerPixelCharacter'] ?? json['pixelCharacter'],
        nickname: OnmuJson.readString(json, 'payerName', '결제자'),
      ),
      sortOrder: OnmuJson.readInt(json, 'sortOrder'),
      totalAmountWon: OnmuJson.readInt(json, 'totalAmountWon'),
      items: OnmuJson.asMapList(
        json['items'],
      ).map(_paymentItem).toList(growable: false),
    );
  }

  List<SettlementSection> _sections(List<Map<String, dynamic>> rawSections) {
    return rawSections.map(_section).toList(growable: false);
  }

  SettlementPaymentItem _paymentItem(Map<String, dynamic> json) {
    final splitType = OnmuJson.readString(json, 'splitType', 'equal');
    return SettlementPaymentItem(
      id: _readId(json, 'id'),
      sectionId: OnmuJson.readString(json, 'sectionId'),
      title: OnmuJson.readString(json, 'title', '결제 항목'),
      amount: OnmuJson.readInt(json, 'amountWon'),
      amountLabel: OnmuJson.readString(json, 'amountLabel', '0원'),
      payerShares: OnmuJson.asMapList(json['payerShares'])
          .map(
            (payer) => SettlementPayerShare(
              userId: OnmuJson.readString(payer, 'userId'),
              name: OnmuJson.readString(payer, 'name', '결제자'),
              amountLabel: OnmuJson.readString(payer, 'amountLabel', '0원'),
              profileImageUrl: _profileImageUrl(payer),
              character: characterDraftFromJson(
                payer['pixelCharacter'],
                nickname: OnmuJson.readString(payer, 'name', '결제자'),
              ),
            ),
          )
          .toList(growable: false),
      targetLabel: OnmuJson.readString(json, 'targetLabel', '0명'),
      splitType: splitType == 'menu' || splitType == 'custom'
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
              owedAmountWon: OnmuJson.readInt(participant, 'amountWon'),
              included: OnmuJson.readBool(participant, 'included', true),
              profileImageUrl: _profileImageUrl(participant),
              character: characterDraftFromJson(
                participant['pixelCharacter'],
                nickname: OnmuJson.readString(participant, 'name', '참여자'),
              ),
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
      userId: OnmuJson.readString(json, 'userId'),
      name: OnmuJson.readString(json, 'name', '참여자'),
      finalShareLabel: OnmuJson.readString(json, 'finalShareLabel', '0원'),
      paidAmountLabel: OnmuJson.readString(
        json,
        'paidAmountLabel',
        OnmuJson.readString(json, 'paidTotalLabel', '0원'),
      ),
      resultLabel: OnmuJson.readString(
        json,
        'resultLabel',
        OnmuJson.readString(json, 'netLabel', '정산 없음'),
      ),
      isMe: OnmuJson.readBool(json, 'isMe'),
      willReceive: OnmuJson.readBool(json, 'willReceive'),
      profileImageUrl: _profileImageUrl(json),
      character: characterDraftFromJson(
        json['pixelCharacter'],
        nickname: OnmuJson.readString(json, 'name', '참여자'),
      ),
    );
  }

  SettlementParticipantStatus _participantStatus(Map<String, dynamic> json) {
    return SettlementParticipantStatus(
      userId: OnmuJson.readString(json, 'userId'),
      name: OnmuJson.readString(json, 'name', '참여자'),
      profileImageUrl: _profileImageUrl(json),
      character: characterDraftFromJson(
        json['pixelCharacter'],
        nickname: OnmuJson.readString(json, 'name', '참여자'),
      ),
      willReceive: OnmuJson.readBool(json, 'willReceive'),
      sent: OnmuJson.readBool(json, 'sent'),
      received: OnmuJson.readBool(json, 'received'),
      completed: OnmuJson.readBool(json, 'completed'),
    );
  }

  SettlementTransferSummary _transfer(Map<String, dynamic> json) {
    return SettlementTransferSummary(
      id: _readId(json, 'id'),
      fromUserId: OnmuJson.readString(json, 'fromUserId'),
      fromName: OnmuJson.readString(json, 'fromName', '보내는 사람'),
      toUserId: OnmuJson.readString(json, 'toUserId'),
      toName: OnmuJson.readString(json, 'toName', '받는 사람'),
      amountWon: OnmuJson.readInt(json, 'amountWon'),
      amountLabel: OnmuJson.readString(json, 'amountLabel', '0원'),
      status: OnmuJson.readString(json, 'status', 'pending'),
      fromProfileImageUrl: _profileImageUrl(json, 'fromProfileImageUrl'),
      toProfileImageUrl: _profileImageUrl(json, 'toProfileImageUrl'),
      fromCharacter: characterDraftFromJson(
        json['fromPixelCharacter'],
        nickname: OnmuJson.readString(json, 'fromName', '보내는 사람'),
      ),
      toCharacter: characterDraftFromJson(
        json['toPixelCharacter'],
        nickname: OnmuJson.readString(json, 'toName', '받는 사람'),
      ),
    );
  }

  String _profileImageUrl(
    Map<String, dynamic> json, [
    String primaryKey = 'profileImageUrl',
  ]) {
    return resolveOnmuProfileImageUrl(
      json,
      primaryKey: primaryKey,
      baseUrl: _client.baseUrl,
    );
  }
}

class _MutableSectionInput {
  _MutableSectionInput({
    required this.id,
    required this.title,
    required this.payerUserId,
    this.schedulePlaceId,
  });

  final String id;
  final String? schedulePlaceId;
  final String title;
  final String payerUserId;
  final List<SettlementDraftItemInput> items = [];
}
