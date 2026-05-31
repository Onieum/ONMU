import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onchat_cards.dart';

class OnChatSettlementSharePage extends StatelessWidget {
  const OnChatSettlementSharePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settlement = demoSettlementSummary;

    return OnmuScaffold(
      title: '정산 공유',
      subtitle: '정산 메시지와 참여자별 입금 상태를 한 화면에서 확인합니다.',
      children: [
        OnmuCard(
          backgroundColor: AppColors.bgPurpleSoft,
          borderColor: AppColors.linePurple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settlement.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${settlement.totalAmountLabel} · 결제자 ${settlement.payer}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                settlement.shareMessage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final member in settlement.members) ...[
          SettlementStatusRow(member: member),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OnmuSecondaryButton(
                label: '대화로 이동',
                icon: Icons.chat_bubble_outline,
                onPressed: () => context.go(RoutePaths.onchatDemoChat),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OnmuPrimaryButton(
                label: '보드로 이동',
                icon: Icons.push_pin_outlined,
                onPressed: () => context.go(RoutePaths.onchatMeetupBoard),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
