import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/app/onmu_app.dart';
import 'package:onmu_mobile/core/routing/app_router.dart';
import 'package:onmu_mobile/core/routing/demo_route_seeds.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';

void main() {
  testWidgets('onmoim list keeps only the inline search field', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groups);
    await tester.pumpAndSettle();

    expect(find.byTooltip('온모임 검색'), findsNothing);
    expect(find.text('모임, 멤버, 약속 검색'), findsOneWidget);
  });

  testWidgets('friend search action appears only in memories and chat', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupDetail(DemoRouteSeeds.groupId));
    await tester.pumpAndSettle();

    expect(find.byTooltip('모임 검색'), findsNothing);

    appRouter.go(RoutePaths.groupMemories(DemoRouteSeeds.groupId));
    await tester.pumpAndSettle();

    expect(find.byTooltip('기록 검색'), findsOneWidget);

    appRouter.go(RoutePaths.groupChat(DemoRouteSeeds.groupId));
    await tester.pumpAndSettle();

    expect(find.byTooltip('채팅 검색'), findsOneWidget);
  });
}
