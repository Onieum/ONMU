import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../core/error/onmu_exception.dart';
import '../../../shared/models/character_model.dart';
import '../../../shared/models/ootd_model.dart';

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return ApiRecordRepository(ref.watch(onmuApiClientProvider));
});

final ootdRecordsProvider = FutureProvider<List<OotdRecord>>((ref) {
  return ref.watch(recordRepositoryProvider).fetchMyRecords();
});

abstract interface class RecordRepository {
  Future<List<OotdRecord>> fetchMyRecords();

  Future<OotdRecord> createRecord(OotdRecord record);

  Future<OotdRecord> fetchRecord(String id);

  Future<OotdRecord> updateRecord(String id, OotdRecord record);

  Future<void> deleteRecord(String id);

  Future<UploadedMedia> uploadMedia(Uint8List bytes, String fileName);

  Future<OotdAvatarGenerationJob> createAvatarGeneration({
    required String recordId,
    required String inputType,
    String? outfitPhotoMediaId,
    String? outfitPhotoStorageKey,
    String? outfitDescription,
    CharacterDraft? characterOverrides,
  });

  Future<OotdAvatarGenerationJob> fetchAvatarGeneration(String jobId);

  Future<List<CrewOotdAppearance>> fetchCrewOotdAppearances({
    required String groupId,
    required String planId,
    required DateTime date,
  });
}

class ApiRecordRepository implements RecordRepository {
  ApiRecordRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<List<OotdRecord>> fetchMyRecords() async {
    final memories = await _client.getList('/api/v1/memories');
    return memories.map(_fromMemory).toList(growable: false);
  }

  @override
  Future<OotdRecord> createRecord(OotdRecord record) async {
    final json = await _client.postObject(
      '/api/v1/memories',
      body: _toMemoryBody(record),
    );
    return _fromMemory(json);
  }

  @override
  Future<OotdRecord> fetchRecord(String id) async {
    final json = await _client.getObject('/api/v1/memories/$id');
    return _fromMemory(json);
  }

  @override
  Future<OotdRecord> updateRecord(String id, OotdRecord record) async {
    final json = await _client.patchObject(
      '/api/v1/memories/$id',
      body: _toMemoryBody(record),
    );
    return _fromMemory(json);
  }

  @override
  Future<void> deleteRecord(String id) {
    return _client.deleteObject('/api/v1/memories/$id');
  }

  @override
  Future<UploadedMedia> uploadMedia(Uint8List bytes, String fileName) async {
    final json = await _client.uploadMultipart(
      '/api/v1/media/upload',
      bytes,
      fileName,
    );
    final storageKey = OnmuJson.readString(json, 'storageKey');
    final publicUrl = OnmuJson.readString(json, 'publicUrl');
    if (storageKey.isEmpty) {
      throw OnmuContractException.missingField(
        feature: 'record',
        field: 'storageKey',
        endpoint: '/api/v1/media/upload',
      );
    }
    if (publicUrl.isEmpty) {
      throw OnmuContractException.missingField(
        feature: 'record',
        field: 'publicUrl',
        endpoint: '/api/v1/media/upload',
      );
    }
    return UploadedMedia(
      storageKey: storageKey,
      publicUrl: _absoluteApiUrl(publicUrl),
    );
  }

  @override
  Future<OotdAvatarGenerationJob> createAvatarGeneration({
    required String recordId,
    required String inputType,
    String? outfitPhotoMediaId,
    String? outfitPhotoStorageKey,
    String? outfitDescription,
    CharacterDraft? characterOverrides,
  }) async {
    final body = <String, Object?>{
      'recordId': recordId,
      'inputType': inputType,
    };
    if (outfitPhotoMediaId != null) {
      body['outfitPhotoMediaId'] = outfitPhotoMediaId;
    }
    if (outfitPhotoStorageKey != null) {
      body['outfitPhotoStorageKey'] = outfitPhotoStorageKey;
    }
    if (outfitDescription != null) {
      body['outfitDescription'] = outfitDescription;
    }
    if (characterOverrides != null) {
      body['characterOverrides'] = {
        'hairStyle': 'hair_style_${characterOverrides.hairStyleIndex}',
        'hairColor': 'hair_color_${characterOverrides.hairColorIndex}',
        'eyeStyle': 'eye_style_${characterOverrides.eyeShapeIndex}',
        'eyeColor': 'eye_color_${characterOverrides.eyeColorIndex}',
      };
    }
    final json = await _client.postObject(
      '/api/v1/ootd/avatar-generations',
      body: body,
    );
    return _avatarGenerationJob(json);
  }

