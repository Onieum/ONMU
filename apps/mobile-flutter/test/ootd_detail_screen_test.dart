import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/ootd/presentation/pages/ootd_detail_screen.dart';
import 'package:onmu_mobile/shared/models/character_model.dart';
import 'package:onmu_mobile/shared/models/ootd_model.dart';

void main() {
  testWidgets('OOTD 상세는 특정 날짜/태그 전용 더미 레이아웃을 사용하지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: OotdDetailScreen(record: _seoulCafeRecord),
      ),
    );

    expect(find.text('2026.10.03 (토)'), findsOneWidget);
    expect(find.text('OOTD 기록'), findsOneWidget);
    expect(find.text('#서울카페투어'), findsOneWidget);
    expect(find.text('서울 카페 투어 ☕'), findsNothing);
    expect(find.text('지훈'), findsNothing);
  });
}

final _seoulCafeRecord = OotdRecord(
  id: 'record-seoul-cafe',
  date: DateTime(2026, 10, 3),
  character: const CharacterDraft(nickname: '나'),
  moodTags: const ['#서울카페투어', '#데이트'],
  brands: const {'상의': '아이보리 니트'},
  weather: 'sunny',
  mood: 'excited',
  timeline: const [
    TimelineItem(
      time: '13:00',
      placeName: '기록 기반 카페',
      category: 'cafe',
      description: '실제 기록에 저장된 장소입니다.',
    ),
  ],
);
