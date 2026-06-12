import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class OnmuLocationSubtitle extends StatelessWidget {
  const OnmuLocationSubtitle({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 16,
          color: AppColors.textSub,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
          ),
        ),
      ],
    );
  }
}
