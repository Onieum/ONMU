import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';
import 'package:go_router/go_router.dart';
import 'package:onmu_mobile/features/auth/domain/auth_user.dart';
import 'package:onmu_mobile/features/group/presentation/pages/group_create_page.dart';
import 'package:onmu_mobile/features/group/presentation/pages/group_list_page.dart';
import 'package:onmu_mobile/features/group/presentation/pages/group_settings_page.dart';
import 'package:onmu_mobile/features/group/presentation/widgets/group_cards.dart';
import 'package:onmu_mobile/features/my/domain/my_profile.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';

import 'support/in_memory_onmu_store.dart';
import 'support/test_onmu_repositories.dart';

Widget _testMaterialApp(Widget child) {
  return onmuTestProviderScope(child: MaterialApp(home: child));
}

Widget _testMaterialAppWithFriends(Widget child) {
  return onmuTestProviderScope(
    friendRepository: TestFriendRepository(
      friends: const [
        FriendProfile(
          publicId: 'friend-doyun',
          userCode: 'doyun',
          name: '도윤',
          preferenceSummary: '',
          isFriend: true,
        ),
        FriendProfile(
          publicId: 'friend-minseo',
          userCode: 'minseo',
          name: '민서',
          preferenceSummary: '',
          isFriend: true,
        ),
      ],
    ),
    child: MaterialApp(home: child),
  );
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

  testWidgets('group create member picker uses repository friends', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testMaterialAppWithFriends(const GroupCreatePage()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('추가').last);
    await tester.pumpAndSettle();

    expect(find.text('도윤'), findsOneWidget);
    expect(find.text('민서'), findsOneWidget);
    expect(find.text('유나'), findsNothing);
  });

  testWidgets('group create starts with current user profile as a member', (
    tester,
  ) async {
    await tester.pumpWidget(
      onmuTestProviderScope(
        user: const AuthUser(
          id: '00000000-0000-0000-0000-000000000001',
          publicId: 'usr_me',
          provider: 'KAKAO',
          nickname: '박진희',
          profileImageUrl: 'https://example.test/me.png',
          onboardingStatus: 'COMPLETED',
        ),
        child: const MaterialApp(home: GroupCreatePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('박진희'), findsOneWidget);
    expect(find.byTooltip('박진희 제거'), findsNothing);
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

  testWidgets('group rename sheet saves without disposing active controller', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testMaterialApp(const GroupSettingsPage(groupId: '1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('모임 이름 변경'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '이름 변경 확인');
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();

    expect(find.text('이름 변경 확인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('group settings sheet updates name and description together', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testMaterialApp(const GroupSettingsPage(groupId: '1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('모임 이름 변경'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '소개까지 수정');
    await tester.enterText(find.byType(TextField).at(1), '새로운 모임 소개');
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();

    expect(find.text('소개까지 수정'), findsOneWidget);
    expect(find.text('새로운 모임 소개'), findsOneWidget);
  });

  testWidgets(
    'group summary description row does not show fake active status',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupSummaryCard(
              group: const GroupSummary(
                id: 1,
                name: '진희가 테스트로 수정',
                description: '테스트입니다',
                members: ['박진희'],
                lastMessage: '',
                unreadCount: 0,
                pinnedPlanTitle: '예정된 약속 없음',
              ),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('테스트입니다'), findsOneWidget);
      expect(find.text('진행중'), findsNothing);
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);
    },
  );
}
