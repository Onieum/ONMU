import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/ootd/presentation/pages/daily_record_edit_screen.dart';
import 'package:onmu_mobile/features/ootd/presentation/pages/daily_record_screen.dart';
import 'package:onmu_mobile/features/ootd/presentation/pages/ootd_list_page.dart';
import 'package:onmu_mobile/features/ootd/presentation/pages/ootd_record_screen.dart';
import 'package:onmu_mobile/shared/models/character_model.dart';
import 'package:onmu_mobile/shared/models/ootd_model.dart';

import 'support/test_onmu_repositories.dart';

void main() {
  testWidgets('기록 캘린더 헤더는 월/진행률 아래에 제목을 2행으로 배치한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_recordApp(_listPage(records: const [])));

    final title = tester.widget<Text>(find.text('오늘의 코디 기록 다이어리'));
    final titleTop = tester.getTopLeft(find.text('오늘의 코디 기록 다이어리')).dy;
    final progressBottom = tester
        .getBottomLeft(find.byType(LinearProgressIndicator))
        .dy;

    expect(title.overflow, isNot(TextOverflow.ellipsis));
    expect(title.softWrap, isFalse);
    expect(titleTop, greaterThan(progressBottom + 6));
  });

  testWidgets('기록 캘린더는 좌우 드래그로 이전/다음 달을 전환한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final today = DateTime.now();
    final initialMonthLabel =
        '${today.year}. ${today.month.toString().padLeft(2, '0')}';
    final nextMonth = DateTime(today.year, today.month + 1, 1);
    final nextMonthLabel =
        '${nextMonth.year}. ${nextMonth.month.toString().padLeft(2, '0')}';

    await tester.pumpWidget(_recordApp(_listPage(records: const [])));

    expect(find.text(initialMonthLabel), findsOneWidget);

    await tester.drag(find.byType(GridView), const Offset(-360, 0));
    await tester.pumpAndSettle();

    expect(find.text(nextMonthLabel), findsOneWidget);

    await tester.drag(find.byType(GridView), const Offset(360, 0));
    await tester.pumpAndSettle();

    expect(find.text(initialMonthLabel), findsOneWidget);
  });

  testWidgets('OOTD만 있는 날짜에서 하루 일과 탭은 하루 일과 empty state를 보여준다', (tester) async {
    final date = DateTime.now();
    final ootdOnlyRecord = OotdRecord(
      id: 'record-ootd-only',
      date: DateTime(date.year, date.month, date.day, 12),
      character: _character,
      moodTags: const ['#OOTD'],
      brands: const {'recordType': 'ootd'},
      weather: 'sunny',
      mood: 'happy',
      timeline: const [
        TimelineItem(
          time: '12:00',
          placeName: '오늘의 착장',
          category: 'ootd',
          description: 'OOTD만 기록한 날짜',
        ),
      ],
    );

    await tester.pumpWidget(_recordApp(_listPage(records: [ootdOnlyRecord])));
    await tester.tap(find.text('${date.day}').first);
    await tester.pumpAndSettle();

    expect(find.text('아직 하루 일과 기록이 없어요'), findsOneWidget);
    expect(find.text('하루 일과 기록하기'), findsOneWidget);
  });

  testWidgets('하루 일과 사진 코멘트는 25자 제한과 정리된 안내 문구를 사용한다', (tester) async {
    await tester.pumpWidget(_recordApp(_dailyRecordScreen()));
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    final commentField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText?.contains('사진') == true,
      ),
    );

    expect(commentField.maxLength, 25);
    expect(commentField.maxLengthEnforcement, MaxLengthEnforcement.enforced);
    expect(commentField.decoration?.hintText, '사진에 대한 코멘트');
  });

  testWidgets('OOTD 사진 입력 안내는 전체 코디 1장 기준으로 표시한다', (tester) async {
    await tester.pumpWidget(_recordApp(_ootdRecordScreen()));
    await tester.tap(find.text('사진으로 생성'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('전체 코디 사진 1장 선택하기'), findsOneWidget);
    expect(
      find.textContaining('상의, 하의, 신발, 가방 같은 주요 아이템이 한 장에 보이도록'),
      findsOneWidget,
    );
    expect(find.textContaining('최대 10장'), findsNothing);
  });

  testWidgets('하루 일과 편집 사진 코멘트는 25자 제한을 유지한다', (tester) async {
    await tester.pumpWidget(
      onmuTestProviderScope(
        recordRepository: TestRecordRepository(records: [_editableDailyRecord]),
        child: _recordApp(
          const DailyRecordEditScreen(memoryId: 'record-edit-daily'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final commentField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == '사진 코멘트 수정',
      ),
    );

    expect(commentField.maxLength, 25);
    expect(commentField.maxLengthEnforcement, MaxLengthEnforcement.enforced);
    expect(commentField.decoration?.counterText, isNull);
  });
}

const _character = CharacterDraft(nickname: '나');

Widget _recordApp(Widget child) {
  return MaterialApp(theme: AppTheme.lightTheme, home: child);
}

OotdListPage _listPage({required List<OotdRecord> records}) {
  return OotdListPage(
    userCharacter: _character,
    customRecords: records,
    onAddOotd: (_, _) {},
    onAddDailyRecord: (_, _) {},
    onViewOotdDetail: (_) {},
    onEditRecord: (_) async => null,
    onDeleteRecord: (_) async {},
    onSaveRecordImage:
        ({required record, required bytes, required fileName}) async => record,
    onNavigateToProfile: () {},
  );
}

DailyRecordScreen _dailyRecordScreen() {
  return DailyRecordScreen(
    userCharacter: _character,
    recordDate: DateTime(2026, 6, 17),
    onSave: (record) async => record,
    onUploadMedia: (Uint8List bytes, String fileName) async => UploadedMedia(
      storageKey: 'records/media/$fileName',
      publicUrl: 'https://cdn.onmu.test/$fileName',
    ),
    onCreateOotd: () async => null,
  );
}

OotdRecordScreen _ootdRecordScreen() {
  return OotdRecordScreen(
    userCharacter: _character,
    recordDate: DateTime(2026, 6, 17),
    onSave: (record) async => record,
  );
}

final _editableDailyRecord = OotdRecord(
  id: 'record-edit-daily',
  date: DateTime(2026, 6, 17, 10),
  character: _character,
  moodTags: const ['#하루기록'],
  brands: const {'recordType': 'daily', 'theme': 'diary'},
  weather: 'sunny',
  mood: 'happy',
  imageUrls: const ['https://cdn.onmu.test/photo-1.jpg'],
  timeline: const [
    TimelineItem(
      time: '메모',
      placeName: '하루 일과',
      category: 'daily',
      description: '오늘의 하루 일과',
    ),
    TimelineItem(
      time: '사진 1',
      placeName: '추가한 사진',
      category: 'photo',
      description: '사진 코멘트',
      imageUrl: 'https://cdn.onmu.test/photo-1.jpg',
    ),
  ],
);
