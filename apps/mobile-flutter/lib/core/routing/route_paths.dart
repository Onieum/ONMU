class RoutePaths {
  const RoutePaths._();

  static const home = '/home';
  static const meetups = '/meetups';
  static const meetupNewMembers = '/meetups/new/members';
  static const meetupNewTitle = '/meetups/new/title';
  static const meetupNewSchedule = '/meetups/new/schedule';

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

  static const onchat = '/onchat';
  static const onchatDemoGroup = '/onchat/groups/friends';
  static const onchatDemoChat = '/onchat/groups/friends/chat';
  static const onchatMeetupNew = '/onchat/groups/friends/meetups/new';
  static const onchatMeetupBoard = '/onchat/groups/friends/meetups/demo/board';
  static const onchatMemories = '/onchat/groups/friends/memories';
  static const settlementNew = '/onchat/groups/friends/settlements/new';
  static const settlementShare =
      '/onchat/groups/friends/settlements/lunch-split';

  static const ootdList = '/ootd/list';
  static const my = '/my';

  static String meetupDetail(String meetupId) => '/meetups/$meetupId';

  static String meetupPlaces(String meetupId) => '/meetups/$meetupId/places';

  static String meetupRouteReview(String meetupId) =>
      '/meetups/$meetupId/route-review';

  static String meetupComplete(String meetupId) =>
      '/meetups/$meetupId/complete';
}
