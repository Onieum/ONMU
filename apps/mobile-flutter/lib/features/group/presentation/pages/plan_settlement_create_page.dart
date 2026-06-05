import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../settlement/view_model/settlement_view_model.dart';

class PlanSettlementCreatePage extends ConsumerWidget {
  const PlanSettlementCreatePage({
    required this.groupId,
    required this.planId,
    super.key,
  });

  final String groupId;
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      settlementViewModelProvider((groupId: groupId, planId: planId)),
    );

    return state.when(
      data: (settlement) => _SettlementCreateContent(
        groupId: groupId,
        planId: planId,
        settlement: settlement,
      ),
      loading: () => const OnmuScaffold(
        title: '약속 정산 만들기',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '약속 정산 만들기',
        children: [
          Text(
            '정산 정보를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SettlementCreateContent extends StatelessWidget {
  const _SettlementCreateContent({
    required this.groupId,
    required this.planId,
    required this.settlement,
  });

  final String groupId;
  final String planId;
  final SettlementSummary settlement;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '약속 정산 만들기',
      subtitle: '이 약속에서 쓴 비용만 항목별로 정리해요.',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.planDetail(groupId, planId)),
      bottom: OnmuPrimaryButton(
        label: '최종 정산 미리보기',
        icon: Icons.visibility_outlined,
        color: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        onPressed: () =>
            context.go(RoutePaths.planSettlementPreview(groupId, planId)),
      ),
      children: [
        _SettlementScopeCard(settlement: settlement),
        const SizedBox(height: AppSpacing.lg),
        const _SettlementStepStrip(activeIndex: 0),
        const SizedBox(height: AppSpacing.xl),
        _SectionHeader(
          title: '결제 항목',
          trailing: '${settlement.paymentItems.length}개',
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final item in settlement.paymentItems) ...[
          _PaymentItemSummaryCard(
            item: item,
            onTap: () => context.push(
              RoutePaths.planSettlementTargets(groupId, planId, item.id),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const _AddPaymentItemCard(),
        const SizedBox(height: AppSpacing.lg),
        const _SettlementGuideCard(),
      ],
    );
  }
}

class _SettlementScopeCard extends StatelessWidget {
  const _SettlementScopeCard({required this.settlement});

  final SettlementSummary settlement;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primaryPinkSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.linePink),
                ),
                child: const SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    Icons.receipt_long_outlined,
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
                      settlement.planTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${settlement.createdDateLabel.replaceFirst('정산일 ', '')} · 참여자 6명',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
              Text(
                settlement.totalAmountLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primaryPink),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OnmuChip(label: settlement.itemCountLabel, selected: true),
              const OnmuChip(label: '항목별 대상자'),
              const OnmuChip(label: '약속 단위 정산'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettlementStepStrip extends StatelessWidget {
  const _SettlementStepStrip({required this.activeIndex});

  final int activeIndex;

  List<String> _createSteps() => ['항목', '대상자', '미리보기'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < _createSteps().length; index++) ...[
          Expanded(
            child: _SettlementStepPill(
              number: index + 1,
              label: _createSteps()[index],
              active: index == activeIndex,
            ),
          ),
          if (index != _createSteps().length - 1)
            const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _SettlementStepPill extends StatelessWidget {
  const _SettlementStepPill({
    required this.number,
    required this.label,
    required this.active,
  });

  final int number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? AppColors.primaryPinkSoft : AppColors.bgDefault,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: active ? AppColors.linePink : AppColors.lineSoft,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$number',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: active ? AppColors.primaryPink : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: active ? AppColors.primaryPink : AppColors.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(
          trailing,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
        ),
      ],
    );
  }
}

class _PaymentItemSummaryCard extends StatelessWidget {
  const _PaymentItemSummaryCard({required this.item, required this.onTap});

  final SettlementPaymentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final participants = item.includedParticipants;

    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PaymentItemIcon(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          item.amountLabel,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: AppColors.primaryPink),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.payerLabel} 결제 · 대상 ${item.targetLabel}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OnmuChip(label: item.targetModeLabel, selected: true),
              OnmuChip(label: item.splitTypeLabel),
              for (final participant in participants.take(4))
                OnmuChip(label: participant.name),
              if (participants.length > 4)
                OnmuChip(label: '+${participants.length - 4}명'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentItemIcon extends StatelessWidget {
  const _PaymentItemIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: const SizedBox.square(
        dimension: 40,
        child: Icon(Icons.payments_outlined, color: AppColors.primaryPink),
      ),
    );
  }
}

class _AddPaymentItemCard extends StatelessWidget {
  const _AddPaymentItemCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: TextButton.icon(
        onPressed: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('결제 항목 추가 UI를 열어요.'))),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('결제 항목 추가'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          minimumSize: const Size.fromHeight(44),
        ),
      ),
    );
  }
}

class _SettlementGuideCard extends StatelessWidget {
  const _SettlementGuideCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.primaryPinkSoft.withValues(alpha: 0.34),
      borderColor: AppColors.linePink,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.tips_and_updates_outlined,
            color: AppColors.primaryPink,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '대상자가 다른 비용은 항목 카드에서 따로 선택해요. 최종 송금은 미리보기에서 한 번에 확인합니다.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
          ),
        ],
      ),
    );
  }
}
