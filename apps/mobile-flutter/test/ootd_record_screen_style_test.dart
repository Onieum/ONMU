import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/ootd/presentation/pages/ootd_record_screen.dart';
import 'package:onmu_mobile/features/ootd/repository/record_repository.dart';
import 'package:onmu_mobile/shared/models/character_model.dart';
import 'package:onmu_mobile/shared/models/ootd_model.dart';

class _FakeRecordRepository implements RecordRepository {
  CharacterDraft? lastOverrides;

  @override
  Future<OotdAvatarGenerationJob> createAvatarGeneration({
    required String recordId,
    required String inputType,
    String? outfitPhotoMediaId,
    String? outfitDescription,
    CharacterDraft? characterOverrides,
  }) async {
    lastOverrides = characterOverrides;
    return OotdAvatarGenerationJob(
      jobId: 'job-1',
      status: 'COMPLETED',
      recordId: recordId,
      generatedImageUrl: 'https://example.com/generated.webp',
    );
  }

  @override
  Future<OotdAvatarGenerationJob> fetchAvatarGeneration(String jobId) async {
    return OotdAvatarGenerationJob(
      jobId: jobId,
      status: 'COMPLETED',
      recordId: 'record-1',
      generatedImageUrl: 'https://example.com/generated.webp',
    );
  }

  @override
  Future<OotdRecord> createRecord(OotdRecord record) async => record;

  @override
  Future<void> deleteRecord(String id) async {}

  @override
  Future<List<OotdRecord>> fetchMyRecords() async => const [];

  @override
  Future<OotdRecord> fetchRecord(String id) async {
    throw StateError('not implemented');
  }

  @override
  Future<UploadedMedia> uploadMedia(Uint8List bytes, String fileName) async {
    return const UploadedMedia(
      storageKey: 'records/media/test.webp',
      publicUrl: 'https://example.com/test.webp',
    );
  }

  @override
  Future<OotdRecord> updateRecord(String id, OotdRecord record) async => record;
}

void main() {
  testWidgets(
    'OOTD record saves today-only style overrides and analysis fields',
    (tester) async {
      final repository = _FakeRecordRepository();
      OotdRecord? savedRecord;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [recordRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: OotdRecordScreen(
              userCharacter: const CharacterDraft(gender: 'female'),
              recordDate: DateTime(2026, 10, 3),
              onSave: (record) async {
                savedRecord = record.copyWith(id: 'record-1');
                return savedRecord!;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('텍스트 설명으로 생성'));
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('ootdDescriptionField')),
        '아이보리 니트, 블랙 롱 스커트, 버건디 숄더백, 로퍼',
      );
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('변경하기'));
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('hairStyleOption-2')),
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('hairColorOption-4')),
      );
      await _tapVisible(tester, find.byKey(const ValueKey('eyeColorOption-2')));
      await _tapVisible(tester, find.byKey(const ValueKey('weather-sunny')));
      await _tapVisible(tester, find.byKey(const ValueKey('mood-excited')));
      await _tapVisible(tester, find.byKey(const ValueKey('rating-5')));
      await tester.enterText(
        find.byKey(const ValueKey('pointField')),
        '가방으로 포인트 주기',
      );
      await tester.enterText(
        find.byKey(const ValueKey('nextSuggestionField')),
        '다음엔 청바지랑 입어보기',
      );

      await tester.tap(find.text('생성 요청하기'));
      await tester.pumpAndSettle();

      expect(savedRecord, isNotNull);
      expect(savedRecord!.character.hairStyleIndex, 2);
      expect(savedRecord!.character.hairColorIndex, 4);
      expect(savedRecord!.character.eyeColorIndex, 2);
      expect(savedRecord!.weather, 'sunny');
      expect(savedRecord!.mood, 'excited');
      expect(savedRecord!.brands['rating'], '5.0');
      expect(savedRecord!.brands['point'], '가방으로 포인트 주기');
      expect(savedRecord!.brands['nextSuggestion'], '다음엔 청바지랑 입어보기');
      expect(repository.lastOverrides?.hairStyleIndex, 2);
      expect(repository.lastOverrides?.hairColorIndex, 4);
      expect(repository.lastOverrides?.eyeColorIndex, 2);
    },
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
