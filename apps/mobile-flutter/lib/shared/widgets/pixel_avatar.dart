import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class PixelAvatar extends StatelessWidget {
  const PixelAvatar({
    required this.label,
    this.size = 48,
    this.bodyColor = AppColors.primaryPurple,
    this.hairColor = AppColors.textMain,
    super.key,
  });

  final String label;
  final double size;
  final Color bodyColor;
  final Color hairColor;

  @override
  Widget build(BuildContext context) {
    final trimmedLabel = label.trim();
    final initial = trimmedLabel.isEmpty ? '?' : trimmedLabel.characters.first;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primaryPinkSoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: Center(
          child: SizedBox(
            width: size * 0.62,
            height: size * 0.7,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 0,
                  child: _PixelBlock(
                    width: size * 0.36,
                    height: size * 0.26,
                    color: bodyColor,
                  ),
                ),
                Positioned(
                  top: size * 0.12,
                  child: _PixelBlock(
                    width: size * 0.45,
                    height: size * 0.36,
                    color: AppColors.bgPaper,
                  ),
                ),
                Positioned(
                  top: size * 0.03,
                  child: _PixelBlock(
                    width: size * 0.52,
                    height: size * 0.22,
                    color: hairColor,
                  ),
                ),
                Positioned(
                  top: size * 0.25,
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelBlock extends StatelessWidget {
  const _PixelBlock({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.textMain),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}
