class RoutePaths {
  const RoutePaths._();

  static const splash = '/splash';
  static const start = '/start';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const onboardingPreferences = '/onboarding/preferences';
  static const onboardingCharacter = '/onboarding/character';
  static const home = '/home';
  static const homeUpcomingPlans = '/home/upcoming-plans';
  static const homeUpcomingCalendar = '/home/upcoming-plans/calendar';
  static const homeNotifications = '/home/notifications';
  static const homeRecentRecords = '/home/recent-records';
  static const groups = '/groups';
  static const groupNew = '/groups/new';
  static const records = '/records';
  static const recordNewDaily = '/records/new/daily';
  static const recordNewOotd = '/records/new/ootd';
  static const my = '/my';
  static const mySettings = '/my/settings';

  static String groupDetail(Object groupId) => '/groups/$groupId';

  static String groupMembers(Object groupId) => '/groups/$groupId/members';

  static String groupInvite(Object groupId) => '/groups/$groupId/invite';

  static String groupSettings(Object groupId) => '/groups/$groupId/settings';

  static String groupChat(Object groupId) => '/groups/$groupId/chat';

  static String groupVotes(Object groupId) => '/groups/$groupId/votes';

  static String groupVote(Object groupId, Object voteId) =>
      '/groups/$groupId/votes/$voteId';

  static String groupMemories(Object groupId) => '/groups/$groupId/memories';

  static String groupMemoryDetail(Object groupId, Object memoryId) =>
      '/groups/$groupId/memories/$memoryId';

  static String groupPlans(Object groupId) => '/groups/$groupId/plans';

  static String planNew(Object groupId) => '/groups/$groupId/plans/new';

  static String planNewSchedule(Object groupId) =>
      '/groups/$groupId/plans/new/schedule';

  static String planNewCalendar(Object groupId) =>
      '/groups/$groupId/plans/new/schedule/calendar';

  static String planDetail(Object groupId, Object planId) =>
      '/groups/$groupId/plans/$planId';

  static String planEdit(Object groupId, Object planId) =>
      '/groups/$groupId/plans/$planId/edit';

  static String planBoard(Object groupId, Object planId) =>
      '/groups/$groupId/plans/$planId/board';

  static String planPlaceCandidates(Object groupId, Object planId) =>
      '/groups/$groupId/plans/$planId/place-candidates';

  static String planPlaceSearch(Object groupId, Object planId) =>
      '/groups/$groupId/plans/$planId/place-search';

  static String planPlaceSearchResults(Object groupId, Object planId) =>
      '/groups/$groupId/plans/$planId/place-search/results';

  static String planVoteNew(Object groupId, Object planId) =>
      '/groups/$groupId/plans/$planId/votes/new';

  static String planVotes(Object groupId, Object planId) =>
      '/groups/$groupId/plans/$planId/votes';

  static String planVote(Object groupId, Object planId, Object voteId) =>
      '/groups/$groupId/plans/$planId/votes/$voteId';

  static String planPlaceCandidateDetail(
    Object groupId,
    Object planId,
    Object candidateId,
  ) => '/groups/$groupId/plans/$planId/place-candidates/$candidateId';

  static String planItinerary(Object groupId, Object planId, {int? dateIndex}) {
    final path = '/groups/$groupId/plans/$planId/itinerary';
    if (dateIndex == null) {
      return path;
    }
    final normalizedDateIndex = dateIndex < 0 ? 0 : dateIndex;
    return '$path?dateIndex=$normalizedDateIndex';
  }

  static String planSettlementNew(Object groupId, Object planId) =>
      '/groups/$groupId/plans/$planId/settlements/new';

  static String planSettlementTargets(
    Object groupId,
    Object planId,
    Object itemId,
  ) => '/groups/$groupId/plans/$planId/settlements/new/items/$itemId/targets';

  static String planSettlementPreview(Object groupId, Object planId) =>
      '/groups/$groupId/plans/$planId/settlements/new/preview';

  static String planSettlementCurrent(Object groupId, Object planId) =>
      '/groups/$groupId/plans/$planId/settlements/current';

  static String planSettlementDetail(
    Object groupId,
    Object planId,
    Object settlementId,
  ) => '/groups/$groupId/plans/$planId/settlements/$settlementId';

  static String planSettlementBasis(
    Object groupId,
    Object planId,
    Object settlementId,
  ) => '/groups/$groupId/plans/$planId/settlements/$settlementId/basis';

  static String recordDetail(String recordId) => '/records/$recordId';

  static String recordEdit(String recordId) => '/records/edit/$recordId';

  static String recordDiaryTemplate(String recordId) =>
      '/records/$recordId/template-diary';
}
