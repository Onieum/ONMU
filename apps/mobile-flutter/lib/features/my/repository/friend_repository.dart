import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/utils/character_draft_json.dart';
import '../../../shared/utils/onmu_display_name.dart';
import '../../../shared/utils/onmu_profile_image.dart';
import '../domain/korea_region.dart';
import '../domain/my_profile.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return ApiFriendRepository(ref.watch(onmuApiClientProvider));
});

final friendsProvider = FutureProvider<List<FriendProfile>>((ref) {
  return ref.watch(friendRepositoryProvider).fetchFriends();
});

final friendProfileProvider = FutureProvider.family<MyProfile, FriendProfile>((
  ref,
  friend,
) {
  return ref.watch(friendRepositoryProvider).fetchFriendProfile(friend);
});

abstract interface class FriendRepository {
  Future<List<FriendProfile>> fetchFriends();

  Future<List<FriendProfile>> searchFriends(String query);

  Future<MyProfile> fetchFriendProfile(FriendProfile friend);

  Future<FriendProfile> addFriend(String publicId, {String? memo});

  Future<FriendProfile> updateFriend(
    FriendProfile friend, {
    String? memo,
    bool? favorite,
  });

  Future<void> deleteFriend(FriendProfile friend);
}

class ApiFriendRepository implements FriendRepository {
  ApiFriendRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<List<FriendProfile>> fetchFriends() async {
    final json = await _client.getList('/api/v1/users/me/friends');
    return json.map(_friendFromJson).toList(growable: false);
  }

  @override
  Future<List<FriendProfile>> searchFriends(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) {
      return const [];
    }
    final json = await _client.getList(
      '/api/v1/users/search?query=${Uri.encodeQueryComponent(cleanQuery)}',
    );
    return json.map(_friendFromJson).toList(growable: false);
  }

  @override
  Future<MyProfile> fetchFriendProfile(FriendProfile friend) async {
    final json = await _client.getObject(
      '/api/v1/users/me/friends/${Uri.encodeComponent(friend.publicId)}/profile',
    );
    return _profileFromJson(json, friend);
  }

  @override
  Future<FriendProfile> addFriend(String publicId, {String? memo}) async {
    final json = await _client.postObject(
      '/api/v1/users/me/friends',
      body: {
        'publicId': publicId,
        if (memo?.trim().isNotEmpty == true) 'memo': memo!.trim(),
      },
    );
    return _friendFromJson(json);
  }

  @override
  Future<FriendProfile> updateFriend(
    FriendProfile friend, {
    String? memo,
    bool? favorite,
  }) async {
    final json = await _client.patchObject(
      '/api/v1/users/me/friends/${Uri.encodeComponent(friend.publicId)}',
      body: {'memo': ?memo, 'favorite': ?favorite},
    );
    return _friendFromJson(json);
  }

  @override
  Future<void> deleteFriend(FriendProfile friend) async {
    await _client.deleteObject(
      '/api/v1/users/me/friends/${Uri.encodeComponent(friend.publicId)}',
    );
  }

  FriendProfile _friendFromJson(Map<String, dynamic> json) {
    final publicId = OnmuJson.readString(json, 'publicId');
    final userCode = OnmuJson.readString(json, 'userCode', publicId);
    final name = resolveOnmuDisplayName([
      OnmuJson.readString(json, 'nickname'),
      OnmuJson.readString(json, 'name'),
    ], fallback: '친구');
    final memo = _cleanFriendMemo(
      OnmuJson.readString(json, 'memo'),
      publicId: publicId,
      userCode: userCode,
    );
    final introText = OnmuJson.readString(json, 'introText');
    final useDefaultProfileImage = OnmuJson.readBool(
      json,
      'useDefaultProfileImage',
    );
    return FriendProfile(
      userId: OnmuJson.readString(json, 'userId'),
      publicId: publicId,
      userCode: userCode,
      name: name,
      preferenceSummary: introText,
      isFriend: true,
      isFavorite: OnmuJson.readBool(json, 'favorite'),
      memo: memo,
      introText: introText,
      useDefaultProfileImage: useDefaultProfileImage,
      friendshipCreatedAt: _dateTimeFromJson(
        _friendshipCreatedAtFromJson(json),
      ),
      character: useDefaultProfileImage
          ? null
          : characterDraftFromJson(json['pixelCharacter'], nickname: name),
      profileImageUrl: resolveOnmuProfileImageUrl(
        json,
        baseUrl: _client.baseUrl,
      ),
    );
  }

  String _friendshipCreatedAtFromJson(Map<String, dynamic> json) {
    return OnmuJson.readString(
      json,
      'friendshipCreatedAt',
      OnmuJson.readString(
        json,
        'friendship_created_at',
        OnmuJson.readString(
          json,
          'createdAt',
          OnmuJson.readString(json, 'created_at'),
        ),
      ),
    );
  }

  String _cleanFriendMemo(
    String value, {
    required String publicId,
    required String userCode,
  }) {
    final memo = value.trim();
    final looksLikeGeneratedUserCode = RegExp(r'^\d+$').hasMatch(memo);
    if (memo.isEmpty ||
        memo == publicId ||
        memo == userCode ||
        looksLikeGeneratedUserCode) {
      return '';
    }
    return memo;
  }

  MyProfile _profileFromJson(Map<String, dynamic> json, FriendProfile friend) {
    final preference = OnmuJson.asMap(json['preferenceProfile']);
    final nickname = resolveOnmuDisplayName([
      OnmuJson.readString(json, 'nickname'),
      friend.name,
    ], fallback: '친구');
    final regionValue = preference['region'];
    final regionVisibility = RegionVisibility.fromJson(
      preference['regionVisibility'],
    );
    final useDefaultProfileImage = OnmuJson.readBool(
      preference,
      'useDefaultProfileImage',
    );
    return MyProfile(
      realName: nickname,
      character: useDefaultProfileImage
          ? null
          : characterDraftFromJson(json['pixelCharacter'], nickname: nickname),
      profileImageUrl: resolveOnmuProfileImageUrl(
        json,
        baseUrl: _client.baseUrl,
      ),
      introText: OnmuJson.readString(preference, 'introText', ''),
      region: !regionVisibility.isPublic || regionValue == null
          ? ''
          : KoreaRegionSelection.fromJson(regionValue).displayName,
      regionVisibility: regionVisibility,
      visibility: ProfileVisibility.fromJson(preference['profileVisibility']),
      useDefaultProfileImage: useDefaultProfileImage,
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

  DateTime? _dateTimeFromJson(String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      return null;
    }
    return DateTime.tryParse(clean);
  }
}
