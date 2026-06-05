import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/demo_route_seeds.dart';
import 'core/routing/legacy_route_redirects.dart';
import 'core/routing/route_paths.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/character/character_start_page.dart';
import 'features/home/home_page.dart';
import 'features/home/presentation/pages/home_notifications_page.dart';
import 'features/home/presentation/pages/home_recent_records_page.dart';
import 'features/home/presentation/pages/upcoming_meetups_page.dart';
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
import 'features/onmoim/presentation/pages/onmoim_settlement_target_selection_page.dart';
import 'features/onmoim/presentation/pages/onmoim_thread_page.dart';
import 'features/onmoim/presentation/pages/onmoim_vote_detail_page.dart';
import 'features/onmoim/presentation/pages/onmoim_vote_list_page.dart';
import 'features/onboarding/onboarding_hub_page.dart';
import 'features/ootd/ootd_list_page.dart';
import 'features/ootd/presentation/pages/daily_record_screen.dart';
import 'features/ootd/presentation/pages/ootd_record_screen.dart';
import 'features/place/presentation/pages/place_candidate_page.dart';
import 'features/place/presentation/pages/place_detail_page.dart';
import 'features/place/presentation/pages/place_map_page.dart';
import 'features/place/presentation/pages/place_search_filter_page.dart';
import 'features/place/presentation/pages/place_vote_create_page.dart';
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
  var _myResetToken = 0;

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
            location == RoutePaths.onboardingCharacter ||
            location == RoutePaths.onboardingPreferences;
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

        if (location == RoutePaths.splash || isLoginRoute) {
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
          path: RoutePaths.onboardingCharacter,
          builder: (context, state) => CharacterStartPage(
            onBackToOnboarding: () => context.go(RoutePaths.onboarding),
            onCompleted: (character) {
              ref.read(userCharacterProvider.notifier).state = character;
              ref.read(skippedCharacterProvider.notifier).state = false;
              context.go(RoutePaths.onboarding);
            },
          ),
        ),
        GoRoute(
          path: RoutePaths.onboardingPreferences,
          builder: (context, state) =>
              PreferenceIntroPage(profile: PreferenceProfile.mock()),
        ),
        ...legacyRedirectRoutes(),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(
              navigationShell: navigationShell,
              onMyTabReselected: _resetMyTab,
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.home,
                  builder: (context, state) => const HomePage(),
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
                              builder: (context, state) =>
                                  OnMoimMemoryDetailPage(
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
                                editingMeetupId:
                                    state.uri.queryParameters['edit'],
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
                                        onmoimId:
                                            state.pathParameters['groupId']!,
                                        meetupId:
                                            state.pathParameters['planId']!,
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
                              builder: (context, state) =>
                                  MeetupRouteReviewPage(
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
                          '${RoutePaths.recordNewOotd}?date=${date.toIso8601String()}',
                          extra: ootdRecord,
                        );
                      },
                      onAddDailyRecord: (date, ootdRecord) {
                        context.push(
                          '${RoutePaths.recordNewDaily}?date=${date.toIso8601String()}',
                          extra: ootdRecord,
                        );
                      },
                      onViewOotdDetail: (record) {
                        final type = record.brands['recordType'] ?? 'ootd';
                        final recordKey =
                            '${record.date.year}-${record.date.month}-${record.date.day}-$type';
                        context.push(RoutePaths.recordDetail(recordKey));
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
                  builder: (context, state) =>
                      MyPage(resetToken: _myResetToken.toString()),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.recordNewDaily,
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
                  '${RoutePaths.recordNewOotd}?date=${date.toIso8601String()}&daily=1',
                );
              },
            );
          },
        ),
        GoRoute(
          path: RoutePaths.recordNewOotd,
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
          path: '/records/:recordId',
          builder: (context, state) {
            final recordId = state.pathParameters['recordId'] ?? '0';
            return MemoryDetailPage(memoryId: recordId);
          },
        ),
        GoRoute(
          path: '/records/:recordId/template-diary',
          builder: (context, state) {
            final recordId = state.pathParameters['recordId'] ?? '0';
            return MemoryDiaryTemplatePage(memoryId: recordId);
          },
        ),
      ],
    );
  }

  void _resetMyTab() {
    setState(() {
      _myResetToken += 1;
    });
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
