import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class OnmuCharacterHero extends StatelessWidget {
  const OnmuCharacterHero({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 154.0 : 230.0;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.bgPaper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: CustomPaint(
          painter: _PixelCharacterPainter(),
          child: const SizedBox.expand(),
        ),
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
    rect(4, 4, 6, 5, AppColors.characterSkin);
    rect(5, 6, 1, 1, AppColors.textMain);
    rect(8, 6, 1, 1, AppColors.textMain);
    rect(6, 8, 2, 1, AppColors.primaryPink);
    rect(4, 9, 6, 3, AppColors.primaryPurpleSoft);
    rect(3, 10, 2, 2, AppColors.primaryPinkSoft);
    rect(9, 10, 2, 2, AppColors.primaryPinkSoft);
    rect(5, 12, 2, 1, AppColors.textSub);
    rect(8, 12, 2, 1, AppColors.textSub);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
