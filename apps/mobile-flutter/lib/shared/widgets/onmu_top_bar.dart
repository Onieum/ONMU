import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class OnmuTopBar extends StatelessWidget {
  const OnmuTopBar({
    required this.title,
    this.showBackButton = false,
    this.onBack,
    this.action,
    super.key,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 8),
          SizedBox.square(
            dimension: 48,
            child: showBackButton
                ? IconButton(
                    tooltip: '뒤로',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textMain,
                      backgroundColor: AppColors.bgWarm,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SizedBox.square(dimension: 48, child: action),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
