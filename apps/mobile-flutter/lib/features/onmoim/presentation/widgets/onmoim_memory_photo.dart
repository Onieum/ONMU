import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

class OnMoimMemoryPhoto extends StatelessWidget {
  const OnMoimMemoryPhoto({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MemoryPhotoPainter(index));
  }
}

class _MemoryPhotoPainter extends CustomPainter {
  const _MemoryPhotoPainter(this.index);

  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    void rect(Rect rect, Color color) {
      paint.color = color;
      paint.style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.sm)),
        paint,
      );
    }

    switch (index % 4) {
      case 0:
        rect(Offset.zero & size, const Color(0xFFF5E4D2));
        rect(
          Rect.fromLTWH(
            size.width * 0.08,
            size.height * 0.1,
            size.width * 0.44,
            size.height * 0.44,
          ),
          const Color(0xFFE2C3A7),
        );
        rect(
          Rect.fromLTWH(
            size.width * 0.58,
            size.height * 0.12,
            size.width * 0.3,
            size.height * 0.34,
          ),
          const Color(0xFFD9EDF0),
        );
        rect(
          Rect.fromLTWH(
            size.width * 0.14,
            size.height * 0.62,
            size.width * 0.72,
            size.height * 0.16,
          ),
          const Color(0xFFC69A76),
        );
        rect(
          Rect.fromLTWH(
            size.width * 0.2,
            size.height * 0.5,
            size.width * 0.22,
            size.height * 0.2,
          ),
          const Color(0xFFFFFAF3),
        );
        rect(
          Rect.fromLTWH(
            size.width * 0.52,
            size.height * 0.48,
            size.width * 0.2,
            size.height * 0.22,
          ),
          const Color(0xFF8B5E3C),
        );
        break;
      case 1:
        rect(Offset.zero & size, const Color(0xFFCDEAF6));
        rect(
          Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.24),
          const Color(0xFF72B7D9),
        );
        rect(
          Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.32),
          const Color(0xFFEFDAB5),
        );
        paint
          ..color = AppColors.bgDefault.withValues(alpha: 0.75)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;
        final wave = Path()
          ..moveTo(size.width * 0.1, size.height * 0.55)
          ..quadraticBezierTo(
            size.width * 0.28,
            size.height * 0.47,
            size.width * 0.48,
            size.height * 0.55,
          )
          ..quadraticBezierTo(
            size.width * 0.68,
            size.height * 0.63,
            size.width * 0.9,
            size.height * 0.54,
          );
        canvas.drawPath(wave, paint);
        break;
      case 2:
        rect(Offset.zero & size, const Color(0xFFE8DED4));
        rect(
          Rect.fromLTWH(
            size.width * 0.2,
            size.height * 0.14,
            size.width * 0.6,
            size.height * 0.72,
          ),
          const Color(0xFFCBBBAF),
        );
        rect(
          Rect.fromLTWH(
            size.width * 0.32,
            size.height * 0.24,
            size.width * 0.36,
            size.height * 0.42,
          ),
          const Color(0xFF6F625D),
        );
        rect(
          Rect.fromLTWH(
            size.width * 0.4,
            size.height * 0.36,
            size.width * 0.2,
            size.height * 0.18,
          ),
          const Color(0xFFFFDFD7),
        );
        break;
      default:
        rect(Offset.zero & size, const Color(0xFFE3EAD9));
        paint
          ..color = const Color(0xFFA7C08F)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke;
        for (var i = 0; i < 4; i += 1) {
          final x = size.width * (0.22 + i * 0.18);
          canvas.drawLine(
            Offset(x, size.height * 0.22),
            Offset(x - size.width * 0.08, size.height * 0.82),
            paint,
          );
        }
        rect(
          Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
          const Color(0xFFB6C9A7),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MemoryPhotoPainter oldDelegate) {
    return oldDelegate.index != index;
  }
}
