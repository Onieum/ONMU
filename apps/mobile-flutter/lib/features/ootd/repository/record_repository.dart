import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
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

  Future<String> uploadMedia(Uint8List bytes, String fileName);
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
  Future<String> uploadMedia(Uint8List bytes, String fileName) async {
    final json = await _client.uploadMultipart(
      '/api/v1/media/upload',
      bytes,
      fileName,
    );
    final publicUrl = OnmuJson.readString(json, 'publicUrl');
    if (publicUrl.isEmpty) {
      throw StateError('media_upload_public_url_missing');
    }
    return _absoluteApiUrl(publicUrl);
  }

  Map<String, Object?> _toMemoryBody(OotdRecord record) {
    final isDaily = record.brands['recordType'] == 'daily';
    final memo = _recordMemo(record);
    final imageUrls = record.imageUrls.isNotEmpty
        ? record.imageUrls
        : record.imagePath == null
            ? const <String>[]
            : <String>[record.imagePath!];
    return {
      'type': isDaily ? 'DAILY' : 'OOTD',
      'title': _recordTitle(record),
      'memo': memo,
      'date': _dateOnly(record.date),
      'tags': record.moodTags,
      'imageUrls': imageUrls,
      'visibility': record.isPublic ? 'PUBLIC' : 'PRIVATE',
      'hairStyle': 'hair_style_${record.character.hairStyleIndex}',
      'hairColor': 'hair_color_${record.character.hairColorIndex}',
      'eyeColor': 'eye_color_${record.character.eyeColorIndex}',
      'payload': _recordPayload(record),
    };
  }

  OotdRecord _fromMemory(Map<String, dynamic> json) {
    final type = OnmuJson.readString(json, 'type', 'OOTD').toUpperCase();
    final tags = OnmuJson.stringList(json['tags']);
    final imageUrls = OnmuJson.stringList(json['imageUrls'])
        .map(_absoluteApiUrl)
        .toList(growable: false);
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
    final timeline = _timelineFromPayload(payload, memo, isDaily, date, imageUrls);
    final brands = <String, String>{
      for (final entry in payloadBrands.entries)
        entry.key.toString(): entry.value?.toString() ?? '',
      'recordType': isDaily ? 'daily' : 'ootd',
      'visibility': OnmuJson.readString(json, 'visibility'),
      'aiStatus': OnmuJson.readString(json, 'aiStatus'),
    };
    final mood = OnmuJson.readString(payload, 'mood', OnmuJson.readString(payloadBrands, 'mood'));
    final weather = OnmuJson.readString(payload, 'weather', OnmuJson.readString(payloadBrands, 'weather'));

    return OotdRecord(
      id: id.isEmpty ? null : id,
      date: date,
      imagePath: imageUrls.isEmpty ? null : imageUrls.first,
      imageUrls: imageUrls,
      character: character,
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
      'timeline': record.timeline
          .map(
            (item) => {
              'time': item.time,
              'placeName': item.placeName,
              'category': item.category,
              'description': item.description,
              if (item.imageUrl != null) 'imageUrl': item.imageUrl,
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
  ) {
    final rawTimeline = payload['timeline'];
    if (rawTimeline is List && rawTimeline.isNotEmpty) {
      return rawTimeline.asMap().entries.map((entry) {
        final item = OnmuJson.asMap(entry.value);
        return TimelineItem(
          time: OnmuJson.readString(item, 'time', entry.key.toString()),
          placeName: OnmuJson.readString(item, 'placeName', '사진 기록 ${entry.key + 1}'),
          category: OnmuJson.readString(item, 'category', 'photo'),
          description: OnmuJson.readString(item, 'description'),
          imageUrl: _nullableImageUrl(OnmuJson.readString(
            item,
            'imageUrl',
            entry.key < imageUrls.length ? imageUrls[entry.key] : '',
          )),
        );
      }).toList(growable: false);
    }
    final photoItems = imageUrls.asMap().entries
        .map(
          (entry) => TimelineItem(
            time: '사진 ${entry.key + 1}',
            placeName: '추가한 사진',
            category: 'photo',
            description: '사진에 대한 코멘트를 남기지 않았어요.',
            imageUrl: entry.value,
          ),
        )
        .toList(growable: true);
    photoItems.add(
      TimelineItem(
        time: _dateOnly(date),
        placeName: isDaily ? '하루 일과' : 'OOTD',
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
}


