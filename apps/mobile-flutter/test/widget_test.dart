import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/app/onmu_app.dart';
import 'package:onmu_mobile/core/theme/app_colors.dart';
import 'package:onmu_mobile/core/theme/app_spacing.dart';
import 'package:onmu_mobile/shared/widgets/onmu_chip.dart';

void main() {
  testWidgets('약속 생성부터 상세와 완료까지 이어진다', (tester) async {
    tester.view.physicalSize = const Size(371, 797);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요, 지우님'), findsOneWidget);
    expect(find.text('진행 중인 약속'), findsOneWidget);
    expect(find.text('약속 만들기'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '약속 만들기'), findsNothing);
    expect(find.widgetWithText(FloatingActionButton, '약속 만들기'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, '약속 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('참여자 선택'), findsOneWidget);
    expect(find.text('누구와 함께할까요?'), findsOneWidget);
    expect(find.text('선택된 참여자 3/10'), findsOneWidget);
    expect(find.text('친구'), findsNothing);
    expect(find.text('그룹'), findsNothing);
    expect(find.text('최근 연락'), findsNothing);
    expect(find.text('카페 투어 좋아해요'), findsNothing);
    expect(find.text('이번엔 내가 추천할게!'), findsNothing);
    expect(find.text('방문지 제안'), findsNothing);
    expect(find.text('시간 제안'), findsNothing);
    expect(find.text('선택됨'), findsNothing);
    final minsuBadge = find.widgetWithText(OnmuChip, '민수');
    expect(minsuBadge, findsOneWidget);

    await tester.tap(
      find.descendant(of: minsuBadge, matching: find.byIcon(Icons.close)),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OnmuChip, '민수'), findsNothing);
    expect(find.text('선택된 참여자 2/10'), findsOneWidget);
    final minsuToggle = find.byKey(const ValueKey('member-toggle-민수'));
    expect(
      find.descendant(of: minsuToggle, matching: find.text('선택')),
      findsOneWidget,
    );

    await tester.ensureVisible(minsuToggle);
    await tester.pumpAndSettle();
    await tester.tap(minsuToggle);
    await tester.pumpAndSettle();
    await _dragUntilFound(
      tester,
      find.widgetWithText(OnmuChip, '민수'),
      const Offset(0, 480),
    );

    expect(find.widgetWithText(OnmuChip, '민수'), findsOneWidget);
    expect(find.text('선택된 참여자 3/10'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.circle_outlined), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '선택'), findsAtLeastNWidgets(1));
    expect(
      find.widgetWithText(OutlinedButton, '선택해제'),
      findsAtLeastNWidgets(1),
    );
    expect(_buttonBackgroundColor(tester, '선택해제'), AppColors.primaryPurple);
    expect(_buttonForegroundColor(tester, '선택해제'), AppColors.textInverse);

    await tester.tap(find.text('약속 이름 입력'));
    await tester.pumpAndSettle();

    expect(find.text('약속 이름을 정해주세요'), findsOneWidget);
    expect(find.text('예: 주말 나들이'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '주말 나들이');
    await tester.pumpAndSettle();
    expect(find.text('주말 나들이'), findsOneWidget);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect(find.text('참여자 선택'), findsOneWidget);

    await tester.tap(find.text('다음 단계로'));
    await tester.pumpAndSettle();

    expect(find.text('날짜/시간 선택'), findsOneWidget);
    expect(find.text('약속 시간 추천'), findsOneWidget);
    expect(find.text('5월 26일 (일) · 오후 1:00 ~ 3:00'), findsOneWidget);
    expect(find.text('약속 상세로'), findsNothing);
    expect(_chipIconColor(tester, '가능한 시간'), AppColors.accentGreen);
    expect(_chipIconColor(tester, '일부만 가능'), AppColors.accentOrange);
    expect(_chipIconColor(tester, '보통 어려워요'), AppColors.accentRed);

    await tester.ensureVisible(find.byKey(const ValueKey('date-pill-27')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-pill-27')));
    await tester.pumpAndSettle();
    expect(find.text('5월 27일 (월) · 오후 1:00 ~ 3:00'), findsOneWidget);

    await _dragUntilFound(
      tester,
      find.byKey(const ValueKey('time-filter-partial')),
      const Offset(0, 480),
    );
    await tester.tap(find.byKey(const ValueKey('time-filter-partial')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -640));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('time-candidate-12:00')), findsNothing);
    expect(find.byKey(const ValueKey('time-candidate-13:00')), findsNothing);
    expect(find.byKey(const ValueKey('time-candidate-15:00')), findsOneWidget);
    expect(find.byKey(const ValueKey('time-candidate-18:00')), findsNothing);
    expect(
      _iconColorByKey(tester, 'time-status-icon-15:00'),
      AppColors.accentOrange,
    );
    expect(_textColorByKey(tester, 'time-count-15:00'), AppColors.accentOrange);
    expect(
      _horizontalGap(
        tester,
        find.text('2명의 친구가 일정이 있어요.'),
        find.byKey(const ValueKey('time-count-15:00')),
      ),
      greaterThanOrEqualTo(AppSpacing.sm),
    );

    await tester.tap(find.byKey(const ValueKey('time-candidate-15:00')));
    await tester.pumpAndSettle();
    expect(find.text('5월 27일 (월) · 오후 3:00 ~ 5:00'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).last, const Offset(0, 640));
    await tester.pumpAndSettle();
    await _dragUntilFound(
      tester,
      find.byKey(const ValueKey('time-filter-difficult')),
      const Offset(0, 480),
    );
    await tester.tap(find.byKey(const ValueKey('time-filter-difficult')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -640));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('time-candidate-18:00')), findsOneWidget);
    expect(
      _iconColorByKey(tester, 'time-status-icon-18:00'),
      AppColors.accentRed,
    );
    expect(_textColorByKey(tester, 'time-count-18:00'), AppColors.accentRed);

    expect(find.widgetWithText(TextButton, '장소 선택'), findsNothing);
    expect(find.widgetWithText(FilledButton, '장소 선택'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '장소 선택'));
    await tester.pumpAndSettle();

    expect(find.text('장소 선택'), findsOneWidget);
    expect(find.text('시간까지 정해졌어요'), findsOneWidget);

    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    expect(find.text('약속 상세'), findsOneWidget);
    expect(find.text('주말 나들이'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('방문 일정'), findsOneWidget);

    await tester.tap(find.text('동선 확인'));
    await tester.pumpAndSettle();

    expect(find.text('방문 동선을 확인해요'), findsOneWidget);
    expect(find.text('총 예상 시간'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '약속 완료'));
    await tester.pumpAndSettle();

    expect(find.text('약속 만들기 완료!'), findsOneWidget);
    expect(find.text('공유하기'), findsOneWidget);
  });
}

