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

  test('createAvatarGeneration posts character profile overrides', () async {
    final requestBodies = <Map<String, dynamic>>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestBodies.add(Map<String, dynamic>.from(options.data as Map));
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'jobId': 'ootd_job_test',
                'recordId': 'record-test',
                'status': 'QUEUED',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiRecordRepository(OnmuApiClient(dio));

    await repository.createAvatarGeneration(
      recordId: 'record-test',
      inputType: 'TEXT_PROMPT',
      weather: 'rainy',
      mood: 'tired',
      outfitDescription: 'black hoodie and jeans',
      characterOverrides: const CharacterDraft(
        gender: 'male',
        skinToneIndex: 2,
        hairStyleIndex: 3,
        hairColorIndex: 4,
        eyeShapeIndex: 1,
        eyeColorIndex: 5,
      ),
    );

    final overrides =
        requestBodies.single['characterOverrides'] as Map<String, dynamic>;
    expect(overrides['gender'], 'male');
    expect(overrides['skinTone'], 'skin_2');
    expect(overrides['hairStyle'], 'hair_style_3');
    expect(overrides['hairColor'], 'hair_color_4');
    expect(overrides['eyeStyle'], 'eye_style_1');
    expect(overrides['eyeColor'], 'eye_color_5');
  });

  test('fetchCrewOotdAppearances preserves character gender', () async {
    final requestedPaths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: [
                {
                  'userId': 'usr-minsu',
                  'nickname': '민수',
                  'source': 'PROFILE_CHARACTER',
                  'character': {
                    'gender': 'male',
                    'skin_tone': 'skin_2',
                    'hair_style': 'hair_style_2',
                    'hair_color': 'hair_color_1',
                    'eye_style': 'eye_style_1',
                    'eye_color': 'eye_color_1',
                    'clothes': 'top_1',
                  },
                },
              ],
            ),
          );
        },
      ),
    );
    final repository = ApiRecordRepository(OnmuApiClient(dio));

    final appearances = await repository.fetchCrewOotdAppearances(
      groupId: '1',
      planId: '101',
      date: DateTime(2026, 6, 25),
    );

    expect(
      requestedPaths.single,
      '/api/v1/groups/1/plans/101/crew-ootd-appearances?date=2026-06-25',
    );
    expect(appearances.single.character?.gender, 'male');
    expect(appearances.single.character?.hairStyleIndex, 2);
    expect(appearances.single.character?.hairColorIndex, 1);
  });
}
