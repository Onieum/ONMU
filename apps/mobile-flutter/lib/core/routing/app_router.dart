import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
import '../../shared/widgets/onmu_bottom_nav_bar.dart';
import '../../shared/widgets/prototype_placeholder_page.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', redirect: (context, state) => RoutePaths.meetups),
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
              builder: (context, state) => const PrototypePlaceholderPage(
                title: '홈',
                description: '약속, 기록, 캐릭터 상태를 한 번에 보는 첫 화면입니다.',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.meetups,
              builder: (context, state) => const PrototypePlaceholderPage(
                title: '약속',
                description: '장소 플로우로 이어지는 약속 목록 화면입니다.',
                primaryLabel: '장소 후보 보기',
                primaryRoute: RoutePaths.placeCandidates,
              ),
              routes: [
                GoRoute(
                  path: ':meetupId',
                  builder: (context, state) => const PrototypePlaceholderPage(
                    title: '약속 상세',
                    description: '참여자와 일정 후보를 확인하는 약속 상세 화면입니다.',
                    primaryLabel: '장소 후보 보기',
                    primaryRoute: RoutePaths.placeCandidates,
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
                      builder: (context, state) =>
                          const OnChatMeetupCreatePage(),
                    ),
                    GoRoute(
                      path: 'meetups/:meetupId/board',
                      builder: (context, state) =>
                          const OnChatMeetupBoardPage(),
                    ),
                    GoRoute(
                      path: 'memories',
                      builder: (context, state) =>
                          const OnChatMemoryBoardPage(),
                    ),
                    GoRoute(
                      path: 'settlements/new',
                      builder: (context, state) =>
                          const OnChatSettlementCreatePage(),
                    ),
                    GoRoute(
                      path: 'settlements/:settlementId',
                      builder: (context, state) =>
                          const OnChatSettlementSharePage(),
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
              builder: (context, state) => const PrototypePlaceholderPage(
                title: '마이 ONMU',
                description: '캐릭터, 취향, 기록 요약을 관리합니다.',
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
