import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../domain/korea_region.dart';
import '../domain/my_profile.dart';

final myRepositoryProvider = Provider<MyRepository>((ref) {
  return ApiMyRepository(ref.watch(onmuApiClientProvider));
});

final myProfileProvider = FutureProvider<MyProfile>((ref) {
  return ref.watch(myRepositoryProvider).fetchMyProfile();
});

abstract interface class MyRepository {
  Future<MyProfile> fetchMyProfile();

  Future<MyProfile> updateMyProfile(
    MyProfile profile, {
    String? onboardingStatus,
  });

  Future<MyProfile> updateOnboardingStatus(String onboardingStatus);
}

class ApiMyRepository implements MyRepository {
  ApiMyRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<MyProfile> fetchMyProfile() async {
    final json = await _client.getObject('/api/v1/users/me');
    return _profileFromJson(json);
  }

  @override
  Future<MyProfile> updateMyProfile(
    MyProfile profile, {
    String? onboardingStatus,
  }) async {
    final body = {
      'displayName': profile.realName,
      'preferenceProfile': _preferenceProfileJson(profile),
    };
    if (onboardingStatus != null) {
      body['onboardingStatus'] = onboardingStatus;
    }
    final json = await _client.patchObject('/api/v1/users/me', body: body);
    return _profileFromJson(json);
  }

  @override
  Future<MyProfile> updateOnboardingStatus(String onboardingStatus) async {
    final json = await _client.patchObject(
      '/api/v1/users/me',
      body: {'onboardingStatus': onboardingStatus},
    );
    return _profileFromJson(json);
  }

  MyProfile _profileFromJson(Map<String, dynamic> json) {
    final preference = OnmuJson.asMap(json['preferenceProfile']);
    final displayName = OnmuJson.readString(json, 'displayName', '사용자');
    final regionSelection = KoreaRegionSelection.fromJson(preference['region']);
    return MyProfile(
      realName: displayName,
      introText: OnmuJson.readString(
        preference,
        'introText',
        '기록하고, 만나고, 추억해요  ♥',
      ),
      region: regionSelection.displayName,
      regionSelection: regionSelection,
      visibility: ProfileVisibility.friends,
      favoriteKeywords: OnmuJson.stringList(preference['favoriteKeywords']),
      dislikedKeywords: OnmuJson.stringList(preference['dislikedKeywords']),
      preferredTimes: OnmuJson.stringList(preference['preferredTimes']),
      availableDays: OnmuJson.stringList(preference['availableDays']),
      unavailableDates: OnmuJson.stringList(preference['unavailableDates']),
      favoritePlaces: const [],
      wantToGoPlaces: const [],
      dislikedPlaces: const [],
      favoriteFoodTags: OnmuJson.stringList(preference['favoriteFoodTags']),
      dislikedFoodTags: OnmuJson.stringList(preference['dislikedFoodTags']),
      favoritePlaceTags: OnmuJson.stringList(preference['favoritePlaceTags']),
      dislikedPlaceTags: OnmuJson.stringList(preference['dislikedPlaceTags']),
      planStyles: OnmuJson.stringList(preference['planStyles']),
      preferredWeekdays: OnmuJson.stringList(preference['preferredWeekdays']),
    );
  }

  Map<String, Object?> _preferenceProfileJson(MyProfile profile) {
    return {
      'favoriteKeywords': profile.favoriteKeywords,
      'introText': profile.introText,
      'region': profile.effectiveRegionSelection.toJson(),
      'dislikedKeywords': profile.dislikedKeywords,
      'preferredTimes': profile.preferredTimes,
      'availableDays': profile.availableDays,
      'unavailableDates': profile.unavailableDates,
      'favoriteFoodTags': profile.favoriteFoodTags,
      'dislikedFoodTags': profile.dislikedFoodTags,
      'favoritePlaceTags': profile.favoritePlaceTags,
      'dislikedPlaceTags': profile.dislikedPlaceTags,
      'planStyles': profile.planStyles,
      'preferredWeekdays': profile.preferredWeekdays,
    };
  }
}
