import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onmu_mobile/features/my/domain/my_profile.dart';
import 'package:onmu_mobile/features/my/repository/friend_repository.dart';
import 'package:onmu_mobile/features/my/view_model/my_profile_controller.dart';

void main() {
  test(
    'addFriend refreshes friends when server reports already friend',
    () async {
      final repository = _AlreadyFriendRepository();
      final container = ProviderContainer(
        overrides: [friendRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(await container.read(friendsProvider.future), isEmpty);

      await expectLater(
        container.read(myProfileControllerProvider).addFriend('usr_friend'),
        throwsA(isA<FriendAddException>()),
      );

      final friends = await container.read(friendsProvider.future);
      expect(friends, hasLength(1));
      expect(friends.single.publicId, 'usr_friend');
      expect(repository.fetchFriendsCallCount, 2);
    },
  );
}

class _AlreadyFriendRepository implements FriendRepository {
  var fetchFriendsCallCount = 0;

  static const _friend = FriendProfile(
    publicId: 'usr_friend',
    userCode: 'usr_friend',
    name: '친구',
    preferenceSummary: '',
    isFriend: true,
  );

  @override
  Future<List<FriendProfile>> fetchFriends() async {
    fetchFriendsCallCount += 1;
    return fetchFriendsCallCount == 1 ? const [] : const [_friend];
  }

  @override
  Future<FriendProfile> addFriend(String publicId, {String? memo}) async {
    final requestOptions = RequestOptions(path: '/api/v1/users/me/friends');
    throw DioException(
      requestOptions: requestOptions,
      response: Response<String>(
        requestOptions: requestOptions,
        statusCode: 409,
        data: 'already_friend',
      ),
    );
  }

  @override
  Future<void> deleteFriend(FriendProfile friend) async {}

  @override
  Future<MyProfile> fetchFriendProfile(FriendProfile friend) async {
    return MyProfile(
      realName: friend.name,
      visibility: ProfileVisibility.friends,
      favoriteKeywords: const [],
      dislikedKeywords: const [],
      preferredTimes: const [],
      availableDays: const [],
      unavailableDates: const [],
      favoritePlaces: const [],
      wantToGoPlaces: const [],
      dislikedPlaces: const [],
    );
  }

  @override
  Future<List<FriendProfile>> searchFriends(String query) async => const [];

  @override
  Future<FriendProfile> updateFriend(
    FriendProfile friend, {
    String? memo,
    bool? favorite,
  }) async {
    return friend.copyWith(memo: memo, isFavorite: favorite);
  }
}
