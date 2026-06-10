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
    this.color,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primaryPink;
    final hasCustomColor = color != null;
    final backgroundColor = selected
        ? AppColors.primaryPinkSoft
        : hasCustomColor
        ? activeColor.withValues(alpha: 0.14)
        : AppColors.bgDefault;
    final borderColor = selected
        ? AppColors.linePink
        : hasCustomColor
        ? activeColor.withValues(alpha: 0.62)
        : AppColors.lineBrown;
    final foregroundColor = selected || hasCustomColor
        ? activeColor
        : AppColors.textSub;

    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xs),
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

    if (onTap == null) {
      return chip;
    }

    return GestureDetector(onTap: onTap, child: chip);
  }
}
