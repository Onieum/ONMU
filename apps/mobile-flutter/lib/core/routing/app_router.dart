import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/character/character_start_page.dart';
import '../../features/home/presentation/pages/home_notifications_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/home_recent_records_page.dart';
import '../../features/home/presentation/pages/upcoming_meetups_page.dart';
import '../../features/launch/splash_page.dart';
import '../../features/launch/start_page.dart';
import '../../features/meetup/presentation/pages/meetup_create_page.dart';
import '../../features/meetup/presentation/pages/meetup_detail_page.dart';
import '../../features/meetup/presentation/pages/meetup_route_review_page.dart';
import '../../features/my/my_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_group_home_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_group_settings_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_create_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_list_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_meetup_list_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_member_list_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_meetup_board_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_memory_board_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_memory_detail_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_settlement_create_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_settlement_share_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_settlement_target_selection_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_thread_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_vote_detail_page.dart';
import '../../features/onboarding/onboarding_hub_page.dart';
import '../../features/onmoim/presentation/pages/onmoim_vote_list_page.dart';
import '../../features/place/presentation/pages/place_candidate_page.dart';
import '../../features/place/presentation/pages/place_detail_page.dart';
import '../../features/place/presentation/pages/place_map_page.dart';
import '../../features/place/presentation/pages/place_search_filter_page.dart';
import '../../features/place/presentation/pages/place_vote_create_page.dart';
import '../../features/preferences/preference_intro_page.dart';
import '../../shared/models/preference_profile.dart';
import '../../shared/widgets/onmu_bottom_nav_bar.dart';
import '../../shared/widgets/prototype_placeholder_page.dart';
import 'demo_route_seeds.dart';
import 'legacy_route_redirects.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: [
    GoRoute(path: '/', redirect: (context, state) => RoutePaths.splash),
    GoRoute(
      path: RoutePaths.splash,
      builder: (context, state) => SplashPage(
        onTimeout: () => context.go(RoutePaths.onboardingPreferences),
      ),
    ),
    GoRoute(
      path: RoutePaths.start,
      builder: (context, state) => const StartPage(),
    ),
    GoRoute(
      path: RoutePaths.onboardingPreferences,
      builder: (context, state) =>
          PreferenceIntroPage(profile: PreferenceProfile.mock()),
    ),
    GoRoute(
      path: RoutePaths.onboarding,
      builder: (context, state) => const OnboardingHubPage(),
    ),
    GoRoute(
      path: RoutePaths.onboardingCharacter,
      builder: (context, state) => CharacterStartPage(
        onBackToOnboarding: () => context.go(RoutePaths.onboarding),
        onCompleted: (_) => context.go(RoutePaths.onboarding),
      ),
    ),
    ...legacyRedirectRoutes(),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: OnmuBottomNavBar(
            navigationShell: navigationShell,
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
            GoRoute(
              path: RoutePaths.homeUpcomingPlans,
              builder: (context, state) => const UpcomingMeetupsPage(),
            ),
            GoRoute(
              path: RoutePaths.homeNotifications,
              builder: (context, state) => const HomeNotificationsPage(),
            ),
            GoRoute(
              path: RoutePaths.homeRecentRecords,
              builder: (context, state) => const HomeRecentRecordsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.groups,
              builder: (context, state) => const OnMoimListPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) {
                    final initialMemberNames = state.extra is List<String>
                        ? state.extra! as List<String>
                        : const <String>[];

                    return OnMoimCreatePage(
                      initialMemberNames: initialMemberNames,
                    );
                  },
                ),
                GoRoute(
                  path: ':groupId',
                  builder: (context, state) => const OnMoimGroupHomePage(),
                  routes: [
                    GoRoute(
                      path: 'members',
                      builder: (context, state) => OnMoimMemberListPage(
                        onmoimId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'invite',
                      builder: (context, state) => OnMoimInvitePage(
                        onmoimId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'settings',
                      builder: (context, state) => OnMoimGroupSettingsPage(
                        onmoimId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'chat',
                      builder: (context, state) => const OnMoimThreadPage(),
                    ),
                    GoRoute(
                      path: 'votes',
                      builder: (context, state) => OnMoimVoteListPage(
                        onmoimId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'votes/:voteId',
                      builder: (context, state) => OnMoimVoteDetailPage(
                        onmoimId: state.pathParameters['groupId']!,
                        voteId:
                            state.pathParameters['voteId'] ??
                            DemoRouteSeeds.voteId,
                      ),
                    ),
                    GoRoute(
                      path: 'memories',
                      builder: (context, state) =>
                          const OnMoimMemoryBoardPage(),
                      routes: [
                        GoRoute(
                          path: ':memoryId',
                          builder: (context, state) => OnMoimMemoryDetailPage(
                            onmoimId: state.pathParameters['groupId']!,
                            memoryId: state.pathParameters['memoryId']!,
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'plans/new',
                      builder: (context, state) => MeetupCreatePage(
                        onmoimId: state.pathParameters['groupId']!,
                        editingMeetupId: state.uri.queryParameters['edit'],
                      ),
                    ),
                    GoRoute(
                      path: 'plans',
                      builder: (context, state) => OnMoimMeetupListPage(
                        onmoimId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'plans/new/schedule',
                      builder: (context, state) => MeetupCreatePage(
                        onmoimId: state.pathParameters['groupId']!,
                        editingMeetupId: state.uri.queryParameters['edit'],
                      ),
                      routes: [
                        GoRoute(
                          path: 'calendar',
                          builder: (context, state) => MeetupCreatePage(
                            onmoimId: state.pathParameters['groupId']!,
                            editingMeetupId: state.uri.queryParameters['edit'],
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'plans/:planId',
                      builder: (context, state) => MeetupDetailPage(
                        onmoimId: state.pathParameters['groupId']!,
                        meetupId: state.pathParameters['planId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'board',
                          builder: (context, state) =>
                              const OnMoimMeetupBoardPage(),
                        ),
                        GoRoute(
                          path: 'place-candidates',
                          builder: (context, state) {
                            return PlaceCandidatePage(
                              onmoimId: state.pathParameters['groupId']!,
                              meetupId: state.pathParameters['planId']!,
                            );
                          },
                          routes: [
                            GoRoute(
                              path: ':candidateId',
                              builder: (context, state) => PlaceDetailPage(
                                onmoimId: state.pathParameters['groupId']!,
                                meetupId: state.pathParameters['planId']!,
                                placeId:
                                    state.pathParameters['candidateId'] ??
                                    DemoRouteSeeds.candidateId,
                              ),
                            ),
                          ],
                        ),
                        GoRoute(
                          path: 'place-search',
                          builder: (context, state) => PlaceMapPage(
                            onmoimId: state.pathParameters['groupId']!,
                            meetupId: state.pathParameters['planId']!,
                          ),
                          routes: [
                            GoRoute(
                              path: 'results',
                              builder: (context, state) =>
                                  PlaceSearchFilterPage(
                                    onmoimId: state.pathParameters['groupId']!,
                                    meetupId: state.pathParameters['planId']!,
                                  ),
                            ),
                          ],
                        ),
                        GoRoute(
                          path: 'votes/new',
                          builder: (context, state) => PlaceVoteCreatePage(
                            onmoimId: state.pathParameters['groupId']!,
                            meetupId: state.pathParameters['planId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'votes/:voteId',
                          builder: (context, state) => OnMoimVoteDetailPage(
                            onmoimId: state.pathParameters['groupId']!,
                            voteId:
                                state.pathParameters['voteId'] ??
                                DemoRouteSeeds.voteId,
                          ),
                        ),
                        GoRoute(
                          path: 'itinerary',
                          builder: (context, state) => MeetupRouteReviewPage(
                            onmoimId: state.pathParameters['groupId']!,
                            meetupId: state.pathParameters['planId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'settlements/new',
                          builder: (context, state) =>
                              OnMoimSettlementCreatePage(
                                onmoimId: state.pathParameters['groupId']!,
                                meetupId: state.pathParameters['planId']!,
                              ),
                        ),
                        GoRoute(
                          path: 'settlements/new/items/:itemId/targets',
                          builder: (context, state) =>
                              OnMoimSettlementTargetSelectionPage(
                                onmoimId: state.pathParameters['groupId']!,
                                meetupId: state.pathParameters['planId']!,
                                itemId: state.pathParameters['itemId']!,
                              ),
                        ),
                        GoRoute(
                          path: 'settlements/new/preview',
                          builder: (context, state) =>
                              OnMoimSettlementSharePage(
                                onmoimId: state.pathParameters['groupId']!,
                                meetupId: state.pathParameters['planId']!,
                                preview: true,
                              ),
                        ),
                        GoRoute(
                          path: 'settlements/:settlementId',
                          builder: (context, state) =>
                              OnMoimSettlementSharePage(
                                onmoimId: state.pathParameters['groupId']!,
                                meetupId: state.pathParameters['planId']!,
                              ),
                        ),
                      ],
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
              path: RoutePaths.records,
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
  ],
);
