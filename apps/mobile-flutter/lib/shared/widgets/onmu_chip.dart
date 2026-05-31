import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class OnmuChip extends StatelessWidget {
  const OnmuChip({
    required this.label,
    super.key,
    this.icon,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(
          color: selected ? AppColors.linePink : AppColors.lineBrown,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: AppColors.primaryPink),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
