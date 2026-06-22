import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onmu_mobile/core/error/onmu_exception.dart';
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

  test(
    'addFriend preserves already friend message from normalized API error',
    () async {
      final repository = _AlreadyFriendRepository();
      final container = ProviderContainer(
        overrides: [friendRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(await container.read(friendsProvider.future), isEmpty);

      await expectLater(
        container.read(myProfileControllerProvider).addFriend('usr_friend'),
        throwsA(
          isA<FriendAddException>()
              .having(
                (error) => error.kind,
                'kind',
                FriendAddErrorKind.alreadyFriend,
              )
              .having((error) => error.message, 'message', '이미 친구예요.'),
        ),
      );

      final friends = await container.read(friendsProvider.future);
      expect(friends, hasLength(1));
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
    throw OnmuApiException(
      kind: OnmuErrorKind.conflict,
      userMessage: '이미 처리된 요청이에요.',
      technicalMessage: 'POST /api/v1/users/me/friends failed with 409',
      feature: 'friend',
      statusCode: 409,
      method: 'POST',
      endpoint: '/api/v1/users/me/friends',
      reportable: false,
      serverReason: 'already_friend',
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
