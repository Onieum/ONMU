import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/app/onmu_app.dart';

void main() {
  testWidgets('starts with splash and opens preference intro', (tester) async {
    await tester.pumpWidget(const OnmuApp());

    expect(find.text('ONMU'), findsOneWidget);
    expect(find.text('약속을 잡고,'), findsOneWidget);
    expect(find.text('함께한 순간을 기록해요'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    expect(find.text('취향을 알려주세요'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('onboarding flows through preference, character, and home', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    for (final label in ['시작하기', '다음', '다음', '다음', '요약 보기']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    expect(find.text('취향 선택 완료'), findsOneWidget);
    expect(find.text('캐릭터 설정하기'), findsOneWidget);

    await tester.tap(find.text('캐릭터 설정하기'));
    await tester.pumpAndSettle();

    expect(find.text('캐릭터 만들기'), findsOneWidget);

    await tester.tap(find.text('건너뛰고 기본 캐릭터로 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요, 지우님'), findsOneWidget);
    expect(find.text('진행 중인 약속'), findsOneWidget);
    expect(find.text('홈'), findsWidgets);
    expect(find.text('약속'), findsNothing);
    expect(find.text('온모임'), findsWidgets);
    expect(find.text('기록'), findsWidgets);
    expect(find.text('마이'), findsWidgets);
  });
}
