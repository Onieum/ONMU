import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/my/domain/profile_schedule_dates.dart';

void main() {
  test('stores unavailable dates as ISO dates and hides past dates', () {
    final today = DateTime(2026, 6, 20);

    expect(
      formatUnavailableDateForStorage(DateTime(2026, 6, 19)),
      '2026-06-19',
    );
    expect(
      visibleUnavailableDates(const [
        '2026-06-19',
        '2026-06-20',
        '2026-06-26',
      ], now: today),
      const ['2026-06-20', '2026-06-26'],
    );
  });

  test('formats ISO unavailable dates for profile display', () {
    expect(formatUnavailableDateForDisplay('2026-06-19'), '6/19 (금)');
    expect(formatUnavailableDateForDisplay('6/26 (금)'), '6/26 (금)');
  });
}
