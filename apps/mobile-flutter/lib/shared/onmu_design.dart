import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

export '../core/theme/app_theme.dart';

class OnmuColors {
  static const bgDefault = AppColors.bgDefault;
  static const bgWarm = AppColors.bgWarm;
  static const paper = AppColors.bgPaper;
  static const purple = AppColors.primaryPurple;
  static const purpleDark = AppColors.primaryPurpleDark;
  static const purpleSoft = AppColors.primaryPurpleSoft;
  static const pink = AppColors.primaryPink;
  static const pinkSoft = AppColors.primaryPinkSoft;
  static const textMain = AppColors.textMain;
  static const textSub = AppColors.textSub;
  static const textMuted = AppColors.textMuted;
  static const lineSoft = AppColors.lineSoft;
  static const linePurple = AppColors.linePurple;
  static const accentGreen = AppColors.accentGreen;
  static const accentBlue = AppColors.accentBlue;
}

class OnmuPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const OnmuPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: OnmuColors.purple,
          disabledBackgroundColor: OnmuColors.purpleSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: AppTextStyles.titleSmall),
      ),
    );
  }
}

class OnmuSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const OnmuSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: OnmuColors.textMain,
          side: const BorderSide(color: OnmuColors.lineSoft),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: AppTextStyles.labelLarge),
      ),
    );
  }
}

class OnmuCharacterHero extends StatelessWidget {
  final bool compact;

  const OnmuCharacterHero({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 154.0 : 230.0;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: OnmuColors.paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: OnmuColors.lineSoft),
        ),
        child: CustomPaint(
          painter: _PixelCharacterPainter(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class PaperNote extends StatelessWidget {
  final String title;
  final String body;
  final IconData? icon;

  const PaperNote({
    super.key,
    required this.title,
    required this.body,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OnmuColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OnmuColors.lineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: OnmuColors.pink, size: 22),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: OnmuColors.textMain,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: OnmuColors.textSub,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelCharacterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 14;
    void rect(int x, int y, int w, int h, Color color) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        Paint()..color = color,
      );
    }

    rect(4, 2, 6, 1, const Color(0xFF5C4035));
    rect(3, 3, 8, 2, const Color(0xFF5C4035));
    rect(3, 5, 1, 3, const Color(0xFF5C4035));
    rect(10, 5, 1, 3, const Color(0xFF5C4035));
    rect(4, 4, 6, 5, const Color(0xFFFFD7BE));
    rect(5, 6, 1, 1, OnmuColors.textMain);
    rect(8, 6, 1, 1, OnmuColors.textMain);
    rect(6, 8, 2, 1, OnmuColors.pink);
    rect(4, 9, 6, 3, OnmuColors.purpleSoft);
    rect(3, 10, 2, 2, OnmuColors.pinkSoft);
    rect(9, 10, 2, 2, OnmuColors.pinkSoft);
    rect(5, 12, 2, 1, OnmuColors.textSub);
    rect(8, 12, 2, 1, OnmuColors.textSub);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
