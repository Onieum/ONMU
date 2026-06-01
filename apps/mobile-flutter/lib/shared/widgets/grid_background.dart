import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GridBackground extends StatelessWidget {
  final Widget? child;
  final double gridSize;

  const GridBackground({
    super.key,
    this.child,
    this.gridSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(gridSize: gridSize),
      child: child,
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridSize;

  GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.bgGrid
      ..strokeWidth = 1.0;

    // 세로선 그리기
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 가로선 그리기
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
