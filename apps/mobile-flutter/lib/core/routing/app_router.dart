import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/character/presentation/pages/character_start_page.dart';
import '../../features/home/presentation/pages/home_notifications_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/home_recent_records_page.dart';
import '../../features/home/view_model/home_view_model.dart';
import '../../features/home/presentation/pages/upcoming_plans_page.dart';
import '../../features/launch/splash_page.dart';
import '../../features/launch/start_page.dart';
import '../../features/plan/presentation/pages/plan_create_page.dart';
import '../../features/plan/presentation/pages/plan_detail_page.dart';
import '../../features/plan/presentation/pages/plan_itinerary_page.dart';
import '../../features/memory/presentation/pages/memory_detail_page.dart';
import '../../features/memory/presentation/pages/memory_diary_template_page.dart';
import '../../features/my/presentation/pages/my_page.dart';
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
import '../../features/group/presentation/pages/plan_settlement_basis_page.dart';
import '../../features/group/presentation/pages/plan_settlement_detail_page.dart';
import '../../features/group/presentation/pages/plan_settlement_target_selection_page.dart';
import '../../features/group/presentation/pages/group_chat_page.dart';
import '../../features/group/presentation/pages/vote_detail_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_hub_page.dart';
import '../../features/onboarding/view_model/onboarding_character_controller.dart';
import '../../features/ootd/presentation/pages/ootd_list_page.dart';
import '../../features/ootd/presentation/pages/daily_record_edit_screen.dart';
import '../../features/ootd/presentation/pages/daily_record_screen.dart';
import '../../features/ootd/presentation/pages/ootd_record_screen.dart';
import '../../features/ootd/view_model/record_flow_controller.dart';
import '../../features/group/presentation/pages/group_vote_list_page.dart';
import '../../features/place/presentation/pages/place_candidate_page.dart';
import '../../features/place/presentation/pages/place_detail_page.dart';
import '../../features/place/presentation/pages/place_map_page.dart';
import '../../features/place/presentation/pages/place_search_filter_page.dart';
import '../../features/place/presentation/pages/place_vote_create_page.dart';
import '../../features/preferences/presentation/pages/preference_intro_page.dart';
import '../../main_shell.dart';
import '../../shared/models/group_models.dart';
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
      redirect: _redirectCompletedOnboarding,
      builder: (context, state) => Consumer(
        builder: (context, ref, child) {
          final profile =
              ref.watch(preferenceProfileProvider) ?? PreferenceProfile.empty();

          return _OnboardingAccessGate(
            child: PreferenceIntroPage(profile: profile),
          );
        },
      ),
    ),
    GoRoute(
      path: RoutePaths.onboarding,
      redirect: _redirectCompletedOnboarding,
      builder: (context, state) =>
          const _OnboardingAccessGate(child: OnboardingHubPage()),
    ),
    GoRoute(
      path: RoutePaths.onboardingCharacter,
      redirect: _redirectCompletedOnboarding,
      builder: (context, state) => Consumer(
        builder: (context, ref, child) {
          return _OnboardingAccessGate(
            child: CharacterStartPage(
              completionButtonLabel: '첫 설정 페이지로 돌아가기',
              onBackToOnboarding: () => context.popOrGo(RoutePaths.onboarding),
              onCompleted: (draft) async {
                final router = GoRouter.of(context);
                try {
                  await ref
                      .read(onboardingCharacterControllerProvider)
                      .saveCharacter(draft);
                  router.go(RoutePaths.onboarding);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '\uCE90\uB9AD\uD130 \uC800\uC7A5\uC5D0 \uC2E4\uD328\uD588\uC5B4\uC694. API \uC5F0\uACB0 \uC0C1\uD0DC\uB97C \uD655\uC778\uD574 \uC8FC\uC138\uC694.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          );
        },
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
                      path: 'plans',
                      builder: (context, state) => GroupPlanListPage(
                        groupId: state.pathParameters['groupId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'new',
                          builder: (context, state) => PlanCreatePage(
                            groupId: state.pathParameters['groupId']!,
                          ),
                          routes: [
                            GoRoute(
                              path: 'schedule',
                              builder: (context, state) => PlanCreatePage(
                                groupId: state.pathParameters['groupId']!,
                                entryIntent: PlanCreateEntryIntent.schedule,
                              ),
                              routes: [
                                GoRoute(
                                  path: 'calendar',
                                  builder: (context, state) => PlanCreatePage(
                                    groupId: state.pathParameters['groupId']!,
                                    entryIntent: PlanCreateEntryIntent.calendar,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        GoRoute(
                          path: ':planId',
                          builder: (context, state) => PlanDetailPage(
                            groupId: state.pathParameters['groupId']!,
                            planId: state.pathParameters['planId']!,
                          ),
                          routes: [
                            GoRoute(
                              path: 'edit',
                              builder: (context, state) => PlanCreatePage(
                                groupId: state.pathParameters['groupId']!,
                                editingPlanId: state.pathParameters['planId']!,
                              ),
                            ),
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
                                    placeId:
                                        state.pathParameters['candidateId']!,
                                  ),
                                ),
                              ],
                            ),
                            GoRoute(
                              path: 'place-search',
                              pageBuilder: (context, state) =>
                                  NoTransitionPage<void>(
                                    key: state.pageKey,
                                    child: PlaceMapPage(
                                      groupId: state.pathParameters['groupId']!,
                                      planId: state.pathParameters['planId']!,
                                      initialQuery:
                                          state.uri.queryParameters['query'] ??
                                          '',
                                    ),
                                  ),
                              routes: [
                                GoRoute(
                                  path: 'results',
                                  builder: (context, state) =>
                                      PlaceSearchFilterPage(
                                        groupId:
                                            state.pathParameters['groupId']!,
                                        planId: state.pathParameters['planId']!,
                                      ),
                                ),
                              ],
                            ),
                            GoRoute(
                              path: 'votes',
                              builder: (context, state) => GroupVoteListPage(
                                groupId: state.pathParameters['groupId']!,
                                planId: state.pathParameters['planId']!,
                              ),
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
                                planId: state.pathParameters['planId']!,
                              ),
                            ),
                            GoRoute(
                              path: 'itinerary',
                              builder: (context, state) => PlanItineraryPage(
                                groupId: state.pathParameters['groupId']!,
                                planId: state.pathParameters['planId']!,
                                initialDateIndex: _dateIndexFromState(state),
                              ),
                            ),
                            GoRoute(
                              path: 'settlements/new',
                              builder: (context, state) =>
                                  PlanSettlementCreatePage(
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
                              builder: (context, state) =>
                                  PlanSettlementDetailPage(
                                    groupId: state.pathParameters['groupId']!,
                                    planId: state.pathParameters['planId']!,
                                    preview: true,
                                  ),
                            ),
                            GoRoute(
                              path: 'settlements/current',
                              builder: (context, state) =>
                                  PlanSettlementDetailPage(
                                    groupId: state.pathParameters['groupId']!,
                                    planId: state.pathParameters['planId']!,
                                  ),
                            ),
                            GoRoute(
                              path: 'settlements/:settlementId/basis',
                              builder: (context, state) =>
                                  PlanSettlementBasisPage(
                                    groupId: state.pathParameters['groupId']!,
                                    planId: state.pathParameters['planId']!,
                                    settlementId:
                                        state.pathParameters['settlementId']!,
                                  ),
                            ),
                            GoRoute(
                              path: 'settlements/:settlementId',
                              builder: (context, state) =>
                                  PlanSettlementDetailPage(
                                    groupId: state.pathParameters['groupId']!,
                                    planId: state.pathParameters['planId']!,
                                    settlementId:
                                        state.pathParameters['settlementId']!,
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
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.records,
              builder: (context, state) => Consumer(
                builder: (context, ref, child) {
                  final routeState = ref.watch(recordRouteStateProvider);
                  final controller = ref.watch(recordFlowControllerProvider);
                  final homeState = ref
                      .watch(homeViewModelProvider)
                      .asData
                      ?.value;

                  return OotdListPage(
                    userCharacter: routeState.character,
                    customRecords: routeState.records.value ?? const [],
                    onAddOotd: (date, ootdRecord) {
                      context.push(
                        '${RoutePaths.recordNewOotd}?date=${date.toIso8601String()}',
                        extra: ootdRecord,
                      );
                    },
                    onAddDailyRecord: (date, ootdRecord) {
                      final dailyContext = _dailyRoutePlanContextFor(
                        date,
                        homeState,
                      );
                      final uri = Uri(
                        path: RoutePaths.recordNewDaily,
                        queryParameters: {
                          'date': date.toIso8601String(),
                          if (dailyContext.groupId != null)
                            'groupId': dailyContext.groupId!,
                          if (dailyContext.planId != null)
                            'planId': dailyContext.planId!,
                          if (dailyContext.memoryPlaceNames.isNotEmpty)
                            'memoryPlaces': _encodeDailyMemoryPlaces(
                              dailyContext.memoryPlaceNames,
                            ),
                        },
                      );
                      context.push(uri.toString(), extra: ootdRecord);
                    },
                    onViewOotdDetail: (record) {
                      context.push(
                        RoutePaths.recordDetail(
                          controller.detailKeyFor(record),
                        ),
                      );
                    },
                    onEditRecord: (record) async {
                      if (controller.validateEditableRecord(record) ==
                          RecordMutationResult.missingId) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이 기록은 아직 수정할 수 없어요. 다시 시도해 주세요.'),
                          ),
                        );
                        return null;
                      }
                      final result = await context.push<Object?>(
                        RoutePaths.recordEdit(record.id!),
                      );
                      controller.refreshRecords();
                      return result;
                    },
                    onDeleteRecord: (record) async {
                      final result = await controller.deleteRecord(record);
                      if (result == RecordMutationResult.missingId) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이 기록은 아직 삭제할 수 없어요. 다시 시도해 주세요.'),
                          ),
                        );
                        return;
                      }
                    },
                    onSaveRecordImage: controller.saveRecordImage,
                    onNavigateToProfile: () =>
                        _showResetDialog(context, controller),
                  );
                },
              ),
              routes: [
                GoRoute(
                  path: 'edit/:recordId',
                  builder: (context, state) {
                    final recordId = state.pathParameters['recordId'] ?? '0';
                    return DailyRecordEditScreen(memoryId: recordId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.my,
              builder: (context, state) =>
                  MyPage(resetToken: state.uri.queryParameters['reset']),
              routes: [
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const MySettingsPage(),
                ),
              ],
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
          final routeState = ref.watch(recordRouteStateProvider);
          final controller = ref.watch(recordFlowControllerProvider);
          final homeState = ref.watch(homeViewModelProvider).asData?.value;
          final dailyContext = _dailyRoutePlanContextFor(date, homeState);
          final groupId =
              state.uri.queryParameters['groupId'] ?? dailyContext.groupId;
          final planId =
              state.uri.queryParameters['planId'] ?? dailyContext.planId;
          final queryMemoryPlaceNames = _decodeDailyMemoryPlaces(
            state.uri.queryParameters['memoryPlaces'],
          );
          final memoryPlaceNames = queryMemoryPlaceNames.isNotEmpty
              ? queryMemoryPlaceNames
              : dailyContext.memoryPlaceNames;

          return DailyRecordScreen(
            userCharacter: routeState.character,
            recordDate: date,
            ootdRecord: ootdRecord,
            memoryPlaceNames: memoryPlaceNames,
            groupId: groupId,
            planId: planId,
            onFetchCrewAppearances: controller.fetchCrewOotdAppearances,
            onSave: controller.saveRecord,
            onUploadMedia: controller.uploadMedia,
            onCreateOotd: () {
              return context.push<OotdRecord>(
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
          final routeState = ref.watch(recordRouteStateProvider);
          final controller = ref.watch(recordFlowControllerProvider);
          final existingRecord = state.extra as OotdRecord?;
          final isDailyRecord = state.uri.queryParameters['daily'] == '1';

          return OotdRecordScreen(
            userCharacter: routeState.character,
            recordDate: date,
            existingRecord: existingRecord,
            isDailyRecord: isDailyRecord,
            onSave: controller.saveRecord,
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

Future<String?> _redirectCompletedOnboarding(
  BuildContext context,
  GoRouterState state,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final existingUser =
      container.read(authUserProvider) ??
      container.read(authBootstrapProvider).asData?.value.user;
  if (existingUser?.hasCompletedOnboarding == true) {
    return RoutePaths.home;
  }
  final AuthBootstrapResult bootstrap;
  try {
    bootstrap = await container
        .read(authBootstrapProvider.future)
        .timeout(const Duration(seconds: 6));
  } catch (_) {
    return null;
  }
  final user = bootstrap.user;
  if (user?.hasCompletedOnboarding == true) {
    return RoutePaths.home;
  }
  return null;
}

class _OnboardingAccessGate extends ConsumerWidget {
  const _OnboardingAccessGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(authBootstrapProvider);
    final user = bootstrap.asData?.value.user ?? ref.watch(authUserProvider);
    if (user?.hasCompletedOnboarding == true) {
      return const SizedBox.shrink();
    }

    if (bootstrap.isLoading && user == null) {
      return const SizedBox.shrink();
    }

    return child;
  }
}

class _DailyRoutePlanContext {
  const _DailyRoutePlanContext({
    required this.memoryPlaceNames,
    this.groupId,
    this.planId,
  });

  final List<String> memoryPlaceNames;
  final String? groupId;
  final String? planId;
}

const _dailyMemoryPlaceSeparator = '\u001F';

String _encodeDailyMemoryPlaces(List<String> places) {
  return places
      .map((place) => place.trim())
      .where((place) => place.isNotEmpty)
      .join(_dailyMemoryPlaceSeparator);
}

List<String> _decodeDailyMemoryPlaces(String? encoded) {
  if (encoded == null || encoded.trim().isEmpty) {
    return const [];
  }
  final seen = <String>{};
  final places = <String>[];
  for (final rawPlace in encoded.split(_dailyMemoryPlaceSeparator)) {
    final place = rawPlace.trim();
    if (place.isEmpty) continue;
    final key = place.toLowerCase();
    if (seen.add(key)) {
      places.add(place);
    }
  }
  return List<String>.unmodifiable(places);
}

_DailyRoutePlanContext _dailyRoutePlanContextFor(
  DateTime date,
  HomeState? homeState,
) {
  final plans =
      homeState?.calendarPlans
          .where((plan) => _planOccursOnDate(plan, date))
          .toList(growable: false) ??
      const <GroupPlanSummary>[];

  if (plans.isEmpty) {
    return const _DailyRoutePlanContext(memoryPlaceNames: []);
  }

  final orderedPlans = [...plans]
    ..sort((a, b) {
      final aStart = a.startsAt;
      final bStart = b.startsAt;
      if (aStart == null && bStart == null) return a.id.compareTo(b.id);
      if (aStart == null) return 1;
      if (bStart == null) return -1;
      return aStart.compareTo(bStart);
    });

  final memoryPlaces = <String>[];
  final seenPlaces = <String>{};
  for (final plan in orderedPlans) {
    final place = plan.placeName.trim();
    if (place.isEmpty) continue;
    final key = place.toLowerCase();
    if (seenPlaces.add(key)) {
      memoryPlaces.add(place);
    }
  }

  return _DailyRoutePlanContext(
    memoryPlaceNames: List<String>.unmodifiable(memoryPlaces),
    groupId: homeState?.groupId?.toString(),
    planId: orderedPlans.first.id.toString(),
  );
}

bool _planOccursOnDate(GroupPlanSummary plan, DateTime date) {
  if (plan.progressStatus == PlanProgressStatus.cancelled) {
    return false;
  }

  final target = DateTime(date.year, date.month, date.day);
  final start = plan.startsAt?.toLocal();
  final end = plan.endsAt?.toLocal();

  if (start == null && end == null) {
    return false;
  }

  final firstDay = start == null
      ? DateTime(end!.year, end.month, end.day)
      : DateTime(start.year, start.month, start.day);
  final lastDay = end == null
      ? firstDay
      : DateTime(end.year, end.month, end.day);

  return !target.isBefore(firstDay) && !target.isAfter(lastDay);
}

DateTime _recordDateFromState(GoRouterState state) {
  final dateStr =
      state.uri.queryParameters['date'] ?? DateTime.now().toIso8601String();
  return DateTime.parse(dateStr);
}

int _dateIndexFromState(GoRouterState state) {
  final parsed = int.tryParse(state.uri.queryParameters['dateIndex'] ?? '');
  if (parsed == null || parsed < 0) {
    return 0;
  }
  return parsed;
}

void _showResetDialog(BuildContext context, RecordFlowController controller) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('\uCE90\uB9AD\uD130 \uC7AC\uC124\uC815'),
      content: const Text(
        '\uCE90\uB9AD\uD130\uB97C \uCC98\uC74C\uBD80\uD130 \uB2E4\uC2DC \uB9CC\uB4E4\uAE4C\uC694?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('\uCDE8\uC18C'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            controller.resetCharacterDraft();
          },
          child: const Text(
            '\uCD08\uAE30\uD654',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}
