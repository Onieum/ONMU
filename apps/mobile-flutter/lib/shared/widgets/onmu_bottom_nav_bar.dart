import 'package:flutter/material.dart';

import '../onmu_design.dart';

class OnmuBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const OnmuBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

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
    return Container(
      decoration: const BoxDecoration(
        color: OnmuColors.bgDefault,
        border: Border(top: BorderSide(color: OnmuColors.lineSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (index) {
              final selected = index == currentIndex;
              final item = _items[index];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.filled : item.outlined,
                        color: selected
                            ? OnmuColors.purple
                            : OnmuColors.textMuted,
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
                              ? OnmuColors.purple
                              : OnmuColors.textMuted,
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
  final String label;
  final IconData outlined;
  final IconData filled;

  const _NavItem({
    required this.label,
    required this.outlined,
    required this.filled,
  });
}
