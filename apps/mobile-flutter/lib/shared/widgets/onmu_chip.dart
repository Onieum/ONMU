import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class OnmuChip extends StatelessWidget {
  const OnmuChip({
    required this.label,
    this.selected = false,
    this.icon,
    this.color,
    super.key,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primaryPurple;
    final hasCustomColor = color != null;
    final backgroundColor = selected
        ? AppColors.primaryPurpleSoft
        : hasCustomColor
        ? activeColor.withValues(alpha: 0.14)
        : AppColors.bgDefault;
    final borderColor = selected
        ? AppColors.linePurple
        : hasCustomColor
        ? activeColor.withValues(alpha: 0.62)
        : AppColors.lineSoft;
    final foregroundColor = (selected || hasCustomColor)
        ? activeColor
        : AppColors.textSub;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor),
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
              Icon(icon, size: 15, color: foregroundColor),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: foregroundColor),
            ),
          ],
        ),
      ),
    );
  }
}
