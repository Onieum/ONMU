import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/ootd_model.dart';
import '../repository/record_repository.dart';

final recordLookupServiceProvider = Provider<RecordLookupService>((ref) {
  return RecordLookupService(ref.watch(recordRepositoryProvider));
});

class RecordLookupService {
  const RecordLookupService(this._repository);

  final RecordRepository _repository;

  Future<OotdRecord> fetchRecord(String key) async {
    try {
      return await _repository.fetchRecord(key);
    } catch (error, stackTrace) {
      final records = await _repository.fetchMyRecords();
      final fallback = findRecordByMemoryKey(records, key);
      if (fallback != null) {
        return fallback;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

OotdRecord? findRecordByMemoryKey(List<OotdRecord> records, String key) {
  for (final record in records) {
    if (record.id == key) {
      return record;
    }
    final type = record.brands['recordType'] ?? 'ootd';
    final dateKey =
        '${record.date.year}-${record.date.month}-${record.date.day}-$type';
    if (dateKey == key) {
      return record;
    }
  }
  return null;
}
