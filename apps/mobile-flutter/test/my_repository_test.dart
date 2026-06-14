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
                'region': {
                  'country': 'KR',
                  'sido': '서울',
                  'sigungu': '성동구',
                  'displayName': '서울 성동구',
                },
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
                    'region': {
                      'country': 'KR',
                      'sido': '서울',
                      'sigungu': '성동구',
                      'displayName': '서울 성동구',
                    },
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
          region: '서울 성동구',
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
      expect(updated.region, '서울 성동구');
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
                'preferenceProfile': {'introText': 'hello', 'region': '서울 성동구'},
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

  test('reads legacy string region as display region', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'GET');
          expect(options.path, '/api/v1/users/me');
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'displayName': 'Shinseok',
                'preferenceProfile': {
                  'introText': 'hello',
                  'region': '부산 해운대구',
                },
              },
            ),
          );
        },
      ),
    );
    final repository = ApiMyRepository(OnmuApiClient(dio));

    final profile = await repository.fetchMyProfile();

    expect(profile.region, '부산 해운대구');
    expect(profile.effectiveRegionSelection.sido, '부산');
    expect(profile.effectiveRegionSelection.sigungu, '해운대구');
  });

  test('preserves legacy string region outside current option list', () async {
    final requestedRegions = <String>['서울 성수동', '서울 강서구'];

    for (final requestedRegion in requestedRegions) {
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/api/v1/users/me');
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'displayName': 'Shinseok',
                  'preferenceProfile': {
                    'introText': 'hello',
                    'region': requestedRegion,
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = ApiMyRepository(OnmuApiClient(dio));

      final profile = await repository.fetchMyProfile();

      expect(profile.region, requestedRegion);
      expect(profile.effectiveRegionSelection.displayName, requestedRegion);
    }
  });

  test('reads structured region object as display region', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'GET');
          expect(options.path, '/api/v1/users/me');
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'displayName': 'Shinseok',
                'preferenceProfile': {
                  'introText': 'hello',
                  'region': {
                    'country': 'KR',
                    'sido': '인천',
                    'sigungu': '연수구',
                    'displayName': '인천 연수구',
                  },
                },
              },
            ),
          );
        },
      ),
    );
    final repository = ApiMyRepository(OnmuApiClient(dio));

    final profile = await repository.fetchMyProfile();

    expect(profile.region, '인천 연수구');
    expect(profile.effectiveRegionSelection.toJson(), {
      'country': 'KR',
      'sido': '인천',
      'sigungu': '연수구',
      'displayName': '인천 연수구',
    });
  });
}
