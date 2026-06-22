import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/character_model.dart';
import '../../../shared/models/ootd_model.dart';
import '../../../shared/providers/state_providers.dart';
import '../../character/repository/character_repository.dart';
import '../repository/record_repository.dart';

final recordFlowControllerProvider = Provider<RecordFlowController>(
  (ref) => RecordFlowController(ref),
);

final recordRouteStateProvider = Provider<RecordRouteState>((ref) {
  final character =
      ref.watch(characterProfileProvider).value ??
      ref.watch(userCharacterProvider) ??
      const CharacterDraft();
  final records = ref.watch(ootdRecordsProvider);
  return RecordRouteState(character: character, records: records);
});

class RecordRouteState {
  const RecordRouteState({required this.character, required this.records});

  final CharacterDraft character;
  final AsyncValue<List<OotdRecord>> records;
}

enum RecordMutationResult { completed, missingId }

class RecordFlowController {
  const RecordFlowController(this._ref);

  final Ref _ref;

  String detailKeyFor(OotdRecord record) {
    final id = record.id;
    if (id != null && id.isNotEmpty) {
      return id;
    }
    final type = record.brands['recordType'] ?? 'ootd';
    return '${record.date.year}-${record.date.month}-${record.date.day}-$type';
  }

  Future<OotdRecord> saveRecord(OotdRecord record) async {
    final saved = await _ref
        .read(recordRepositoryProvider)
        .createRecord(record);
    _ref.invalidate(ootdRecordsProvider);
    return saved;
  }

  Future<UploadedMedia> uploadMedia(Uint8List bytes, String fileName) {
    return _ref.read(recordRepositoryProvider).uploadMedia(bytes, fileName);
  }

  Future<List<CrewOotdAppearance>> fetchCrewOotdAppearances({
    required String groupId,
    required String planId,
    required DateTime date,
  }) {
    return _ref.read(recordRepositoryProvider).fetchCrewOotdAppearances(
      groupId: groupId,
      planId: planId,
      date: date,
    );
  }

  Future<OotdRecord> saveRecordImage({
    required OotdRecord record,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final uploaded = await uploadMedia(bytes, fileName);
    final compositePrefix = record.brands['recordType'] == 'daily'
        ? 'dailyComposite'
        : 'ootdComposite';
    final updatedRecord = record.copyWith(
      imageUrls: [...record.imageUrls, uploaded.publicUrl],
      media: [
        ...record.media,
        uploaded.copyWith(sortOrder: record.media.length),
      ],
      brands: {
        ...record.brands,
        '${compositePrefix}ImageUrl': uploaded.publicUrl,
        '${compositePrefix}StorageKey': uploaded.storageKey,
      },
    );
    final saved = await saveRecord(updatedRecord);
    refreshRecords();
    return saved;
  }

  Future<RecordMutationResult> deleteRecord(OotdRecord record) async {
    final id = record.id;
    if (id == null || id.isEmpty) {
      return RecordMutationResult.missingId;
    }
    await _ref.read(recordRepositoryProvider).deleteRecord(id);
    _ref.invalidate(ootdRecordsProvider);
    return RecordMutationResult.completed;
  }

  RecordMutationResult validateEditableRecord(OotdRecord record) {
    final id = record.id;
    return id == null || id.isEmpty
        ? RecordMutationResult.missingId
        : RecordMutationResult.completed;
  }

  void refreshRecords() {
    _ref.invalidate(ootdRecordsProvider);
  }

  void resetCharacterDraft() {
    _ref.read(userCharacterProvider.notifier).state = null;
    _ref.read(skippedCharacterProvider.notifier).state = false;
  }
}
