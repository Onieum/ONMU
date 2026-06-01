import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/settlement_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onmoim_cards.dart';

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
      title: '정산 만들기',
      subtitle: '이 약속에서 쓴 비용만 정산 메모로 차분히 정리합니다.',
      children: [
        OnmuCard(
          backgroundColor: AppColors.bgPaper,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnmuStickerLabel(label: '정산 정보', icon: Icons.receipt_long),
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
              const OnmuStickerLabel(label: '대상자', icon: Icons.group_outlined),
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
          onPressed: () => context.go(
            RoutePaths.onmoimMeetupSettlementShare(
              onmoimId,
              meetupId,
              settlement.id,
            ),
          ),
        ),
      ],
    );
  }
}