Color? _chipIconColor(WidgetTester tester, String label) {
  final chipFinder = find.widgetWithText(OnmuChip, label);
  final iconFinder = find.descendant(
    of: chipFinder,
    matching: find.byIcon(Icons.circle),
  );

  return tester.widget<Icon>(iconFinder).color;
}

Color? _iconColorByKey(WidgetTester tester, String key) {
  return tester.widget<Icon>(find.byKey(ValueKey(key))).color;
}

Color? _textColorByKey(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(ValueKey(key))).style?.color;
}

Color? _buttonBackgroundColor(WidgetTester tester, String label) {
  final button = tester.widget<OutlinedButton>(
    find.widgetWithText(OutlinedButton, label).first,
  );

  return button.style?.backgroundColor?.resolve(<WidgetState>{});
}

Color? _buttonForegroundColor(WidgetTester tester, String label) {
  final button = tester.widget<OutlinedButton>(
    find.widgetWithText(OutlinedButton, label).first,
  );

  return button.style?.foregroundColor?.resolve(<WidgetState>{});
}

double _horizontalGap(WidgetTester tester, Finder left, Finder right) {
  return tester.getRect(right).left - tester.getRect(left).right;
}

Future<void> _dragUntilFound(
  WidgetTester tester,
  Finder finder,
  Offset offset,
) async {
  for (var index = 0; index < 8 && finder.evaluate().isEmpty; index += 1) {
    await tester.drag(find.byType(Scrollable).last, offset);
    await tester.pumpAndSettle();
  }

  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}
