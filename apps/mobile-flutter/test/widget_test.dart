import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/app/onmu_app.dart';

void main() {
  testWidgets('renders ONMU prototype shell', (tester) async {
    await tester.pumpWidget(const OnmuApp());

    expect(find.text('약속'), findsWidgets);
    expect(find.text('장소 플로우로 이어지는 약속 목록 화면입니다.'), findsOneWidget);
    expect(find.text('장소 후보 보기'), findsOneWidget);
  });
}
