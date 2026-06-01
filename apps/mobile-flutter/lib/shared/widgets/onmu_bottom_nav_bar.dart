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
      label: '홈',
    ),
    _BottomNavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: '약속',
    ),
    _BottomNavItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: '온챗',
    ),
    _BottomNavItem(
      icon: Icons.checkroom_outlined,
      activeIcon: Icons.checkroom,
      label: '기록',
    ),
    _BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
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
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      size: 24,
                      color: color,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
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
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