  @override
  Future<OotdAvatarGenerationJob> fetchAvatarGeneration(String jobId) async {
    final json = await _client.getObject(
      '/api/v1/ootd/avatar-generations/$jobId',
    );
    return _avatarGenerationJob(json);
  }

  @override
  Future<List<CrewOotdAppearance>> fetchCrewOotdAppearances({
    required String groupId,
    required String planId,
    required DateTime date,
  }) async {
    final items = await _client.getList(
      '/api/v1/groups/$groupId/plans/$planId/crew-ootd-appearances'
      '?date=${_dateOnly(date)}',
    );
    return items.map(_crewOotdAppearance).toList(growable: false);
  }

  Map<String, Object?> _toMemoryBody(OotdRecord record) {
    final isDaily = record.brands['recordType'] == 'daily';
    final memo = _recordMemo(record);
    final imageUrls = record.imageUrls.isNotEmpty
        ? record.imageUrls
        : record.imagePath == null
        ? const <String>[]
        : <String>[record.imagePath!];
    final media = record.media
        .asMap()
        .entries
        .map(
          (entry) => {
            'mediaType': entry.value.mediaType,
            'storageKey': entry.value.storageKey,
            'publicUrl': entry.value.publicUrl,
            'width': entry.value.width,
            'height': entry.value.height,
            'durationSeconds': entry.value.durationSeconds,
            'sortOrder': entry.value.sortOrder == 0
                ? entry.key
                : entry.value.sortOrder,
          },
        )
        .toList(growable: false);
    return {
      'type': isDaily ? 'DAILY' : 'OOTD',
      'title': _recordTitle(record),
      'memo': memo,
      'date': _dateOnly(record.date),
      'tags': record.moodTags,
      'imageUrls': imageUrls,
      if (media.isNotEmpty) 'media': media,
      'visibility': record.isPublic ? 'PUBLIC' : 'PRIVATE',
      'hairStyle': 'hair_style_${record.character.hairStyleIndex}',
      'hairColor': 'hair_color_${record.character.hairColorIndex}',
      'eyeStyle': 'eye_style_${record.character.eyeShapeIndex}',
      'eyeColor': 'eye_color_${record.character.eyeColorIndex}',
      'payload': _recordPayload(record),
    };
  }

