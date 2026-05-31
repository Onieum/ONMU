import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/app/onmu_app.dart';

void main() {
  testWidgets('renders place and onchat prototype flows', (tester) async {
    await tester.pumpWidget(const OnmuApp());

    expect(find.text('약속'), findsWidgets);
    expect(find.text('장소 플로우로 이어지는 약속 목록 화면입니다.'), findsOneWidget);
    expect(find.text('장소 후보 보기'), findsOneWidget);

    await tester.tap(find.text('장소 후보 보기'));
    await tester.pumpAndSettle();

    expect(find.text('장소 후보'), findsWidgets);
    expect(find.text('카페 문라이트'), findsOneWidget);

    await tester.tap(find.text('온챗'));
    await tester.pumpAndSettle();

    expect(find.text('성수 토요일 멤버'), findsOneWidget);
    expect(find.text('친구들이 남긴 새 메모'), findsOneWidget);
  });
}
