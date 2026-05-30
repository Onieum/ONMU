import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/meetup/presentation/pages/meetup_complete_page.dart';
import '../../features/meetup/presentation/pages/meetup_date_select_page.dart';
import '../../features/meetup/presentation/pages/meetup_detail_page.dart';
import '../../features/meetup/presentation/pages/meetup_member_select_page.dart';
import '../../features/meetup/presentation/pages/meetup_place_handoff_page.dart';
import '../../features/meetup/presentation/pages/meetup_route_review_page.dart';
import '../../features/meetup/presentation/pages/meetup_title_input_page.dart';
import '../../shared/widgets/onmu_bottom_nav_bar.dart';
import '../../shared/widgets/onmu_scaffold.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _OnmuShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.meetups,
              builder: (context, state) =>
                  const HomePage(showOnlyMeetups: true),
              routes: [
                GoRoute(
                  path: 'new/members',
                  builder: (context, state) => const MeetupMemberSelectPage(),
                ),
                GoRoute(
                  path: 'new/title',
                  builder: (context, state) => const MeetupTitleInputPage(),
                ),
                GoRoute(
                  path: 'new/schedule',
                  builder: (context, state) => const MeetupDateSelectPage(),
                ),
                GoRoute(
                  path: ':meetupId',
                  builder: (context, state) => MeetupDetailPage(
                    meetupId: state.pathParameters['meetupId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'places',
                      builder: (context, state) => MeetupPlaceHandoffPage(
                        meetupId: state.pathParameters['meetupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'route-review',
                      builder: (context, state) => MeetupRouteReviewPage(
                        meetupId: state.pathParameters['meetupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'complete',
                      builder: (context, state) => MeetupCompletePage(
                        meetupId: state.pathParameters['meetupId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.onchat,
              builder: (context, state) => const _PlaceholderTab(
                title: '온챗',
                message: '온챗 화면은 온챗 담당 화면에서 이어져요',
                icon: Icons.chat_bubble_outline,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.ootdList,
              builder: (context, state) => const _PlaceholderTab(
                title: '기록',
                message: 'OOTD와 기억 화면은 기록 담당 화면에서 이어져요',
                icon: Icons.photo_library_outlined,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.my,
              builder: (context, state) => const _PlaceholderTab(
                title: '마이',
                message: '마이 ONMU 화면은 마이 담당 화면에서 이어져요',
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _OnmuShell extends StatelessWidget {
  const _OnmuShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: OnmuBottomNavBar(navigationShell: navigationShell),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: title,
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 56),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
