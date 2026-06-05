import 'package:go_router/go_router.dart';

import 'demo_route_seeds.dart';
import 'route_paths.dart';

List<RouteBase> legacyRedirectRoutes() {
  return [
    GoRoute(
      path: '/preferences/intro',
      redirect: (context, state) => RoutePaths.onboardingPreferences,
    ),
    GoRoute(
      path: '/character/start',
      redirect: (context, state) => RoutePaths.onboardingCharacter,
    ),
    GoRoute(
      path: '/home/upcoming-meetups',
      redirect: (context, state) => RoutePaths.homeUpcomingPlans,
    ),
    GoRoute(
      path: '/places',
      redirect: (context, state) => RoutePaths.planPlaceCandidates(
        DemoRouteSeeds.groupId,
        DemoRouteSeeds.planId,
      ),
    ),
    GoRoute(
      path: '/places/search',
      redirect: (context, state) => RoutePaths.planPlaceSearch(
        DemoRouteSeeds.groupId,
        DemoRouteSeeds.planId,
      ),
    ),
    GoRoute(
      path: '/places/map',
      redirect: (context, state) => RoutePaths.planPlaceSearch(
        DemoRouteSeeds.groupId,
        DemoRouteSeeds.planId,
      ),
    ),
    GoRoute(
      path: '/places/risks/:riskKind',
      redirect: (context, state) => RoutePaths.planPlaceSearch(
        DemoRouteSeeds.groupId,
        DemoRouteSeeds.planId,
      ),
    ),
    GoRoute(
      path: '/places/risks',
      redirect: (context, state) => RoutePaths.planPlaceSearch(
        DemoRouteSeeds.groupId,
        DemoRouteSeeds.planId,
      ),
    ),
    GoRoute(
      path: '/places/:candidateId',
      redirect: (context, state) => RoutePaths.planPlaceCandidateDetail(
        DemoRouteSeeds.groupId,
        DemoRouteSeeds.planId,
        state.pathParameters['candidateId']!,
      ),
    ),
    GoRoute(
      path: '/place-compare',
      redirect: (context, state) => RoutePaths.planPlaceCandidates(
        DemoRouteSeeds.groupId,
        DemoRouteSeeds.planId,
      ),
    ),
    GoRoute(
      path: '/route-review',
      redirect: (context, state) => RoutePaths.planItinerary(
        DemoRouteSeeds.groupId,
        DemoRouteSeeds.planId,
      ),
    ),
    GoRoute(
      path: '/complete',
      redirect: (context, state) =>
          RoutePaths.planDetail(DemoRouteSeeds.groupId, DemoRouteSeeds.planId),
    ),
    GoRoute(path: '/onmoim', redirect: (context, state) => RoutePaths.groups),
    GoRoute(
      path: '/onmoim/new',
      redirect: (context, state) => RoutePaths.groupNew,
    ),
    GoRoute(
      path: '/onmoim/:groupId/members',
      redirect: (context, state) =>
          RoutePaths.groupMembers(state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/onmoim/:groupId/invite',
      redirect: (context, state) =>
          RoutePaths.groupInvite(state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/onmoim/:groupId/settings',
      redirect: (context, state) =>
          RoutePaths.groupSettings(state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/onmoim/:groupId/chat',
      redirect: (context, state) =>
          RoutePaths.groupChat(state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/onmoim/:groupId/votes/:voteId',
      redirect: (context, state) => RoutePaths.groupVote(
        state.pathParameters['groupId']!,
        state.pathParameters['voteId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/votes',
      redirect: (context, state) =>
          RoutePaths.groupVotes(state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/onmoim/:groupId/memories/:memoryId',
      redirect: (context, state) => RoutePaths.groupMemoryDetail(
        state.pathParameters['groupId']!,
        state.pathParameters['memoryId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/memories',
      redirect: (context, state) =>
          RoutePaths.groupMemories(state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/new/members',
      redirect: (context, state) =>
          RoutePaths.planNew(state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/new/schedule/calendar',
      redirect: (context, state) =>
          RoutePaths.planNewCalendar(state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/new/schedule',
      redirect: (context, state) =>
          RoutePaths.planNewSchedule(state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/places/search',
      redirect: (context, state) => RoutePaths.planPlaceSearch(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/places/map',
      redirect: (context, state) => RoutePaths.planPlaceSearch(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/places/risks/:riskKind',
      redirect: (context, state) => RoutePaths.planPlaceSearch(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/places/risks',
      redirect: (context, state) => RoutePaths.planPlaceSearch(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/places/vote/new',
      redirect: (context, state) => RoutePaths.planVoteNew(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/places/:candidateId',
      redirect: (context, state) => RoutePaths.planPlaceCandidateDetail(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
        state.pathParameters['candidateId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/places',
      redirect: (context, state) {
        final groupId = state.pathParameters['groupId']!;
        final planId = state.pathParameters['planId']!;
        if (state.uri.queryParameters['voteResult'] == '1') {
          return RoutePaths.planVote(groupId, planId, DemoRouteSeeds.voteId);
        }
        return RoutePaths.planPlaceCandidates(groupId, planId);
      },
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/place-compare',
      redirect: (context, state) => RoutePaths.planPlaceCandidates(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/route-review',
      redirect: (context, state) => RoutePaths.planItinerary(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/complete',
      redirect: (context, state) => RoutePaths.planDetail(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
      ),
    ),
    GoRoute(
      path:
          '/onmoim/:groupId/meetups/:planId/settlements/new/items/:itemId/targets',
      redirect: (context, state) => RoutePaths.planSettlementTargets(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
        state.pathParameters['itemId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/settlements/new/preview',
      redirect: (context, state) => RoutePaths.planSettlementPreview(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/settlements/new',
      redirect: (context, state) => RoutePaths.planSettlementNew(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId/settlements/:settlementId',
      redirect: (context, state) => RoutePaths.planSettlementDetail(
        state.pathParameters['groupId']!,
        state.pathParameters['planId']!,
        state.pathParameters['settlementId']!,
      ),
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups/:planId',
      redirect: (context, state) {
        final groupId = state.pathParameters['groupId']!;
        final planId = state.pathParameters['planId']!;
        if (state.uri.queryParameters['place'] == 'confirmed') {
          return RoutePaths.planItinerary(groupId, planId);
        }
        return RoutePaths.planDetail(groupId, planId);
      },
    ),
    GoRoute(
      path: '/onmoim/:groupId/meetups',
      redirect: (context, state) =>
          RoutePaths.groupPlans(state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/onmoim/:groupId',
      redirect: (context, state) =>
          RoutePaths.groupDetail(state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: '/ootd/list',
      redirect: (context, state) => RoutePaths.records,
    ),
    GoRoute(
      path: '/ootd/new/daily',
      redirect: (context, state) =>
          _withQuery(RoutePaths.recordNewDaily, state),
    ),
    GoRoute(
      path: '/ootd/new/ootd',
      redirect: (context, state) => _withQuery(RoutePaths.recordNewOotd, state),
    ),
    GoRoute(
      path: '/memories/:recordId/template-diary',
      redirect: (context, state) =>
          RoutePaths.recordDiaryTemplate(state.pathParameters['recordId']!),
    ),
    GoRoute(
      path: '/memories/:recordId',
      redirect: (context, state) =>
          RoutePaths.recordDetail(state.pathParameters['recordId']!),
    ),
  ];
}

String _withQuery(String path, GoRouterState state) {
  final query = state.uri.query;
  if (query.isEmpty) {
    return path;
  }
  return '$path?$query';
}
