import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class OnMoimSettlementSharePage extends StatelessWidget {
  const OnMoimSettlementSharePage({
    required this.onmoimId,
    required this.meetupId,
    super.key,
    this.preview = false,
  });

  final String onmoimId;
  final String meetupId;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final settlement = demoSettlementSummary;

    return OnmuScaffold(
      title: preview ? '정산 미리보기' : '약속 정산',
      subtitle: preview
          ? '만들기 전에 최종 송금 방향만 가볍게 확인해요.'
          : '${settlement.meetupTitle} 정산 결과를 확인해요.',
      showBackButton: true,
      onBack: () => context.go(
        preview
            ? RoutePaths.planSettlementNew(onmoimId, meetupId)
            : RoutePaths.planDetail(onmoimId, meetupId),
      ),
      bottom: Row(
        children: [
          Expanded(
            child: OnmuSecondaryButton(
              label: '정산 수정',
              icon: Icons.edit_outlined,
              onPressed: () =>
                  context.go(RoutePaths.planSettlementNew(onmoimId, meetupId)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OnmuPrimaryButton(
              label: preview ? '정산 만들기' : '약속 상세',
              icon: preview
                  ? Icons.check_circle_outline
                  : Icons.event_note_outlined,
              color: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              onPressed: () => context.go(
                preview
                    ? RoutePaths.planSettlementDetail(
                        onmoimId,
                        meetupId,
                        settlement.id,
                      )
                    : RoutePaths.planDetail(onmoimId, meetupId),
              ),
            ),
          ),
        ],
      ),
      children: [
        _SettlementHeaderCard(settlement: settlement, preview: preview),
        const SizedBox(height: AppSpacing.md),
        _MyResultCompactCard(settlement: settlement),
        const SizedBox(height: AppSpacing.md),
        _TransferCompactCard(transfers: settlement.transfers),
        const SizedBox(height: AppSpacing.md),
        _ItemTargetCompactCard(items: settlement.paymentItems),
        const SizedBox(height: AppSpacing.md),
        _MemberResultCompactCard(results: settlement.memberResults),
      ],
    );
  }
}

class _SettlementHeaderCard extends StatelessWidget {
  const _SettlementHeaderCard({
    required this.settlement,
    required this.preview,
  });

  final SettlementSummary settlement;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.linePink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primaryPinkSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.linePink),
                ),
                child: const SizedBox.square(
                  dimension: 42,
                  child: Icon(
                    Icons.payments_outlined,
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settlement.meetupTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${settlement.itemCountLabel} · ${settlement.finalSummaryLabel}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
              OnmuChip(label: preview ? '미리보기' : '공유됨', selected: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _MiniSummaryTile(label: '총액', value: settlement.totalAmountLabel),
              const SizedBox(width: AppSpacing.xs),
              _MiniSummaryTile(label: '결제 항목', value: '2개'),
              const SizedBox(width: AppSpacing.xs),
              _MiniSummaryTile(label: '송금', value: '5건'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSummaryTile extends StatelessWidget {
  const _MiniSummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bgPaper,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(color: AppColors.lineWarm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.textMain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyResultCompactCard extends StatelessWidget {
  const _MyResultCompactCard({required this.settlement});

  final SettlementSummary settlement;

  @override
  Widget build(BuildContext context) {
    final myResult = settlement.memberResults.firstWhere(
      (result) => result.isMe,
    );
    final mySummary = settlement.mySummaryLabel.replaceFirst('나는 ', '');

    return OnmuCard(
      backgroundColor: AppColors.primaryPinkSoft.withValues(alpha: 0.36),
      borderColor: AppColors.linePink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_circle, color: AppColors.primaryPink),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '내 정산 결과',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const OnmuChip(label: '받을 예정', selected: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            mySummary,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.primaryPink),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _MiniSummaryTile(label: '부담', value: myResult.finalShareLabel),
              const SizedBox(width: AppSpacing.xs),
              _MiniSummaryTile(label: '결제', value: myResult.paidAmountLabel),
              const SizedBox(width: AppSpacing.xs),
              _MiniSummaryTile(label: '결과', value: myResult.resultLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransferCompactCard extends StatelessWidget {
  const _TransferCompactCard({required this.transfers});

  final List<SettlementTransferSummary> transfers;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '최종 송금 요약',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              OnmuChip(label: '${transfers.length}건'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final transfer in transfers.take(4)) ...[
            _TransferRow(transfer: transfer),
            if (transfer != transfers.take(4).last)
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
        PixelAvatar(label: transfer.fromName, size: 30),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '${transfer.fromName} → ${transfer.toName}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          transfer.amountLabel,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.primaryPink),
        ),
      ],
    );
  }
}

class _ItemTargetCompactCard extends StatelessWidget {
  const _ItemTargetCompactCard({required this.items});

  final List<SettlementPaymentItem> items;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('결제 항목별 대상자', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primaryPink,
                  size: 20,
                ),
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
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          OnmuChip(
                            label: '대상 ${item.targetLabel}',
                            selected: true,
                          ),
                          OnmuChip(label: item.splitTypeLabel),
                          OnmuChip(label: '${item.payerLabel} 결제'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item != items.last) const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _MemberResultCompactCard extends StatelessWidget {
  const _MemberResultCompactCard({required this.results});

  final List<SettlementMemberResult> results;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('사람별 최종 결과', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final result in results.take(4)) ...[
            Row(
              children: [
                PixelAvatar(label: result.name, size: 30),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    result.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  result.resultLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: result.willReceive
                        ? AppColors.primaryPink
                        : AppColors.textSub,
                  ),
                ),
              ],
            ),
            if (result != results.take(4).last)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
