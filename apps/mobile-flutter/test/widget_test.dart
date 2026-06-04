import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:onmu_mobile/app/onmu_app.dart';
import 'package:onmu_mobile/core/routing/app_router.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/onmoim/presentation/pages/onmoim_memory_detail_page.dart';

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

    await tester.tap(find.text('홈으로 가기').last);
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요, 지우님'), findsOneWidget);
    expect(find.text('진행 중인 약속'), findsOneWidget);
    expect(find.text('홈'), findsWidgets);
    expect(find.text('약속'), findsNothing);
    expect(find.text('온모임'), findsWidgets);
    expect(find.text('기록'), findsWidgets);
    expect(find.text('마이'), findsWidgets);
  });

  testWidgets('legacy meetup creation route opens the unified create screen', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.onmoimMeetupNewMembers('friends'));
    await tester.pumpAndSettle();

    expect(find.text('약속 만들기'), findsWidgets);
    expect(find.text('약속 이름'), findsOneWidget);
    expect(find.text('참여 멤버'), findsOneWidget);
    expect(find.text('참여자 선택'), findsNothing);
  });

  testWidgets('confirmed meetup date tabs can be selected', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(
      '${RoutePaths.onmoimMeetupDetail('friends', 'demo')}?place=confirmed',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('6/8 일'));
    await tester.pumpAndSettle();

    final secondTabText = tester.widget<Text>(find.text('6/8 일'));

    expect(secondTabText.style?.color, AppColors.primaryPink);
  });

  testWidgets('place candidate date tabs can be selected', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.onmoimMeetupPlaces('friends', 'demo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('6/8 일'));
    await tester.pumpAndSettle();

    final secondTabText = tester.widget<Text>(find.text('6/8 일'));

    expect(secondTabText.style?.color, AppColors.primaryPink);
  });

  testWidgets('route review date tabs can be selected', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.onmoimMeetupRouteReview('friends', 'demo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('6/8 일'));
    await tester.pumpAndSettle();

    final secondTabText = tester.widget<Text>(find.text('6/8 일'));

    expect(secondTabText.style?.color, AppColors.primaryPink);
  });

  testWidgets('onmoim memory detail screen renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const OnMoimMemoryDetailPage(
          onmoimId: 'friends',
          memoryId: 'seongsu-cafe',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(find.text('분위기 좋은 카페 발견! 디저트도 너무 맛있었어요.'), findsOneWidget);
  });

  testWidgets('onmoim chat input sends a visible message', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.onmoimChat('friends'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '확인 메시지');
    await tester.tap(find.byTooltip('전송'));
    await tester.pumpAndSettle();

    expect(find.text('확인 메시지'), findsOneWidget);
  });
}
