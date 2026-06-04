import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/route_paths.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/character/character_start_page.dart';
import 'features/home/home_page.dart';
import 'features/launch/splash_page.dart';
import 'features/meetup/presentation/pages/meetup_create_page.dart';
import 'features/meetup/presentation/pages/meetup_detail_page.dart';
import 'features/meetup/presentation/pages/meetup_route_review_page.dart';
import 'features/memory/presentation/pages/memory_detail_page.dart';
import 'features/memory/presentation/pages/memory_diary_template_page.dart';
import 'features/my/my_page.dart';
import 'features/onmoim/presentation/pages/onmoim_group_home_page.dart';
import 'features/onmoim/presentation/pages/onmoim_group_settings_page.dart';
import 'features/onmoim/presentation/pages/onmoim_list_page.dart';
import 'features/onmoim/presentation/pages/onmoim_create_page.dart';
import 'features/onmoim/presentation/pages/onmoim_meetup_list_page.dart';
import 'features/onmoim/presentation/pages/onmoim_member_list_page.dart';
import 'features/onmoim/presentation/pages/onmoim_meetup_board_page.dart';
import 'features/onmoim/presentation/pages/onmoim_memory_board_page.dart';
import 'features/onmoim/presentation/pages/onmoim_memory_detail_page.dart';
import 'features/onmoim/presentation/pages/onmoim_settlement_create_page.dart';
import 'features/onmoim/presentation/pages/onmoim_settlement_share_page.dart';
import 'features/onmoim/presentation/pages/onmoim_thread_page.dart';
import 'features/onboarding/onboarding_hub_page.dart';
import 'features/ootd/ootd_list_page.dart';
import 'features/ootd/presentation/pages/daily_record_screen.dart';
import 'features/ootd/presentation/pages/ootd_record_screen.dart';
import 'features/place/presentation/pages/place_candidate_page.dart';
import 'features/place/presentation/pages/place_compare_page.dart';
import 'features/place/presentation/pages/place_detail_page.dart';
import 'features/place/presentation/pages/place_map_page.dart';
import 'features/place/presentation/pages/place_risks_page.dart';
import 'features/place/presentation/pages/place_search_filter_page.dart';
import 'features/preferences/preference_intro_page.dart';
import 'main_shell.dart';
import 'shared/models/character_model.dart';
import 'shared/models/ootd_model.dart';
import 'shared/models/preference_profile.dart';
import 'shared/providers/state_providers.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: OnmuApp()));
}

class OnmuApp extends ConsumerStatefulWidget {
  const OnmuApp({super.key});

  @override
  ConsumerState<OnmuApp> createState() => _OnmuAppState();
}

class _OnmuAppState extends ConsumerState<OnmuApp> {
  late final GoRouter _router;
  late final _RouterRefreshNotifier _refreshNotifier;

