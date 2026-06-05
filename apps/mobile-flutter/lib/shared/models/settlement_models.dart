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

const _allParticipants = [
  SettlementPaymentParticipant(name: '지민', owedAmountLabel: '20,667원'),
  SettlementPaymentParticipant(name: '민수', owedAmountLabel: '20,667원'),
  SettlementPaymentParticipant(name: '소연', owedAmountLabel: '20,667원'),
  SettlementPaymentParticipant(name: '현우', owedAmountLabel: '20,667원'),
  SettlementPaymentParticipant(name: '준호', owedAmountLabel: '20,666원'),
  SettlementPaymentParticipant(name: '혜진', owedAmountLabel: '20,666원'),
];

const mockSettlementSummary = SettlementSummary(
  id: 301,
  planTitle: '주말 나들이',
  totalAmountLabel: '186,000원',
  createdDateLabel: '정산일 2025.05.28',
  itemCountLabel: '결제 항목 2개',
  finalSummaryLabel: '4명이 송금 필요',
  mySummaryLabel: '나는 103,333원을 받아요',
  paymentItems: [
    SettlementPaymentItem(
      id: 401,
      title: '저녁',
      amountLabel: '124,000원',
      payerShares: [SettlementPayerShare(name: '지민', amountLabel: '124,000원')],
      targetLabel: '6명',
      splitType: SettlementSplitType.equal,
      participants: _allParticipants,
    ),
    SettlementPaymentItem(
      id: 402,
      title: '카페',
      amountLabel: '62,000원',
      payerShares: [
        SettlementPayerShare(name: '민수', amountLabel: '42,000원'),
        SettlementPayerShare(name: '지민', amountLabel: '20,000원'),
      ],
      targetLabel: '4명',
      splitType: SettlementSplitType.custom,
      participants: [
        SettlementPaymentParticipant(name: '지민', owedAmountLabel: '20,000원'),
        SettlementPaymentParticipant(name: '민수', owedAmountLabel: '18,000원'),
        SettlementPaymentParticipant(name: '소연', owedAmountLabel: '12,000원'),
        SettlementPaymentParticipant(name: '현우', owedAmountLabel: '12,000원'),
        SettlementPaymentParticipant(
          name: '준호',
          owedAmountLabel: '-',
          included: false,
        ),
        SettlementPaymentParticipant(
          name: '혜진',
          owedAmountLabel: '-',
          included: false,
        ),
      ],
    ),
  ],
  memberResults: [
    SettlementMemberResult(
      name: '지민 (나)',
      finalShareLabel: '40,667원',
      paidAmountLabel: '144,000원',
      resultLabel: '103,333원 받음',
      isMe: true,
      willReceive: true,
    ),
    SettlementMemberResult(
      name: '민수',
      finalShareLabel: '38,667원',
      paidAmountLabel: '42,000원',
      resultLabel: '3,333원 받음',
      willReceive: true,
    ),
    SettlementMemberResult(
      name: '소연',
      finalShareLabel: '32,667원',
      paidAmountLabel: '0원',
      resultLabel: '지민에게 32,667원',
    ),
    SettlementMemberResult(
      name: '현우',
      finalShareLabel: '32,667원',
      paidAmountLabel: '0원',
      resultLabel: '지민에게 32,667원',
    ),
    SettlementMemberResult(
      name: '준호',
      finalShareLabel: '20,666원',
      paidAmountLabel: '0원',
      resultLabel: '지민에게 20,666원',
    ),
    SettlementMemberResult(
      name: '혜진',
      finalShareLabel: '20,666원',
      paidAmountLabel: '0원',
      resultLabel: '지민에게 17,333원 · 민수에게 3,333원',
    ),
  ],
  transfers: [
    SettlementTransferSummary(
      fromName: '소연',
      toName: '지민',
      amountLabel: '32,667원',
    ),
    SettlementTransferSummary(
      fromName: '현우',
      toName: '지민',
      amountLabel: '32,667원',
    ),
    SettlementTransferSummary(
      fromName: '준호',
      toName: '지민',
      amountLabel: '20,666원',
    ),
    SettlementTransferSummary(
      fromName: '혜진',
      toName: '지민',
      amountLabel: '17,333원',
    ),
    SettlementTransferSummary(
      fromName: '혜진',
      toName: '민수',
      amountLabel: '3,333원',
    ),
  ],
  shareMessage: '주말 나들이 약속 정산입니다. 최종 송금 금액만 확인해 주세요.',
);
