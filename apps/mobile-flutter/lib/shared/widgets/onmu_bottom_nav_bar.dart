import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class OnmuBottomNavBar extends StatelessWidget {
  const OnmuBottomNavBar({
    super.key,
    this.navigationShell,
    this.currentIndex,
    this.onTap,
    this.onMyTabReselected,
  }) : assert(
         navigationShell != null || (currentIndex != null && onTap != null),
         'navigationShell 또는 currentIndex/onTap을 전달해야 합니다.',
       );

  final StatefulNavigationShell? navigationShell;
  final int? currentIndex;
  final ValueChanged<int>? onTap;
  final VoidCallback? onMyTabReselected;

  List<_BottomNavItem> _createItems() {
    return [
      _BottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: '홈',
      ),
      _BottomNavItem(
        icon: Icons.groups_outlined,
        activeIcon: Icons.groups_rounded,
        label: '온모임',
      ),
      _BottomNavItem(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: '기록',
      ),
      _BottomNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: '마이',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell?.currentIndex ?? currentIndex ?? 0;
    final items = _createItems();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgDefault,
        border: Border(top: BorderSide(color: AppColors.lineSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = selectedIndex == index;
              final color = selected
                  ? AppColors.primaryPurple
                  : AppColors.textMuted;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (navigationShell != null) {
                      final isCurrentBranch =
                          index == navigationShell!.currentIndex;
                      final isMyBranch = index == 3;

                      if (isCurrentBranch && isMyBranch) {
                        navigationShell!.goBranch(index, initialLocation: true);
                        onMyTabReselected?.call();
                        return;
                      }

                      navigationShell!.goBranch(
                        index,
                        initialLocation: isCurrentBranch,
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
