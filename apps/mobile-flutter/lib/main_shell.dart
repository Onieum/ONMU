import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/route_paths.dart';
import 'shared/widgets/onmu_bottom_nav_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    this.onMyTabReselected,
  });

  final StatefulNavigationShell navigationShell;
  final VoidCallback? onMyTabReselected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: OnmuBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          final isCurrentBranch = index == navigationShell.currentIndex;
          final isMyBranch = index == 3;

          if (isCurrentBranch && isMyBranch) {
            context.go(
              '${RoutePaths.my}?reset=${DateTime.now().microsecondsSinceEpoch}',
            );
            onMyTabReselected?.call();
            return;
          }

          navigationShell.goBranch(index, initialLocation: isCurrentBranch);
        },
      ),
    );
  }
}
