import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class OnmuTopBar extends StatelessWidget {
  const OnmuTopBar({
    required this.title,
    this.showBackButton = false,
    this.onBack,
    this.action,
    this.subtitle,
    super.key,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? action;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    const sideWidth = 104.0;

    return SizedBox(
      height: subtitle == null ? 56 : 76,
      child: Row(
        children: [
          SizedBox(
            width: sideWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox.square(
                dimension: 44,
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
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  subtitle!,
                ],
              ],
            ),
          ),
          SizedBox(
            width: sideWidth,
            child: Align(alignment: Alignment.centerRight, child: action),
          ),
        ],
      ),
    );
  }
}
