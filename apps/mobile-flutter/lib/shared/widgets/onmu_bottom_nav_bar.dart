import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class OnmuBottomNavBar extends StatelessWidget {
  const OnmuBottomNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    _NavItem(label: '홈', outlined: Icons.home_outlined, filled: Icons.home),
    _NavItem(
      label: '약속',
      outlined: Icons.calendar_today_outlined,
      filled: Icons.calendar_today,
    ),
    _NavItem(
      label: '온챗',
      outlined: Icons.chat_bubble_outline,
      filled: Icons.chat_bubble,
    ),
    _NavItem(
      label: '기록',
      outlined: Icons.menu_book_outlined,
      filled: Icons.menu_book,
    ),
    _NavItem(label: '마이', outlined: Icons.person_outline, filled: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgDefault,
        border: Border(top: BorderSide(color: AppColors.lineSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (index) {
              final selected = navigationShell.currentIndex == index;
              final item = _items[index];

              return Expanded(
                child: InkWell(
                  onTap: () {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.filled : item.outlined,
                        color: selected
                            ? AppColors.primaryPink
                            : AppColors.textMuted,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? AppColors.primaryPink
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.outlined,
    required this.filled,
  });

  final String label;
  final IconData outlined;
  final IconData filled;
}
