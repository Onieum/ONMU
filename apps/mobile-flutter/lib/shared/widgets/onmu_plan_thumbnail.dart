import 'package:flutter/material.dart';

import '../../core/api/onmu_media_url.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class OnmuPlanThumbnail extends StatelessWidget {
  const OnmuPlanThumbnail({
    required this.iconKind,
    this.imageUrl,
    this.size = 82,
    this.borderRadius = AppRadius.sm,
    super.key,
  });

  final String iconKind;
  final String? imageUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = resolveOnmuMediaUrl(imageUrl);
    final icon = _iconFor(iconKind);
    final color = _colorFor(iconKind);
    final fallback = _PlanThumbnailFallback(
      size: size,
      icon: icon,
      color: color,
      borderRadius: borderRadius,
    );

    if (resolvedImageUrl.isEmpty) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: SizedBox.square(
          dimension: size,
          child: Image.network(
            resolvedImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
          ),
        ),
      ),
    );
  }
}

class _PlanThumbnailFallback extends StatelessWidget {
  const _PlanThumbnailFallback({
    required this.size,
    required this.icon,
    required this.color,
    required this.borderRadius,
  });

  final double size;
  final IconData icon;
  final Color color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, color: color, size: size * 0.42),
      ),
    );
  }
}

IconData _iconFor(String kind) {
  return switch (kind.trim().toLowerCase()) {
    'coffee' || 'cafe' => Icons.local_cafe_outlined,
    'park' => Icons.park_outlined,
    'food' || 'restaurant' => Icons.restaurant_outlined,
    'calendar' => Icons.event_note_outlined,
    _ => Icons.water,
  };
}

Color _colorFor(String kind) {
  return switch (kind.trim().toLowerCase()) {
    'coffee' || 'cafe' => AppColors.accentBrown,
    'park' => AppColors.accentGreen,
    'food' || 'restaurant' => AppColors.primaryPink,
    'calendar' => AppColors.primaryPink,
    _ => AppColors.accentBlue,
  };
}