  OotdRecord _fromMemory(Map<String, dynamic> json) {
    final type = OnmuJson.readString(json, 'type', 'OOTD').toUpperCase();
    final tags = OnmuJson.stringList(json['tags']);
    final media = _mediaList(json['media']);
    final imageUrls = media.isNotEmpty
        ? media.map((item) => item.publicUrl).toList(growable: false)
        : OnmuJson.stringList(
            json['imageUrls'],
          ).map(_absoluteApiUrl).toList(growable: false);
    final payload = OnmuJson.asMap(json['payload']);
    final payloadBrands = OnmuJson.asMap(payload['brands']);
    final snapshot = OnmuJson.asMap(json['characterSnapshot']);
    final memo = OnmuJson.readString(json, 'memo');
    final date =
        DateTime.tryParse(OnmuJson.readString(json, 'date')) ?? DateTime.now();
    final isDaily = type == 'DAILY';
    final character = CharacterDraft(
      skinToneIndex: _readIndexedValue(snapshot['skin_tone'], 'skin'),
      hairStyleIndex: _readIndexedValue(snapshot['hair_style'], 'hair_style'),
      hairColorIndex: _readIndexedValue(snapshot['hair_color'], 'hair_color'),
      eyeShapeIndex: _readIndexedValue(snapshot['eye_style'], 'eye_style'),
      eyeColorIndex: _readIndexedValue(snapshot['eye_color'], 'eye_color'),
      topStyleIndex: _readIndexedValue(
        snapshot['clothes'],
        'top',
        fallback: -1,
      ),
    );

    final id = OnmuJson.readString(
      json,
      'publicId',
      OnmuJson.readString(json, 'id'),
    );
    final timeline = _timelineFromPayload(
      payload,
      memo,
      isDaily,
      date,
      imageUrls,
      media,
    );
    final generatedImageUrl = OnmuJson.readString(
      payload,
      'generatedImageUrl',
      OnmuJson.readString(json, 'generatedImageUrl'),
    );
    final aiStatus = OnmuJson.readString(
      json,
      'aiStatus',
      OnmuJson.readString(payload, 'aiStatus'),
    );
    final brands = <String, String>{
      for (final entry in payloadBrands.entries)
        entry.key.toString(): entry.value?.toString() ?? '',
      'recordType': isDaily ? 'daily' : 'ootd',
      'visibility': OnmuJson.readString(json, 'visibility'),
      'aiStatus': aiStatus,
      if (generatedImageUrl.isNotEmpty)
        'generatedImageUrl': _absoluteApiUrl(generatedImageUrl),
    };
    final mood = OnmuJson.readString(
      payload,
      'mood',
      OnmuJson.readString(payloadBrands, 'mood'),
    );
    final weather = OnmuJson.readString(
      payload,
      'weather',
      OnmuJson.readString(payloadBrands, 'weather'),
    );

    return OotdRecord(
      id: id.isEmpty ? null : id,
      date: date,
      imagePath: imageUrls.isEmpty ? null : imageUrls.first,
      imageUrls: imageUrls,
      media: media,
      character: character,
      crewCharacters: _crewCharactersFromPayload(payload),
      crewAppearances: _crewAppearancesFromPayload(payload),
      moodTags: tags,
      brands: brands,
      weather: weather,
      mood: mood,
      isPublic:
          OnmuJson.readString(json, 'visibility').toUpperCase() == 'PUBLIC',
      timeline: timeline,
    );
  }

  Map<String, Object?> _recordPayload(OotdRecord record) {
    return {
      'brands': record.brands,
      'mood': record.mood,
      'weather': record.weather,
      if (record.crewAppearances.isNotEmpty)
        'crewAppearances': record.crewAppearances
            .map(_crewOotdAppearancePayload)
            .toList(growable: false),
      'timeline': record.timeline
          .map(
            (item) => {
              'time': item.time,
              'placeName': item.placeName,
              'category': item.category,
              'description': item.description,
              if (item.imageUrl != null) 'imageUrl': item.imageUrl,
              if (item.mediaStorageKey != null)
                'mediaStorageKey': item.mediaStorageKey,
            },
          )
          .toList(growable: false),
    };
  }

