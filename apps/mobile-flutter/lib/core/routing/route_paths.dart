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
  static const homeNotifications = '/home/notifications';
  static const homeRecentRecords = '/home/recent-records';
  static const groups = '/groups';
  static const groupNew = '/groups/new';
  static const records = '/records';
  static const recordNewDaily = '/records/new/daily';
  static const recordNewOotd = '/records/new/ootd';
  static const my = '/my';

  static String groupDetail(String groupId) => '/groups/$groupId';

  static String groupMembers(String groupId) => '/groups/$groupId/members';

  static String groupInvite(String groupId) => '/groups/$groupId/invite';

  static String groupSettings(String groupId) => '/groups/$groupId/settings';

  static String groupChat(String groupId) => '/groups/$groupId/chat';

  static String groupVotes(String groupId) => '/groups/$groupId/votes';

  static String groupVote(String groupId, String voteId) =>
      '/groups/$groupId/votes/$voteId';

  static String groupMemories(String groupId) => '/groups/$groupId/memories';

  static String groupMemoryDetail(String groupId, String memoryId) =>
      '/groups/$groupId/memories/$memoryId';

  static String groupPlans(String groupId) => '/groups/$groupId/plans';

  static String planNew(String groupId) => '/groups/$groupId/plans/new';

  static String planNewSchedule(String groupId) =>
      '/groups/$groupId/plans/new/schedule';

  static String planNewCalendar(String groupId) =>
      '/groups/$groupId/plans/new/schedule/calendar';

  static String planDetail(String groupId, String planId) =>
      '/groups/$groupId/plans/$planId';

  static String planEdit(String groupId, String planId) =>
      '/groups/$groupId/plans/$planId/edit';

  static String planBoard(String groupId, String planId) =>
      '/groups/$groupId/plans/$planId/board';

  static String planPlaceCandidates(String groupId, String planId) =>
      '/groups/$groupId/plans/$planId/place-candidates';

  static String planPlaceSearch(String groupId, String planId) =>
      '/groups/$groupId/plans/$planId/place-search';

  static String planPlaceSearchResults(String groupId, String planId) =>
      '/groups/$groupId/plans/$planId/place-search/results';

  static String planVoteNew(String groupId, String planId) =>
      '/groups/$groupId/plans/$planId/votes/new';

  static String planVotes(String groupId, String planId) =>
      '/groups/$groupId/plans/$planId/votes';

  static String planVote(String groupId, String planId, String voteId) =>
      '/groups/$groupId/plans/$planId/votes/$voteId';

  static String planPlaceCandidateDetail(
    String groupId,
    String planId,
    String candidateId,
  ) => '/groups/$groupId/plans/$planId/place-candidates/$candidateId';

  static String planItinerary(String groupId, String planId) =>
      '/groups/$groupId/plans/$planId/itinerary';

  static String planSettlementNew(String groupId, String planId) =>
      '/groups/$groupId/plans/$planId/settlements/new';

  static String planSettlementTargets(
    String groupId,
    String planId,
    String itemId,
  ) => '/groups/$groupId/plans/$planId/settlements/new/items/$itemId/targets';

  static String planSettlementPreview(String groupId, String planId) =>
      '/groups/$groupId/plans/$planId/settlements/new/preview';

  static String planSettlementDetail(
    String groupId,
    String planId,
    String settlementId,
  ) => '/groups/$groupId/plans/$planId/settlements/$settlementId';

  static String recordDetail(String recordId) => '/records/$recordId';

  static String recordDiaryTemplate(String recordId) =>
      '/records/$recordId/template-diary';
}
