import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/shared/widgets/onmu_date_time_picker.dart';
import 'package:onmu_mobile/shared/widgets/onmu_date_time_range_picker.dart';

void main() {
  testWidgets('단일 날짜와 시간 선택은 ONMU 캘린더와 슬라이딩 시간 선택을 사용한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    OnmuDateTimePicker.show(
                      context: context,
                      initialDateTime: DateTime(2026, 6, 12, 14),
                    );
                  },
                  child: const Text('단일 열기'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('단일 열기'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsNothing);
    expect(find.text('2026년 6월'), findsOneWidget);
    expect(find.text('시간 선택'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    expect(find.byType(OnmuSlidingTimePicker), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsWidgets);
    expect(find.text('시간을 위아래로 밀어서 조정'), findsOneWidget);
    expect(find.byType(OnmuTimeChipPicker), findsNothing);
  });

  testWidgets('범위 선택 시트는 시작/종료 날짜와 시간을 접은 상태로 먼저 보여준다', (tester) async {
    await _pumpRangePicker(tester);
    await _openRangePicker(tester);

    expect(find.byType(CupertinoDatePicker), findsNothing);
    expect(find.text('2026년 6월'), findsNothing);
    expect(find.text('추천 시간대 또는 직접 시간을 터치해서 선택'), findsNothing);

    expect(find.text('시작 날짜'), findsOneWidget);
    expect(find.text('종료 날짜'), findsOneWidget);
    expect(find.text('6월 15일 (월)'), findsOneWidget);
    expect(find.text('6월 20일 (토)'), findsOneWidget);

    expect(find.text('14:00'), findsWidgets);
    expect(find.text('16:00'), findsWidgets);
    expect(find.byType(OnmuSlidingTimePicker), findsNothing);
    expect(find.byType(OnmuTimeChipPicker), findsNothing);
    expect(find.byType(CupertinoDatePicker), findsNothing);
  });

  testWidgets('시작 날짜 필드만 열면 캘린더와 시작 시간 선택만 함께 보여준다', (tester) async {
    final picked = <OnmuDateTimeRange>[];

    await _pumpRangePicker(tester, onPicked: picked.add);
    await _openRangePicker(tester);

    await tester.tap(find.text('시작 날짜'));
    await tester.pumpAndSettle();

    expect(find.text('2026년 6월'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
    expect(find.byType(OnmuSlidingTimePicker), findsOneWidget);
    expect(find.text('시작 시간'), findsOneWidget);
    expect(find.text('종료 시간'), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(find.byType(ListWheelScrollView), findsNWidgets(2));

    await tester.tap(_calendarDay('16'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('start-time-slider-hour')),
      find.byType(Scrollable).last,
      const Offset(0, -120),
    );
    await tester.drag(
      find.byKey(const ValueKey('start-time-slider-hour')),
      const Offset(0, -58),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    expect(picked, hasLength(1));
    expect(picked.single.start, DateTime(2026, 6, 16, 15));
    expect(picked.single.end, DateTime(2026, 6, 20, 17));
  });

  testWidgets('종료 날짜 필드만 열면 캘린더와 종료 시간 선택만 함께 보여준다', (tester) async {
    final picked = <OnmuDateTimeRange>[];

    await _pumpRangePicker(tester, onPicked: picked.add);
    await _openRangePicker(tester);

    await tester.tap(find.text('종료 날짜'));
    await tester.pumpAndSettle();

    expect(find.text('2026년 6월'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
    expect(find.byType(OnmuSlidingTimePicker), findsOneWidget);
    expect(find.text('시작 시간'), findsNothing);
    expect(find.text('종료 시간'), findsOneWidget);

    await tester.tap(_calendarDay('21'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    expect(picked, hasLength(1));
    expect(picked.single.start, DateTime(2026, 6, 15, 14));
    expect(picked.single.end, DateTime(2026, 6, 21, 16));
  });
}

Future<void> _pumpRangePicker(
  WidgetTester tester, {
  ValueChanged<OnmuDateTimeRange>? onPicked,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final picked = await OnmuDateTimeRangePicker.show(
                    context: context,
                    initialStart: DateTime(2026, 6, 15, 14),
                    initialEnd: DateTime(2026, 6, 20, 16),
                  );
                  if (picked != null) {
                    onPicked?.call(picked);
                  }
                },
                child: const Text('열기'),
              ),
            ),
          );
        },
      ),
    ),
  );
}

Future<void> _openRangePicker(WidgetTester tester) async {
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

Finder _calendarDay(String day) {
  return find.descendant(
    of: find.byType(OnmuCalendarDatePicker),
    matching: find.text(day),
  );
}
