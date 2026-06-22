import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/onmu_exception.dart';
import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/models/group_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../settlement/repository/settlement_repository.dart';
import '../../../settlement/view_model/settlement_view_model.dart';
import 'plan_settlement_detail_page.dart';

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
    final draftProvider = settlementDraftViewModelProvider((
      groupId: groupId,
      planId: planId,
    ));
    final state = ref.watch(draftProvider);
    final members = ref.watch(
      settlementDraftParticipantsProvider((groupId: groupId, planId: planId)),
    );

    return state.when(
      data: (settlement) {
        if (!settlement.isDraft) {
          return PlanSettlementDetailPage(
            groupId: groupId,
            planId: planId,
            settlementId: settlement.id,
          );
        }
        return _SettlementCreateContent(
          groupId: groupId,
          planId: planId,
          settlement: settlement,
          members: members.asData?.value ?? const [],
          onAddItem: (input) => ref
              .read(
                settlementDraftViewModelProvider((
                  groupId: groupId,
                  planId: planId,
                )).notifier,
              )
              .addDraftItem(input),
          onSectionPayerChanged: (sectionId, payer) => ref
              .read(
                settlementDraftViewModelProvider((
                  groupId: groupId,
                  planId: planId,
                )).notifier,
              )
              .updateSectionPayer(
                sectionId: sectionId,
                payerUserId: payer.userId,
              ),
        );
      },
      loading: () => const OnmuScaffold(
        title: '약속 정산 만들기',
        children: [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: '약속 정산 만들기',
        children: [
          Text(
            _settlementDraftLoadMessage(error),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          OnmuSecondaryButton(
            label: '다시 시도',
            icon: Icons.refresh_rounded,
            onPressed: () => ref.invalidate(draftProvider),
          ),
        ],
      ),
    );
  }
}

String _settlementDraftLoadMessage(Object error) {
  if (error is OnmuApiException) {
    final reason = error.serverReason.toLowerCase();
    if (reason.contains('settlement_plan_not_eligible')) {
      return '아직 시작 전인 약속은 정산을 만들 수 없어요.';
    }
    if (reason.contains('settlement_participant_not_found')) {
      return '이 약속에 참여 중인 멤버만 정산을 만들 수 있어요.';
    }
    if (reason.contains('plan_not_found')) {
      return '약속 정보를 찾을 수 없어요.';
    }
    if (reason.contains('not_group_member')) {
      return '이 모임의 멤버만 정산을 만들 수 있어요.';
    }
    return error.userMessage;
  }
  return '정산 정보를 불러오지 못했어요.';
}

class _SettlementCreateContent extends StatelessWidget {
  const _SettlementCreateContent({
    required this.groupId,
    required this.planId,
    required this.settlement,
    required this.members,
    required this.onAddItem,
    required this.onSectionPayerChanged,
  });

