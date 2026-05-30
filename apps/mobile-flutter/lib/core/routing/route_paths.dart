abstract final class RoutePaths {
  static const home = '/home';
  static const meetups = '/meetups';
  static const meetupNewMembers = '/meetups/new/members';
  static const meetupNewTitle = '/meetups/new/title';
  static const meetupNewSchedule = '/meetups/new/schedule';
  static const onchat = '/onchat';
  static const ootdList = '/ootd/list';
  static const my = '/my';

  static String meetupDetail(String meetupId) => '/meetups/$meetupId';

  static String meetupPlaces(String meetupId) => '/meetups/$meetupId/places';

  static String meetupRouteReview(String meetupId) =>
      '/meetups/$meetupId/route-review';

  static String meetupComplete(String meetupId) =>
      '/meetups/$meetupId/complete';
}
