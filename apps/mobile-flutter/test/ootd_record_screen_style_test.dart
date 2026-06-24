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
    String? outfitPhotoStorageKey,
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
  Future<void> deleteRecord(String id) async {}

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
  Future<List<CrewOotdAppearance>> fetchCrewOotdAppearances({
    required String groupId,
    required String planId,
    required DateTime date,
  }) async {
    return const [];
  }

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
  Future<OotdRecord> createRecord(OotdRecord record) async => record;

  @override
  Future<OotdRecord> createGroupRecord({
    required Object groupId,
    required OotdRecord record,
  }) async => record;

  @override
  Future<OotdRecord> updateRecord(String id, OotdRecord record) async => record;
}

void main() {
  testWidgets('OOTD record saves text-mode today-only style overrides', (
    tester,
  ) async {
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
      '아이보리 니트, 블랙 롱스커트, 버건디 숄더백, 로퍼',
    );
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('변경하기'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(const ValueKey('hairStyleOption-2')));
    await _tapVisible(tester, find.byKey(const ValueKey('hairColorOption-4')));
    await _tapVisible(tester, find.byKey(const ValueKey('eyeColorOption-2')));
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(const ValueKey('weather-sunny')));
    await _tapVisible(tester, find.byKey(const ValueKey('mood-excited')));
    await _tapVisible(tester, find.byKey(const ValueKey('rating-5')));
    await tester.tap(find.text('생성 요청하기'));
    await tester.pumpAndSettle();

    expect(savedRecord, isNotNull);
    expect(savedRecord!.character.hairStyleIndex, 2);
    expect(savedRecord!.character.hairColorIndex, 4);
    expect(savedRecord!.character.eyeColorIndex, 2);
    expect(savedRecord!.weather, 'sunny');
    expect(savedRecord!.mood, 'excited');
    expect(savedRecord!.brands['rating'], '5.0');
    expect(repository.lastOverrides?.hairStyleIndex, 2);
    expect(repository.lastOverrides?.hairColorIndex, 4);
    expect(repository.lastOverrides?.eyeColorIndex, 2);
  });

  testWidgets('daily OOTD completion returns to daily record flow', (
    tester,
  ) async {
    final repository = _FakeRecordRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [recordRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: _DailyOotdHost(
            onSave: (record) async => record.copyWith(id: 'record-1'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OOTD 열기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('텍스트 설명으로 생성'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('ootdDescriptionField')),
      '아이보리 니트, 블랙 롱스커트, 버건디 숄더백, 로퍼',
    );
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byKey(const ValueKey('weather-sunny')));
    await tester.tap(find.text('생성 요청하기'));
    await tester.pumpAndSettle();

    expect(find.text('일과 작성으로 돌아가기'), findsOneWidget);

    await tester.tap(find.text('일과 작성으로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.text('returned: record-1'), findsOneWidget);
  });
}

class _DailyOotdHost extends StatefulWidget {
  const _DailyOotdHost({required this.onSave});

  final Future<OotdRecord> Function(OotdRecord) onSave;

  @override
  State<_DailyOotdHost> createState() => _DailyOotdHostState();
}

class _DailyOotdHostState extends State<_DailyOotdHost> {
  String? returnedRecordId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('returned: ${returnedRecordId ?? 'none'}'),
            ElevatedButton(
              onPressed: () async {
                final record = await Navigator.of(context).push<OotdRecord>(
                  MaterialPageRoute(
                    builder: (context) => OotdRecordScreen(
                      userCharacter: const CharacterDraft(gender: 'female'),
                      recordDate: DateTime(2026, 10, 3),
                      isDailyRecord: true,
                      onSave: widget.onSave,
                    ),
                  ),
                );
                if (!mounted) return;
                setState(() => returnedRecordId = record?.id);
              },
              child: const Text('OOTD 열기'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
