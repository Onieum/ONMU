import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/launch/splash_page.dart';
import '../../features/launch/start_page.dart';
import '../../features/meetup/presentation/pages/meetup_complete_page.dart';
import '../../features/meetup/presentation/pages/meetup_calendar_page.dart';
import '../../features/meetup/presentation/pages/meetup_date_select_page.dart';
import '../../features/meetup/presentation/pages/meetup_detail_page.dart';
import '../../features/meetup/presentation/pages/meetup_member_select_page.dart';
import '../../features/meetup/presentation/pages/meetup_route_review_page.dart';
import '../../features/my/my_page.dart';
import '../../features/onchat/presentation/pages/onchat_group_home_page.dart';
import '../../features/onchat/presentation/pages/onchat_list_page.dart';
import '../../features/onchat/presentation/pages/onchat_meetup_board_page.dart';
import '../../features/onchat/presentation/pages/onchat_meetup_create_page.dart';
import '../../features/onchat/presentation/pages/onchat_memory_board_page.dart';
import '../../features/onchat/presentation/pages/onchat_settlement_create_page.dart';
import '../../features/onchat/presentation/pages/onchat_settlement_share_page.dart';
import '../../features/onchat/presentation/pages/onchat_thread_page.dart';
import '../../features/place/presentation/pages/place_candidate_page.dart';
import '../../features/place/presentation/pages/place_compare_page.dart';
import '../../features/place/presentation/pages/place_detail_page.dart';
import '../../features/place/presentation/pages/place_map_page.dart';
import '../../features/place/presentation/pages/place_risks_page.dart';
import '../../features/place/presentation/pages/place_search_filter_page.dart';
import '../../features/preferences/preference_intro_page.dart';
import '../../shared/models/preference_profile.dart';
import '../../shared/widgets/onmu_bottom_nav_bar.dart';
import '../../shared/widgets/prototype_placeholder_page.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: [
    GoRoute(path: '/', redirect: (context, state) => RoutePaths.splash),
    GoRoute(
      path: RoutePaths.splash,
      builder: (context, state) =>
          SplashPage(onTimeout: () => context.go(RoutePaths.preferenceIntro)),
    ),
    GoRoute(
      path: RoutePaths.start,
      builder: (context, state) => const StartPage(),
    ),
    GoRoute(
      path: RoutePaths.preferenceIntro,
      builder: (context, state) =>
          PreferenceIntroPage(profile: PreferenceProfile.mock()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: OnmuBottomNavBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => HomePage(
                summaryProfile: state.extra is PreferenceProfile
                    ? state.extra! as PreferenceProfile
                    : null,
              ),
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
                  path: 'new/schedule',
                  builder: (context, state) => const MeetupDateSelectPage(),
                ),
                GoRoute(
                  path: 'new/schedule/calendar',
                  builder: (context, state) => const MeetupCalendarPage(),
                ),
                GoRoute(
                  path: ':meetupId',
                  builder: (context, state) => MeetupDetailPage(
                    meetupId: state.pathParameters['meetupId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'places',
                      builder: (context, state) {
                        return PlaceCandidatePage(
                          showVoteResult:
                              state.uri.queryParameters['voteResult'] == '1',
                        );
                      },
                      routes: [
                        GoRoute(
                          path: 'search',
                          builder: (context, state) =>
                              const PlaceSearchFilterPage(),
                        ),
                        GoRoute(
                          path: 'map',
                          builder: (context, state) => const PlaceMapPage(),
                        ),
                        GoRoute(
                          path: 'risks',
                          builder: (context, state) => const PlaceRisksPage(),
                          routes: [
                            GoRoute(
                              path: 'keyword',
                              builder: (context, state) =>
                                  const PlaceRiskDialogPreviewPage(
                                    kind: PlaceRiskDialogKind.keyword,
                                  ),
                            ),
                            GoRoute(
                              path: 'break-time',
                              builder: (context, state) =>
                                  const PlaceRiskDialogPreviewPage(
                                    kind: PlaceRiskDialogKind.breakTime,
                                  ),
                            ),
                            GoRoute(
                              path: 'closed-day',
                              builder: (context, state) =>
                                  const PlaceRiskDialogPreviewPage(
                                    kind: PlaceRiskDialogKind.closedDay,
                                  ),
                            ),
                          ],
                        ),
                        GoRoute(
                          path: ':placeId',
                          builder: (context, state) => PlaceDetailPage(
                            placeId:
                                state.pathParameters['placeId'] ?? 'onmu-diner',
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'place-compare',
                      builder: (context, state) => const PlaceComparePage(),
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
              path: RoutePaths.ootdList,
              builder: (context, state) => const PrototypePlaceholderPage(
                title: '기록',
                description: 'OOTD와 기억 상세 플로우가 들어갈 탭입니다.',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.my,
              builder: (context, state) => const MyPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.onchat,
      builder: (context, state) => const OnChatListPage(),
      routes: [
        GoRoute(
          path: 'groups/:groupId',
          builder: (context, state) => const OnChatGroupHomePage(),
          routes: [
            GoRoute(
              path: 'chat',
              builder: (context, state) => const OnChatThreadPage(),
            ),
            GoRoute(
              path: 'meetups/new',
              builder: (context, state) => const OnChatMeetupCreatePage(),
            ),
            GoRoute(
              path: 'meetups/:meetupId/board',
              builder: (context, state) => const OnChatMeetupBoardPage(),
            ),
            GoRoute(
              path: 'memories',
              builder: (context, state) => const OnChatMemoryBoardPage(),
            ),
            GoRoute(
              path: 'settlements/new',
              builder: (context, state) => const OnChatSettlementCreatePage(),
            ),
            GoRoute(
              path: 'settlements/:settlementId',
              builder: (context, state) => const OnChatSettlementSharePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