  List<TimelineItem> _timelineFromPayload(
    Map<String, dynamic> payload,
    String memo,
    bool isDaily,
    DateTime date,
    List<String> imageUrls,
    List<UploadedMedia> media,
  ) {
    final rawTimeline = payload['timeline'];
    if (rawTimeline is List && rawTimeline.isNotEmpty) {
      return rawTimeline
          .asMap()
          .entries
          .map((entry) {
            final item = OnmuJson.asMap(entry.value);
            return TimelineItem(
              time: OnmuJson.readString(item, 'time', entry.key.toString()),
              placeName: OnmuJson.readString(
                item,
                'placeName',
                'Photo record ${entry.key + 1}',
              ),
              category: OnmuJson.readString(item, 'category', 'photo'),
              description: OnmuJson.readString(item, 'description'),
              imageUrl: _nullableImageUrl(
                OnmuJson.readString(
                  item,
                  'imageUrl',
                  entry.key < imageUrls.length ? imageUrls[entry.key] : '',
                ),
              ),
              mediaStorageKey: OnmuJson.readString(
                item,
                'mediaStorageKey',
                entry.key < media.length ? media[entry.key].storageKey : '',
              ),
            );
          })
          .toList(growable: false);
    }
    final photoItems = imageUrls
        .asMap()
        .entries
        .map(
          (entry) => TimelineItem(
            time: 'Photo ${entry.key + 1}',
            placeName: 'Added photo',
            category: 'photo',
            description: 'No photo comment was written.',
            imageUrl: entry.value,
            mediaStorageKey: entry.key < media.length
                ? media[entry.key].storageKey
                : null,
          ),
        )
        .toList(growable: true);
    photoItems.add(
      TimelineItem(
        time: _dateOnly(date),
        placeName: isDaily ? 'Daily record' : 'OOTD',
        category: isDaily ? 'daily' : 'ootd',
        description: memo,
      ),
    );
    return photoItems;
  }

  String _recordTitle(OotdRecord record) {
    final isDaily = record.brands['recordType'] == 'daily';
    return isDaily
        ? 'Daily record ${_dateOnly(record.date)}'
        : 'OOTD ${_dateOnly(record.date)}';
  }

  String _recordMemo(OotdRecord record) {
    final daily = record.timeline.where((item) => item.category == 'daily');
    if (daily.isNotEmpty) {
      return daily.first.description;
    }
    if (record.timeline.isNotEmpty) {
      return record.timeline.first.description;
    }
    return '';
  }

  List<UploadedMedia> _mediaList(Object? value) {
    if (value is! List) return const [];
    return value
        .map(OnmuJson.asMap)
        .map((item) {
          final storageKey = OnmuJson.readString(item, 'storageKey');
          final publicUrl = OnmuJson.readString(item, 'publicUrl');
          if (storageKey.isEmpty || publicUrl.isEmpty) return null;
          return UploadedMedia(
            id: OnmuJson.readString(item, 'id').isEmpty
                ? null
                : OnmuJson.readString(item, 'id'),
            storageKey: storageKey,
            publicUrl: _absoluteApiUrl(publicUrl),
            mediaType: OnmuJson.readString(item, 'mediaType', 'IMAGE'),
            width: _nullableInt(item['width']),
            height: _nullableInt(item['height']),
            durationSeconds: _nullableDouble(item['durationSeconds']),
            sortOrder: OnmuJson.readInt(item, 'sortOrder'),
          );
        })
        .whereType<UploadedMedia>()
        .toList(growable: false);
  }

  int? _nullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _nullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

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

