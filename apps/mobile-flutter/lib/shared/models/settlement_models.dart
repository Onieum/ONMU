enum SettlementSplitType { equal, custom }

class SettlementPayerShare {
  const SettlementPayerShare({required this.name, required this.amountLabel});

  final String name;
  final String amountLabel;
}

class SettlementPaymentParticipant {
  const SettlementPaymentParticipant({
    required this.name,
    required this.owedAmountLabel,
    this.included = true,
  });

  final String name;
  final String owedAmountLabel;
  final bool included;
}

class SettlementPaymentItem {
  const SettlementPaymentItem({
    required this.id,
    required this.title,
    required this.amountLabel,
    required this.payerShares,
    required this.targetLabel,
    required this.splitType,
    required this.participants,
  });

  final int id;
  final String title;
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
      splitType == SettlementSplitType.equal ? '1/N' : '개별 금액';
}

class SettlementTransferSummary {
  const SettlementTransferSummary({
    required this.fromName,
    required this.toName,
    required this.amountLabel,
  });

  final String fromName;
  final String toName;
  final String amountLabel;
}

class SettlementMemberResult {
  const SettlementMemberResult({
    required this.name,
    required this.finalShareLabel,
    required this.paidAmountLabel,
    required this.resultLabel,
    this.isMe = false,
    this.willReceive = false,
  });

  final String name;
  final String finalShareLabel;
  final String paidAmountLabel;
  final String resultLabel;
  final bool isMe;
  final bool willReceive;
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
  });

  final int id;
  final String planTitle;
  final String totalAmountLabel;
  final String createdDateLabel;
  final String itemCountLabel;
  final String finalSummaryLabel;
  final String mySummaryLabel;
  final List<SettlementPaymentItem> paymentItems;
  final List<SettlementMemberResult> memberResults;
  final List<SettlementTransferSummary> transfers;
  final String shareMessage;
}
