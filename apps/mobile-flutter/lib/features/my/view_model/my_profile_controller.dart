import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import '../../../shared/models/character_model.dart';
import '../../../shared/providers/state_providers.dart';
import '../../auth/providers/auth_providers.dart';
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
    final updated = await _ref
        .read(myRepositoryProvider)
        .updateMyProfile(profile);
    final currentUser = _ref.read(authUserProvider);
    final nickname = updated.realName.trim();
    if (currentUser != null && nickname.isNotEmpty) {
      _ref.read(authUserProvider.notifier).state = currentUser.copyWith(
        nickname: nickname,
        profileImageUrl: updated.profileImageUrl,
      );
    }
    _ref.invalidate(myProfileProvider);
  }

  Future<String> uploadProfileImage(Uint8List bytes, String fileName) {
    return _ref.read(myRepositoryProvider).uploadProfileImage(bytes, fileName);
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

  Future<void> deleteFriend(FriendProfile friend) async {
    await _ref.read(friendRepositoryProvider).deleteFriend(friend);
    _ref.invalidate(friendsProvider);
    _ref.invalidate(friendProfileProvider(friend));
  }

  Future<void> addFriend(String publicId) async {
    await _ref.read(friendRepositoryProvider).addFriend(publicId);
    _ref.invalidate(friendsProvider);
  }
}
