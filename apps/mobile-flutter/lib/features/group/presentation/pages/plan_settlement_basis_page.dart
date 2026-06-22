import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../settlement/view_model/settlement_view_model.dart';

class PlanSettlementBasisPage extends ConsumerWidget {
  const PlanSettlementBasisPage({
    required this.groupId,
    required this.planId,
    required this.settlementId,
    super.key,
  });

  final String groupId;
  final String planId;
  final String settlementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      settlementBasisViewModelProvider((
        groupId: groupId,
        planId: planId,
        settlementId: settlementId,
      )),
    );

    return state.when(
      data: (basis) => _SettlementBasisContent(basis: basis),
      loading: () => const OnmuScaffold(
        title: '정산 근거',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '정산 근거',
        children: [
          Text(
            '정산 근거를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SettlementBasisContent extends StatelessWidget {
  const _SettlementBasisContent({required this.basis});

  final SettlementBasis basis;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '정산 근거',
      subtitle: '${basis.planTitle} 계산 기준',
      showBackButton: true,
      children: [
        OnmuCard(
          backgroundColor: AppColors.primaryPinkSoft.withValues(alpha: 0.28),
          borderColor: AppColors.linePink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '총액 ${basis.totalAmountLabel}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                basis.summary,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final section in basis.sections) ...[
          _BasisSectionCard(section: section),
          const SizedBox(height: AppSpacing.sm),
        ],
        _BasisTransferCard(transfers: basis.transfers),
      ],
    );
  }
}

class _BasisSectionCard extends StatelessWidget {
  const _BasisSectionCard({required this.section});

  final SettlementSection section;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${section.payerName}님 결제 · ${section.items.length}개 항목',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    item.amountLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BasisTransferCard extends StatelessWidget {
  const _BasisTransferCard({required this.transfers});

  final List<SettlementTransferSummary> transfers;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('최소 이체 결과', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (transfers.isEmpty)
            Text(
              '이체할 내역이 없어요.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
            )
          else
            for (final transfer in transfers)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${transfer.fromName} → ${transfer.toName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      transfer.amountLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
