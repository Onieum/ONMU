import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/main.dart' as app;

void main() {
  testWidgets('starts with splash and opens login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: app.OnmuApp()));

    expect(find.text('ONMU'), findsOneWidget);
    expect(find.text('약속을 잡고,'), findsOneWidget);
    expect(find.text('함께한 순간을 기록해요'), findsOneWidget);

    await tester.tap(find.text('ONMU'));
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('구글로 시작하기'), findsOneWidget);
    expect(find.text('네이버로 시작하기'), findsOneWidget);
  });

  testWidgets('mock login opens onboarding and skip flow enters home', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: app.OnmuApp()));

    await tester.tap(find.text('ONMU'));
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    await tester.tap(find.text('네이버로 시작하기'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('기록 준비를 해볼까요?'), findsOneWidget);
    expect(find.text('캐릭터 만들기'), findsOneWidget);
    expect(find.text('취향 선택'), findsOneWidget);

    await tester.tap(find.text('나중에 할게요'));
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
