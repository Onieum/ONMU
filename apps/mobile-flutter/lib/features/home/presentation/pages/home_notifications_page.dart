import 'package:flutter/material.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

class HomeNotificationsPage extends StatelessWidget {
  const HomeNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '알림',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.home),
      children: const [_EmptyNotificationState()],
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('알림이 없어요.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '서버에서 알림 데이터를 받으면 이곳에 표시돼요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