  String _absoluteApiUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (!trimmed.startsWith('/')) return trimmed;
    final baseUrl = _client.baseUrl.endsWith('/')
        ? _client.baseUrl.substring(0, _client.baseUrl.length - 1)
        : _client.baseUrl;
    return '$baseUrl$trimmed';
  }

  String? _nullableImageUrl(String url) {
    final normalized = _absoluteApiUrl(url);
    return normalized.isEmpty ? null : normalized;
  }

  List<CharacterDraft> _crewCharactersFromPayload(
    Map<String, dynamic> payload,
  ) {
    final fromAppearances = _crewAppearancesFromPayload(payload)
        .map((appearance) => appearance.character)
        .whereType<CharacterDraft>()
        .toList(growable: false);
    if (fromAppearances.isNotEmpty) return fromAppearances;
    final raw = payload['crewCharacters'];
    if (raw is! List) return const [];
    return raw
        .map(OnmuJson.asMap)
        .map(_characterDraftFromJson)
        .whereType<CharacterDraft>()
        .toList(growable: false);
  }

  List<CrewOotdAppearance> _crewAppearancesFromPayload(
    Map<String, dynamic> payload,
  ) {
    final raw = payload['crewAppearances'];
    if (raw is! List) return const [];
    return raw
        .map(OnmuJson.asMap)
        .map(_crewOotdAppearance)
        .toList(growable: false);
  }

  CrewOotdAppearance _crewOotdAppearance(Map<String, dynamic> json) {
    final characterJson = OnmuJson.asMap(json['character']);
    final character = characterJson.isEmpty
        ? null
        : _characterDraftFromJson(characterJson);
    final imageUrl = OnmuJson.readString(json, 'ootdImageUrl');
    return CrewOotdAppearance(
      userId: OnmuJson.readString(json, 'userId'),
      nickname: OnmuJson.readString(json, 'nickname'),
      source: OnmuJson.readString(json, 'source', 'PROFILE_CHARACTER'),
      ootdRecordId: _blankToNull(OnmuJson.readString(json, 'ootdRecordId')),
      ootdImageUrl: imageUrl.isEmpty ? null : _absoluteApiUrl(imageUrl),
      character: character,
    );
  }

  CharacterDraft? _characterDraftFromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return null;
    return CharacterDraft(
      skinToneIndex: _readIndexedValue(
        json['skin_tone'] ?? json['skinTone'],
        'skin',
      ),
      hairStyleIndex: _readIndexedValue(
        json['hair_style'] ?? json['hairStyle'],
        'hair_style',
      ),
      hairColorIndex: _readIndexedValue(
        json['hair_color'] ?? json['hairColor'],
        'hair_color',
      ),
      eyeShapeIndex: _readIndexedValue(
        json['eye_style'] ?? json['eyeStyle'],
        'eye_style',
      ),
      eyeColorIndex: _readIndexedValue(
        json['eye_color'] ?? json['eyeColor'],
        'eye_color',
      ),
      topStyleIndex: _readIndexedValue(
        json['clothes'] ?? json['topStyle'],
        'top',
        fallback: -1,
      ),
    );
  }

  Map<String, Object?> _crewOotdAppearancePayload(
    CrewOotdAppearance appearance,
  ) {
    return {
      'userId': appearance.userId,
      'nickname': appearance.nickname,
      'source': appearance.source,
      if (appearance.ootdRecordId != null)
        'ootdRecordId': appearance.ootdRecordId,
      if (appearance.ootdImageUrl != null)
        'ootdImageUrl': appearance.ootdImageUrl,
      if (appearance.character != null)
        'character': _characterDraftPayload(appearance.character!),
    };
  }

  Map<String, Object?> _characterDraftPayload(CharacterDraft character) {
    return {
      'skin_tone': 'skin_${character.skinToneIndex}',
      'hair_style': 'hair_style_${character.hairStyleIndex}',
      'hair_color': 'hair_color_${character.hairColorIndex}',
      'eye_style': 'eye_style_${character.eyeShapeIndex}',
      'eye_color': 'eye_color_${character.eyeColorIndex}',
      'clothes': 'top_${character.topStyleIndex}',
    };
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  OotdAvatarGenerationJob _avatarGenerationJob(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(OnmuJson.readString(json, 'createdAt'));
    final updatedAt = DateTime.tryParse(OnmuJson.readString(json, 'updatedAt'));
    final generatedImageUrl = OnmuJson.readString(json, 'generatedImageUrl');
    final errorCode = OnmuJson.readString(json, 'errorCode');
    return OotdAvatarGenerationJob(
      jobId: OnmuJson.readString(json, 'jobId'),
      status: OnmuJson.readString(json, 'status', 'PENDING'),
      recordId: OnmuJson.readString(json, 'recordId'),
      generatedImageUrl: generatedImageUrl.isEmpty
          ? null
          : _absoluteApiUrl(generatedImageUrl),
      errorCode: errorCode.isEmpty ? null : errorCode,
      retryable: OnmuJson.readBool(json, 'retryable'),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
