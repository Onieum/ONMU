import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onchat_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../widgets/onchat_cards.dart';

class OnChatThreadPage extends StatelessWidget {
  const OnChatThreadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '온챗 대화',
      subtitle: '실제 WebSocket 없이 메시지 목록과 입력 UI만 보여줍니다.',
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: AppSpacing.xs),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '메시지를 입력해보세요',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '전송',
                  onPressed: () {},
                  icon: const Icon(Icons.send_outlined),
                ),
              ],
            ),
          ),
        ),
      ),
      children: [
        PinnedMeetupCard(
          meetup: demoPinnedMeetup,
          onBoardPressed: () => context.go(RoutePaths.onchatMeetupBoard),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final message in demoOnChatMessages) ...[
          ChatMessageBubble(message: message),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        OnmuCard(
          backgroundColor: AppColors.bgPurpleSoft,
          borderColor: AppColors.linePurple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ONMU 추천 카드', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '장소 후보를 투표 보드에 올리고 대화 흐름 안에서 바로 비교할 수 있어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              OnmuPrimaryButton(
                label: '투표 보드 보기',
                icon: Icons.how_to_vote_outlined,
                onPressed: () => context.go(RoutePaths.onchatMeetupBoard),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
