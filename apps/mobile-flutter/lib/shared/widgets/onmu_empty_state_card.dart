import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'onmu_card.dart';

class OnmuEmptyStateCard extends StatelessWidget {
  const OnmuEmptyStateCard({
    required this.title,
    super.key,
    this.description,
    this.icon,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final String title;
  final String? description;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final hasDetail = icon != null || description != null;

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            title,
            style: hasDetail
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
          ],
        ],
      ),
    );
  }
}
