enum SettlementSplitType { equal, custom }

class SettlementSection {
  const SettlementSection({
    required this.id,
    required this.title,
    required this.payerName,
    required this.items,
    this.schedulePlaceId = '',
    this.payerUserId = '',
    this.payerProfileImageUrl = '',
    this.sortOrder = 0,
    this.totalAmountWon = 0,
  });

  final String id;
  final String schedulePlaceId;
  final String title;
  final String payerUserId;
  final String payerName;
  final String payerProfileImageUrl;
  final int sortOrder;
  final int totalAmountWon;
  final List<SettlementPaymentItem> items;
}

class SettlementPayerShare {
  const SettlementPayerShare({
    required this.name,
    required this.amountLabel,
    this.userId = '',
    this.profileImageUrl = '',
  });

  final String userId;
  final String name;
  final String amountLabel;
  final String profileImageUrl;
}

class SettlementPaymentParticipant {
  const SettlementPaymentParticipant({
    required this.name,
    required this.owedAmountLabel,
    this.userId = '',
    this.included = true,
    this.profileImageUrl = '',
  });

  final String userId;
  final String name;
  final String owedAmountLabel;
  final bool included;
  final String profileImageUrl;

  String get selectionKey => userId.isNotEmpty ? userId : name;
}

class SettlementPaymentItem {
  const SettlementPaymentItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.amountLabel,
    required this.payerShares,
    required this.targetLabel,
    required this.splitType,
    required this.participants,
    this.sectionId = '',
  });

  final String id;
  final String sectionId;
  final String title;
  final int amount;
  final String amountLabel;
  final List<SettlementPayerShare> payerShares;
  final String targetLabel;
  final SettlementSplitType splitType;
  final List<SettlementPaymentParticipant> participants;

  String get payerLabel => payerShares.map((payer) => payer.name).join(', ');

  List<SettlementPaymentParticipant> get includedParticipants =>
      participants.where((participant) => participant.included).toList();

  String get targetModeLabel =>
      splitType == SettlementSplitType.equal ? '전체 참여자' : '직접 선택';

  String get splitTypeLabel =>
      splitType == SettlementSplitType.equal ? '균등분할' : '메뉴별';
}

class SettlementTransferSummary {
  const SettlementTransferSummary({
    required this.fromName,
    required this.toName,
    required this.amountLabel,
    this.id = '',
    this.fromUserId = '',
    this.toUserId = '',
    this.amountWon = 0,
    this.status = 'pending',
    this.fromProfileImageUrl = '',
    this.toProfileImageUrl = '',
  });

  final String id;
  final String fromUserId;
  final String fromName;
  final String toUserId;
  final String toName;
  final int amountWon;
  final String amountLabel;
  final String status;
  final String fromProfileImageUrl;
  final String toProfileImageUrl;

  bool get sent => status == 'sent' || status == 'received';

  bool get received => status == 'received';
}

class SettlementMemberResult {
  const SettlementMemberResult({
    required this.name,
    required this.finalShareLabel,
    required this.paidAmountLabel,
    required this.resultLabel,
    this.userId = '',
    this.isMe = false,
    this.willReceive = false,
    this.profileImageUrl = '',
  });

  final String userId;
  final String name;
  final String finalShareLabel;
  final String paidAmountLabel;
  final String resultLabel;
  final bool isMe;
  final bool willReceive;
  final String profileImageUrl;
}

class SettlementParticipantStatus {
  const SettlementParticipantStatus({
    required this.userId,
    required this.name,
    this.profileImageUrl = '',
    this.willReceive = false,
    this.sent = false,
    this.received = false,
    this.completed = false,
  });

  final String userId;
  final String name;
  final String profileImageUrl;
  final bool willReceive;
  final bool sent;
  final bool received;
  final bool completed;
}

class SettlementBasis {
  const SettlementBasis({
    required this.settlementId,
    required this.planTitle,
    required this.totalAmountLabel,
    required this.sections,
    required this.participants,
    required this.transfers,
    required this.summary,
  });

  final String settlementId;
  final String planTitle;
  final String totalAmountLabel;
  final List<SettlementSection> sections;
  final List<SettlementMemberResult> participants;
  final List<SettlementTransferSummary> transfers;
  final String summary;
}

class SettlementSummary {
  const SettlementSummary({
    required this.id,
    required this.planTitle,
    required this.totalAmountLabel,
    required this.createdDateLabel,
    required this.itemCountLabel,
    required this.finalSummaryLabel,
    required this.mySummaryLabel,
    required this.paymentItems,
    required this.memberResults,
    required this.transfers,
    required this.shareMessage,
    this.status = '',
    this.totalAmountWon = 0,
    this.sections = const [],
    this.participantStatuses = const [],
    this.preview = false,
  });

  final String id;
  final String status;
  final String planTitle;
  final int totalAmountWon;
  final String totalAmountLabel;
  final String createdDateLabel;
  final String itemCountLabel;
  final String finalSummaryLabel;
  final String mySummaryLabel;
  final List<SettlementPaymentItem> paymentItems;
  final List<SettlementSection> sections;
  final List<SettlementMemberResult> memberResults;
  final List<SettlementParticipantStatus> participantStatuses;
  final List<SettlementTransferSummary> transfers;
  final String shareMessage;
  final bool preview;

  bool get isDraft => status == 'draft';

  bool get isFinalized => status == 'finalized';

  bool get isCompleted => status == 'completed';

  bool get isCreated {
    final normalizedId = id.trim().toLowerCase();
    return !preview &&
        normalizedId.isNotEmpty &&
        normalizedId != 'draft' &&
        !isCompleted;
  }

  String get displayFinalSummaryLabel {
    final trimmed = finalSummaryLabel.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return '정산 요약 없음';
  }

  SettlementSummary copyWith({
    String? id,
    String? status,
    String? planTitle,
    int? totalAmountWon,
    String? totalAmountLabel,
    String? createdDateLabel,
    String? itemCountLabel,
    String? finalSummaryLabel,
    String? mySummaryLabel,
    List<SettlementPaymentItem>? paymentItems,
    List<SettlementSection>? sections,
    List<SettlementMemberResult>? memberResults,
    List<SettlementParticipantStatus>? participantStatuses,
    List<SettlementTransferSummary>? transfers,
    String? shareMessage,
    bool? preview,
  }) {
    return SettlementSummary(
      id: id ?? this.id,
      status: status ?? this.status,
      planTitle: planTitle ?? this.planTitle,
      totalAmountWon: totalAmountWon ?? this.totalAmountWon,
      totalAmountLabel: totalAmountLabel ?? this.totalAmountLabel,
      createdDateLabel: createdDateLabel ?? this.createdDateLabel,
      itemCountLabel: itemCountLabel ?? this.itemCountLabel,
      finalSummaryLabel: finalSummaryLabel ?? this.finalSummaryLabel,
      mySummaryLabel: mySummaryLabel ?? this.mySummaryLabel,
      paymentItems: paymentItems ?? this.paymentItems,
      sections: sections ?? this.sections,
      memberResults: memberResults ?? this.memberResults,
      participantStatuses: participantStatuses ?? this.participantStatuses,
      transfers: transfers ?? this.transfers,
      shareMessage: shareMessage ?? this.shareMessage,
      preview: preview ?? this.preview,
    );
  }
}
