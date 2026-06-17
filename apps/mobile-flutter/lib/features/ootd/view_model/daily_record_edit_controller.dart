import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/ootd_model.dart';
import '../../memory/view_model/memory_detail_view_model.dart';
import '../repository/record_repository.dart';

final dailyRecordEditControllerProvider = Provider<DailyRecordEditController>(
  (ref) => DailyRecordEditController(ref),
);

class DailyRecordEditController {
  const DailyRecordEditController(this._ref);

  static const _maxPhotoCount = 5;

  final Ref _ref;

  Future<DailyRecordEditLoadState> load(String memoryId) async {
    final record = await _ref
        .read(recordRepositoryProvider)
        .fetchRecord(memoryId);
    final dailyItems = record.timeline
        .where((item) => item.category == 'daily')
        .toList(growable: false);
    final photoItems = record.timeline
        .where((item) => item.category == 'photo')
        .toList(growable: false);
    final memo = dailyItems.isNotEmpty
        ? dailyItems.first.description
        : record.timeline.isEmpty
        ? ''
        : record.timeline.first.description;
    final photos = <DailyRecordEditPhotoState>[];

    if (photoItems.isEmpty && record.imageUrls.isEmpty) {
      photos.add(const DailyRecordEditPhotoState());
    } else {
      final rawCount = photoItems.length > record.imageUrls.length
          ? photoItems.length
          : record.imageUrls.length;
      final count = rawCount > _maxPhotoCount ? _maxPhotoCount : rawCount;
      for (var i = 0; i < count; i++) {
        final item = i < photoItems.length ? photoItems[i] : null;
        photos.add(
          DailyRecordEditPhotoState(
            originalUrl:
                item?.imageUrl ??
                (i < record.imageUrls.length ? record.imageUrls[i] : null),
            description: item?.description ?? '',
          ),
        );
      }
    }

    return DailyRecordEditLoadState(
      record: record,
      tags: [...record.moodTags],
      memo: memo,
      mood: record.mood.isEmpty ? record.brands['mood'] ?? '평온' : record.mood,
      weather: record.weather.isEmpty
          ? record.brands['weather'] ?? '맑음'
          : record.weather,
      theme: record.brands['theme'] == 'clean' ? 'clean' : 'diary',
      photos: photos,
    );
  }

  Future<DailyRecordEditSaveResult> save(DailyRecordEditSaveInput input) async {
    final imageUrls = <String>[];
    final photoTimeline = <TimelineItem>[];
    var hasPhotoUploadFailure = false;
    for (var i = 0; i < input.photos.length; i++) {
      final photo = input.photos[i];
      String? url = photo.originalUrl;
      if (photo.imageBytes != null) {
        try {
          url = await _ref
              .read(recordRepositoryProvider)
              .uploadMedia(
                photo.imageBytes!,
                photo.fileName ?? 'daily-record.jpg',
              );
        } catch (_) {
          hasPhotoUploadFailure = true;
        }
      }
      final description = photo.description.trim();
      if (url == null && description.isEmpty) {
        continue;
      }
      if (url != null) {
        imageUrls.add(url);
      }
      photoTimeline.add(
        TimelineItem(
          time: '사진 ${i + 1}',
          placeName: url == null ? '사진 메모' : '추가한 사진',
          category: 'photo',
          description: description.isEmpty
              ? '사진에 대한 코멘트를 남기지 않았어요.'
              : description,
          imageUrl: url,
        ),
      );
    }

    final memo = input.memo.trim();
    final updated = input.record.copyWith(
      imagePath: imageUrls.isEmpty ? null : imageUrls.first,
      clearImagePath: imageUrls.isEmpty,
      imageUrls: imageUrls,
      moodTags: input.tags,
      mood: input.mood,
      weather: input.weather,
      brands: {
        ...input.record.brands,
        'recordType': 'daily',
        'mood': input.mood,
        'weather': input.weather,
        'theme': input.theme,
      },
      timeline: [
        ...photoTimeline,
        TimelineItem(
          time: '오늘',
          placeName: '하루 일과',
          category: 'daily',
          description: memo.isEmpty ? '오늘의 소중한 순간을 기록했어요.' : memo,
        ),
      ],
    );
    final saved = await _ref
        .read(recordRepositoryProvider)
        .updateRecord(input.memoryId, updated);
    _invalidateRecord(input.memoryId);
    return DailyRecordEditSaveResult(
      record: saved,
      hasPhotoUploadFailure: hasPhotoUploadFailure,
    );
  }

  Future<void> delete(String memoryId) async {
    await _ref.read(recordRepositoryProvider).deleteRecord(memoryId);
    _invalidateRecord(memoryId);
  }

  void _invalidateRecord(String memoryId) {
    _ref.invalidate(ootdRecordsProvider);
    _ref.invalidate(memoryRecordProvider(memoryId));
  }
}

class DailyRecordEditLoadState {
  const DailyRecordEditLoadState({
    required this.record,
    required this.tags,
    required this.memo,
    required this.mood,
    required this.weather,
    required this.theme,
    required this.photos,
  });

  final OotdRecord record;
  final List<String> tags;
  final String memo;
  final String mood;
  final String weather;
  final String theme;
  final List<DailyRecordEditPhotoState> photos;
}

class DailyRecordEditPhotoState {
  const DailyRecordEditPhotoState({this.originalUrl, this.description = ''});

  final String? originalUrl;
  final String description;
}

class DailyRecordEditPhotoInput {
  const DailyRecordEditPhotoInput({
    this.originalUrl,
    this.imageBytes,
    this.fileName,
    required this.description,
  });

  final String? originalUrl;
  final Uint8List? imageBytes;
  final String? fileName;
  final String description;
}

class DailyRecordEditSaveInput {
  const DailyRecordEditSaveInput({
    required this.memoryId,
    required this.record,
    required this.tags,
    required this.mood,
    required this.weather,
    required this.theme,
    required this.memo,
    required this.photos,
  });

  final String memoryId;
  final OotdRecord record;
  final List<String> tags;
  final String mood;
  final String weather;
  final String theme;
  final String memo;
  final List<DailyRecordEditPhotoInput> photos;
}

class DailyRecordEditSaveResult {
  const DailyRecordEditSaveResult({
    required this.record,
    required this.hasPhotoUploadFailure,
  });

  final OotdRecord record;
  final bool hasPhotoUploadFailure;
}
