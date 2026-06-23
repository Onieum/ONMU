import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/shared/models/preference_profile.dart';
import 'package:onmu_mobile/shared/widgets/onmu_card.dart';
import 'package:onmu_mobile/shared/widgets/onmu_date_time_picker.dart';
import 'package:onmu_mobile/shared/widgets/onmu_date_time_range_picker.dart';

void main() {
  testWidgets('단일 날짜와 시간 선택은 ONMU 캘린더와 슬라이딩 시간 선택을 사용한다', (tester) async {
    final initialDateTime = DateTime.now().add(const Duration(days: 2));

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
                      initialDateTime: DateTime(
                        initialDateTime.year,
                        initialDateTime.month,
                        initialDateTime.day,
                        14,
                      ),
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
    expect(
      find.text('${initialDateTime.year}년 ${initialDateTime.month}월'),
      findsOneWidget,
    );
    expect(find.text('시간 선택'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    expect(find.byType(OnmuSlidingTimePicker), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsWidgets);
    expect(find.text('시간을 위아래로 밀어서 조정'), findsOneWidget);
    expect(find.byType(OnmuTimeChipPicker), findsNothing);
  });

  testWidgets('슬라이딩 시간 선택은 주어진 시간 범위 밖의 wheel 값을 보여주지 않는다', (tester) async {
    var selected = DateTime(2026, 6, 19, 14);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: OnmuSlidingTimePicker(
                title: '방문 시작 시간',
                selectedDateTime: selected,
                minimumDateTime: DateTime(2026, 6, 19, 14),
                maximumDateTime: DateTime(2026, 6, 19, 16),
                sliderKey: const ValueKey('bounded-visit-time'),
                onChanged: (value) => setState(() => selected = value),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('04'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('bounded-visit-time-hour')),
      const Offset(0, 460),
    );
    await tester.pumpAndSettle();

    expect(find.text('04'), findsNothing);
    expect(selected.hour, greaterThanOrEqualTo(14));
    expect(selected.hour, lessThanOrEqualTo(16));
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
    await _pumpRangePicker(tester);
    await _openRangePicker(tester);

    await tester.tap(find.text('시작 날짜'));
    await tester.pumpAndSettle();

    expect(find.text('2026년 6월'), findsOneWidget);
    expect(_calendarStarIcons(), findsNothing);
    expect(find.byType(OnmuSlidingTimePicker), findsOneWidget);
    expect(find.text('시작 시간'), findsOneWidget);
    expect(find.text('종료 시간'), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(find.byType(ListWheelScrollView), findsNWidgets(2));
  });

  testWidgets('종료 날짜 필드만 열면 캘린더와 종료 시간 선택만 함께 보여준다', (tester) async {
    final picked = <OnmuDateTimeRange>[];

    await _pumpRangePicker(tester, onPicked: picked.add);
    await _openRangePicker(tester);

    await tester.tap(find.text('종료 날짜'));
    await tester.pumpAndSettle();

    expect(find.text('2026년 6월'), findsOneWidget);
    expect(_calendarStarIcons(), findsNothing);
    expect(find.byType(OnmuSlidingTimePicker), findsOneWidget);
    expect(find.text('시작 시간'), findsNothing);
    expect(find.text('종료 시간'), findsOneWidget);

    await tester.tap(_calendarDay('21'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    expect(picked, hasLength(1));
    _expectLocalDateTime(
      picked.single.start,
      year: 2026,
      month: 6,
      day: 15,
      hour: 14,
      minute: 0,
    );
    _expectLocalDateTime(
      picked.single.end,
      year: 2026,
      month: 6,
      day: 21,
      hour: 16,
      minute: 0,
    );
  });

  testWidgets('종료 시간을 직접 조정하면 추천 시간대 선택 상태가 해제되고 선택 결과에 반영된다', (tester) async {
    final picked = <OnmuDateTimeRange>[];

    await _pumpRangePicker(
      tester,
      onPicked: picked.add,
      initialEnd: DateTime(2026, 6, 15, 16),
    );
    await _openRangePicker(tester);

    final initialRecommendation = _recommendationCard(tester, '14:00 ~ 16:00');
    expect(initialRecommendation.backgroundColor, AppColors.bgPurpleSoft);

    await tester.tap(find.text('종료 날짜'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('end-time-slider-hour')),
      find.byType(Scrollable).last,
      const Offset(0, -120),
    );
    await tester.drag(
      find.byKey(const ValueKey('end-time-slider-hour')),
      const Offset(0, -58),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('end-time-slider-minute')),
      const Offset(0, -58),
    );
    await tester.pumpAndSettle();

    final changedRecommendation = _recommendationCard(tester, '14:00 ~ 16:00');
    expect(changedRecommendation.backgroundColor, AppColors.bgDefault);

    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    expect(picked, hasLength(1));
    _expectLocalDateTime(
      picked.single.start,
      year: 2026,
      month: 6,
      day: 15,
      hour: 14,
      minute: 0,
    );
    _expectLocalDateTime(
      picked.single.end,
      year: 2026,
      month: 6,
      day: 15,
      hour: 17,
      minute: 5,
    );
  });

  testWidgets('직접 시간을 조정한 뒤 추천 시간대를 선택해도 build 중 setState 예외가 나지 않는다', (
    tester,
  ) async {
    await _pumpRangePicker(tester);
    await _openRangePicker(tester);

    await tester.tap(find.text('시작 날짜'));
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

    await tester.dragUntilVisible(
      find.text('가장 많이 선택되는 시간대예요.'),
      find.byType(Scrollable).last,
      const Offset(0, -160),
    );
    await tester.tap(find.text('가장 많이 선택되는 시간대예요.'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('참여자 선호 시간이 겹치지 않으면 실제 데이터 기반 대안 상태와 선호/비선호 수를 보여준다', (
    tester,
  ) async {
    await _pumpRangePicker(
      tester,
      participantPreferences: [
        _participant(
          '박진희',
          PreferenceProfile.empty().copyWith(
            preferredWeekdays: ['월요일'],
            preferredTimes: ['점심'],
          ),
        ),
        _participant(
          '찬도치',
          PreferenceProfile.empty().copyWith(
            preferredWeekdays: ['월요일'],
            preferredTimes: ['오후'],
          ),
        ),
        _participant(
          '민수',
          PreferenceProfile.empty().copyWith(
            preferredWeekdays: ['월요일'],
            preferredTimes: ['점심'],
            unavailableDates: ['2026-06-15'],
          ),
        ),
      ],
    );
    await _openRangePicker(tester);

    expect(find.text('민수님이 불가능해요'), findsWidgets);
    expect(find.text('2명 선호'), findsWidgets);
    expect(find.textContaining('찬도치님 선호'), findsWidgets);
    expect(find.text('4명 추천'), findsNothing);
  });

  testWidgets('fallback recommendations use proposal label', (tester) async {
    await _pumpRangePicker(tester);
    await _openRangePicker(tester);

    expect(find.text('제안'), findsNWidgets(4));
    expect(find.text('일반 추천'), findsNothing);
  });

  testWidgets('recommended time cards avoid duplicated recommendation chip', (
    tester,
  ) async {
    await _pumpRangePicker(
      tester,
      initialStart: DateTime(2026, 6, 15, 14),
      initialEnd: DateTime(2026, 6, 15, 16),
      participantPreferences: [
        _participant(
          '찬도치',
          PreferenceProfile.empty().copyWith(
            preferredWeekdays: ['월요일'],
            preferredTimes: ['오후'],
          ),
        ),
      ],
    );
    await _openRangePicker(tester);

    expect(find.text('선택한 날짜의 추천 시간대'), findsOneWidget);
    expect(find.text('추천 시간대'), findsNothing);
    expect(find.textContaining('찬도치님 선호'), findsWidgets);
  });

  testWidgets('recommended dates are shown separately from time slots', (
    tester,
  ) async {
    final today = DateTime.now();
    final initialDate = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 2));
    final expectedRecommendedDate = _firstMatchingWeekday(initialDate, {
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    });

    await _pumpRangePicker(
      tester,
      initialStart: DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
        14,
      ),
      initialEnd: DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
        16,
      ),
      participantPreferences: [
        _participant(
          '박진희',
          PreferenceProfile.empty().copyWith(
            preferredWeekdays: ['금요일', '토요일', '일요일'],
            preferredTimes: ['점심'],
          ),
        ),
      ],
    );
    await _openRangePicker(tester);

    expect(find.text('추천 날짜'), findsOneWidget);
    expect(find.text('선택한 날짜의 추천 시간대'), findsOneWidget);
    expect(find.text('추천/비추천 시간대'), findsNothing);
    final expectedRecommendedDateKey =
        '${expectedRecommendedDate.year}-'
        '${expectedRecommendedDate.month.toString().padLeft(2, '0')}-'
        '${expectedRecommendedDate.day.toString().padLeft(2, '0')}';
    expect(
      find.byKey(ValueKey('recommended-date-$expectedRecommendedDateKey')),
      findsOneWidget,
    );
    expect(
      find.textContaining('${_expectedDateLabel(initialDate)}\n'),
      findsNothing,
    );
  });

  testWidgets(
    'recommended dates keep unavailable conflicts with participant names',
    (tester) async {
      final startDate = _firstMatchingWeekday(
        DateTime.now().add(const Duration(days: 1)),
        {DateTime.friday},
      );
      final conflictedSunday = startDate.add(const Duration(days: 2));

      await _pumpRangePicker(
        tester,
        initialStart: DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          14,
        ),
        initialEnd: DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          16,
        ),
        participantPreferences: [
          _participant(
            '박진희',
            PreferenceProfile.empty().copyWith(
              preferredWeekdays: ['금요일', '토요일', '일요일'],
              preferredTimes: ['점심'],
            ),
          ),
          _participant(
            '민수',
            PreferenceProfile.empty().copyWith(
              preferredWeekdays: ['일요일', '월요일'],
              unavailableDates: [
                '${conflictedSunday.year}-${conflictedSunday.month.toString().padLeft(2, '0')}-${conflictedSunday.day.toString().padLeft(2, '0')}',
              ],
            ),
          ),
        ],
      );
      await _openRangePicker(tester);

      expect(find.text(_expectedDateLabel(conflictedSunday)), findsOneWidget);
      expect(find.text('2명 선호'), findsWidgets);
      expect(find.text('민수님이 불가능해요'), findsWidgets);

      await tester.tap(find.text(_expectedDateLabel(conflictedSunday)));
      await tester.pumpAndSettle();

      expect(find.textContaining('박진희님 선호'), findsWidgets);
      expect(find.text('민수님이 불가능해요'), findsWidgets);
    },
  );

  testWidgets(
    'unavailable participant preferred times still appear with conflict reason',
    (tester) async {
      await _pumpRangePicker(
        tester,
        initialStart: DateTime(2026, 6, 27, 14),
        initialEnd: DateTime(2026, 6, 27, 16),
        participantPreferences: [
          _participant(
            '박진희',
            PreferenceProfile.empty().copyWith(
              preferredWeekdays: ['토요일'],
              preferredTimes: ['점심'],
              unavailableDates: ['2026-06-27'],
            ),
          ),
        ],
      );
      await _openRangePicker(tester);

      expect(find.text('12:00 ~ 14:00'), findsOneWidget);
      expect(find.text('박진희님 선호'), findsWidgets);
      expect(find.text('박진희님이 불가능해요'), findsWidgets);
      expect(find.text('점심부터 여유롭게 시작할 수 있어요.'), findsNothing);
    },
  );

  testWidgets('recommended date cards keep a stable height for long notices', (
    tester,
  ) async {
    await _pumpRangePicker(
      tester,
      initialStart: DateTime(2026, 6, 30, 14),
      initialEnd: DateTime(2026, 6, 30, 16),
      participantPreferences: [
        _participant(
          '아주긴이름의박진희',
          PreferenceProfile.empty().copyWith(
            preferredWeekdays: ['토요일'],
            preferredTimes: ['점심'],
            unavailableDates: ['2026-07-25'],
          ),
        ),
      ],
    );
    await _openRangePicker(tester);

    final conflictCard = tester.getSize(
      find.byKey(const ValueKey('recommended-date-2026-07-25')),
    );
    final normalCard = tester.getSize(
      find.byKey(const ValueKey('recommended-date-2026-07-04')),
    );

    expect(conflictCard.height, normalCard.height);
  });

  testWidgets(
    'multi-day range shows in-range recommendation dates as read-only visit days',
    (tester) async {
      final startDate = _firstMatchingWeekday(
        DateTime.now().add(const Duration(days: 1)),
        {DateTime.friday},
      );
      final middleDate = startDate.add(const Duration(days: 1));
      final endDate = startDate.add(const Duration(days: 2));
      final outsideDate = startDate.add(const Duration(days: 7));

      await _pumpRangePicker(
        tester,
        initialStart: DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          14,
        ),
        initialEnd: DateTime(endDate.year, endDate.month, endDate.day, 16),
        participantPreferences: [
          _participant(
            '박진희',
            PreferenceProfile.empty().copyWith(
              preferredWeekdays: ['금요일', '토요일', '일요일'],
              preferredTimes: ['점심'],
            ),
          ),
        ],
      );
      await _openRangePicker(tester);

      expect(find.text('추천 날짜'), findsNothing);
      expect(find.text('선택 범위의 추천 방문일'), findsOneWidget);
      expect(find.text('시작 날짜의 추천 시간대'), findsOneWidget);
      expect(find.text('선택한 날짜의 추천 시간대'), findsNothing);
      expect(find.text(_expectedDateLabel(startDate)), findsNWidgets(2));
      expect(find.text(_expectedDateLabel(middleDate)), findsOneWidget);
      expect(find.text(_expectedDateLabel(outsideDate)), findsNothing);

      await tester.tap(find.text(_expectedDateLabel(middleDate)));
      await tester.pumpAndSettle();

      expect(find.text(_expectedDateLabel(startDate)), findsNWidgets(2));
      expect(find.text(_expectedDateLabel(middleDate)), findsOneWidget);
    },
  );

  test('recommended dates come from participant weekday preference', () {
    final dates = onmuRecommendedDatesForRangePicker(
      anchor: DateTime(2026, 6, 19),
      participantPreferences: [
        _participant(
          '박진희',
          PreferenceProfile.empty().copyWith(
            preferredWeekdays: ['금요일'],
            preferredTimes: ['점심'],
          ),
        ),
        _participant(
          '민수',
          PreferenceProfile.empty().copyWith(
            preferredWeekdays: ['금요일'],
            preferredTimes: ['오후'],
            unavailableDates: ['2026-06-26'],
          ),
        ),
      ],
      dayCount: 8,
    );

    expect(dates.map((date) => date.day), contains(19));
    expect(dates.map((date) => date.day), isNot(contains(20)));
    expect(dates.map((date) => date.day), contains(26));
  });

  test('recommended dates accept preferredDays API alias', () {
    final profile = PreferenceProfile.fromJson({
      'preferredDays': ['SATURDAY', 'SUNDAY'],
      'preferredTimes': ['afternoon'],
    });

    final dates = onmuRecommendedDatesForRangePicker(
      anchor: DateTime(2026, 6, 19),
      participantPreferences: [_participant('찬도치', profile)],
    );

    expect(profile.preferredWeekdays, ['SATURDAY', 'SUNDAY']);
    expect(dates.map((date) => date.day), containsAll([20, 21]));
  });
}

Future<void> _pumpRangePicker(
  WidgetTester tester, {
  ValueChanged<OnmuDateTimeRange>? onPicked,
  List<ParticipantSchedulePreference> participantPreferences = const [],
  DateTime? initialStart,
  DateTime? initialEnd,
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
                    initialStart: initialStart ?? DateTime(2026, 6, 15, 14),
                    initialEnd: initialEnd ?? DateTime(2026, 6, 20, 16),
                    participantPreferences: participantPreferences,
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

Finder _calendarStarIcons() {
  return find.descendant(
    of: find.byType(OnmuCalendarDatePicker),
    matching: find.byIcon(Icons.star_rounded),
  );
}

OnmuCard _recommendationCard(WidgetTester tester, String timeText) {
  final cardFinder = find
      .ancestor(of: find.text(timeText), matching: find.byType(OnmuCard))
      .first;
  return tester.widget<OnmuCard>(cardFinder);
}

ParticipantSchedulePreference _participant(
  String name,
  PreferenceProfile preferenceProfile,
) {
  return ParticipantSchedulePreference(
    userId: name,
    name: name,
    preferenceProfile: preferenceProfile,
  );
}

void _expectLocalDateTime(
  DateTime actual, {
  required int year,
  required int month,
  required int day,
  required int hour,
  required int minute,
}) {
  final local = actual.toLocal();

  expect(local.year, year);
  expect(local.month, month);
  expect(local.day, day);
  expect(local.hour, hour);
  expect(local.minute, minute);
}

DateTime _firstMatchingWeekday(DateTime anchor, Set<int> weekdays) {
  final anchorDate = DateTime(anchor.year, anchor.month, anchor.day);
  for (var offset = 0; offset < 30; offset += 1) {
    final candidate = anchorDate.add(Duration(days: offset));
    if (weekdays.contains(candidate.weekday)) {
      return candidate;
    }
  }
  throw StateError('No matching weekday found within 30 days.');
}

String _expectedDateLabel(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]})';
}
