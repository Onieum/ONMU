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
  title: '카페 문라이트 디저트 정산',
  totalAmountLabel: '48,000원',
  payer: '민서',
  dueDateLabel: '오늘 23:00까지',
  members: [
    SettlementMember(
      name: '민서',
      amountLabel: '결제자',
      statusLabel: '완료',
      isPaid: true,
    ),
    SettlementMember(
      name: '지훈',
      amountLabel: '16,000원',
      statusLabel: '입금 완료',
      isPaid: true,
    ),
    SettlementMember(
      name: '하린',
      amountLabel: '16,000원',
      statusLabel: '대기 중',
      isPaid: false,
    ),
    SettlementMember(
      name: '나',
      amountLabel: '16,000원',
      statusLabel: '대기 중',
      isPaid: false,
    ),
  ],
  shareMessage: '민서에게 16,000원씩 보내면 이번 디저트 정산이 끝나요.',
);
