import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/character/character_start_page.dart';
import '../../features/character/repository/character_repository.dart';
import '../../features/home/presentation/pages/home_notifications_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/home_recent_records_page.dart';
import '../../features/home/presentation/pages/upcoming_plans_page.dart';
import '../../features/launch/splash_page.dart';
import '../../features/launch/start_page.dart';
import '../../features/plan/presentation/pages/plan_create_page.dart';
import '../../features/plan/presentation/pages/plan_detail_page.dart';
import '../../features/plan/presentation/pages/plan_itinerary_page.dart';
import '../../features/memory/presentation/pages/memory_detail_page.dart';
import '../../features/memory/presentation/pages/memory_diary_template_page.dart';
import '../../features/my/my_page.dart';
import '../../features/group/presentation/pages/group_home_page.dart';
import '../../features/group/presentation/pages/group_settings_page.dart';
import '../../features/group/presentation/pages/group_create_page.dart';
import '../../features/group/presentation/pages/group_list_page.dart';
import '../../features/group/presentation/pages/group_plan_list_page.dart';
import '../../features/group/presentation/pages/group_member_list_page.dart';
import '../../features/group/presentation/pages/group_plan_board_page.dart';
import '../../features/group/presentation/pages/group_memory_board_page.dart';
import '../../features/group/presentation/pages/group_memory_detail_page.dart';
import '../../features/group/presentation/pages/plan_settlement_create_page.dart';
import '../../features/group/presentation/pages/plan_settlement_detail_page.dart';
import '../../features/group/presentation/pages/plan_settlement_target_selection_page.dart';
import '../../features/group/presentation/pages/group_chat_page.dart';
import '../../features/group/presentation/pages/vote_detail_page.dart';
import '../../features/onboarding/onboarding_hub_page.dart';
import '../../features/ootd/ootd_list_page.dart';
import '../../features/ootd/presentation/pages/daily_record_screen.dart';
import '../../features/ootd/presentation/pages/ootd_record_screen.dart';
import '../../features/ootd/repository/record_repository.dart';
import '../../features/group/presentation/pages/group_vote_list_page.dart';
import '../../features/place/presentation/pages/place_candidate_page.dart';
import '../../features/place/presentation/pages/place_detail_page.dart';
import '../../features/place/presentation/pages/place_map_page.dart';
import '../../features/place/presentation/pages/place_search_filter_page.dart';
import '../../features/place/presentation/pages/place_vote_create_page.dart';
import '../../features/preferences/preference_intro_page.dart';
import '../../main_shell.dart';
import '../../shared/models/character_model.dart';
import '../../shared/models/ootd_model.dart';
import '../../shared/models/preference_profile.dart';
import '../../shared/providers/state_providers.dart';
import 'navigation_extensions.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: [
    GoRoute(path: '/', redirect: (context, state) => RoutePaths.splash),
    GoRoute(
      path: RoutePaths.splash,
      builder: (context, state) => Consumer(
        builder: (context, ref, child) {
          ref.watch(authBootstrapProvider);
          return SplashPage(
            onTimeout: () async {
              final nextRoute = await _resolvePostSplashRoute(ref);
              if (context.mounted) {
                context.go(nextRoute);
              }
            },
          );
        },
      ),
    ),
    GoRoute(
      path: RoutePaths.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: RoutePaths.start,
      builder: (context, state) => const StartPage(),
    ),
    GoRoute(
      path: RoutePaths.onboardingPreferences,
      builder: (context, state) => Consumer(
        builder: (context, ref, child) {
          final profile =
              ref.watch(preferenceProfileProvider) ?? PreferenceProfile.empty();

          return PreferenceIntroPage(profile: profile);
        },
      ),
    ),
    GoRoute(
      path: RoutePaths.onboarding,
      builder: (context, state) => const OnboardingHubPage(),
    ),
    GoRoute(
      path: RoutePaths.onboardingCharacter,
      builder: (context, state) => Consumer(
        builder: (context, ref, child) => CharacterStartPage(
          onBackToOnboarding: () => context.popOrGo(RoutePaths.onboarding),
          onCompleted: (draft) async {
            final router = GoRouter.of(context);
            CharacterDraft saved;
            try {
              saved = await ref
                  .read(characterRepositoryProvider)
                  .saveMyCharacter(draft);
            } catch (_) {
              saved = draft;
            }
            ref.read(userCharacterProvider.notifier).state = saved;
            ref.read(skippedCharacterProvider.notifier).state = false;
            ref.invalidate(characterProfileProvider);
            router.go(RoutePaths.onboarding);
          },
        ),
      ),
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
              builder: (context, state) => HomePage(
                summaryProfile: state.extra is PreferenceProfile
                    ? state.extra! as PreferenceProfile
                    : null,
              ),
            ),
            GoRoute(
              path: RoutePaths.homeUpcomingPlans,
              builder: (context, state) => const UpcomingPlansPage(),
            ),
            GoRoute(
              path: RoutePaths.homeUpcomingCalendar,
              builder: (context, state) => const UpcomingPlansCalendarPage(),
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
              builder: (context, state) => const GroupListPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) {
                    final initialMemberNames = state.extra is List<String>
                        ? state.extra! as List<String>
                        : const <String>[];

                    return GroupCreatePage(
                      initialMemberNames: initialMemberNames,
                    );
                  },
                ),
                GoRoute(
                  path: ':groupId',
                  builder: (context, state) =>
                      GroupHomePage(groupId: state.pathParameters['groupId']!),
                  routes: [
                    GoRoute(
                      path: 'members',
                      builder: (context, state) => GroupMemberListPage(
                        groupId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'invite',
                      builder: (context, state) => GroupInvitePage(
                        groupId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'settings',
                      builder: (context, state) => GroupSettingsPage(
                        groupId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'chat',
                      builder: (context, state) => GroupChatPage(
                        groupId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'votes',
                      builder: (context, state) => GroupVoteListPage(
                        groupId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'votes/:voteId',
                      builder: (context, state) => VoteDetailPage(
                        groupId: state.pathParameters['groupId']!,
                        voteId: state.pathParameters['voteId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'memories',
                      builder: (context, state) => GroupMemoryBoardPage(
                        groupId: state.pathParameters['groupId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: ':memoryId',
                          builder: (context, state) => GroupMemoryDetailPage(
                            groupId: state.pathParameters['groupId']!,
                            memoryId: state.pathParameters['memoryId']!,
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'plans/new',
                      builder: (context, state) => PlanCreatePage(
                        groupId: state.pathParameters['groupId']!,
                        editingPlanId: state.uri.queryParameters['edit'],
                      ),
                    ),
                    GoRoute(
                      path: 'plans',
                      builder: (context, state) => GroupPlanListPage(
                        groupId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'plans/new/schedule',
                      builder: (context, state) => PlanCreatePage(
                        groupId: state.pathParameters['groupId']!,
                        editingPlanId: state.uri.queryParameters['edit'],
                      ),
                      routes: [
                        GoRoute(
                          path: 'calendar',
                          builder: (context, state) => PlanCreatePage(
                            groupId: state.pathParameters['groupId']!,
                            editingPlanId: state.uri.queryParameters['edit'],
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'plans/:planId',
                      builder: (context, state) => PlanDetailPage(
                        groupId: state.pathParameters['groupId']!,
                        planId: state.pathParameters['planId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'board',
                          builder: (context, state) => GroupPlanBoardPage(
                            groupId: state.pathParameters['groupId']!,
                            planId: state.pathParameters['planId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'place-candidates',
                          builder: (context, state) {
                            return PlaceCandidatePage(
                              groupId: state.pathParameters['groupId']!,
                              planId: state.pathParameters['planId']!,
                            );
                          },
                          routes: [
                            GoRoute(
                              path: ':candidateId',
                              builder: (context, state) => PlaceDetailPage(
                                groupId: state.pathParameters['groupId']!,
                                planId: state.pathParameters['planId']!,
                                placeId: state.pathParameters['candidateId']!,
                              ),
                            ),
                          ],
                        ),
                        GoRoute(
                          path: 'place-search',
                          builder: (context, state) => PlaceMapPage(
                            groupId: state.pathParameters['groupId']!,
                            planId: state.pathParameters['planId']!,
                          ),
                          routes: [
                            GoRoute(
                              path: 'results',
                              builder: (context, state) =>
                                  PlaceSearchFilterPage(
                                    groupId: state.pathParameters['groupId']!,
                                    planId: state.pathParameters['planId']!,
                                  ),
                            ),
                          ],
                        ),
                        GoRoute(
                          path: 'votes/new',
                          builder: (context, state) => PlaceVoteCreatePage(
                            groupId: state.pathParameters['groupId']!,
                            planId: state.pathParameters['planId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'votes/:voteId',
                          builder: (context, state) => VoteDetailPage(
                            groupId: state.pathParameters['groupId']!,
                            voteId: state.pathParameters['voteId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'itinerary',
                          builder: (context, state) => PlanItineraryPage(
                            groupId: state.pathParameters['groupId']!,
                            planId: state.pathParameters['planId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'settlements/new',
                          builder: (context, state) => PlanSettlementCreatePage(
                            groupId: state.pathParameters['groupId']!,
                            planId: state.pathParameters['planId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'settlements/new/items/:itemId/targets',
                          builder: (context, state) =>
                              PlanSettlementTargetSelectionPage(
                                groupId: state.pathParameters['groupId']!,
                                planId: state.pathParameters['planId']!,
                                itemId: state.pathParameters['itemId']!,
                              ),
                        ),
                        GoRoute(
                          path: 'settlements/new/preview',
                          builder: (context, state) => PlanSettlementDetailPage(
                            groupId: state.pathParameters['groupId']!,
                            planId: state.pathParameters['planId']!,
                            preview: true,
                          ),
                        ),
                        GoRoute(
                          path: 'settlements/:settlementId',
                          builder: (context, state) => PlanSettlementDetailPage(
                            groupId: state.pathParameters['groupId']!,
                            planId: state.pathParameters['planId']!,
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
              builder: (context, state) => Consumer(
                builder: (context, ref, child) {
                  final profile = ref.watch(characterProfileProvider);
                  final character =
                      profile.value ??
                      ref.watch(userCharacterProvider) ??
                      const CharacterDraft();
                  final records = ref.watch(ootdRecordsProvider);

                  return OotdListPage(
                    userCharacter: character,
                    customRecords: records.value ?? const [],
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
                    onNavigateToProfile: () => _showResetDialog(context, ref),
                  );
                },
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.my,
              builder: (context, state) =>
                  MyPage(resetToken: state.uri.queryParameters['reset']),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.recordNewDaily,
      builder: (context, state) => Consumer(
        builder: (context, ref, child) {
          final date = _recordDateFromState(state);
          final ootdRecord = state.extra as OotdRecord?;
          final character =
              ref.watch(characterProfileProvider).value ??
              ref.read(userCharacterProvider) ??
              const CharacterDraft();

          return DailyRecordScreen(
            userCharacter: character,
            recordDate: date,
            ootdRecord: ootdRecord,
            onSave: (record) => _saveRecord(ref, record),
            onCreateOotd: () {
              context.push(
                '${RoutePaths.recordNewOotd}?date=${date.toIso8601String()}&daily=1',
              );
            },
          );
        },
      ),
    ),
    GoRoute(
      path: RoutePaths.recordNewOotd,
      builder: (context, state) => Consumer(
        builder: (context, ref, child) {
          final date = _recordDateFromState(state);
          final character =
              ref.watch(characterProfileProvider).value ??
              ref.read(userCharacterProvider) ??
              const CharacterDraft();
          final existingRecord = state.extra as OotdRecord?;
          final isDailyRecord = state.uri.queryParameters['daily'] == '1';

          return OotdRecordScreen(
            userCharacter: character,
            recordDate: date,
            existingRecord: existingRecord,
            isDailyRecord: isDailyRecord,
            onSave: (record) => _saveRecord(ref, record),
          );
        },
      ),
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

Future<String> _resolvePostSplashRoute(WidgetRef ref) async {
  final AuthBootstrapResult bootstrap;
  try {
    bootstrap = await ref
        .read(authBootstrapProvider.future)
        .timeout(const Duration(seconds: 6));
  } catch (_) {
    return RoutePaths.login;
  }
  final user = bootstrap.user;
  if (user == null) {
    return RoutePaths.login;
  }
  if (user.hasCompletedOnboarding) {
    return RoutePaths.home;
  }
  return RoutePaths.onboarding;
}

DateTime _recordDateFromState(GoRouterState state) {
  final dateStr =
      state.uri.queryParameters['date'] ?? DateTime.now().toIso8601String();
  return DateTime.parse(dateStr);
}

Future<void> _saveRecord(WidgetRef ref, OotdRecord newRecord) async {
  await ref.read(recordRepositoryProvider).createRecord(newRecord);
  ref.invalidate(ootdRecordsProvider);
}

void _showResetDialog(BuildContext context, WidgetRef ref) {
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
