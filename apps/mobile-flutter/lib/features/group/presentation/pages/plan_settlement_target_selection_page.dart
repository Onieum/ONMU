import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../../settlement/view_model/settlement_view_model.dart';

class PlanSettlementTargetSelectionPage extends StatefulWidget {
  const PlanSettlementTargetSelectionPage({
    required this.groupId,
    required this.planId,
    required this.itemId,
    super.key,
  });

  final String groupId;
  final String planId;
  final String itemId;

  @override
  State<PlanSettlementTargetSelectionPage> createState() =>
      _PlanSettlementTargetSelectionPageState();
}

class _PlanSettlementTargetSelectionPageState
    extends State<PlanSettlementTargetSelectionPage> {
  String? _mode;
  final Set<String> _selectedNames = {};

  void _selectMode(String mode, SettlementPaymentItem item) {
    setState(() {
      _mode = mode;
      if (mode == '전체 참여자') {
        _selectedNames
          ..clear()
          ..addAll(item.participants.map((participant) => participant.name));
      }
    });
  }

  void _toggleParticipant(String name, SettlementPaymentItem item) {
    if (_mode == '전체 참여자') {
      _selectMode('직접 선택', item);
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
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(
          settlementViewModelProvider((
            groupId: widget.groupId,
            planId: widget.planId,
          )),
        );

        return state.when(
          data: (settlement) {
            if (settlement.paymentItems.isEmpty) {
              return OnmuScaffold(
                title: '정산 대상 선택',
                showBackButton: true,
                onBack: () => context.popOrGo(
                  RoutePaths.planSettlementNew(widget.groupId, widget.planId),
                ),
                children: [
                  Text(
                    '선택할 정산 항목이 없어요.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
            }

            final item = _findPaymentItem(
              settlement.paymentItems,
              widget.itemId,
            );
            _mode ??= item.targetModeLabel;
            if (_selectedNames.isEmpty) {
              _selectedNames.addAll(
                item.includedParticipants.map(
                  (participant) => participant.name,
                ),
              );
            }

            return _SettlementTargetContent(
              groupId: widget.groupId,
              planId: widget.planId,
              item: item,
              items: settlement.paymentItems,
              mode: _mode!,
              selectedNames: _selectedNames,
              onModeSelected: (mode) => _selectMode(mode, item),
              onParticipantSelected: (name) => _toggleParticipant(name, item),
            );
          },
          loading: () => const OnmuScaffold(
            title: '정산 대상자 선택',
            children: [Center(child: CircularProgressIndicator())],
          ),
          error: (error, stackTrace) => OnmuScaffold(
            title: '정산 대상자 선택',
            children: [
              Text(
                '정산 대상자 정보를 불러오지 못했어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  SettlementPaymentItem _findPaymentItem(
    List<SettlementPaymentItem> items,
    String itemId,
  ) {
    for (final item in items) {
      if (item.id.toString() == itemId) {
        return item;
      }
    }
    return items.first;
  }
}

class _SettlementTargetContent extends StatelessWidget {
  const _SettlementTargetContent({
    required this.groupId,
    required this.planId,
    required this.item,
    required this.items,
    required this.mode,
    required this.selectedNames,
    required this.onModeSelected,
    required this.onParticipantSelected,
  });

  final String groupId;
  final String planId;
  final SettlementPaymentItem item;
  final List<SettlementPaymentItem> items;
  final String mode;
  final Set<String> selectedNames;
  final ValueChanged<String> onModeSelected;
  final ValueChanged<String> onParticipantSelected;

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedNames.length;

    return OnmuScaffold(
      title: '정산 대상자 선택',
      subtitle: '${item.title} 비용을 함께 나눌 사람만 선택해요.',
      showBackButton: true,
      onBack: () =>
          context.popOrGo(RoutePaths.planSettlementNew(groupId, planId)),
      bottom: OnmuPrimaryButton(
        label: '이 항목 대상자 저장',
        icon: Icons.check_circle_outline,
        color: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        onPressed: () =>
            context.popOrGo(RoutePaths.planSettlementNew(groupId, planId)),
      ),
      children: [
        _TargetItemHeader(item: item),
        const SizedBox(height: AppSpacing.lg),
        _TargetModeSegmentedControl(selected: mode, onSelected: onModeSelected),
        const SizedBox(height: AppSpacing.lg),
        _TargetSummaryCard(
          selectedCount: selectedCount,
          totalAmountLabel: item.amountLabel,
          mode: mode,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final participant in item.participants) ...[
          _TargetParticipantRow(
            participant: participant,
            selected: selectedNames.contains(participant.name),
            editableAmount: mode == '금액 다르게',
            onTap: () => onParticipantSelected(participant.name),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        const SizedBox(height: AppSpacing.lg),
        _ItemTargetOverviewCard(items: items),
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

  List<String> _createModes() => ['전체 참여자', '직접 선택', '금액 다르게'];

  @override
  Widget build(BuildContext context) {
    final modes = _createModes();

    return Row(
      children: [
        for (final mode in modes) ...[
          Expanded(
            child: _TargetModeButton(
              label: mode,
              selected: selected == mode,
              onTap: () => onSelected(mode),
            ),
          ),
          if (mode != modes.last) const SizedBox(width: AppSpacing.xs),
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
          PixelAvatar(
            label: participant.name,
            size: 36,
            profileImageUrl: participant.profileImageUrl,
          ),
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
