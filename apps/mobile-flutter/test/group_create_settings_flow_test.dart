import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';
import 'package:go_router/go_router.dart';
import 'package:onmu_mobile/features/group/presentation/pages/group_create_page.dart';
import 'package:onmu_mobile/features/group/presentation/pages/group_list_page.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';

import 'support/in_memory_onmu_store.dart';
import 'support/test_onmu_repositories.dart';

Widget _testMaterialApp(Widget child) {
  return onmuTestProviderScope(child: MaterialApp(home: child));
}

Widget _testRouterApp(GoRouter router) {
  return onmuTestProviderScope(child: MaterialApp.router(routerConfig: router));
}

void main() {
  test('in-memory store persists group rename', () {
    final store = InMemoryOnmuStore.seeded();
    final created = store.createGroup(
      GroupCreateInput(
        name: '원래 모임',
        description: '원래 소개',
        memberNames: const ['나', '은지'],
      ),
    );

    final updated = store.updateGroup(
      groupId: created.id,
      name: '바뀐 모임',
      description: '바뀐 소개',
    );

    expect(updated.name, '바뀐 모임');
    expect(updated.description, '바뀐 소개');
    expect(store.fetchGroup(created.id).name, '바뀐 모임');
    expect(store.fetchGroups().first.name, '바뀐 모임');
  });

  testWidgets('selected member chips can be removed while creating group', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testMaterialApp(const GroupCreatePage(initialMemberNames: ['은지', '태호'])),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('은지 제거'), findsOneWidget);
    expect(find.byTooltip('태호 제거'), findsOneWidget);

    await tester.tap(find.byTooltip('은지 제거'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('은지 제거'), findsNothing);
    expect(find.byTooltip('태호 제거'), findsOneWidget);
  });

  testWidgets('creating group with first plan toggle off opens plan creation', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: RoutePaths.groupNew,
      routes: [
        GoRoute(
          path: RoutePaths.groups,
          builder: (context, state) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) =>
                  const GroupCreatePage(initialMemberNames: ['은지']),
            ),
            GoRoute(
              path: ':groupId',
              builder: (context, state) => const Text('group-detail'),
              routes: [
                GoRoute(
                  path: 'plans/new',
                  builder: (context, state) => const Text('plan-new'),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(_testRouterApp(router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '첫 약속 모임');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    tester.widget<Switch>(find.byType(Switch)).onChanged!(false);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();

    expect(find.text('plan-new'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      RoutePaths.planNew(4),
    );
  });

  testWidgets('group list search is pinned outside the scrolling list', (
    tester,
  ) async {
    await tester.pumpWidget(_testMaterialApp(const GroupListPage()));
    await tester.pumpAndSettle();

    final search = find.byKey(const ValueKey('group-list-sticky-search'));
    expect(search, findsOneWidget);
    expect(
      find.ancestor(of: search, matching: find.byType(ListView)),
      findsNothing,
    );
  });
}
