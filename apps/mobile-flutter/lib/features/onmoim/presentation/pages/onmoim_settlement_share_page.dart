import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
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
      subtitle: '이 약속의 총액, N분의 1, 입금 상태를 확인합니다.',
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OnmuPrimaryButton(
            label: '약속 상세로 돌아가기',
            icon: Icons.event_note_outlined,
            color: AppColors.primaryPink,
            onPressed: () =>
                context.go(RoutePaths.onmoimMeetupDetail(onmoimId, meetupId)),
          ),
        ),
      ),
      children: [
        _TotalAmountCard(settlement: settlement),
        const SizedBox(height: AppSpacing.md),
        _SplitSummaryCard(settlement: settlement),
        const SizedBox(height: AppSpacing.md),
        for (final member in settlement.members) ...[
          SettlementStatusRow(member: member),
          const SizedBox(height: AppSpacing.sm),
        ],
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
                      settlement.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      settlement.totalAmountLabel,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      settlement.dueDateLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const OnmuPixelBuddy(size: 70),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '결제자\n${settlement.payer}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitSummaryCard extends StatelessWidget {
  const _SplitSummaryCard({required this.settlement});

  final SettlementSummary settlement;

  @override
  Widget build(BuildContext context) {
    final paidCount = settlement.members
        .where((member) => member.isPaid)
        .length;
    final unpaidCount = settlement.members.length - paidCount;

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('N분의 1 정산', style: Theme.of(context).textTheme.titleMedium),
              Text(
                '완료 $paidCount명 / 미완료 $unpaidCount명',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.accentBrown),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '1인당 금액 31,000원',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.primaryPink),
          ),
        ],
      ),
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
          OnmuCard(
            backgroundColor: AppColors.bgDefault,
            borderColor: AppColors.lineSoft,
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
