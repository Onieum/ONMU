import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/onmu_bottom_nav_bar.dart';
import '../../shared/widgets/prototype_placeholder_page.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.meetups,
  routes: [
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
                      builder: (context, state) =>
                          const PrototypePlaceholderPage(
                            title: '장소 후보',
                            description: '추천 장소 카드가 들어갈 화면입니다.',
                          ),
                      routes: [
                        GoRoute(
                          path: 'search',
                          builder: (context, state) =>
                              const PrototypePlaceholderPage(
                                title: '장소 검색',
                                description: '필터와 검색 UI가 들어갈 화면입니다.',
                              ),
                        ),
                        GoRoute(
                          path: 'map',
                          builder: (context, state) =>
                              const PrototypePlaceholderPage(
                                title: '지도 보기',
                                description: '지도 기반 후보 비교 UI가 들어갈 화면입니다.',
                              ),
                        ),
                        GoRoute(
                          path: 'risks',
                          builder: (context, state) =>
                              const PrototypePlaceholderPage(
                                title: '장소 리스크',
                                description: '휴무, 브레이크타임, 비선호 조건을 확인합니다.',
                              ),
                        ),
                        GoRoute(
                          path: ':placeId',
                          builder: (context, state) =>
                              const PrototypePlaceholderPage(
                                title: '장소 상세',
                                description: '장소 상세 정보 sheet 역할의 화면입니다.',
                              ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'place-compare',
                      builder: (context, state) =>
                          const PrototypePlaceholderPage(
                            title: '장소 비교',
                            description: '후보별 점수와 리스크를 비교합니다.',
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
              builder: (context, state) => const PrototypePlaceholderPage(
                title: '온챗',
                description: '채팅, 약속 보드, 추억 보드, 정산으로 이동합니다.',
                primaryLabel: '온챗 그룹 열기',
                primaryRoute: RoutePaths.onchatDemoGroup,
              ),
              routes: [
                GoRoute(
                  path: 'groups/:groupId',
                  builder: (context, state) => const PrototypePlaceholderPage(
                    title: '온챗 그룹',
                    description: '고정 약속과 최근 대화를 확인합니다.',
                  ),
                  routes: [
                    GoRoute(
                      path: 'chat',
                      builder: (context, state) =>
                          const PrototypePlaceholderPage(
                            title: '온챗 대화',
                            description: 'mock message list와 입력창 UI입니다.',
                          ),
                    ),
                    GoRoute(
                      path: 'meetups/new',
                      builder: (context, state) =>
                          const PrototypePlaceholderPage(
                            title: '온챗 약속 만들기',
                            description: '대화방 안에서 새 약속을 만듭니다.',
                          ),
                    ),
                    GoRoute(
                      path: 'meetups/:meetupId/board',
                      builder: (context, state) =>
                          const PrototypePlaceholderPage(
                            title: '온챗 약속 보드',
                            description: '장소 투표와 약속 준비 상태를 봅니다.',
                          ),
                    ),
                    GoRoute(
                      path: 'memories',
                      builder: (context, state) =>
                          const PrototypePlaceholderPage(
                            title: '온챗 추억 보드',
                            description: '함께 남긴 기록을 카드로 모아봅니다.',
                          ),
                    ),
                    GoRoute(
                      path: 'settlements/new',
                      builder: (context, state) =>
                          const PrototypePlaceholderPage(
                            title: '정산 만들기',
                            description: '결제자, 금액, 대상자를 고르는 화면입니다.',
                          ),
                    ),
                    GoRoute(
                      path: 'settlements/:settlementId',
                      builder: (context, state) =>
                          const PrototypePlaceholderPage(
                            title: '정산 공유',
                            description: '정산 상태와 공유 메시지를 확인합니다.',
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
