import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/app/onmu_app.dart';
import 'package:onmu_mobile/core/routing/app_router.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';

import 'support/test_onmu_repositories.dart';

const _groupId = 1;

Widget _testOnmuApp() {
  return onmuTestProviderScope(child: const OnmuMaterialApp());
}

void main() {
  testWidgets('group list keeps only the inline search field', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groups);
    await tester.pumpAndSettle();

    expect(find.byTooltip('온모임 검색'), findsNothing);
    expect(find.text('모임, 멤버, 약속 검색'), findsOneWidget);
  });

  testWidgets(
    'group quick actions expose chat from memories and search in chat',
    (tester) async {
      await tester.pumpWidget(_testOnmuApp());
      await tester.pumpAndSettle(const Duration(milliseconds: 5000));

      appRouter.go(RoutePaths.groupDetail(_groupId));
      await tester.pumpAndSettle();

      expect(find.byTooltip('모임 검색'), findsNothing);

      appRouter.go(RoutePaths.groupMemories(_groupId));
      await tester.pumpAndSettle();

      expect(find.byTooltip('기록 검색'), findsNothing);
      expect(find.byTooltip('채팅'), findsOneWidget);

      appRouter.go(RoutePaths.groupChat(_groupId));
      await tester.pumpAndSettle();

      expect(find.byTooltip('채팅 검색'), findsOneWidget);
    },
  );
}
