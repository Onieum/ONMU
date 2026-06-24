import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/core/error/onmu_exception.dart';
import 'package:onmu_mobile/features/ootd/repository/record_repository.dart';
import 'package:onmu_mobile/shared/models/character_model.dart';
import 'package:onmu_mobile/shared/models/ootd_model.dart';

void main() {
  test('uploadMedia reports missing storageKey as contract mismatch', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {'publicUrl': '/api/v1/media/public?key=photo.jpg'},
            ),
          );
        },
      ),
    );
    final repository = ApiRecordRepository(OnmuApiClient(dio));

    await expectLater(
      repository.uploadMedia(Uint8List.fromList([1, 2, 3]), 'photo.jpg'),
      throwsA(
        isA<OnmuContractException>()
            .having(
              (error) => error.kind,
              'kind',
              OnmuErrorKind.contractMismatch,
            )
            .having((error) => error.reportable, 'reportable', isTrue),
      ),
    );
  });

  test(
    'createGroupRecord posts a calendar record to group memories endpoint',
    () async {
      final requestedPaths = <String>[];
      final requestBodies = <Map<String, dynamic>>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            requestBodies.add(Map<String, dynamic>.from(options.data as Map));
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'publicId': 'memory-shared-1',
                  'type': 'DAILY',
                  'title': 'Daily record 2026-06-24',
                  'memo': '오늘 모임 기록',
                  'date': '2026-06-24',
                  'visibility': 'GROUP_ONLY',
                  'tags': ['#하루기록'],
                  'imageUrls': <String>[],
                  'payload': {
                    'brands': {'recordType': 'daily'},
                    'timeline': <Object>[],
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = ApiRecordRepository(OnmuApiClient(dio));
      final record = OotdRecord(
        date: DateTime(2026, 6, 24),
        character: const CharacterDraft(),
        moodTags: const ['#하루기록'],
        brands: const {'recordType': 'daily'},
        timeline: const [
          TimelineItem(
            time: '메모',
            placeName: '하루 일과',
            category: 'daily',
            description: '오늘 모임 기록',
          ),
        ],
      );

      final saved = await repository.createGroupRecord(
        groupId: '1',
        record: record,
      );

      expect(requestedPaths.single, '/api/v1/groups/1/memories');
      expect(requestBodies.single['visibility'], 'GROUP_ONLY');
      expect(requestBodies.single['type'], 'DAILY');
      expect(saved.id, 'memory-shared-1');
    },
  );
}
