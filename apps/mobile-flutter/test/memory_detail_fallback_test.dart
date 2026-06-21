import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';
import 'package:onmu_mobile/features/group/view_model/group_memory_view_model.dart';
import 'package:onmu_mobile/features/memory/view_model/memory_detail_view_model.dart';
import 'package:onmu_mobile/features/ootd/repository/record_repository.dart';
import 'package:onmu_mobile/features/ootd/view_model/daily_record_edit_controller.dart';
import 'package:onmu_mobile/shared/models/character_model.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';
import 'package:onmu_mobile/shared/models/ootd_model.dart';

import 'support/in_memory_onmu_store.dart';
import 'support/test_onmu_repositories.dart';

void main() {
  test(
    'memory detail provider falls back to record list when detail is missing',
    () async {
      final container = ProviderContainer(
        overrides: [
          recordRepositoryProvider.overrideWithValue(
            _DetailMissingRecordRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final record = await container.read(
        memoryRecordProvider('record-hangang-picnic').future,
      );

      expect(record.id, 'record-hangang-picnic');
      expect(record.timeline.single.description, '돗자리 펴고 같이 남긴 기록');
    },
  );

  test(
    'daily record edit load falls back to record list when detail is missing',
    () async {
      final container = ProviderContainer(
        overrides: [
          recordRepositoryProvider.overrideWithValue(
            _DetailMissingRecordRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await container
          .read(dailyRecordEditControllerProvider)
          .load('record-hangang-picnic');

      expect(state.record.id, 'record-hangang-picnic');
      expect(state.memo, '돗자리 펴고 같이 남긴 기록');
    },
  );

  test(
    'group memory detail falls back to group memory list when detail is missing',
    () async {
      final store = InMemoryOnmuStore.seeded();
      final container = ProviderContainer(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            _DetailMissingGroupRepository(store),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        groupMemoryDetailViewModelProvider((
          groupId: '1',
          memoryId: '1001',
        )).future,
      );

      expect(state.memory.id, 1001);
      expect(state.memory.description, '분위기 좋은 카페 발견! 디저트도 너무 맛있었어요.');
    },
  );
}

class _DetailMissingRecordRepository implements RecordRepository {
  _DetailMissingRecordRepository()
    : _records = List.of(TestRecordRepository.defaultRecords);

  final List<OotdRecord> _records;

  @override
  Future<List<OotdRecord>> fetchMyRecords() async =>
      List.unmodifiable(_records);

  @override
  Future<OotdRecord> fetchRecord(String id) {
    throw StateError('record detail missing');
  }

  @override
  Future<OotdRecord> createRecord(OotdRecord record) {
    throw UnimplementedError();
  }

  @override
  Future<OotdRecord> updateRecord(String id, OotdRecord record) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteRecord(String id) {
    throw UnimplementedError();
  }

  @override
  Future<UploadedMedia> uploadMedia(Uint8List bytes, String fileName) {
    throw UnimplementedError();
  }

  @override
  Future<OotdAvatarGenerationJob> createAvatarGeneration({
    required String recordId,
    required String inputType,
    String? outfitPhotoMediaId,
    String? outfitPhotoStorageKey,
    String? outfitDescription,
    CharacterDraft? characterOverrides,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<OotdAvatarGenerationJob> fetchAvatarGeneration(String jobId) {
    throw UnimplementedError();
  }
}

class _DetailMissingGroupRepository extends TestGroupRepository {
  _DetailMissingGroupRepository(super.store);

  @override
  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) {
    throw StateError('group memory detail missing');
  }
}
