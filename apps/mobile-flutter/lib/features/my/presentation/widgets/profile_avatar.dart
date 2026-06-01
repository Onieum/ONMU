import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({this.size = 76, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '나의 아바타',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.bgGrid,
          border: Border.all(color: AppColors.lineBrown, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.face_retouching_natural,
              size: size * 0.48,
              color: AppColors.textMain,
            ),
            Positioned(
              right: AppSpacing.xs,
              bottom: AppSpacing.xs,
              child: Container(
                width: size * 0.18,
                height: size * 0.18,
                decoration: BoxDecoration(
                  color: AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
