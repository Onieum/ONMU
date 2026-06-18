import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class OnmuRemoveBadgeButton extends StatelessWidget {
  const OnmuRemoveBadgeButton({
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        minimumSize: const Size(24, 24),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      iconSize: 14,
      onPressed: onPressed,
      icon: const Icon(Icons.close),
    );
  }
}