  final String groupId;
  final String planId;
  final SettlementSummary settlement;
  final List<GroupMemberProfile> members;
  final Future<void> Function(SettlementDraftItemInput input) onAddItem;
  final Future<void> Function(Object sectionId, GroupMemberProfile payer)
  onSectionPayerChanged;

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
        onPressed: settlement.paymentItems.isEmpty
            ? null
            : () =>
                  context.go(RoutePaths.planSettlementPreview(groupId, planId)),
      ),
      children: [
        _SettlementScopeCard(
          settlement: settlement,
          participantCount: members.length,
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SettlementStepStrip(activeIndex: 0),
        const SizedBox(height: AppSpacing.xl),
        _SectionHeader(
          title: '결제 항목',
          trailing: '${settlement.paymentItems.length}개',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (settlement.sections.isNotEmpty)
          for (final section in settlement.sections) ...[
            _SettlementSectionCard(
              section: section,
              members: members,
              onAddItem: onAddItem,
              onPayerChanged: (payer) =>
                  onSectionPayerChanged(section.id, payer),
              itemBuilder: (item) => _PaymentItemSummaryCard(
                item: item,
                onTap: () => context.push(
                  RoutePaths.planSettlementTargets(groupId, planId, item.id),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ]
        else ...[
          for (final item in settlement.paymentItems) ...[
            _PaymentItemSummaryCard(
              item: item,
              onTap: () => context.push(
                RoutePaths.planSettlementTargets(groupId, planId, item.id),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _AddPaymentItemCard(members: members, onAddItem: onAddItem),
        ],
        const SizedBox(height: AppSpacing.lg),
        const _SettlementGuideCard(),
      ],
    );
  }
}

class _SettlementSectionCard extends StatelessWidget {
  const _SettlementSectionCard({
    required this.section,
    required this.members,
    required this.onAddItem,
    required this.onPayerChanged,
    required this.itemBuilder,
  });

  final SettlementSection section;
  final List<GroupMemberProfile> members;
  final Future<void> Function(SettlementDraftItemInput input) onAddItem;
  final Future<void> Function(GroupMemberProfile payer) onPayerChanged;
  final Widget Function(SettlementPaymentItem item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                section.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _SectionPayerSelector(
              section: section,
              members: members,
              onChanged: onPayerChanged,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (section.items.isEmpty)
          OnmuCard(
            backgroundColor: AppColors.bgPaper,
            borderColor: AppColors.lineSoft,
            child: Text(
              '아직 입력한 비용이 없어요.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
          )
        else
          for (final item in section.items) ...[
            itemBuilder(item),
            if (item != section.items.last)
              const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.sm),
        _AddPaymentItemCard(
          members: members,
          onAddItem: onAddItem,
          section: section,
        ),
      ],
    );
  }
}

class _SettlementScopeCard extends StatelessWidget {
  const _SettlementScopeCard({
    required this.settlement,
    required this.participantCount,
  });

  final SettlementSummary settlement;
  final int participantCount;

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
                      _subtitle(),
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
          Text(
            '${settlement.itemCountLabel} · 장소별 결제자와 항목별 대상자를 기준으로 계산해요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    final dateLabel = settlement.createdDateLabel.replaceFirst('정산일 ', '');
    if (participantCount <= 0) {
      return dateLabel;
    }
    return '$dateLabel · 참여자 $participantCount명';
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

class _SectionPayerSelector extends StatelessWidget {
  const _SectionPayerSelector({
    required this.section,
    required this.members,
    required this.onChanged,
  });

  final SettlementSection section;
  final List<GroupMemberProfile> members;
  final Future<void> Function(GroupMemberProfile payer) onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedPayer();
    final label = selected?.name.trim().isNotEmpty == true
        ? selected!.name
        : section.payerName;
    if (members.isEmpty) {
      return OnmuChip(label: '$label 결제');
    }

    return PopupMenuButton<GroupMemberProfile>(
      tooltip: '결제자 변경',
      onSelected: (member) async {
        if (member.userId == section.payerUserId) {
          return;
        }
        try {
          await onChanged(member);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('결제자를 변경했어요.')));
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('결제자 변경에 실패했어요.')));
          }
        }
      },
      itemBuilder: (context) => [
        for (final member in members)
          PopupMenuItem<GroupMemberProfile>(
            value: member,
            child: Row(
              children: [
                if (member.userId == section.payerUserId) ...[
                  const Icon(
                    Icons.check,
                    size: 18,
                    color: AppColors.primaryPink,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(child: Text(member.name)),
              ],
            ),
          ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bgDefault,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.lineWarm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 16,
                color: AppColors.textSub,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(width: AppSpacing.xxs),
              const Icon(
                Icons.expand_more,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  GroupMemberProfile? _selectedPayer() {
    for (final member in members) {
      if (member.userId == section.payerUserId) {
        return member;
      }
    }
    return null;
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
  const _AddPaymentItemCard({
    required this.members,
    required this.onAddItem,
    this.section,
  });

  final List<GroupMemberProfile> members;
  final Future<void> Function(SettlementDraftItemInput input) onAddItem;
  final SettlementSection? section;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: TextButton.icon(
        onPressed: members.isEmpty ? null : () => _showAddItemDialog(context),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('결제 항목 추가'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          minimumSize: const Size.fromHeight(44),
        ),
      ),
    );
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    final payer = _sectionPayer();
    if (payer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약속 참여자를 불러온 뒤 다시 시도해 주세요.')),
      );
      return;
    }
    final input = await showDialog<SettlementDraftItemInput>(
      context: context,
      builder: (dialogContext) =>
          _AddSettlementItemDialog(members: members, payer: payer),
    );
    if (input == null || !context.mounted) {
      return;
    }
    try {
      await onAddItem(_attachSection(input));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('정산 항목을 저장했어요.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_addItemFailureMessage(error))));
      }
    }
  }

  GroupMemberProfile? _sectionPayer() {
    final sectionPayerId = section?.payerUserId.trim() ?? '';
    if (sectionPayerId.isNotEmpty) {
      for (final member in members) {
        if (member.userId == sectionPayerId) {
          return member;
        }
      }
    }
    return members.isEmpty ? null : members.first;
  }

  String _addItemFailureMessage(Object error) {
    if (error is OnmuApiException) {
      final reason = error.serverReason.toLowerCase();
      if (reason.contains('settlement_participant_not_found')) {
        return '약속 참여자만 정산에 포함할 수 있어요.';
      }
      if (reason.contains('invalid_settlement_amount')) {
        return '1원 이상의 금액을 입력해 주세요.';
      }
      if (reason.contains('missing_settlement_targets')) {
        return '정산 대상을 한 명 이상 선택해 주세요.';
      }
      return error.userMessage;
    }
    return '정산 항목 저장에 실패했어요.';
  }

  SettlementDraftItemInput _attachSection(SettlementDraftItemInput input) {
    final targetSection = section;
    if (targetSection == null) {
      return input;
    }
    return SettlementDraftItemInput(
      id: input.id,
      sectionId: targetSection.id,
      sectionTitle: targetSection.title,
      schedulePlaceId: targetSection.schedulePlaceId,
      title: input.title,
      amount: input.amount,
      payerUserId: input.payerUserId,
      payerName: input.payerName,
      splitType: input.splitType,
      targetUserIds: input.targetUserIds,
      targetNames: input.targetNames,
    );
  }
}

class _AddSettlementItemDialog extends StatefulWidget {
  const _AddSettlementItemDialog({required this.members, required this.payer});

  final List<GroupMemberProfile> members;
  final GroupMemberProfile payer;

  @override
  State<_AddSettlementItemDialog> createState() =>
      _AddSettlementItemDialogState();
}

class _AddSettlementItemDialogState extends State<_AddSettlementItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late final Set<String> _targetKeys;

  @override
  void initState() {
    super.initState();
    _targetKeys = widget.members.map(_memberKey).toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('결제 항목 추가'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '항목 이름'),
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? '항목 이름을 입력해 주세요.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: '금액'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = _amountFrom(value);
                  if (amount == null || amount <= 0) {
                    return '1원 이상의 금액을 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '정산 대상',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final member in widget.members)
                CheckboxListTile(
                  value: _targetKeys.contains(_memberKey(member)),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _targetKeys.add(_memberKey(member));
                        return;
                      }
                      _targetKeys.remove(_memberKey(member));
                    });
                  },
                  title: Text(member.name),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final targets = widget.members
        .where((member) => _targetKeys.contains(_memberKey(member)))
        .toList(growable: false);
    if (targets.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정산 대상을 한 명 이상 선택해 주세요.')));
      return;
    }
    Navigator.of(context).pop(
      SettlementDraftItemInput(
        title: _titleController.text.trim(),
        amount: _amountFrom(_amountController.text) ?? 0,
        payerUserId: widget.payer.userId,
        payerName: widget.payer.name,
        splitType: targets.length == widget.members.length
            ? SettlementSplitType.equal
            : SettlementSplitType.custom,
        targetUserIds: targets.map((member) => member.userId).toList(),
        targetNames: targets.map((member) => member.name).toList(),
      ),
    );
  }

  String _memberKey(GroupMemberProfile member) {
    return member.userId.isNotEmpty ? member.userId : 'name:${member.name}';
  }

  int? _amountFrom(String? value) {
    if (value == null) {
      return null;
    }
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
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
