class SettlementMember {
  const SettlementMember({
    required this.name,
    required this.amountLabel,
    required this.statusLabel,
    required this.isPaid,
  });

  final String name;
  final String amountLabel;
  final String statusLabel;
  final bool isPaid;
}

class SettlementSummary {
  const SettlementSummary({
    required this.id,
    required this.title,
    required this.totalAmountLabel,
    required this.payer,
    required this.dueDateLabel,
    required this.members,
    required this.shareMessage,
  });

  final String id;
  final String title;
  final String totalAmountLabel;
  final String payer;
  final String dueDateLabel;
  final List<SettlementMember> members;
  final String shareMessage;
}

const demoSettlementSummary = SettlementSummary(
  id: 'lunch-split',
  title: '이번 약속 총 금액',
  totalAmountLabel: '186,000원',
  payer: '지민',
  dueDateLabel: '정산일 2025.05.28',
  members: [
    SettlementMember(
      name: '지민 (나)',
      amountLabel: '31,000원',
      statusLabel: '완료',
      isPaid: true,
    ),
    SettlementMember(
      name: '민수',
      amountLabel: '31,000원',
      statusLabel: '완료',
      isPaid: true,
    ),
    SettlementMember(
      name: '소연',
      amountLabel: '31,000원',
      statusLabel: '완료',
      isPaid: true,
    ),
    SettlementMember(
      name: '현우',
      amountLabel: '31,000원',
      statusLabel: '완료',
      isPaid: true,
    ),
    SettlementMember(
      name: '준호',
      amountLabel: '31,000원',
      statusLabel: '미완료',
      isPaid: false,
    ),
    SettlementMember(
      name: '혜진',
      amountLabel: '31,000원',
      statusLabel: '미완료',
      isPaid: false,
    ),
  ],
  shareMessage: '5/30~6/1 제주도 여행 약속 정산입니다! 확인 부탁드려요.',
);
