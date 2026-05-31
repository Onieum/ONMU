import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onchat_cards.dart';

class OnChatSettlementCreatePage extends StatelessWidget {
  const OnChatSettlementCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settlement = demoSettlementSummary;

    return OnmuScaffold(
      title: '정산 만들기',
      subtitle: '결제자, 금액, 정산 대상자를 고르는 mock 입력 화면입니다.',
      children: [
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('정산 정보', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                decoration: InputDecoration(
                  labelText: '정산 제목',
                  hintText: settlement.title,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                decoration: InputDecoration(
                  labelText: '총 금액',
                  hintText: settlement.totalAmountLabel,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('대상자', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final member in settlement.members)
                    OnmuChip(
                      label: member.name,
                      selected: member.name != settlement.payer,
                    ),
                ],
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
        OnmuPrimaryButton(
          label: '정산 공유 화면 보기',
          icon: Icons.send_outlined,
          onPressed: () => context.go(RoutePaths.settlementShare),
        ),
      ],
    );
  }
}
