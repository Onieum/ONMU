import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onchat_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onchat_cards.dart';

class OnChatListPage extends StatelessWidget {
  const OnChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '온챗',
      subtitle: '약속, 장소 후보, 추억, 정산을 친구 다이어리처럼 이어봅니다.',
      children: [
        const OnmuPaperHeader(
          title: '친구들이 남긴 새 메모',
          body: '새 메시지 3개와 진행 중인 장소 투표가 있어요.',
          stickerLabel: '온챗 알림',
          icon: Icons.chat_bubble_outline,
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
