import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    this.label = '사용자',
    this.profileImageUrl,
    this.size = 76,
    super.key,
  });

  final String label;
  final String? profileImageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profileImageUrl?.trim() ?? '';

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _ProfileAvatarFallback(label: label, size: size),
                )
              : _ProfileAvatarFallback(label: label, size: size),
        ),
      ),
    );
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  const _ProfileAvatarFallback({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PixelAvatar(label: label, size: size * 0.62),
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
    );
  }
}
