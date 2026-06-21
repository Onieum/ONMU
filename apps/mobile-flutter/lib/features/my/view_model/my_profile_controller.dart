import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _ref.read(preferenceProfileProvider.notifier).state = updated
        .toPreferenceProfile();
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

  Future<void> updateFriendMemo(FriendProfile friend, String memo) async {
    await _ref.read(friendRepositoryProvider).updateFriend(friend, memo: memo);
    _ref.invalidate(friendsProvider);
  }

  Future<void> deleteFriend(FriendProfile friend) async {
    await _ref.read(friendRepositoryProvider).deleteFriend(friend);
    _ref.invalidate(friendsProvider);
    _ref.invalidate(friendProfileProvider(friend));
  }

  Future<void> addFriend(String publicId) async {
    try {
      await _ref.read(friendRepositoryProvider).addFriend(publicId);
      _ref.invalidate(friendsProvider);
    } on DioException catch (error) {
      final friendError = FriendAddException.fromDio(error);
      if (friendError.kind == FriendAddErrorKind.alreadyFriend) {
        _ref.invalidate(friendsProvider);
      }
      throw friendError;
    }
  }
}

enum FriendAddErrorKind {
  notFound,
  alreadyFriend,
  searchNotAllowed,
  cannotAddSelf,
  unknown,
}

class FriendAddException implements Exception {
  const FriendAddException(
    this.message, {
    this.kind = FriendAddErrorKind.unknown,
  });

  final String message;
  final FriendAddErrorKind kind;

  factory FriendAddException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final reason = error.response?.data?.toString() ?? '';
    if (statusCode == 404) {
      return const FriendAddException(
        '없는 고유 ID예요.',
        kind: FriendAddErrorKind.notFound,
      );
    }
    if (statusCode == 409 || reason.contains('already_friend')) {
      return const FriendAddException(
        '이미 친구예요.',
        kind: FriendAddErrorKind.alreadyFriend,
      );
    }
    if (statusCode == 403 || reason.contains('search_not_allowed')) {
      return const FriendAddException(
        '상대가 친구 추가를 허용하지 않았어요.',
        kind: FriendAddErrorKind.searchNotAllowed,
      );
    }
    if (statusCode == 400 || reason.contains('cannot_add_self')) {
      return const FriendAddException(
        '내 고유 ID는 친구로 추가할 수 없어요.',
        kind: FriendAddErrorKind.cannotAddSelf,
      );
    }
    return const FriendAddException('친구 등록에 실패했어요. 다시 시도해주세요.');
  }
}
