import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/my/domain/my_profile.dart';
import 'package:onmu_mobile/features/my/repository/my_repository.dart';

void main() {
  test(
    'updates current user preference profile through users me API',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'PATCH');
            expect(options.path, '/api/v1/users/me');
            expect(options.data, {
              'displayName': 'Shinseok',
              'onboardingStatus': 'COMPLETED',
              'preferenceProfile': {
                'favoriteKeywords': ['quiet'],
                'introText': 'hello',
                'region': 'Seoul',
                'dislikedKeywords': ['crowded'],
                'preferredTimes': ['evening'],
                'availableDays': ['friday'],
                'unavailableDates': ['2026-06-15'],
                'favoriteFoodTags': ['pasta'],
                'dislikedFoodTags': ['spicy'],
                'favoritePlaceTags': ['park'],
                'dislikedPlaceTags': ['mall'],
                'planStyles': ['planned'],
                'preferredWeekdays': ['friday'],
              },
            });

            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'displayName': 'Shinseok',
                  'preferenceProfile': {
                    'favoriteKeywords': ['quiet'],
                    'introText': 'hello',
                    'region': 'Seoul',
                    'dislikedKeywords': ['crowded'],
                    'preferredTimes': ['evening'],
                    'availableDays': ['friday'],
                    'unavailableDates': ['2026-06-15'],
                    'favoriteFoodTags': ['pasta'],
                    'dislikedFoodTags': ['spicy'],
                    'favoritePlaceTags': ['park'],
                    'dislikedPlaceTags': ['mall'],
                    'planStyles': ['planned'],
                    'preferredWeekdays': ['friday'],
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = ApiMyRepository(OnmuApiClient(dio));

      final updated = await repository.updateMyProfile(
        const MyProfile(
          realName: 'Shinseok',
          introText: 'hello',
          region: 'Seoul',
          visibility: ProfileVisibility.friends,
          favoriteKeywords: ['quiet'],
          dislikedKeywords: ['crowded'],
          preferredTimes: ['evening'],
          availableDays: ['friday'],
          unavailableDates: ['2026-06-15'],
          favoritePlaces: [],
          wantToGoPlaces: [],
          dislikedPlaces: [],
          favoriteFoodTags: ['pasta'],
          dislikedFoodTags: ['spicy'],
          favoritePlaceTags: ['park'],
          dislikedPlaceTags: ['mall'],
          planStyles: ['planned'],
          preferredWeekdays: ['friday'],
        ),
        onboardingStatus: 'COMPLETED',
      );

      expect(updated.realName, 'Shinseok');
      expect(updated.favoriteFoodTags, ['pasta']);
      expect(updated.preferredWeekdays, ['friday']);
    },
  );

  test('updates onboarding status through users me API', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'PATCH');
          expect(options.path, '/api/v1/users/me');
          expect(options.data, {'onboardingStatus': 'PREFERENCE_READY'});

          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'displayName': 'Shinseok',
                'onboardingStatus': 'PREFERENCE_READY',
                'preferenceProfile': {'introText': 'hello', 'region': 'Seoul'},
              },
            ),
          );
        },
      ),
    );
    final repository = ApiMyRepository(OnmuApiClient(dio));

    final updated = await repository.updateOnboardingStatus('PREFERENCE_READY');

    expect(updated.realName, 'Shinseok');
    expect(updated.introText, 'hello');
  });
}
