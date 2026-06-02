import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_decorations.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class OnMoimMemoryBoardPage extends StatelessWidget {
  const OnMoimMemoryBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '추억 보드',
      subtitle: '대학 동기 여행단 · 우리가 함께한 순간들',
      useGridBackground: true,
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OnmuPrimaryButton(
            label: '기록 카드 만들기',
            icon: Icons.add_photo_alternate_outlined,
            color: AppColors.primaryPink,
            onPressed: () {},
          ),
        ),
      ),
      children: [
        const _MemoryFilters(),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.72,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final memory in demoOnMoimMemories)
              _MemoryCard(memory: memory),
          ],
        ),
      ],
    );
  }
}

class _MemoryFilters extends StatelessWidget {
  const _MemoryFilters();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const OnmuPixelBuddy(size: 56),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '대학 동기 여행단',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '사진 18장 · 기록 7개',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton.outlined(
              tooltip: '필터',
              onPressed: () {},
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: const [
            OnmuChip(label: '전체', icon: Icons.favorite, selected: true),
            OnmuChip(label: '사진', icon: Icons.image_outlined),
            OnmuChip(label: '기록', icon: Icons.edit_outlined),
            OnmuChip(label: '링크', icon: Icons.link),
          ],
        ),
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory});

  final OnMoimMemoryRecord memory;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgPaper,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnmuTape(width: 62),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bgDefault,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lineSoft),
              ),
              child: const Center(
                child: Icon(
                  Icons.photo_outlined,
                  size: 38,
                  color: AppColors.primaryPink,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(memory.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            memory.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          OnmuChip(label: memory.tags.first, selected: true),
        ],
      ),
    );
  }
}
