import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class OnmuBottomNavBar extends StatelessWidget {
  const OnmuBottomNavBar({
    super.key,
    this.navigationShell,
    this.currentIndex,
    this.onTap,
  }) : assert(
         navigationShell != null || (currentIndex != null && onTap != null),
         'navigationShell 또는 currentIndex/onTap을 전달해야 합니다.',
       );

  final StatefulNavigationShell? navigationShell;
  final int? currentIndex;
  final ValueChanged<int>? onTap;

  static const _items = [
    _BottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      iconKind: _BottomNavIconKind.material,
      label: '홈',
    ),
    _BottomNavItem(iconKind: _BottomNavIconKind.group, label: '온모임'),
    _BottomNavItem(iconKind: _BottomNavIconKind.calendar, label: '기록'),
    _BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      iconKind: _BottomNavIconKind.material,
      label: '마이',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell?.currentIndex ?? currentIndex ?? 0;

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.bgDefault,
        border: Border(top: BorderSide(color: AppColors.lineSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = selectedIndex == index;
            final color = selected
                ? AppColors.primaryPurple
                : AppColors.textMuted;

            return Expanded(
              child: InkWell(
                onTap: () {
                  if (navigationShell != null) {
                    navigationShell!.goBranch(
                      index,
                      initialLocation: index == navigationShell!.currentIndex,
                    );
                    return;
                  }
                  onTap?.call(index);
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BottomNavIcon(
                      item: item,
                      selected: selected,
                      color: color,
                    ),
                    SizedBox(height: 2),
                    Text(
                      item.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        height: 1.2,
                        color: color,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    this.icon,
    this.activeIcon,
    required this.iconKind,
    required this.label,
  });

  final IconData? icon;
  final IconData? activeIcon;
  final _BottomNavIconKind iconKind;
  final String label;
}

enum _BottomNavIconKind { material, group, calendar }

class _BottomNavIcon extends StatelessWidget {
  const _BottomNavIcon({
    required this.item,
    required this.selected,
    required this.color,
  });

  final _BottomNavItem item;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return switch (item.iconKind) {
      _BottomNavIconKind.group => CustomPaint(
        painter: _GroupNavIconPainter(color: color, filled: selected),
        child: const SizedBox(width: 24, height: 24),
      ),
      _BottomNavIconKind.calendar => CustomPaint(
        painter: _CalendarNavIconPainter(color: color, filled: selected),
        child: const SizedBox(width: 24, height: 24),
      ),
      _BottomNavIconKind.material => Icon(
        selected ? item.activeIcon : item.icon,
        size: 24,
        color: color,
      ),
    };
  }
}

class _GroupNavIconPainter extends CustomPainter {
  const _GroupNavIconPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void person(Offset center, double scale) {
      canvas.drawCircle(
        Offset(center.dx, center.dy - 4.7 * scale),
        4.2 * scale,
        paint,
      );
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 4.8 * scale),
          width: 9.2 * scale,
          height: 12.4 * scale,
        ),
        Radius.circular(3.4 * scale),
      );
      canvas.drawRRect(body, paint);
    }

    person(Offset(size.width * 0.28, size.height * 0.49), 0.78);
    person(Offset(size.width * 0.72, size.height * 0.49), 0.78);
    person(Offset(size.width * 0.50, size.height * 0.50), 1.0);
  }

  @override
  bool shouldRepaint(covariant _GroupNavIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.filled != filled;
  }
}

class _CalendarNavIconPainter extends CustomPainter {
  const _CalendarNavIconPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: filled ? 0.16 : 0)
      ..style = PaintingStyle.fill;

    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 3.5, size.width - 6, size.height - 6),
      const Radius.circular(3.5),
    );

    if (filled) {
      canvas.drawRRect(frame, fillPaint);
    }
    canvas.drawRRect(frame, strokePaint);
    canvas.drawLine(
      Offset(3, size.height * 0.34),
      Offset(size.width - 3, size.height * 0.34),
      strokePaint,
    );

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final dot in const [
      Offset(8, 12),
      Offset(12, 12),
      Offset(8, 16),
      Offset(12, 16),
      Offset(16, 16),
    ]) {
      canvas.drawCircle(dot, 1.35, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CalendarNavIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.filled != filled;
  }
}
