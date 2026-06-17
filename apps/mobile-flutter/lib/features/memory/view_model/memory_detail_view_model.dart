import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/ootd_model.dart';
import '../../ootd/repository/record_repository.dart';

final memoryRecordProvider = FutureProvider.family<OotdRecord, String>((
  ref,
  memoryId,
) {
  return ref.watch(recordRepositoryProvider).fetchRecord(memoryId);
});

final memoryRecordListProvider = ootdRecordsProvider;
