import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/character_model.dart';
import '../../../shared/providers/state_providers.dart';
import '../../character/repository/character_repository.dart';
import '../domain/my_profile.dart';
import '../repository/friend_repository.dart';
import '../repository/my_repository.dart';

final myProfileControllerProvider = Provider<MyProfileController>(
  (ref) => MyProfileController(ref),
);

class MyProfileController {
  const MyProfileController(this._ref);

  final Ref _ref;

  Future<void> saveProfile(MyProfile profile) async {
    await _ref.read(myRepositoryProvider).updateMyProfile(profile);
    _ref.invalidate(myProfileProvider);
  }

  Future<void> saveCharacter(CharacterDraft draft) async {
    try {
      final saved = await _ref
          .read(characterRepositoryProvider)
          .saveMyCharacter(draft);
      _ref.read(userCharacterProvider.notifier).state = saved;
      _ref.invalidate(characterProfileProvider);
    } catch (_) {
      _ref.read(userCharacterProvider.notifier).state = draft;
    }
    _ref.read(skippedCharacterProvider.notifier).state = false;
  }

  Future<void> toggleFavoriteFriend(FriendProfile friend) async {
    await _ref
        .read(friendRepositoryProvider)
        .updateFriend(friend, favorite: !friend.isFavorite);
    _ref.invalidate(friendsProvider);
  }

  Future<void> addFriend(String publicId) async {
    await _ref.read(friendRepositoryProvider).addFriend(publicId);
    _ref.invalidate(friendsProvider);
  }
}
