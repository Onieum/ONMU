import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/character_model.dart';

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return ApiCharacterRepository(ref.watch(onmuApiClientProvider));
});

final characterProfileProvider = FutureProvider<CharacterDraft?>((ref) {
  return ref.watch(characterRepositoryProvider).fetchMyCharacter();
});

abstract interface class CharacterRepository {
  Future<CharacterDraft?> fetchMyCharacter();

  Future<CharacterDraft> saveMyCharacter(CharacterDraft draft);
}

class ApiCharacterRepository implements CharacterRepository {
  ApiCharacterRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<CharacterDraft?> fetchMyCharacter() async {
    try {
      final json = await _client.getObject('/api/v1/users/me/character');
      return CharacterDraft.fromApiJson(json);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<CharacterDraft> saveMyCharacter(CharacterDraft draft) async {
    final json = await _client.putObject(
      '/api/v1/users/me/character',
      body: {
        'gender': draft.gender,
        'skinTone': _indexedValue('skin', draft.skinToneIndex),
        'hairStyle': _indexedValue('hair_style', draft.hairStyleIndex),
        'hairColor': _indexedValue('hair_color', draft.hairColorIndex),
        'eyeStyle': _indexedValue('eye_style', draft.eyeShapeIndex),
        'eyeColor': _indexedValue('eye_color', draft.eyeColorIndex),
        'clothes': _indexedValue('top', draft.topStyleIndex),
      },
    );
    return CharacterDraft.fromApiJson(json, nickname: draft.nickname);
  }

  String _indexedValue(String prefix, int index) => '${prefix}_$index';
}
