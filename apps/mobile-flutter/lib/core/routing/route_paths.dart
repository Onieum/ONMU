class RoutePaths {
  const RoutePaths._();

  static const home = '/home';

  static const meetups = '/meetups';
  static const meetupNewMembers = '/meetups/new/members';
  static const meetupNewSchedule = '/meetups/new/schedule';
  static const meetupNewCalendar = '/meetups/new/schedule/calendar';

  static const meetupDemo = '/meetups/demo';
  static const placeCandidates = '/meetups/demo/places';
  static const placeSearch = '/meetups/demo/places/search';
  static const placeMap = '/meetups/demo/places/map';
  static const placeDetail = '/meetups/demo/places/onmu-diner';
  static const placeRiskKeyword = '/meetups/demo/places/risks/keyword';
  static const placeRiskBreakTime = '/meetups/demo/places/risks/break-time';
  static const placeRiskClosedDay = '/meetups/demo/places/risks/closed-day';
  static const placeCompare = '/meetups/demo/place-compare';
  static const placeRisks = '/meetups/demo/places/risks';

  static const onmoim = '/onmoim';
  static const onmoimDemo = '/onmoim/friends';
  static const onmoimDemoChat = '/onmoim/friends/chat';
  static const onmoimDemoMemories = '/onmoim/friends/memories';
  static const onmoimDemoMeetup = '/onmoim/friends/meetups/demo';
  static const onmoimDemoMeetupBoard = '/onmoim/friends/meetups/demo/board';
  static const onmoimDemoMeetupPlaces = '/onmoim/friends/meetups/demo/places';
  static const onmoimDemoMeetupPlaceMap =
      '/onmoim/friends/meetups/demo/places/map';
  static const onmoimDemoMeetupSettlementNew =
      '/onmoim/friends/meetups/demo/settlements/new';
  static const onmoimDemoMeetupSettlementShare =
      '/onmoim/friends/meetups/demo/settlements/lunch-split';

  static const onchat = '/onchat';
  static const onchatDemoGroup = onmoimDemo;
  static const onchatDemoChat = onmoimDemoChat;
  static const onchatMeetupNew = '/onmoim/friends/meetups/new/members';
  static const onchatMeetupBoard = onmoimDemoMeetupBoard;
  static const onchatMemories = onmoimDemoMemories;
  static const settlementNew = onmoimDemoMeetupSettlementNew;
  static const settlementShare = onmoimDemoMeetupSettlementShare;

  static const ootdList = '/ootd/list';
  static const my = '/my';

  static String meetupDetail(String meetupId) => '/meetups/$meetupId';

  static String meetupPlaces(String meetupId) => '/meetups/$meetupId/places';

  static String meetupRouteReview(String meetupId) =>
      '/meetups/$meetupId/route-review';

  static String meetupComplete(String meetupId) =>
      '/meetups/$meetupId/complete';

  static String onmoimDetail(String onmoimId) => '/onmoim/$onmoimId';

  static String onmoimChat(String onmoimId) => '/onmoim/$onmoimId/chat';

  static String onmoimMemories(String onmoimId) => '/onmoim/$onmoimId/memories';

  static String onmoimMeetupNewMembers(String onmoimId) =>
      '/onmoim/$onmoimId/meetups/new/members';

  static String onmoimMeetupNewTitle(String onmoimId) =>
      '/onmoim/$onmoimId/meetups/new/title';

  static String onmoimMeetupNewSchedule(String onmoimId) =>
      '/onmoim/$onmoimId/meetups/new/schedule';

  static String onmoimMeetupDetail(String onmoimId, String meetupId) =>
      '/onmoim/$onmoimId/meetups/$meetupId';

  static String onmoimMeetupBoard(String onmoimId, String meetupId) =>
      '/onmoim/$onmoimId/meetups/$meetupId/board';

  static String onmoimMeetupPlaces(String onmoimId, String meetupId) =>
      '/onmoim/$onmoimId/meetups/$meetupId/places';

  static String onmoimMeetupPlaceSearch(String onmoimId, String meetupId) =>
      '/onmoim/$onmoimId/meetups/$meetupId/places/search';

  static String onmoimMeetupPlaceMap(String onmoimId, String meetupId) =>
      '/onmoim/$onmoimId/meetups/$meetupId/places/map';

  static String onmoimMeetupPlaceDetail(
    String onmoimId,
    String meetupId,
    String placeId,
  ) => '/onmoim/$onmoimId/meetups/$meetupId/places/$placeId';

  static String onmoimMeetupPlaceRisks(String onmoimId, String meetupId) =>
      '/onmoim/$onmoimId/meetups/$meetupId/places/risks';

  static String onmoimMeetupPlaceRisk(
    String onmoimId,
    String meetupId,
    String riskKind,
  ) => '/onmoim/$onmoimId/meetups/$meetupId/places/risks/$riskKind';

  static String onmoimMeetupPlaceCompare(String onmoimId, String meetupId) =>
      '/onmoim/$onmoimId/meetups/$meetupId/place-compare';

  static String onmoimMeetupRouteReview(String onmoimId, String meetupId) =>
      '/onmoim/$onmoimId/meetups/$meetupId/route-review';

  static String onmoimMeetupComplete(String onmoimId, String meetupId) =>
      '/onmoim/$onmoimId/meetups/$meetupId/complete';

  static String onmoimMeetupSettlementNew(String onmoimId, String meetupId) =>
      '/onmoim/$onmoimId/meetups/$meetupId/settlements/new';

  static String onmoimMeetupSettlementShare(
    String onmoimId,
    String meetupId,
    String settlementId,
  ) => '/onmoim/$onmoimId/meetups/$meetupId/settlements/$settlementId';
}
