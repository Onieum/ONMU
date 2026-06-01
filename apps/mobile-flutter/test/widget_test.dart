import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/app/onmu_app.dart';

void main() {
  testWidgets('renders integrated mobile shell', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요, 지우님'), findsOneWidget);
    expect(find.text('진행 중인 약속'), findsOneWidget);
    expect(find.text('홈'), findsWidgets);
    expect(find.text('약속'), findsWidgets);
    expect(find.text('온챗'), findsWidgets);
    expect(find.text('기록'), findsWidgets);
    expect(find.text('마이'), findsWidgets);
  });

  testWidgets('기존 하단 마이 탭에서 마이페이지가 열린다', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();

    expect(find.text('김온무'), findsOneWidget);
    expect(find.text('프로필 수정'), findsOneWidget);
    expect(find.text('선호 키워드'), findsOneWidget);
    expect(find.text('좋아하는 장소'), findsOneWidget);
  });

  testWidgets('마이페이지 친구 탭에서 친구 추가를 할 수 있다', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('친구').first);
    await tester.pumpAndSettle();

    expect(find.text('최민준'), findsOneWidget);
    expect(find.text('이지수'), findsNothing);

    await tester.tap(find.text('친구 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '지수');
    await tester.pumpAndSettle();

    expect(find.text('이지수'), findsOneWidget);
    await tester.tap(find.text('추가하기'));
    await tester.pumpAndSettle();

    expect(find.text('이지수'), findsOneWidget);
    expect(find.text('추가하기'), findsNothing);
  });

  testWidgets('불가능한 날짜는 달력에서 여러 날짜를 선택할 수 있다', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();

    final unavailableSection = find.ancestor(
      of: find.text('불가능한 날짜'),
      matching: find.byType(Column),
    );
    await tester.tap(
      find.descendant(of: unavailableSection.first, matching: find.text('수정')),
    );
    await tester.pumpAndSettle();

    expect(find.text('불가능한 날짜 선택'), findsOneWidget);
    expect(find.text('6월 2026'), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.tap(find.text('22'));
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('6월 15일'), findsOneWidget);
    expect(find.text('6월 22일'), findsOneWidget);
  });

  testWidgets('가능 요일은 요일 버튼으로 여러 개 선택할 수 있다', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    final availableSection = find.ancestor(
      of: find.text('가능 요일'),
      matching: find.byType(Column),
    );
    await tester.tap(
      find.descendant(of: availableSection.first, matching: find.text('수정')),
    );
    await tester.pumpAndSettle();

    expect(find.text('가능 요일 선택'), findsOneWidget);
    await tester.tap(find.text('월'));
    await tester.tap(find.text('금'));
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('월'), findsOneWidget);
    expect(find.text('금'), findsOneWidget);
  });
}
