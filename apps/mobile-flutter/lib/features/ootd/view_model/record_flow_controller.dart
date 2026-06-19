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
