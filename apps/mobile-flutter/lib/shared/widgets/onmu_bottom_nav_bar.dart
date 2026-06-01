import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class OnmuBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const OnmuBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈'),
      _BottomNavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: '약속'),
      _BottomNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: '온챗'),
      _BottomNavItem(icon: Icons.checkroom_outlined, activeIcon: Icons.checkroom, label: '기록'),
      _BottomNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: '마이'),
    ];

    return Container(
      height: 60.0,
      decoration: const BoxDecoration(
        color: AppColors.bgDefault,
        border: Border(
          top: BorderSide(
            color: AppColors.lineSoft,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = currentIndex == index;
          final color = isSelected ? AppColors.primaryPurple : AppColors.textMuted;

          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: 24.0,
                    color: color,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 11.0,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: color,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
