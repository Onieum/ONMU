import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onchat_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class OnChatMemoryBoardPage extends StatelessWidget {
  const OnChatMemoryBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '온챗 추억 보드',
      subtitle: '같은 온챗 멤버와 남긴 OOTD와 기억을 스크랩북처럼 모아봅니다.',
      useGridBackground: true,
      children: [
        for (final memory in demoOnChatMemories) ...[
          OnmuCard(
            backgroundColor: AppColors.bgPaper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OnmuTape(width: 74),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_stories_outlined,
                      color: AppColors.primaryPink,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        memory.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      memory.dateLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  memory.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in memory.tags)
                      OnmuChip(label: tag, selected: tag == 'OOTD'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
