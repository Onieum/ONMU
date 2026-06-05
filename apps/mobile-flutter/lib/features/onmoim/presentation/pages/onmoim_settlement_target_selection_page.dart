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

class OnMoimSettlementTargetSelectionPage extends StatefulWidget {
  const OnMoimSettlementTargetSelectionPage({
    required this.onmoimId,
    required this.meetupId,
    required this.itemId,
    super.key,
  });

  final String onmoimId;
  final String meetupId;
  final String itemId;

  @override
  State<OnMoimSettlementTargetSelectionPage> createState() =>
      _OnMoimSettlementTargetSelectionPageState();
}

class _OnMoimSettlementTargetSelectionPageState
    extends State<OnMoimSettlementTargetSelectionPage> {
  late final SettlementPaymentItem _item = _findItem(widget.itemId);
  late String _mode = _item.targetModeLabel;
  late final Set<String> _selectedNames = {
    for (final participant in _item.includedParticipants) participant.name,
  };

  SettlementPaymentItem _findItem(String itemId) {
    for (final item in demoSettlementSummary.paymentItems) {
      if (item.id == itemId) {
        return item;
      }
    }
    return demoSettlementSummary.paymentItems.first;
  }

  void _selectMode(String mode) {
    setState(() {
      _mode = mode;
      if (mode == '전체 참여자') {
        _selectedNames
          ..clear()
          ..addAll(_item.participants.map((participant) => participant.name));
      }
    });
  }

  void _toggleParticipant(String name) {
    if (_mode == '전체 참여자') {
      _selectMode('직접 선택');
    }

    setState(() {
      if (_selectedNames.contains(name)) {
        _selectedNames.remove(name);
        return;
      }
      _selectedNames.add(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedNames.length;

    return OnmuScaffold(
      title: '정산 대상자 선택',
      subtitle: '${_item.title} 비용을 함께 나눌 사람만 선택해요.',
      showBackButton: true,
      onBack: () => context.go(
        RoutePaths.planSettlementNew(widget.onmoimId, widget.meetupId),
      ),
      bottom: OnmuPrimaryButton(
        label: '이 항목 대상자 저장',
        icon: Icons.check_circle_outline,
        color: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        onPressed: () => context.go(
          RoutePaths.planSettlementNew(widget.onmoimId, widget.meetupId),
        ),
      ),
      children: [
        _TargetItemHeader(item: _item),
        const SizedBox(height: AppSpacing.lg),
        _TargetModeSegmentedControl(selected: _mode, onSelected: _selectMode),
        const SizedBox(height: AppSpacing.lg),
        _TargetSummaryCard(
          selectedCount: selectedCount,
          totalAmountLabel: _item.amountLabel,
          mode: _mode,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final participant in _item.participants) ...[
          _TargetParticipantRow(
            participant: participant,
            selected: _selectedNames.contains(participant.name),
            editableAmount: _mode == '금액 다르게',
            onTap: () => _toggleParticipant(participant.name),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        const SizedBox(height: AppSpacing.lg),
        _ItemTargetOverviewCard(items: demoSettlementSummary.paymentItems),
      ],
    );
  }
}

class _TargetItemHeader extends StatelessWidget {
  const _TargetItemHeader({required this.item});

  final SettlementPaymentItem item;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      borderColor: AppColors.lineWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primaryPink,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                item.amountLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primaryPink),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${item.payerLabel} 결제 · ${item.splitTypeLabel}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OnmuChip(label: item.targetModeLabel, selected: true),
              OnmuChip(label: '대상 ${item.targetLabel}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetModeSegmentedControl extends StatelessWidget {
  const _TargetModeSegmentedControl({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  static const _modes = ['전체 참여자', '직접 선택', '금액 다르게'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final mode in _modes) ...[
          Expanded(
            child: _TargetModeButton(
              label: mode,
              selected: selected == mode,
              onTap: () => onSelected(mode),
            ),
          ),
          if (mode != _modes.last) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _TargetModeButton extends StatelessWidget {
  const _TargetModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.linePink : AppColors.lineSoft,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.primaryPink : AppColors.textSub,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetSummaryCard extends StatelessWidget {
  const _TargetSummaryCard({
    required this.selectedCount,
    required this.totalAmountLabel,
    required this.mode,
  });

  final int selectedCount;
  final String totalAmountLabel;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '선택 $selectedCount명 · $mode',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Text(
            totalAmountLabel,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.primaryPink),
          ),
        ],
      ),
    );
  }
}

class _TargetParticipantRow extends StatelessWidget {
  const _TargetParticipantRow({
    required this.participant,
    required this.selected,
    required this.editableAmount,
    required this.onTap,
  });

  final SettlementPaymentParticipant participant;
  final bool selected;
  final bool editableAmount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amountLabel = selected ? participant.owedAmountLabel : '제외';

    return OnmuCard(
      onTap: onTap,
      backgroundColor: selected ? AppColors.bgPaper : AppColors.bgDefault,
      borderColor: selected ? AppColors.linePink : AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          PixelAvatar(label: participant.name, size: 36),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selected ? AppColors.textMain : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  selected ? '정산 대상 포함' : '이번 항목 제외',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          if (editableAmount && selected) ...[
            OnmuChip(label: amountLabel, icon: Icons.edit_outlined),
            const SizedBox(width: AppSpacing.xs),
          ] else ...[
            Text(
              amountLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.primaryPink : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? AppColors.primaryPink : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _ItemTargetOverviewCard extends StatelessWidget {
  const _ItemTargetOverviewCard({required this.items});

  final List<SettlementPaymentItem> items;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.primaryPinkSoft.withValues(alpha: 0.32),
      borderColor: AppColors.linePink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('항목별 구분 방식', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.title} · 대상 ${item.targetLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                OnmuChip(label: item.splitTypeLabel),
              ],
            ),
            if (item != items.last) const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
