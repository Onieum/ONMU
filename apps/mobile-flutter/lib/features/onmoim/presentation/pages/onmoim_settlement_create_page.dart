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
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class OnMoimSettlementCreatePage extends StatelessWidget {
  const OnMoimSettlementCreatePage({
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
      title: '약속 정산 만들기',
      subtitle: '${settlement.meetupTitle}에서 쓴 결제 항목을 약속 단위로 정리해요.',
      bottom: OnmuPrimaryButton(
        label: '최종 정산 미리보기',
        icon: Icons.visibility_outlined,
        color: AppColors.primaryPink,
        onPressed: () => context.go(
          RoutePaths.onmoimMeetupSettlementShare(
            onmoimId,
            meetupId,
            settlement.id,
          ),
        ),
      ),
      children: [
        _MeetupSettlementScopeCard(settlement: settlement),
        const SizedBox(height: AppSpacing.md),
        for (final item in settlement.paymentItems) ...[
          _PaymentItemEditorCard(
            item: item,
            itemNumber: settlement.paymentItems.indexOf(item) + 1,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const _AddPaymentItemCard(),
        const SizedBox(height: AppSpacing.md),
        _PaymentItemListCard(items: settlement.paymentItems),
        const SizedBox(height: AppSpacing.md),
        _ValidationCard(
          totalAmountLabel: settlement.totalAmountLabel,
          participantCount: settlement.memberResults.length,
        ),
      ],
    );
  }
}

class _MeetupSettlementScopeCard extends StatelessWidget {
  const _MeetupSettlementScopeCard({required this.settlement});

  final SettlementSummary settlement;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Row(
        children: [
          const OnmuPixelBuddy(size: 56),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settlement.meetupTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '모임 전체가 아니라 이 약속에서 발생한 비용만 정산합니다.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OnmuChip(label: settlement.itemCountLabel),
                    const OnmuChip(label: '참여자 6명'),
                    const OnmuChip(label: '항목별 대상자 선택'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentItemEditorCard extends StatelessWidget {
  const _PaymentItemEditorCard({required this.item, required this.itemNumber});

  final SettlementPaymentItem item;
  final int itemNumber;

  @override
  Widget build(BuildContext context) {
    final isCustom = item.splitType == SettlementSplitType.custom;

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.linePink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnmuStickerLabel(
            label: '결제 항목 $itemNumber',
            icon: Icons.receipt_long,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: InputDecoration(
              labelText: '결제 항목명',
              hintText: item.title,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: '결제 금액',
                    hintText: item.amountLabel,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: '대표 결제자',
                    hintText: item.payerLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '결제자별 결제 금액',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '여러 명 가능',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final payer in item.payerShares) ...[
            _PayerShareRow(payer: payer),
            const SizedBox(height: AppSpacing.xs),
          ],
          SizedBox(
            width: double.infinity,
            child: OnmuSecondaryButton(
              label: '결제자 추가',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('결제자별 금액 입력 UI를 열어요.')),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('정산 방식', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _SplitModePill(label: '1/N으로 나누기', selected: !isCustom),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SplitModePill(label: '참여자별 금액 다르게', selected: isCustom),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '정산 대상자',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                isCustom
                    ? '${item.targetLabel} · 직접 입력'
                    : '${item.targetLabel} · 자동 계산',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final participant in item.participants)
                OnmuChip(
                  label: participant.name,
                  selected: participant.included,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final participant in item.participants) ...[
            _ParticipantAmountRow(participant: participant, isCustom: isCustom),
            const SizedBox(height: AppSpacing.xs),
          ],
          _ItemValidationNote(item: item),
        ],
      ),
    );
  }
}

class _AddPaymentItemCard extends StatelessWidget {
  const _AddPaymentItemCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: AppColors.primaryPink,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '저녁, 카페, 택시처럼 결제 항목을 계속 추가할 수 있어요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OnmuSecondaryButton(
              label: '결제 항목 추가',
              icon: Icons.add,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('결제 항목 추가 UI를 열어요.')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayerShareRow extends StatelessWidget {
  const _PayerShareRow({required this.payer});

  final SettlementPayerShare payer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.person_outline,
              size: 18,
              color: AppColors.textSub,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                payer.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              payer.amountLabel,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.primaryPink),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitModePill extends StatelessWidget {
  const _SplitModePill({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPurpleSoft : AppColors.bgDefault,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.linePurple : AppColors.lineSoft,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.primaryPurpleDark : AppColors.textSub,
          ),
        ),
      ),
    );
  }
}

class _ParticipantAmountRow extends StatelessWidget {
  const _ParticipantAmountRow({
    required this.participant,
    required this.isCustom,
  });

  final SettlementPaymentParticipant participant;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          participant.included ? Icons.check_circle : Icons.remove_circle,
          size: 18,
          color: participant.included
              ? AppColors.primaryPink
              : AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            participant.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: participant.included
                  ? AppColors.textMain
                  : AppColors.textMuted,
            ),
          ),
        ),
        _AmountFieldPreview(
          label: participant.included ? participant.owedAmountLabel : '제외',
          enabled: participant.included,
          editable: participant.included && isCustom,
        ),
      ],
    );
  }
}

class _AmountFieldPreview extends StatelessWidget {
  const _AmountFieldPreview({
    required this.label,
    required this.enabled,
    required this.editable,
  });

  final String label;
  final bool enabled;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final borderColor = editable ? AppColors.linePink : AppColors.lineSoft;
    final backgroundColor = editable ? AppColors.bgDefault : AppColors.bgPaper;
    final foregroundColor = enabled
        ? AppColors.primaryPink
        : AppColors.textMuted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (editable) ...[
              const Icon(
                Icons.edit_outlined,
                size: 13,
                color: AppColors.primaryPink,
              ),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: foregroundColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemValidationNote extends StatelessWidget {
  const _ItemValidationNote({required this.item});

  final SettlementPaymentItem item;

  @override
  Widget build(BuildContext context) {
    final isCustom = item.splitType == SettlementSplitType.custom;
    final message = isCustom
        ? '참여자별 입력 합계가 ${item.amountLabel}와 일치해요.'
        : '${item.targetLabel} 기준 1/N 금액이 자동으로 계산됐어요.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPinkSoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.linePink),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: AppColors.primaryPink,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentItemListCard extends StatelessWidget {
  const _PaymentItemListCard({required this.items});

  final List<SettlementPaymentItem> items;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('결제 항목 요약', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items) ...[
            _PaymentItemSummaryRow(item: item),
            if (item != items.last) const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _PaymentItemSummaryRow extends StatelessWidget {
  const _PaymentItemSummaryRow({required this.item});

  final SettlementPaymentItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.payments_outlined, color: AppColors.primaryPink),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${item.amountLabel} · 결제자 ${item.payerLabel}',
                style: Theme.of(context).textTheme.bodyMedium,
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

class _ValidationCard extends StatelessWidget {
  const _ValidationCard({
    required this.totalAmountLabel,
    required this.participantCount,
  });

  final String totalAmountLabel;
  final int participantCount;

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
              const Icon(Icons.verified_outlined, color: AppColors.accentGreen),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '저장 전 확인',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '총 $totalAmountLabel · 정산 대상 $participantCount명 · 참여자별 합계 정상',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          OnmuSecondaryButton(
            label: '영수증으로 자동 입력',
            icon: Icons.document_scanner_outlined,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('영수증 OCR은 후순위 확장으로 연결해요.')),
            ),
          ),
        ],
      ),
    );
  }
}
