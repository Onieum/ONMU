import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/ootd_model.dart';
import '../../ootd/repository/record_repository.dart';
import '../../ootd/view_model/record_lookup_service.dart';

final memoryRecordProvider = FutureProvider.family<OotdRecord, String>((
  ref,
  memoryId,
) {
  return ref.watch(recordLookupServiceProvider).fetchRecord(memoryId);
});

final memoryRecordListProvider = ootdRecordsProvider;
