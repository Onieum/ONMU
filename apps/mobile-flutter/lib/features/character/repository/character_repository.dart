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
      return _fromJson(json);
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
    return _fromJson(json).copyWith(nickname: draft.nickname);
  }

  CharacterDraft _fromJson(Map<String, dynamic> json) {
    return CharacterDraft(
      gender: OnmuJson.readString(json, 'gender', 'female'),
      skinToneIndex: _readIndexedValue(json['skinTone'], 'skin'),
      hairStyleIndex: _readIndexedValue(json['hairStyle'], 'hair_style'),
      hairColorIndex: _readIndexedValue(json['hairColor'], 'hair_color'),
      eyeShapeIndex: _readIndexedValue(json['eyeStyle'], 'eye_style'),
      eyeColorIndex: _readIndexedValue(json['eyeColor'], 'eye_color'),
      topStyleIndex: _readIndexedValue(json['clothes'], 'top', fallback: -1),
    );
  }

  String _indexedValue(String prefix, int index) => '${prefix}_$index';

  int _readIndexedValue(Object? value, String prefix, {int fallback = 0}) {
    final text = value?.toString() ?? '';
    final match = RegExp(
      '^${RegExp.escape(prefix)}_(-?\\d+)\$',
    ).firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? fallback;
    }
    return fallback;
  }
}
