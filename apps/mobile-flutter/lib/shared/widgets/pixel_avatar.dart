import 'package:flutter/material.dart';

import '../../core/api/onmu_media_url.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class PixelAvatar extends StatelessWidget {
  const PixelAvatar({
    required this.label,
    this.size = 48,
    this.profileImageUrl,
    this.bodyColor = AppColors.primaryPurple,
    this.hairColor = AppColors.textMain,
    super.key,
  });

  final String label;
  final double size;
  final String? profileImageUrl;
  final Color bodyColor;
  final Color hairColor;

  @override
  Widget build(BuildContext context) {
    final trimmedLabel = label.trim();
    final imageUrl = resolveOnmuMediaUrl(profileImageUrl);

    return Semantics(
      label: trimmedLabel.isEmpty ? '프로필 이미지' : '$trimmedLabel 프로필 이미지',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgGrid,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _PixelAvatarFallback(size: size, iconColor: bodyColor),
                  ),
                )
              : _PixelAvatarFallback(size: size, iconColor: bodyColor),
        ),
      ),
    );
  }
}

class _PixelAvatarFallback extends StatelessWidget {
  const _PixelAvatarFallback({required this.size, required this.iconColor});

  final double size;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bgDefault,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: SizedBox.square(
          dimension: size * 0.72,
          child: Icon(
            Icons.person_rounded,
            size: size * 0.48,
            color: iconColor.withOpacity(0.72),
          ),
        ),
      ),
    );
  }
}
