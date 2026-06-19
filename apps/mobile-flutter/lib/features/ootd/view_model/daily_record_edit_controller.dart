import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/ootd_model.dart';
import '../repository/record_repository.dart';
import 'record_lookup_service.dart';

final dailyRecordEditControllerProvider = Provider<DailyRecordEditController>(
  (ref) => DailyRecordEditController(ref),
);

class DailyRecordEditController {
  const DailyRecordEditController(this._ref);

  static const _maxPhotoCount = 5;

  final Ref _ref;

  Future<DailyRecordEditLoadState> load(String memoryId) async {
    final record = await _ref
        .read(recordLookupServiceProvider)
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
      final rawCount = [
        photoItems.length,
        record.imageUrls.length,
        record.media.length,
      ].reduce((a, b) => a > b ? a : b);
      final count = rawCount > _maxPhotoCount ? _maxPhotoCount : rawCount;
      for (var i = 0; i < count; i++) {
        final item = i < photoItems.length ? photoItems[i] : null;
        final media = i < record.media.length ? record.media[i] : null;
        photos.add(
          DailyRecordEditPhotoState(
            originalUrl:
                item?.imageUrl ??
                media?.publicUrl ??
                (i < record.imageUrls.length ? record.imageUrls[i] : null),
            originalStorageKey: item?.mediaStorageKey ?? media?.storageKey,
            description: item?.description ?? '',
          ),
        );
      }
    }

    return DailyRecordEditLoadState(
      record: record,
      tags: [...record.moodTags],
      memo: memo,
      mood: record.mood.isEmpty ? record.brands['mood'] ?? 'calm' : record.mood,
      weather: record.weather.isEmpty
          ? record.brands['weather'] ?? 'sunny'
          : record.weather,
      theme: record.brands['theme'] == 'clean' ? 'clean' : 'diary',
      photos: photos,
    );
  }

  Future<DailyRecordEditSaveResult> save(DailyRecordEditSaveInput input) async {
    final imageUrls = <String>[];
    final media = <UploadedMedia>[];
    final photoTimeline = <TimelineItem>[];
    var hasPhotoUploadFailure = false;

    for (var i = 0; i < input.photos.length; i++) {
      final photo = input.photos[i];
      String? url = photo.originalUrl;
      String? storageKey = photo.originalStorageKey;

      if (photo.imageBytes != null) {
        try {
          final uploaded = await _ref
              .read(recordRepositoryProvider)
              .uploadMedia(
                photo.imageBytes!,
                photo.fileName ?? 'daily-record.jpg',
              );
          url = uploaded.publicUrl;
          storageKey = uploaded.storageKey;
          media.add(uploaded.copyWith(sortOrder: media.length));
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
        if (storageKey != null &&
            storageKey.isNotEmpty &&
            !media.any((item) => item.storageKey == storageKey)) {
          media.add(
            UploadedMedia(
              storageKey: storageKey,
              publicUrl: url,
              sortOrder: media.length,
            ),
          );
        }
      }

      photoTimeline.add(
        TimelineItem(
          time: 'Photo ${i + 1}',
          placeName: url == null ? 'Photo memo' : 'Added photo',
          category: 'photo',
          description: description.isEmpty
              ? 'No photo comment was written.'
              : description,
          imageUrl: url,
          mediaStorageKey: storageKey,
        ),
      );
    }

    final memo = input.memo.trim();
    final updated = input.record.copyWith(
      imagePath: imageUrls.isEmpty ? null : imageUrls.first,
      clearImagePath: imageUrls.isEmpty,
      imageUrls: imageUrls,
      media: media,
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
          time: 'Today',
          placeName: 'Daily record',
          category: 'daily',
          description: memo.isEmpty
              ? 'No daily memo was written.'
              : memo,
        ),
      ],
    );
    final saved = await _ref
        .read(recordRepositoryProvider)
        .updateRecord(input.memoryId, updated);
    _invalidateRecords();
    return DailyRecordEditSaveResult(
      record: saved,
      hasPhotoUploadFailure: hasPhotoUploadFailure,
    );
  }

  Future<void> delete(String memoryId) async {
    await _ref.read(recordRepositoryProvider).deleteRecord(memoryId);
    _invalidateRecords();
  }

  void _invalidateRecords() {
    _ref.invalidate(ootdRecordsProvider);
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
  const DailyRecordEditPhotoState({
    this.originalUrl,
    this.originalStorageKey,
    this.description = '',
  });

  final String? originalUrl;
  final String? originalStorageKey;
  final String description;
}

class DailyRecordEditPhotoInput {
  const DailyRecordEditPhotoInput({
    this.originalUrl,
    this.originalStorageKey,
    this.imageBytes,
    this.fileName,
    required this.description,
  });

  final String? originalUrl;
  final String? originalStorageKey;
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
