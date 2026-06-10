import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class HomeRecentRecordsPage extends StatelessWidget {
  const HomeRecentRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '최근 기록',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.home),
      children: [
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.lineSoft,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '최근 기록이 없어요.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '서버에서 기록 데이터를 받으면 이곳에 표시돼요.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () => context.push(RoutePaths.records),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('기록 카드 만들기'),
        ),
      ],
    );
  }
}
