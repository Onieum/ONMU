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
    final isDaily = record.brands['recordType'] == 'daily';
    final memo = _recordMemo(record);
    final json = await _client.postObject(
      '/api/v1/memories',
      body: {
        'type': isDaily ? 'DAILY' : 'OOTD',
        'title': _recordTitle(record),
        'memo': memo,
        'date': _dateOnly(record.date),
        'tags': record.moodTags,
        'imageUrls': record.imagePath == null ? const [] : [record.imagePath],
        'visibility': record.isPublic ? 'PUBLIC' : 'PRIVATE',
        'hairStyle': 'hair_style_${record.character.hairStyleIndex}',
        'hairColor': 'hair_color_${record.character.hairColorIndex}',
        'eyeColor': 'eye_color_${record.character.eyeColorIndex}',
      },
    );
    return _fromMemory(json);
  }

  OotdRecord _fromMemory(Map<String, dynamic> json) {
    final type = OnmuJson.readString(json, 'type', 'OOTD').toUpperCase();
    final tags = OnmuJson.stringList(json['tags']);
    final imageUrls = OnmuJson.stringList(json['imageUrls']);
    final snapshot = OnmuJson.asMap(json['characterSnapshot']);
    final memo = OnmuJson.readString(json, 'memo');
    final date = DateTime.tryParse(OnmuJson.readString(json, 'date')) ??
        DateTime.now();
    final isDaily = type == 'DAILY';
    final character = CharacterDraft(
      skinToneIndex: _readIndexedValue(snapshot['skin_tone'], 'skin'),
      hairStyleIndex: _readIndexedValue(snapshot['hair_style'], 'hair_style'),
      hairColorIndex: _readIndexedValue(snapshot['hair_color'], 'hair_color'),
      eyeShapeIndex: _readIndexedValue(snapshot['eye_style'], 'eye_style'),
      eyeColorIndex: _readIndexedValue(snapshot['eye_color'], 'eye_color'),
      topStyleIndex: _readIndexedValue(snapshot['clothes'], 'top', fallback: -1),
    );

    return OotdRecord(
      date: date,
      imagePath: imageUrls.isEmpty ? null : imageUrls.first,
      character: character,
      moodTags: tags,
      brands: {
        'recordType': isDaily ? 'daily' : 'ootd',
        'visibility': OnmuJson.readString(json, 'visibility'),
        'aiStatus': OnmuJson.readString(json, 'aiStatus'),
      },
      weather: '',
      mood: '',
      isPublic: OnmuJson.readString(json, 'visibility').toUpperCase() ==
          'PUBLIC',
      timeline: [
        TimelineItem(
          time: _dateOnly(date),
          placeName: isDaily ? 'Daily record' : 'OOTD',
          category: isDaily ? 'daily' : 'ootd',
          description: memo,
        ),
      ],
    );
  }

  String _recordTitle(OotdRecord record) {
    final isDaily = record.brands['recordType'] == 'daily';
    return isDaily ? 'Daily record ${_dateOnly(record.date)}' : 'OOTD ${_dateOnly(record.date)}';
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

  int _readIndexedValue(
    Object? value,
    String prefix, {
    int fallback = 0,
  }) {
    final text = value?.toString() ?? '';
    final match = RegExp('^${RegExp.escape(prefix)}_(-?\\d+)\$')
        .firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? fallback;
    }
    return fallback;
  }
}
