import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/my/domain/korea_region.dart';
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
              'nickname': 'Shinseok',
              'profileImageUrl': '',
              'onboardingStatus': 'COMPLETED',
              'preferenceProfile': {
                'favoriteKeywords': ['quiet'],
                'introText': 'hello',
                'profileVisibility': 'FRIENDS',
                'searchAllowed': true,
                'useDefaultProfileImage': false,
                'region': {
                  'country': 'KR',
                  'sido': '서울특별시',
                  'sigungu': '성동구',
                  'displayName': '서울특별시 성동구',
                },
                'regionVisibility': 'PUBLIC',
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
                  'nickname': 'Shinseok',
                  'preferenceProfile': {
                    'favoriteKeywords': ['quiet'],
                    'introText': 'hello',
                    'profileVisibility': 'FRIENDS',
                    'region': {
                      'country': 'KR',
                      'sido': '서울특별시',
                      'sigungu': '성동구',
                      'displayName': '서울특별시 성동구',
                    },
                    'regionVisibility': 'PUBLIC',
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
          regionVisibility: RegionVisibility.public,
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
      expect(updated.region, '서울특별시 성동구');
      expect(updated.regionVisibility, RegionVisibility.public);
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
                'nickname': 'Shinseok',
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

  test('does not treat default nickname as a profile real name', () async {
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
                'nickname': 'ONMU User',
                'preferenceProfile': {'introText': 'hello'},
              },
            ),
          );
        },
      ),
    );
    final repository = ApiMyRepository(OnmuApiClient(dio));

    final profile = await repository.fetchMyProfile();

    expect(profile.realName, isEmpty);
    expect(profile.introText, 'hello');
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
                'nickname': 'Shinseok',
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

    expect(profile.region, '부산광역시 해운대구');
    expect(profile.effectiveRegionSelection.sido, '부산광역시');
    expect(profile.effectiveRegionSelection.sigungu, '해운대구');
    expect(profile.regionVisibility, RegionVisibility.private);
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
                  'nickname': 'Shinseok',
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

      final normalizedRegion = KoreaRegionSelection.fromDisplayName(
        requestedRegion,
      ).displayName;
      expect(profile.region, normalizedRegion);
      expect(profile.effectiveRegionSelection.displayName, normalizedRegion);
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
                'nickname': 'Shinseok',
                'preferenceProfile': {
                  'introText': 'hello',
                  'region': {
                    'country': 'KR',
                    'sido': '인천',
                    'sigungu': '연수구',
                    'displayName': '인천 연수구',
                  },
                  'regionVisibility': 'PUBLIC',
                },
              },
            ),
          );
        },
      ),
    );
    final repository = ApiMyRepository(OnmuApiClient(dio));

    final profile = await repository.fetchMyProfile();

    expect(profile.region, '인천광역시 연수구');
    expect(profile.effectiveRegionSelection.toJson(), {
      'country': 'KR',
      'sido': '인천광역시',
      'sigungu': '연수구',
      'displayName': '인천광역시 연수구',
    });
    expect(profile.regionVisibility, RegionVisibility.public);
  });

  test(
    'filters mojibake and nested JSON profile values from API payload',
    () async {
      final brokenRegion = _mojibake('서울 성동구');
      final nestedJsonText = jsonEncode({'region': '서울 성동구'});
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
                  'nickname': 'Shinseok',
                  'preferenceProfile': {
                    'introText': nestedJsonText,
                    'region': brokenRegion,
                    'favoriteFoodTags': [brokenRegion, 'pasta'],
                    'preferredWeekdays': [nestedJsonText, 'friday'],
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = ApiMyRepository(OnmuApiClient(dio));

      final profile = await repository.fetchMyProfile();

      expect(profile.introText, '');
      expect(profile.region, KoreaRegionSelection.fallback.displayName);
      expect(profile.favoriteFoodTags, ['pasta']);
      expect(profile.preferredWeekdays, ['friday']);
    },
  );

  test(
    'does not send mojibake and nested JSON values back on profile update',
    () async {
      final brokenRegion = _mojibake('서울 성동구');
      final nestedJsonText = jsonEncode({'style': '조용한'});
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'PATCH');
            expect(options.path, '/api/v1/users/me');
            final data = options.data as Map<String, Object?>;
            final preference =
                data['preferenceProfile'] as Map<String, Object?>;
            expect(preference['introText'], '');
            expect(preference['favoriteFoodTags'], ['pasta']);
            expect(preference['planStyles'], isEmpty);
            expect(
              preference['region'],
              KoreaRegionSelection.fallback.toJson(),
            );

            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'nickname': 'Shinseok',
                  'preferenceProfile': {
                    'introText': '',
                    'region': KoreaRegionSelection.fallback.toJson(),
                    'favoriteFoodTags': ['pasta'],
                    'planStyles': <String>[],
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = ApiMyRepository(OnmuApiClient(dio));

      final updated = await repository.updateMyProfile(
        MyProfile(
          realName: 'Shinseok',
          introText: nestedJsonText,
          region: brokenRegion,
          regionSelection: KoreaRegionSelection.fromDisplayName(brokenRegion),
          visibility: ProfileVisibility.friends,
          favoriteKeywords: const [],
          dislikedKeywords: const [],
          preferredTimes: const [],
          availableDays: const [],
          unavailableDates: const [],
          favoritePlaces: const [],
          wantToGoPlaces: const [],
          dislikedPlaces: const [],
          favoriteFoodTags: [brokenRegion, 'pasta'],
          planStyles: [nestedJsonText],
        ),
      );

      expect(updated.region, KoreaRegionSelection.fallback.displayName);
      expect(updated.favoriteFoodTags, ['pasta']);
      expect(updated.planStyles, isEmpty);
    },
  );
}

String _mojibake(String value) {
  return latin1.decode(utf8.encode(value));
}
