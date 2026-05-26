import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/main.dart';

void main() {
  testWidgets('renders ONMU prototype flow', (tester) async {
    await tester.pumpWidget(const OnmuApp());

    expect(find.text('ONMU'), findsOneWidget);
    expect(find.text('프로필 취향'), findsOneWidget);
    expect(find.text('약속 방'), findsOneWidget);
    expect(find.text('장소 후보'), findsOneWidget);
    expect(find.text('기록 카드'), findsOneWidget);
    expect(find.text('약속 만들기'), findsOneWidget);
  });
}
