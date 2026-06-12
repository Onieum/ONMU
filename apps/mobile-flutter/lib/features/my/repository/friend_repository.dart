import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../domain/my_profile.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return ApiFriendRepository(ref.watch(onmuApiClientProvider));
});

final friendsProvider = FutureProvider<List<FriendProfile>>((ref) {
  return ref.watch(friendRepositoryProvider).fetchFriends();
});

abstract interface class FriendRepository {
  Future<List<FriendProfile>> fetchFriends();

  Future<List<FriendProfile>> searchFriends(String query);

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
    final name = OnmuJson.readString(
      json,
      'nickname',
      OnmuJson.readString(json, 'displayName', '친구'),
    );
    final memo = OnmuJson.readString(json, 'memo', userCode);
    return FriendProfile(
      userId: OnmuJson.readString(json, 'userId'),
      publicId: publicId,
      userCode: userCode,
      name: name,
      preferenceSummary: memo.isEmpty ? userCode : memo,
      isFriend: true,
      isFavorite: OnmuJson.readBool(json, 'favorite'),
      memo: memo,
      profileImageUrl: OnmuJson.readString(
        json,
        'profileImageUrl',
        OnmuJson.readString(
          json,
          'profilePhotoUrl',
          OnmuJson.readString(json, 'avatarUrl'),
        ),
      ),
    );
  }
}
