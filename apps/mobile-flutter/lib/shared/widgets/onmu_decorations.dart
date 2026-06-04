import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class OnmuStickerLabel extends StatelessWidget {
  const OnmuStickerLabel({
    required this.label,
    super.key,
    this.icon,
    this.backgroundColor = AppColors.bgSticker,
    this.borderColor = AppColors.linePink,
  });

  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
              Icon(icon, size: 15, color: AppColors.accentBrown),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class OnmuTape extends StatelessWidget {
  const OnmuTape({super.key, this.width = 68});

  final double width;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgTape,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.lineWarm),
      ),
      child: SizedBox(width: width, height: 18),
    );
  }
}

class OnmuPixelBuddy extends StatelessWidget {
  const OnmuPixelBuddy({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PixelBuddyPainter()),
    );
  }
}

class OnmuPaperHeader extends StatelessWidget {
  const OnmuPaperHeader({
    required this.title,
    required this.body,
    super.key,
    this.stickerLabel,
    this.icon,
  });

  final String title;
  final String body;
  final String? stickerLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.lineBrown),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OnmuPixelBuddy(size: 64),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stickerLabel != null) ...[
                        OnmuStickerLabel(label: stickerLabel!, icon: icon),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(body, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(top: -8, right: 26, child: OnmuTape()),
      ],
    );
  }
}

class _PixelBuddyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 12;
    final paint = Paint();

    void rect(int x, int y, int w, int h, Color color) {
      paint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        paint,
      );
    }

    rect(4, 1, 4, 1, AppColors.accentBrown);
    rect(3, 2, 6, 2, AppColors.accentBrown);
    rect(3, 4, 1, 3, AppColors.accentBrown);
    rect(8, 4, 1, 3, AppColors.accentBrown);
    rect(4, 3, 4, 5, AppColors.characterSkin);
    rect(5, 5, 1, 1, AppColors.textMain);
    rect(7, 5, 1, 1, AppColors.textMain);
    rect(5, 7, 2, 1, AppColors.primaryPink);
    rect(3, 8, 6, 2, AppColors.primaryPinkSoft);
    rect(2, 9, 2, 1, AppColors.bgTape);
    rect(8, 9, 2, 1, AppColors.bgTape);
    rect(4, 10, 2, 1, AppColors.textSub);
    rect(7, 10, 2, 1, AppColors.textSub);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
