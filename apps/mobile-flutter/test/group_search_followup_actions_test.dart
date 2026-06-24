import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/app/onmu_app.dart';
import 'package:onmu_mobile/core/routing/app_router.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';
import 'package:onmu_mobile/shared/widgets/onmu_card.dart';

import 'support/test_onmu_repositories.dart';

Widget _testOnmuApp() {
  return onmuTestProviderScope(child: const OnmuMaterialApp());
}

Finder _planCardFinder(String title) {
  return find.ancestor(of: find.text(title), matching: find.byType(OnmuCard));
}

Finder _planMoreButtonFinder(String title) {
  return find.descendant(
    of: _planCardFinder(title).first,
    matching: find.byTooltip('약속 더보기'),
  );
}

void main() {
  testWidgets(
    'group list search filters by member, pinned plan, and last chat',
    (tester) async {
      await tester.pumpWidget(_testOnmuApp());
      await tester.pumpAndSettle(const Duration(milliseconds: 5000));

      appRouter.go(RoutePaths.groups);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('group-list-search-field')),
        '현우',
      );
      await tester.pumpAndSettle();

      expect(find.text('대학 동기 여행단'), findsOneWidget);
      expect(find.text('퇴근 후 러닝크루'), findsNothing);
      expect(find.text('보드게임 모임'), findsNothing);
      expect(find.text('1개 결과'), findsOneWidget);

      await tester.tap(find.byTooltip('검색어 지우기'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('group-list-search-field')),
        'D-4',
      );
      await tester.pumpAndSettle();

      expect(find.text('보드게임 모임'), findsOneWidget);
      expect(find.text('대학 동기 여행단'), findsNothing);

      await tester.tap(find.byTooltip('검색어 지우기'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('group-list-search-field')),
        '체크리스트',
      );
      await tester.pumpAndSettle();

      expect(find.text('대학 동기 여행단'), findsOneWidget);
      expect(find.text('보드게임 모임'), findsNothing);
    },
  );

  testWidgets(
    'group list search empty state is distinct from default empty data',
    (tester) async {
      await tester.pumpWidget(_testOnmuApp());
      await tester.pumpAndSettle(const Duration(milliseconds: 5000));

      appRouter.go(RoutePaths.groups);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('group-list-search-field')),
        '없는 모임 이름',
      );
      await tester.pumpAndSettle();

      expect(find.text('검색 결과가 없어요.'), findsOneWidget);
      expect(find.text('아직 온모임이 없어요.'), findsNothing);
    },
  );

  testWidgets('group memories filter switches between records and memos', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupMemories(1));
    await tester.pumpAndSettle();

    expect(find.text('전체'), findsOneWidget);
    expect(find.text('기록'), findsWidgets);
    expect(find.text('메모'), findsOneWidget);
    expect(find.text('제주 바다'), findsOneWidget);
    expect(find.text('메모 항목이 아직 없어요.'), findsNothing);

    await tester.tap(find.text('메모'));
    await tester.pumpAndSettle();

    expect(find.text('제주 바다'), findsNothing);
    expect(find.text('메모 항목이 아직 없어요.'), findsOneWidget);

    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();

    expect(find.text('제주 바다'), findsOneWidget);
    expect(find.text('메모 항목이 아직 없어요.'), findsNothing);
  });

  testWidgets('group memories empty board and empty filter states differ', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupMemories(3));
    await tester.pumpAndSettle();

    expect(find.text('전체 항목이 아직 없어요.'), findsOneWidget);

    appRouter.go(RoutePaths.groupMemories(2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('메모'));
    await tester.pumpAndSettle();

    expect(find.text('메모 항목이 아직 없어요.'), findsOneWidget);
    expect(find.text('사의동 산책'), findsNothing);
  });

  testWidgets(
    'plan more menu shows future actions without settlement and opens place candidates',
    (tester) async {
      await tester.pumpWidget(_testOnmuApp());
      await tester.pumpAndSettle(const Duration(milliseconds: 5000));

      appRouter.go(RoutePaths.groupPlans(1));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('홍대 전시회 구경'));
      await tester.tap(_planMoreButtonFinder('홍대 전시회 구경'));
      await tester.pumpAndSettle();

      expect(find.text('약속 상세 보기'), findsOneWidget);
      expect(find.text('약속 수정하기'), findsOneWidget);
      expect(find.text('장소 후보 보기'), findsOneWidget);
      expect(find.text('투표 보기'), findsOneWidget);
      expect(find.text('정산 보기'), findsNothing);

      await tester.tap(find.text('장소 후보 보기'));
      await tester.pumpAndSettle();

      expect(find.text('장소 후보 리스트'), findsOneWidget);
    },
  );

  testWidgets(
    'plan more menu keeps settlement action for ongoing or past plans',
    (tester) async {
      await tester.pumpWidget(_testOnmuApp());
      await tester.pumpAndSettle(const Duration(milliseconds: 5000));

      appRouter.go(RoutePaths.groupPlans(1));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '한강');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('약속 더보기').first);
      await tester.pumpAndSettle();

      expect(find.text('정산 보기'), findsOneWidget);
    },
  );
}
