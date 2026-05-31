import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onchat_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onchat_cards.dart';

class OnChatListPage extends StatelessWidget {
  const OnChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '온챗',
      subtitle: '약속과 장소 후보, 추억, 정산을 대화방 안에서 이어보는 플로우입니다.',
      children: [
        OnmuCard(
          backgroundColor: AppColors.bgPurpleSoft,
          borderColor: AppColors.linePurple,
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '새 메시지 3개와 진행 중인 장소 투표가 있어요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final group in demoOnChatGroups) ...[
          OnChatGroupCard(
            group: group,
            onTap: () => context.go(RoutePaths.onchatDemoGroup),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        OnmuPrimaryButton(
          label: '성수 온챗 열기',
          icon: Icons.arrow_forward,
          onPressed: () => context.go(RoutePaths.onchatDemoGroup),
        ),
      ],
    );
  }
}
