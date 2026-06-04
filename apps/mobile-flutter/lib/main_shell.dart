import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/route_paths.dart';
import 'shared/widgets/onmu_bottom_nav_bar.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

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
            navigationShell.goBranch(index, initialLocation: true);
            context.go(
              '${RoutePaths.my}?reset=${DateTime.now().microsecondsSinceEpoch}',
            );
            return;
          }

          navigationShell.goBranch(
            index,
            initialLocation: isCurrentBranch,
          );
        },
      ),
    );
  }
}
