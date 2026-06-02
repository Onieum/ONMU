class RoutePaths {
  const RoutePaths._();

  static const splash = '/splash';
  static const start = '/start';
  static const preferenceIntro = '/preferences/intro';
  static const characterStart = '/character/start';
  static const home = '/home';
  static const onmoim = '/onmoim';
  static const onmoimDemo = '/onmoim/friends';
  static const onmoimDemoSettings = '/onmoim/friends/settings';
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
  static const ootdList = '/ootd/list';
  static const my = '/my';

  static String onmoimDetail(String onmoimId) => '/onmoim/$onmoimId';

  static String onmoimSettings(String onmoimId) => '/onmoim/$onmoimId/settings';

  static String onmoimChat(String onmoimId) => '/onmoim/$onmoimId/chat';

  static String onmoimMemories(String onmoimId) => '/onmoim/$onmoimId/memories';

  static String onmoimMeetupNewMembers(String onmoimId) =>
      '/onmoim/$onmoimId/meetups/new/members';

  static String onmoimMeetupNewSchedule(String onmoimId) =>
      '/onmoim/$onmoimId/meetups/new/schedule';

  static String onmoimMeetupNewCalendar(String onmoimId) =>
      '/onmoim/$onmoimId/meetups/new/schedule/calendar';

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
