import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/app/onmu_app.dart';
import 'package:onmu_mobile/core/routing/app_router.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';
import 'package:onmu_mobile/core/theme/app_colors.dart';

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

    await tester.tap(find.text('스킵하고 기본 캐릭터로 시작하기 ➔'));
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
}
