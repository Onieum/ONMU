import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onmoim_cards.dart';

class OnMoimSettlementSharePage extends StatelessWidget {
  const OnMoimSettlementSharePage({
    required this.onmoimId,
    required this.meetupId,
    super.key,
  });

  final String onmoimId;
  final String meetupId;

  @override
  Widget build(BuildContext context) {
    final settlement = demoSettlementSummary;

    return OnmuScaffold(
      title: '약속 정산',
      subtitle: '${settlement.meetupTitle}에서 최종적으로 누구에게 얼마를 보내면 되는지 확인해요.',
      bottom: Row(
        children: [
          Expanded(
            child: OnmuSecondaryButton(
              label: '정산 수정',
              icon: Icons.edit_outlined,
              onPressed: () => context.go(
                RoutePaths.onmoimMeetupSettlementNew(onmoimId, meetupId),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OnmuPrimaryButton(
              label: '약속 상세',
              icon: Icons.event_note_outlined,
              color: AppColors.primaryPink,
              onPressed: () =>
                  context.go(RoutePaths.onmoimMeetupDetail(onmoimId, meetupId)),
            ),
          ),
        ],
      ),
      children: [
        _TotalAmountCard(settlement: settlement),
        const SizedBox(height: AppSpacing.md),
        _MySettlementCard(settlement: settlement),
        const SizedBox(height: AppSpacing.md),
        _PaymentItemsCard(items: settlement.paymentItems),
        const SizedBox(height: AppSpacing.md),
        _TransferSummaryCard(transfers: settlement.transfers),
        const SizedBox(height: AppSpacing.md),
        _FinalResultsCard(results: settlement.memberResults),
        const SizedBox(height: AppSpacing.md),
        _ShareMessageCard(message: settlement.shareMessage),
      ],
    );
  }
}

class _TotalAmountCard extends StatelessWidget {
  const _TotalAmountCard({required this.settlement});

  final SettlementSummary settlement;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.linePink,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -24,
            right: 18,
            child: Transform.rotate(
              angle: -0.18,
              child: const OnmuTape(width: 70),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settlement.meetupTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      settlement.totalAmountLabel,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        OnmuChip(label: settlement.itemCountLabel),
                        OnmuChip(label: settlement.finalSummaryLabel),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      settlement.createdDateLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const OnmuPixelBuddy(size: 70),
            ],
          ),
        ],
      ),
    );
  }
}

class _MySettlementCard extends StatelessWidget {
  const _MySettlementCard({required this.settlement});

  final SettlementSummary settlement;

  @override
  Widget build(BuildContext context) {
    final myResult = settlement.memberResults.firstWhere(
      (result) => result.isMe,
    );

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_circle, color: AppColors.primaryPink),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '내 최종 정산',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            settlement.mySummaryLabel,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.primaryPink),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '최종 부담 ${myResult.finalShareLabel} · 결제 ${myResult.paidAmountLabel}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '송금 여부는 개별 결제 항목이 아니라 최종 정산 결과 기준으로 확인합니다.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PaymentItemsCard extends StatelessWidget {
  const _PaymentItemsCard({required this.items});

  final List<SettlementPaymentItem> items;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('결제자 및 결제 내역', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items) ...[
            _PaymentItemRow(item: item),
            if (item != items.last) const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _PaymentItemRow extends StatelessWidget {
  const _PaymentItemRow({required this.item});

  final SettlementPaymentItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.receipt_long_outlined, color: AppColors.primaryPurple),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    item.amountLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '정산 대상 ${item.targetLabel} · ${item.splitTypeLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final payer in item.payerShares)
                    OnmuChip(
                      label: '${payer.name} ${payer.amountLabel}',
                      icon: Icons.person_outline,
                      color: AppColors.primaryPurple,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransferSummaryCard extends StatelessWidget {
  const _TransferSummaryCard({required this.transfers});

  final List<SettlementTransferSummary> transfers;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('최종 송금 요약', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final transfer in transfers) ...[
            _TransferRow(transfer: transfer),
            if (transfer != transfers.last)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({required this.transfer});

  final SettlementTransferSummary transfer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.arrow_forward, size: 18, color: AppColors.primaryPink),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '${transfer.fromName} → ${transfer.toName}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMain),
          ),
        ),
        Text(
          transfer.amountLabel,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primaryPink),
        ),
      ],
    );
  }
}

class _FinalResultsCard extends StatelessWidget {
  const _FinalResultsCard({required this.results});

  final List<SettlementMemberResult> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('참여자별 최종 결과', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final result in results) ...[
          FinalSettlementResultRow(result: result),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ShareMessageCard extends StatelessWidget {
  const _ShareMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('공유용 메시지', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    color: AppColors.primaryPink,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '$message\n확인 부탁드려요 :)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: OnmuSecondaryButton(
              label: '복사하기',
              icon: Icons.copy,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