  @override
  void initState() {
    super.initState();

    _refreshNotifier = _RouterRefreshNotifier();
    _router = GoRouter(
      initialLocation: RoutePaths.splash,
      refreshListenable: _refreshNotifier,
      redirect: (context, state) {
        final showSplash = ref.read(showSplashProvider);
        final authUser = ref.read(authUserProvider);
        final character = ref.read(userCharacterProvider);
        final preference = ref.read(preferenceProfileProvider);
        final skippedCharacter = ref.read(skippedCharacterProvider);
        final skippedPreference = ref.read(skippedPreferenceProvider);
        final location = state.matchedLocation;
        final isLoggedIn = authUser != null;
        final isLoginRoute = location == RoutePaths.login;
        final isOnboardingRoute =
            location == RoutePaths.onboarding ||
            location == RoutePaths.characterStart ||
            location.startsWith('/preferences');
        final isOnboardingComplete =
            (character != null || skippedCharacter) &&
            (preference != null || skippedPreference);

        if (showSplash) {
          return RoutePaths.splash;
        }

        if (!isLoggedIn) {
          return isLoginRoute ? null : RoutePaths.login;
        }

        if (!isOnboardingComplete) {
          if (isOnboardingRoute) {
            return null;
          }
          return RoutePaths.onboarding;
        }

        if (location == RoutePaths.splash ||
            isLoginRoute ||
            isOnboardingRoute) {
          return RoutePaths.home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RoutePaths.splash,
          builder: (context, state) => SplashPage(
            onTimeout: () {
              ref.read(showSplashProvider.notifier).state = false;
            },
          ),
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: RoutePaths.onboarding,
          builder: (context, state) => const OnboardingHubPage(),
        ),
        GoRoute(
          path: RoutePaths.characterStart,
          builder: (context, state) => CharacterStartPage(
            onCompleted: (character) {
              ref.read(userCharacterProvider.notifier).state = character;
              ref.read(skippedCharacterProvider.notifier).state = false;
              context.go(RoutePaths.onboarding);
            },
          ),
        ),
        GoRoute(
          path: RoutePaths.preferenceIntro,
          builder: (context, state) =>
              PreferenceIntroPage(profile: PreferenceProfile.mock()),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
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
                  path: RoutePaths.onmoim,
                  builder: (context, state) => const OnMoimListPage(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const OnMoimCreatePage(),
                    ),
                    GoRoute(
                      path: ':onmoimId',
                      builder: (context, state) => const OnMoimGroupHomePage(),
                      routes: [
                        GoRoute(
                          path: 'members',
                          builder: (context, state) => OnMoimMemberListPage(
                            onmoimId: state.pathParameters['onmoimId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'invite',
                          builder: (context, state) => OnMoimInvitePage(
                            onmoimId: state.pathParameters['onmoimId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'settings',
                          builder: (context, state) => OnMoimGroupSettingsPage(
                            onmoimId: state.pathParameters['onmoimId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'chat',
                          builder: (context, state) => const OnMoimThreadPage(),
                        ),
                        GoRoute(
                          path: 'memories',
                          builder: (context, state) =>
                              const OnMoimMemoryBoardPage(),
                          routes: [
                            GoRoute(
                              path: ':memoryId',
                              builder: (context, state) =>
                                  OnMoimMemoryDetailPage(
                                    onmoimId: state.pathParameters['onmoimId']!,
                                    memoryId: state.pathParameters['memoryId']!,
                                  ),
                            ),
                          ],
                        ),
                        GoRoute(
                          path: 'meetups/new/members',
                          builder: (context, state) => MeetupCreatePage(
                            onmoimId: state.pathParameters['onmoimId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'meetups',
                          builder: (context, state) => OnMoimMeetupListPage(
                            onmoimId: state.pathParameters['onmoimId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'meetups/new/schedule',
                          builder: (context, state) => MeetupCreatePage(
                            onmoimId: state.pathParameters['onmoimId']!,
                          ),
                          routes: [
                            GoRoute(
                              path: 'calendar',
                              builder: (context, state) => MeetupCreatePage(
                                onmoimId: state.pathParameters['onmoimId']!,
                              ),
                            ),
                          ],
                        ),
                        GoRoute(
                          path: 'meetups/:meetupId',
                          builder: (context, state) => MeetupDetailPage(
                            onmoimId: state.pathParameters['onmoimId']!,
                            meetupId: state.pathParameters['meetupId']!,
                            placeConfirmed:
                                state.uri.queryParameters['place'] ==
                                'confirmed',
                          ),
                          routes: [
                            GoRoute(
                              path: 'board',
                              builder: (context, state) =>
                                  const OnMoimMeetupBoardPage(),
                            ),
                            GoRoute(
                              path: 'places',
                              builder: (context, state) {
                                return PlaceCandidatePage(
                                  onmoimId: state.pathParameters['onmoimId']!,
                                  meetupId: state.pathParameters['meetupId']!,
                                  showVoteResult:
                                      state.uri.queryParameters['voteResult'] ==
                                      '1',
                                );
                              },
                              routes: [
                                GoRoute(
                                  path: 'search',
                                  builder: (context, state) =>
                                      PlaceSearchFilterPage(
                                        onmoimId:
                                            state.pathParameters['onmoimId']!,
                                        meetupId:
                                            state.pathParameters['meetupId']!,
                                      ),
                                ),
                                GoRoute(
                                  path: 'map',
                                  builder: (context, state) => PlaceMapPage(
                                    onmoimId: state.pathParameters['onmoimId']!,
                                    meetupId: state.pathParameters['meetupId']!,
                                  ),
                                ),
                                GoRoute(
                                  path: 'risks',
                                  builder: (context, state) => PlaceRisksPage(
                                    onmoimId: state.pathParameters['onmoimId']!,
                                    meetupId: state.pathParameters['meetupId']!,
                                  ),
                                  routes: [
                                    GoRoute(
                                      path: 'keyword',
                                      builder: (context, state) =>
                                          PlaceRiskDialogPreviewPage(
                                            onmoimId: state
                                                .pathParameters['onmoimId']!,
                                            meetupId: state
                                                .pathParameters['meetupId']!,
                                            kind: PlaceRiskDialogKind.keyword,
                                          ),
                                    ),
                                    GoRoute(
                                      path: 'break-time',
                                      builder: (context, state) =>
                                          PlaceRiskDialogPreviewPage(
                                            onmoimId: state
                                                .pathParameters['onmoimId']!,
                                            meetupId: state
                                                .pathParameters['meetupId']!,
                                            kind: PlaceRiskDialogKind.breakTime,
                                          ),
                                    ),
                                    GoRoute(
                                      path: 'closed-day',
                                      builder: (context, state) =>
                                          PlaceRiskDialogPreviewPage(
                                            onmoimId: state
                                                .pathParameters['onmoimId']!,
                                            meetupId: state
                                                .pathParameters['meetupId']!,
                                            kind: PlaceRiskDialogKind.closedDay,
                                          ),
                                    ),
                                  ],
                                ),
                                GoRoute(
                                  path: ':placeId',
                                  builder: (context, state) => PlaceDetailPage(
                                    onmoimId: state.pathParameters['onmoimId']!,
                                    meetupId: state.pathParameters['meetupId']!,
                                    placeId:
                                        state.pathParameters['placeId'] ??
                                        'onmu-diner',
                                  ),
                                ),
                              ],
                            ),
                            GoRoute(
                              path: 'place-compare',
                              builder: (context, state) => PlaceComparePage(
                                onmoimId: state.pathParameters['onmoimId']!,
                                meetupId: state.pathParameters['meetupId']!,
                              ),
                            ),
                            GoRoute(
                              path: 'route-review',
                              builder: (context, state) =>
                                  MeetupRouteReviewPage(
                                    onmoimId: state.pathParameters['onmoimId']!,
                                    meetupId: state.pathParameters['meetupId']!,
                                  ),
                            ),
                            GoRoute(
                              path: 'complete',
                              builder: (context, state) => MeetupDetailPage(
                                onmoimId: state.pathParameters['onmoimId']!,
                                meetupId: state.pathParameters['meetupId']!,
                                placeConfirmed: true,
                              ),
                            ),
                            GoRoute(
                              path: 'settlements/new',
                              builder: (context, state) =>
                                  OnMoimSettlementCreatePage(
                                    onmoimId: state.pathParameters['onmoimId']!,
                                    meetupId: state.pathParameters['meetupId']!,
                                  ),
                            ),
                            GoRoute(
                              path: 'settlements/:settlementId',
                              builder: (context, state) =>
                                  OnMoimSettlementSharePage(
                                    onmoimId: state.pathParameters['onmoimId']!,
                                    meetupId: state.pathParameters['meetupId']!,
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
                  path: RoutePaths.ootdList,
                  builder: (context, state) {
                    final character =
                        ref.watch(userCharacterProvider) ??
                        const CharacterDraft();
                    final records = ref.watch(customRecordsProvider);
                    return OotdListPage(
                      userCharacter: character,
                      customRecords: records,
                      onAddOotd: (date, ootdRecord) {
                        context.push(
                          '/ootd/new/ootd?date=${date.toIso8601String()}',
                          extra: ootdRecord,
                        );
                      },
                      onAddDailyRecord: (date, ootdRecord) {
                        context.push(
                          '/ootd/new/daily?date=${date.toIso8601String()}',
                          extra: ootdRecord,
                        );
                      },
                      onViewOotdDetail: (record) {
                        final type = record.brands['recordType'] ?? 'ootd';
                        final recordKey =
                            '${record.date.year}-${record.date.month}-${record.date.day}-$type';
                        context.push('/memories/$recordKey');
                      },
                      onNavigateToProfile: () {
                        _showResetDialog(context);
                      },
                    );
                  },
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
          path: '/ootd/new/daily',
          builder: (context, state) {
            final dateStr =
                state.uri.queryParameters['date'] ??
                DateTime.now().toIso8601String();
            final date = DateTime.parse(dateStr);
            final ootdRecord = state.extra as OotdRecord?;
            final character =
                ref.read(userCharacterProvider) ?? const CharacterDraft();

            return DailyRecordScreen(
              userCharacter: character,
              recordDate: date,
              ootdRecord: ootdRecord,
              onSave: _upsertRecord,
              onCreateOotd: () {
                context.push(
                  '/ootd/new/ootd?date=${date.toIso8601String()}&daily=1',
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/ootd/new/ootd',
          builder: (context, state) {
            final dateStr =
                state.uri.queryParameters['date'] ??
                DateTime.now().toIso8601String();
            final date = DateTime.parse(dateStr);
            final character =
                ref.read(userCharacterProvider) ?? const CharacterDraft();
            final existingRecord = state.extra as OotdRecord?;
            final isDailyRecord = state.uri.queryParameters['daily'] == '1';

            return OotdRecordScreen(
              userCharacter: character,
              recordDate: date,
              existingRecord: existingRecord,
              isDailyRecord: isDailyRecord,
              onSave: _upsertRecord,
            );
          },
        ),
        GoRoute(
          path: '/memories/:memoryId',
          builder: (context, state) {
            final memoryId = state.pathParameters['memoryId'] ?? '0';
            return MemoryDetailPage(memoryId: memoryId);
          },
        ),
        GoRoute(
          path: '/memories/:memoryId/template-diary',
          builder: (context, state) {
            final memoryId = state.pathParameters['memoryId'] ?? '0';
            return MemoryDiaryTemplatePage(memoryId: memoryId);
          },
        ),
      ],
    );
  }

  void _upsertRecord(OotdRecord newRecord) {
    ref.read(customRecordsProvider.notifier).update((state) {
      final type = newRecord.brands['recordType'] ?? 'daily';
      final index = state.indexWhere((record) {
        return record.date.year == newRecord.date.year &&
            record.date.month == newRecord.date.month &&
            record.date.day == newRecord.date.day &&
            (record.brands['recordType'] ?? 'daily') == type;
      });

      if (index != -1) {
        final list = List<OotdRecord>.from(state);
        list[index] = newRecord;
        return list;
      }

      return [...state, newRecord];
    });
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('캐릭터 재설정'),
        content: const Text('캐릭터를 처음부터 다시 만들까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(userCharacterProvider.notifier).state = null;
              ref.read(skippedCharacterProvider.notifier).state = false;
            },
            child: const Text('초기화', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(showSplashProvider, (previous, next) {
      _refreshNotifier.notify();
    });
    ref.listen(authUserProvider, (previous, next) {
      _refreshNotifier.notify();
    });
    ref.listen(userCharacterProvider, (previous, next) {
      _refreshNotifier.notify();
    });
    ref.listen(preferenceProfileProvider, (previous, next) {
      _refreshNotifier.notify();
    });
    ref.listen(skippedCharacterProvider, (previous, next) {
      _refreshNotifier.notify();
    });
    ref.listen(skippedPreferenceProvider, (previous, next) {
      _refreshNotifier.notify();
    });

    return MaterialApp.router(
      title: 'ONMU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
