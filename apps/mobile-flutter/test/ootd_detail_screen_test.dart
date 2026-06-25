import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/ootd/presentation/pages/ootd_detail_screen.dart';
import 'package:onmu_mobile/features/ootd/presentation/widgets/ootd_generated_image_view.dart';
import 'package:onmu_mobile/shared/models/character_model.dart';
import 'package:onmu_mobile/shared/models/ootd_model.dart';

void main() {
  testWidgets('OOTD detail renders scrapbook analysis sections', (tester) async {
    final record = OotdRecord(
      id: 'ootd-1',
      date: DateTime(2026, 10, 3),
      imagePath: '',
      character: const CharacterDraft(
        gender: 'female',
        skinToneIndex: 1,
        eyeShapeIndex: 1,
        eyeColorIndex: 2,
        hairColorIndex: 3,
        hairStyleIndex: 2,
      ),
      moodTags: const ['#카페투어', '#ootd'],
      weather: 'sunny',
      mood: 'excited',
      brands: const {
        'title': 'OOTD 기록',
        'todayLook': '베이지와 블랙 조합이 단정하면서도 포인트가 살아있는 룩이에요.',
        'hairNote': '오늘은 웨이브를 살짝 넣어서 분위기 있게 연출했어요.',
        'outfitInfoOuter': '베이지 하프코트',
        'outfitInfoTop': '아이보리 니트',
        'outfitInfoBottom': '블랙 롱 스커트',
        'outfitInfoBag': '버건디 숄더백',
        'outfitInfoShoes': '화이트 삭스 + 로퍼',
        'point': '가방으로 포인트 주기',
        'nextSuggestion': '다음엔 니트에 청바지 조합도 좋을 것 같아요.',
        'rating': '4.0',
        'generatedImageUrl': 'https://example.com/generated-ootd.png',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: OotdDetailScreen(record: record),
      ),
    );

    expect(find.text('OOTD 기록'), findsWidgets);
    expect(find.text("Today's Look"), findsOneWidget);
    expect(find.text('HAIR'), findsOneWidget);
    expect(find.text('OUTFIT INFO'), findsOneWidget);
    expect(find.text('POINT'), findsOneWidget);
    expect(find.text('오늘 코디는 어땠나요?'), findsOneWidget);
    expect(find.text('4.0'), findsOneWidget);
    expect(find.textContaining('베이지와 블랙'), findsOneWidget);
    expect(find.textContaining('청바지 조합'), findsOneWidget);

    final generatedImage = tester.widget<OotdGeneratedImageView>(
      find.byType(OotdGeneratedImageView),
    );
    expect(generatedImage.width, double.infinity);
    expect(generatedImage.height, greaterThan(300));
  });
}
