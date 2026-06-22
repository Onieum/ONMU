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
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../../settlement/view_model/settlement_view_model.dart';

class PlanSettlementDetailPage extends ConsumerWidget {
  const PlanSettlementDetailPage({
    required this.groupId,
    required this.planId,
    super.key,
    this.preview = false,
    this.settlementId,
  });

  final String groupId;
  final String planId;
  final bool preview;
  final String? settlementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = (groupId: groupId, planId: planId);
    final id = settlementId;
    final state = preview
        ? ref.watch(settlementDraftViewModelProvider(scope))
        : id == null
        ? ref.watch(settlementViewModelProvider(scope))
        : ref.watch(
            settlementByIdViewModelProvider((
              groupId: groupId,
              planId: planId,
              settlementId: id,
            )),
          );

    return state.when(
      data: (settlement) => _SettlementShareContent(
        groupId: groupId,
        planId: planId,
        preview: preview,
        settlement: settlement,
        onCreate: preview
            ? () => ref
                  .read(settlementDraftViewModelProvider(scope).notifier)
                  .createCurrentDraft()
            : null,
        onMarkSent: !preview && id != null
            ? (transferId) => ref
                  .read(
                    settlementByIdViewModelProvider((
                      groupId: groupId,
                      planId: planId,
                      settlementId: id,
                    )).notifier,
                  )
                  .markTransferSent(transferId)
            : null,
        onMarkReceived: !preview && id != null
            ? (transferId) => ref
                  .read(
                    settlementByIdViewModelProvider((
                      groupId: groupId,
                      planId: planId,
                      settlementId: id,
                    )).notifier,
                  )
                  .markTransferReceived(transferId)
            : null,
      ),
      loading: () => OnmuScaffold(
        title: preview ? '정산 미리보기' : '약속 정산',
        children: const [Center(child: CircularProgressIndicator())],
      ),
      error: (error, stackTrace) => OnmuScaffold(
        title: preview ? '정산 미리보기' : '약속 정산',
        children: [
          Text(
            '정산 결과를 불러오지 못했어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SettlementShareContent extends StatelessWidget {
  const _SettlementShareContent({
    required this.groupId,
    required this.planId,
    required this.preview,
    required this.settlement,
    this.onCreate,
    this.onMarkSent,
    this.onMarkReceived,
  });

  final String groupId;
  final String planId;
  final bool preview;
  final SettlementSummary settlement;
  final Future<SettlementSummary> Function()? onCreate;
  final Future<void> Function(String transferId)? onMarkSent;
  final Future<void> Function(String transferId)? onMarkReceived;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: preview ? '정산 미리보기' : '약속 정산',
      subtitle: preview
          ? '만들기 전에 최종 송금 방향만 가볍게 확인해요.'
          : '${settlement.planTitle} 정산 결과를 확인해요.',
      showBackButton: true,
      onBack: () => context.popOrGo(
        preview
            ? RoutePaths.planSettlementNew(groupId, planId)
            : RoutePaths.planDetail(groupId, planId),
      ),
      bottom: _buildBottomActions(context),
      children: [
        _SettlementHeaderCard(settlement: settlement, preview: preview),
        const SizedBox(height: AppSpacing.md),
        if (settlement.participantStatuses.isNotEmpty) ...[
          _ParticipantStatusGrid(statuses: settlement.participantStatuses),
          const SizedBox(height: AppSpacing.md),
        ],
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

  Widget _buildBottomActions(BuildContext context) {
    if (preview) {
      return Row(
        children: [
          Expanded(
            child: OnmuSecondaryButton(
              label: '정산 수정',
              icon: Icons.edit_outlined,
              onPressed: () =>
                  context.push(RoutePaths.planSettlementNew(groupId, planId)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OnmuPrimaryButton(
              label: '정산 만들기',
              icon: Icons.check_circle_outline,
              color: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              onPressed: () => _createSettlement(context),
            ),
          ),
        ],
      );
    }

    final action = _currentAction();
    return Row(
      children: [
        Expanded(
          child: OnmuSecondaryButton(
            label: '정산 근거',
            icon: Icons.fact_check_outlined,
            onPressed: settlement.id.isEmpty
                ? null
                : () => context.push(
                    RoutePaths.planSettlementBasis(
                      groupId,
                      planId,
                      settlement.id,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OnmuPrimaryButton(
            label: action?.label ?? '약속 상세',
            icon: action?.icon ?? Icons.event_note_outlined,
            color: AppColors.primaryPink,
            foregroundColor: AppColors.textInverse,
            onPressed: action == null
                ? () => context.go(RoutePaths.planDetail(groupId, planId))
                : () => _confirmTransferAction(context, action),
          ),
        ),
      ],
    );
  }

  _TransferAction? _currentAction() {
    final currentUserId = _currentUserId();
    if (currentUserId.isEmpty || settlement.isCompleted) {
      return null;
    }
    for (final transfer in settlement.transfers) {
      if (transfer.fromUserId == currentUserId && !transfer.sent) {
        final markSent = onMarkSent;
        if (markSent == null || transfer.id.isEmpty) {
          continue;
        }
        return _TransferAction(
          label: '송금 완료 알리기',
          icon: Icons.outgoing_mail,
          transferId: transfer.id,
          submit: markSent,
        );
      }
      if (transfer.toUserId == currentUserId && !transfer.received) {
        final markReceived = onMarkReceived;
        if (markReceived == null || transfer.id.isEmpty) {
          continue;
        }
        return _TransferAction(
          label: '수취 완료하기',
          icon: Icons.check_circle_outline,
          transferId: transfer.id,
          submit: markReceived,
        );
      }
    }
    return null;
  }

  String _currentUserId() {
    for (final result in settlement.memberResults) {
      if (result.isMe) {
        return result.userId;
      }
    }
    return '';
  }

  Future<void> _confirmTransferAction(
    BuildContext context,
    _TransferAction action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('정말로 정산을 완료하셨나요?'),
        content: const Text('확인 후에는 이 상태를 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await action.submit(action.transferId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('정산 상태를 반영했어요.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('정산 상태 반영에 실패했어요.')));
      }
    }
  }

  Future<void> _createSettlement(BuildContext context) async {
    final create = onCreate;
    if (create == null) {
      return;
    }
    try {
      final created = await create();
      if (context.mounted) {
        context.go(
          RoutePaths.planSettlementDetail(groupId, planId, created.id),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('정산 만들기에 실패했어요.')));
      }
    }
  }
}

class _TransferAction {
  const _TransferAction({
    required this.label,
    required this.icon,
    required this.transferId,
    required this.submit,
  });

  final String label;
  final IconData icon;
  final String transferId;
  final Future<void> Function(String transferId) submit;
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
                      settlement.planTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${settlement.itemCountLabel} · ${settlement.displayFinalSummaryLabel}',
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
              _MiniSummaryTile(
                label: '결제 항목',
                value: '${settlement.paymentItems.length}개',
              ),
              const SizedBox(width: AppSpacing.xs),
              _MiniSummaryTile(
                label: '송금',
                value: '${settlement.transfers.length}건',
              ),
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

class _ParticipantStatusGrid extends StatelessWidget {
  const _ParticipantStatusGrid({required this.statuses});

  final List<SettlementParticipantStatus> statuses;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('참여자 정산 상태', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: statuses.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisExtent: 82,
            ),
            itemBuilder: (context, index) {
              final status = statuses[index];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PixelAvatar(
                        label: status.name,
                        size: 44,
                        profileImageUrl: status.profileImageUrl,
                      ),
                      if (status.willReceive)
                        const Positioned(
                          top: -6,
                          left: -4,
                          child: Icon(
                            Icons.workspace_premium,
                            color: AppColors.accentOrange,
                            size: 20,
                          ),
                        ),
                      if (status.completed)
                        const Positioned(
                          right: -4,
                          bottom: -2,
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.accentGreen,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    status.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MyResultCompactCard extends StatelessWidget {
  const _MyResultCompactCard({required this.settlement});

  final SettlementSummary settlement;

  @override
  Widget build(BuildContext context) {
    final myResult = _findMyResult(settlement.memberResults);
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
              _MiniSummaryTile(
                label: '부담',
                value: myResult?.finalShareLabel ?? '-',
              ),
              const SizedBox(width: AppSpacing.xs),
              _MiniSummaryTile(
                label: '결제',
                value: myResult?.paidAmountLabel ?? '-',
              ),
              const SizedBox(width: AppSpacing.xs),
              _MiniSummaryTile(
                label: '결과',
                value: myResult?.resultLabel ?? '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  SettlementMemberResult? _findMyResult(List<SettlementMemberResult> results) {
    for (final result in results) {
      if (result.isMe) {
        return result;
      }
    }
    return null;
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
        PixelAvatar(
          label: transfer.fromName,
          size: 30,
          profileImageUrl: transfer.fromProfileImageUrl,
        ),
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
                PixelAvatar(
                  label: result.name,
                  size: 30,
                  profileImageUrl: result.profileImageUrl,
                ),
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
