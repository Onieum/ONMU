import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/main.dart';

void main() {
  testWidgets('renders ONMU prototype flow', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OnmuApp(),
      ),
    );

    // Verify splash page renders initially
    expect(find.text('ONMU'), findsOneWidget);
    expect(find.text('오늘의 코디와 일상을 픽셀로 기록해요'), findsOneWidget);

    // Advance time to let the splash timeout timer complete cleanly
    await tester.pumpAndSettle(const Duration(milliseconds: 1500));
  });
}

