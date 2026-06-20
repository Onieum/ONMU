import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/my/domain/my_profile.dart';
import 'package:onmu_mobile/features/my/repository/friend_repository.dart';

void main() {
  test('maps friend list friendship creation timestamp', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'GET');
          expect(options.path, '/api/v1/users/me/friends');

          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: [
                {
                  'publicId': 'usr_recent',
                  'nickname': 'Recent',
                  'introText': '',
                  'friendshipCreatedAt': '2026-06-20T04:30:00Z',
                },
              ],
            ),
          );
        },
      ),
    );

    final repository = ApiFriendRepository(OnmuApiClient(dio));
    final friends = await repository.fetchFriends();

    expect(
      friends.single.friendshipCreatedAt,
      DateTime.utc(2026, 6, 20, 4, 30),
    );
  });

  test(
    'maps friend detail profile image, character, and profile hashtags',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/api/v1/users/me/friends/usr_friend/profile');

            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'nickname': 'Jin',
                  'profileImageUrl': 'dev/avatars/jin.png',
                  'pixelCharacter': {
                    'gender': 'female',
                    'skinTone': 'skin_1',
                    'hairStyle': 'hair_style_3',
                    'hairColor': 'hair_color_2',
                    'eyeStyle': 'eye_style_1',
                    'eyeColor': 'eye_color_1',
                    'clothes': 'top_0',
                  },
                  'preferenceProfile': {
                    'introText': 'hello',
                    'profileVisibility': 'FRIENDS',
                    'favoriteKeywords': ['cafe', 'walk'],
                    'favoriteFoodTags': ['pasta'],
                    'favoritePlaceTags': ['quiet'],
                    'planStyles': ['planned'],
                  },
                },
              ),
            );
          },
        ),
      );

      final repository = ApiFriendRepository(OnmuApiClient(dio));
      final profile = await repository.fetchFriendProfile(
        const FriendProfile(
          publicId: 'usr_friend',
          name: 'Friend',
          preferenceSummary: '',
          isFriend: true,
        ),
      );

      expect(
        profile.profileImageUrl,
        'https://dev-api.onmu.cloud/api/v1/media/public?key=dev%2Favatars%2Fjin.png',
      );
      expect(profile.character, isNotNull);
      expect(profile.character!.skinToneIndex, 1);
      expect(profile.character!.hairStyleIndex, 3);
      expect(profile.character!.hairColorIndex, 2);
      expect(profile.character!.eyeShapeIndex, 1);
      expect(profile.character!.eyeColorIndex, 1);
      expect(profile.character!.topStyleIndex, 0);
      expect(profile.favoriteKeywords, ['cafe', 'walk']);
      expect(profile.preferenceHighlights, ['pasta', 'quiet', 'planned']);
    },
  );
}
