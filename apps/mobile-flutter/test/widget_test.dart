import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/launch/start_page.dart';
import 'package:onmu_mobile/main.dart';

void main() {
  testWidgets('starts with splash and moves to start page', (tester) async {
    await tester.pumpWidget(const OnmuApp());

    expect(find.text('ONMU'), findsOneWidget);
    expect(find.text('오늘의 취향을 불러오는 중'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(milliseconds: 950));

    expect(find.byType(StartPage), findsOneWidget);
    expect(find.text('취향 입력 시작하기'), findsOneWidget);
  });

  testWidgets('preference flow reaches summary and home', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartPage()));

    await tester.tap(find.text('취향 입력 시작하기'));
    await tester.pumpAndSettle();

    for (final label in ['시작하기', '다음', '다음', '다음', '다음', '요약 보기']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    expect(find.text('취향 입력이 끝났어요'), findsOneWidget);
    expect(find.text('선호 음식/메뉴'), findsOneWidget);
    expect(find.text('약속 스타일'), findsOneWidget);

    await tester.tap(find.text('홈으로 가기'));
    await tester.pumpAndSettle();

    expect(find.text('오늘 약속 추천을\n취향 기준으로 준비했어요'), findsOneWidget);
  });
}
