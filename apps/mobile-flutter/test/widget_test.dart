import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onmu_mobile/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:onmu_mobile/core/routing/app_router.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/auth/data/auth_token_store.dart';
import 'package:onmu_mobile/features/auth/domain/auth_user.dart';
import 'package:onmu_mobile/features/auth/providers/auth_providers.dart';
import 'package:onmu_mobile/features/home/presentation/pages/home_page.dart';
import 'package:onmu_mobile/features/group/presentation/pages/group_home_page.dart';
import 'package:onmu_mobile/features/group/presentation/pages/group_chat_page.dart';
import 'package:onmu_mobile/features/group/presentation/pages/group_memory_detail_page.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';
import 'package:onmu_mobile/features/my/domain/my_profile.dart';
import 'package:onmu_mobile/features/my/presentation/pages/my_page.dart';
import 'package:onmu_mobile/features/my/repository/friend_repository.dart';
import 'package:onmu_mobile/features/place/presentation/pages/place_candidate_page.dart';
import 'package:onmu_mobile/features/place/repository/place_repository.dart';
import 'package:onmu_mobile/features/plan/repository/plan_repository.dart';
import 'package:onmu_mobile/features/plan/widgets/plan_member_avatar_row.dart';
import 'package:onmu_mobile/features/settlement/repository/settlement_repository.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';
import 'package:onmu_mobile/shared/models/preference_profile.dart';
import 'package:onmu_mobile/shared/models/settlement_models.dart';
import 'package:onmu_mobile/shared/models/vote_models.dart';

import 'support/in_memory_onmu_store.dart';
import 'support/test_onmu_repositories.dart';

const _groupId = 1;
const _planId = 101;
const _candidateId = 201;
const _memoryId = 1001;

String _weekdayLabel(DateTime date) {
  return const ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];
}

Widget _testOnmuApp() {
  appRouter.go(RoutePaths.splash);
  return onmuTestProviderScope(child: const app.OnmuMaterialApp());
}

void main() {
  testWidgets('login redirects authenticated completed user to home', (
    tester,
  ) async {
    appRouter.go(RoutePaths.login);
    await tester.pumpWidget(
      onmuTestProviderScope(
        user: const AuthUser(
          id: '00000000-0000-0000-0000-000000000001',
          publicId: 'user-me',
          provider: 'NAVER',
          nickname: '나',
          onboardingStatus: 'COMPLETED',
        ),
        child: const app.OnmuMaterialApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('안녕하세요,'), findsOneWidget);
    expect(find.text('나님'), findsOneWidget);
    expect(find.text('카카오로 시작하기'), findsNothing);
  });

  testWidgets('completed user direct onboarding route returns home', (
    tester,
  ) async {
    appRouter.go(RoutePaths.onboarding);
    await tester.pumpWidget(
      onmuTestProviderScope(
        user: const AuthUser(
          id: '00000000-0000-0000-0000-000000000001',
          publicId: 'user-me',
          provider: 'NAVER',
          nickname: '나',
          onboardingStatus: 'COMPLETED',
        ),
        child: const app.OnmuMaterialApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('안녕하세요,'), findsOneWidget);
    expect(find.text('나님'), findsOneWidget);
    expect(find.text('캐릭터 만들기'), findsNothing);
    expect(find.text('취향 선택'), findsNothing);
  });

  testWidgets(
    'completed user direct onboarding child routes do not reparent shell',
    (tester) async {
      const user = AuthUser(
        id: '00000000-0000-0000-0000-000000000001',
        publicId: 'user-me',
        provider: 'NAVER',
        nickname: '나',
        onboardingStatus: 'COMPLETED',
      );

      for (final route in [
        RoutePaths.onboardingPreferences,
        RoutePaths.onboardingCharacter,
      ]) {
        appRouter.go(route);
        await tester.pumpWidget(
          onmuTestProviderScope(user: user, child: const app.OnmuMaterialApp()),
        );
        await tester.pumpAndSettle();

        expect(find.text('안녕하세요,'), findsOneWidget);
        expect(find.text('나님'), findsOneWidget);
        expect(find.text('취향 선택'), findsNothing);
        expect(find.text('캐릭터 만들기'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('starts with splash and opens login', (tester) async {
    await tester.pumpWidget(_testOnmuApp());

    expect(find.text('약속을 잡고,\n함께한 순간을 기록해요'), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('구글로 시작하기'), findsOneWidget);
    expect(find.text('네이버로 시작하기'), findsOneWidget);
  });

  testWidgets('login opens onboarding and skip flow enters home', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());

    await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    await tester.tap(find.text('네이버로 시작하기'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('기록 준비', findRichText: true), findsOneWidget);
    expect(find.text('캐릭터 만들기'), findsOneWidget);
    expect(find.text('취향 선택'), findsOneWidget);

    await tester.tap(find.text('홈으로 가기').last);
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요,'), findsOneWidget);
    expect(find.text('네이버 친구님'), findsOneWidget);
    expect(find.text('오늘의 약속'), findsOneWidget);
    expect(find.text('약속 만들기'), findsNothing);
    expect(find.text('전체 보기'), findsWidgets);
    expect(find.text('홈'), findsWidgets);
    expect(find.text('약속'), findsNothing);
    expect(find.text('온모임'), findsWidgets);
    expect(find.text('기록'), findsWidgets);
    expect(find.text('마이'), findsWidgets);
  });

  testWidgets('onboarding saves character completion from character flow', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.onboarding);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '시작하기').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, '시작하기'));
    await tester.pumpAndSettle();

    for (var step = 0; step < 4; step += 1) {
      await tester.tap(find.widgetWithText(ElevatedButton, '다음'));
      await tester.pumpAndSettle();
    }

    expect(find.text('꾸미기 완료!'), findsOneWidget);
    expect(find.text('캐릭터 이름을 정해 주세요'), findsNothing);
    expect(find.text('이름을 입력해 주세요'), findsNothing);

    await tester.tap(find.widgetWithText(ElevatedButton, '첫 설정 페이지로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.text('캐릭터 만들기'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    expect(find.text('다시 설정'), findsOneWidget);
  });

  testWidgets('onboarding saves preference completion from preference flow', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.onboarding);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '시작하기').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('한식'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('조용한 대화 공간'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('미리 일정을 정하는 편'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('토요일'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저녁'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('요약 보기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('첫 설정 페이지로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.text('취향 선택'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    expect(find.text('다시 설정'), findsOneWidget);
  });

  testWidgets('group plan creation route opens the create screen', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planNew(_groupId));
    await tester.pumpAndSettle();

    expect(find.text('약속 만들기'), findsWidgets);
    expect(find.text('약속 이름'), findsOneWidget);
    expect(find.text('참여 멤버'), findsOneWidget);
    expect(find.text('참여자 선택'), findsNothing);
  });

  testWidgets('group plan schedule routes focus date time creation intent', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planNewSchedule(_groupId));
    await tester.pumpAndSettle();

    expect(find.text('날짜와 시간을 먼저 정해요'), findsOneWidget);

    appRouter.go(RoutePaths.planNewCalendar(_groupId));
    await tester.pumpAndSettle();

    expect(find.text('캘린더에서 날짜와 시간을 고르세요'), findsOneWidget);
  });

  testWidgets('plan create starts with current user and warns before saving', (
    tester,
  ) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.pumpWidget(
      onmuTestProviderScope(
        user: const AuthUser(
          id: '00000000-0000-0000-0000-000000000001',
          publicId: 'user-me',
          provider: 'NAVER',
          nickname: '나',
          onboardingStatus: 'COMPLETED',
        ),
        preferenceProfile: PreferenceProfile.empty().copyWith(
          unavailableDates: [
            '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}',
          ],
        ),
        child: const app.OnmuMaterialApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planNew(_groupId));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(PlanMemberAvatar),
        matching: find.text('나'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('참여 멤버')).dy,
      lessThan(tester.getTopLeft(find.text('날짜와 시간')).dy),
    );

    await tester.enterText(find.byType(TextFormField).first, '새 약속');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '약속 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('해당 약속 시간에 참여가 힘든 멤버가 있어요. 그래도 진행할까요?'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '아니오'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '예'), findsOneWidget);
  });

  testWidgets('home plan cards open plan detail when tapped', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.home);
    await tester.pumpAndSettle();

    expect(find.text('상세 보기'), findsNothing);

    appRouter.push(RoutePaths.planDetail(_groupId, 104));
    await tester.pumpAndSettle();

    expect(find.text('홍대 전시회 구경'), findsOneWidget);
    expect(find.text('후보 리스트 보기'), findsOneWidget);
  });

  testWidgets(
    'home header shows ONMU logo and active card fits compact width',
    (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      await binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => binding.setSurfaceSize(null));

      await tester.pumpWidget(
        onmuTestProviderScope(
          child: MaterialApp(theme: AppTheme.lightTheme, home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ONMU'), findsOneWidget);
      expect(find.text('상세 보기'), findsNothing);
      expect(find.text('오늘의 약속'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('my page uses authenticated dev user instead of local fixture', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authTokenStoreProvider.overrideWithValue(InMemoryAuthTokenStore()),
          authUserProvider.overrideWith(
            (ref) => const AuthUser(
              id: '00000000-0000-0000-0000-000000000001',
              publicId: 'user-me',
              provider: 'NAVER',
              nickname: '나',
              onboardingStatus: 'COMPLETED',
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.lightTheme, home: const MyPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('나'), findsOneWidget);
    expect(find.text('온이음'), findsNothing);
  });

  testWidgets('my page replaces default profile name with auth display name', (
    tester,
  ) async {
    await tester.pumpWidget(
      onmuTestProviderScope(
        user: const AuthUser(
          id: '00000000-0000-0000-0000-000000000001',
          publicId: 'user-me',
          provider: 'KAKAO',
          nickname: '카카오 프로필',
          onboardingStatus: 'COMPLETED',
        ),
        myRepository: TestMyRepository(),
        child: MaterialApp(theme: AppTheme.lightTheme, home: const MyPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('카카오 프로필'), findsOneWidget);
    expect(find.text('ONMU User'), findsNothing);
  });

  testWidgets('my page profile editor saves display name through repository', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    final repository = TestMyRepository();

    await tester.pumpWidget(
      onmuTestProviderScope(
        user: const AuthUser(
          id: '00000000-0000-0000-0000-000000000001',
          publicId: 'user-me',
          provider: 'NAVER',
          nickname: '나',
          onboardingStatus: 'COMPLETED',
        ),
        myRepository: repository,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const MyPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '프로필 수정'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '수정된 나');
    await tester.ensureVisible(find.text('저장하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(repository.updateProfileCallCount, 1);
    expect(repository.lastUpdatedProfile?.realName, '수정된 나');
    expect(find.text('수정된 나'), findsOneWidget);
    expect(find.text('저장하기'), findsNothing);
  });

  testWidgets('my page profile editor stays open when save fails', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    final repository = TestMyRepository(failUpdates: true);

    await tester.pumpWidget(
      onmuTestProviderScope(
        user: const AuthUser(
          id: '00000000-0000-0000-0000-000000000001',
          publicId: 'user-me',
          provider: 'NAVER',
          nickname: '나',
          onboardingStatus: 'COMPLETED',
        ),
        myRepository: repository,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const MyPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '프로필 수정'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '저장 실패');
    await tester.ensureVisible(find.text('저장하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.updateProfileCallCount, 1);
    expect(repository.lastUpdatedProfile?.realName, '저장 실패');
    expect(find.text('프로필 저장에 실패했어요. 잠시 후 다시 시도해주세요.'), findsOneWidget);
    expect(find.text('저장하기'), findsOneWidget);
  });

  testWidgets('my page profile editor blocks top-bar back while saving', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    final saveGate = Completer<void>();
    final repository = TestMyRepository(
      failUpdates: true,
      updateProfileGate: saveGate,
    );

    await tester.pumpWidget(
      onmuTestProviderScope(
        user: const AuthUser(
          id: '00000000-0000-0000-0000-000000000001',
          publicId: 'user-me',
          provider: 'NAVER',
          nickname: '나',
          onboardingStatus: 'COMPLETED',
        ),
        myRepository: repository,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const MyPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '프로필 수정'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '저장 대기');
    await tester.ensureVisible(find.text('저장하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pump();

    expect(repository.updateProfileCallCount, 1);
    expect(find.text('저장 중'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).last);
    await tester.pump();

    expect(find.text('프로필 수정'), findsOneWidget);
    expect(find.text('저장 중'), findsOneWidget);

    saveGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('프로필 저장에 실패했어요. 잠시 후 다시 시도해주세요.'), findsOneWidget);
    expect(find.text('저장하기'), findsOneWidget);
  });

  testWidgets('my page friend add registers friend by pasted user id', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => binding.setSurfaceSize(null));

    final friendRepository = _UserCodeFriendRepository();

    await tester.pumpWidget(
      onmuTestProviderScope(
        user: const AuthUser(
          id: '00000000-0000-0000-0000-000000000001',
          publicId: 'user-me',
          provider: 'NAVER',
          nickname: 'Me',
          onboardingStatus: 'COMPLETED',
        ),
        friendRepository: friendRepository,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const MyPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('친구'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_add_alt_1));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '1234567890');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();

    expect(friendRepository.addedPublicId, '1234567890');
    expect(find.text('친구로 등록했어요.'), findsOneWidget);
  });

  testWidgets('upcoming plan see all opens the full upcoming list', (
    tester,
  ) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.home);
    await tester.pumpAndSettle();

    await tester.tap(find.text('전체 보기').first);
    await tester.pumpAndSettle();

    expect(find.text('다가오는 약속'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('홍대 전시회 구경'), 320);
    expect(find.text('홍대 전시회 구경'), findsOneWidget);
    expect(find.text('${tomorrow.month}월 ${tomorrow.day}일'), findsOneWidget);
    expect(
      find.text('${weekdayLabels[tomorrow.weekday - 1]}요일'),
      findsOneWidget,
    );
    expect(find.text('14:00'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('성수 디저트 모임'), 320);
    expect(find.text('성수 디저트 모임'), findsOneWidget);
    expect(find.text('제주도 여행'), findsNothing);
    expect(find.text('한남 카페 투어'), findsNothing);
  });

  testWidgets('upcoming week selector shows past plans when selected', (
    tester,
  ) async {
    final today = DateTime.now();
    final pastDate = today.subtract(const Duration(days: 3));
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final pastDayKey = ValueKey(
      'upcoming-week-day-${pastDate.year}-${pastDate.month}-${pastDate.day}',
    );

    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.homeUpcomingPlans);
    await tester.pumpAndSettle();

    expect(find.text('한남 카페 투어'), findsNothing);

    if (pastDate.isBefore(currentWeekStart)) {
      await tester.tap(find.byTooltip('이전 주'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(pastDayKey));
    await tester.pumpAndSettle();

    expect(find.text('${pastDate.month}월 ${pastDate.day}일 약속'), findsOneWidget);
    expect(find.text('한남 카페 투어'), findsOneWidget);
  });

  testWidgets('upcoming calendar shows only current month day cells', (
    tester,
  ) async {
    final now = DateTime.now();
    final currentMonthFirstDay = DateTime(now.year, now.month);
    final nextMonthFirstDay = DateTime(now.year, now.month + 1);
    final currentMonthCellKey = ValueKey(
      'upcoming-calendar-day-${currentMonthFirstDay.year}-${currentMonthFirstDay.month}-${currentMonthFirstDay.day}',
    );
    final nextMonthCellKey = ValueKey(
      'upcoming-calendar-day-${nextMonthFirstDay.year}-${nextMonthFirstDay.month}-${nextMonthFirstDay.day}',
    );
    final currentMonthCell = find.byKey(currentMonthCellKey);

    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.homeUpcomingCalendar);
    await tester.pumpAndSettle();

    expect(find.text('약속 캘린더'), findsOneWidget);
    expect(currentMonthCell, findsOneWidget);
    expect(nextMonthCellKey, isNot(equals(currentMonthCellKey)));
    expect(find.byKey(nextMonthCellKey), findsNothing);
    expect(
      find.descendant(
        of: currentMonthCell,
        matching: find.text(_weekdayLabel(currentMonthFirstDay)),
      ),
      findsNothing,
    );
  });

  testWidgets('upcoming calendar shows past plans when selected', (
    tester,
  ) async {
    final pastDate = DateTime.now().subtract(const Duration(days: 5));
    final pastDayKey = ValueKey(
      'upcoming-calendar-day-${pastDate.year}-${pastDate.month}-${pastDate.day}',
    );

    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.homeUpcomingCalendar);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(pastDayKey));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('${pastDate.month}월 ${pastDate.day}일 약속'), findsOneWidget);
    expect(find.text('제주도 여행'), findsWidgets);
  });

  testWidgets('home notification bell opens API notification list', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.home);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('알림'));
    await tester.pumpAndSettle();

    expect(find.text('알림'), findsOneWidget);
    expect(find.text('장소 후보가 추가됐어요'), findsOneWidget);
    expect(find.text('카페 오션뷰 후보가 제주도 여행에 추가됐습니다.'), findsOneWidget);
    expect(find.text('알림이 없어요.'), findsNothing);
    expect(find.text('성수 저녁 약속이 30분 뒤 시작돼요'), findsNothing);
  });

  testWidgets('home recent records see all opens API record list', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.home);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('최근 기록'), 320);
    await tester.pumpAndSettle();

    expect(find.text('한강 피크닉 기록'), findsOneWidget);

    await tester.tap(find.text('전체 보기').last);
    await tester.pumpAndSettle();

    expect(find.text('최근 기록'), findsOneWidget);
    expect(find.text('한강 피크닉 기록'), findsOneWidget);
    expect(find.text('성수 디저트룩'), findsOneWidget);
    expect(find.text('최근 기록이 없어요.'), findsNothing);
  });

  testWidgets('records calendar ignores invalid bgColorIndex values', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.records);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('group home uses create plan fab only', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupDetail(_groupId));
    await tester.pumpAndSettle();

    expect(find.text('대학 동기 여행단'), findsOneWidget);
    expect(find.text('다가오는 약속'), findsOneWidget);
    expect(find.byTooltip('약속 만들기'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-home-create-plan-fab')),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, '약속 만들기'), findsNothing);
    expect(find.text('모임원'), findsNothing);
  });

  testWidgets('group home renders with a single server member', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            _SingleMemberGroupRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const GroupHomePage(groupId: '4'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('서버 단일 멤버 모임'), findsOneWidget);
    expect(find.text('멤버 1명'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('group home create fab opens plan creation', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupDetail(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('group-home-create-plan-fab')));
    await tester.pumpAndSettle();

    expect(find.text('약속 만들기'), findsWidgets);
    expect(find.text('약속 이름'), findsOneWidget);
    expect(find.text('참여 멤버'), findsOneWidget);
  });

  testWidgets('group plan detail back returns to the previous plan list', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupDetail(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('전체 보기').first);
    await tester.pumpAndSettle();

    expect(find.text('약속'), findsOneWidget);
    expect(find.text('모임 약속 검색'), findsOneWidget);

    appRouter.push(RoutePaths.planDetail(_groupId, 104));
    await tester.pumpAndSettle();

    expect(find.text('후보 리스트 보기'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();

    expect(find.text('약속'), findsOneWidget);
    expect(find.text('모임 약속 검색'), findsOneWidget);
  });

  testWidgets('group creation persists the new group in repository state', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groups);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('온모임 만들기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '테스트 모임');
    await tester.enterText(find.byType(TextField).at(1), '생성 흐름 검증');
    await tester.tap(find.widgetWithText(FilledButton, '온모임 만들기'));
    await tester.pumpAndSettle();

    appRouter.go(RoutePaths.groups);
    await tester.pumpAndSettle();

    expect(find.text('테스트 모임'), findsOneWidget);
    expect(find.text('생성 흐름 검증'), findsOneWidget);
  });

  testWidgets('group creation add invite button selects a friend', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupNew);
    await tester.pumpAndSettle();

    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    expect(find.text('멤버 추가'), findsOneWidget);
    expect(find.text('친구 목록에서 초대할 멤버를 선택해 주세요.'), findsOneWidget);
    expect(find.text('도윤'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '선택').first);
    await tester.pumpAndSettle();

    expect(find.text('도윤'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '초대 테스트 모임');
    await tester.enterText(find.byType(TextField).at(1), '멤버 추가 검증');
    await tester.tap(find.widgetWithText(FilledButton, '온모임 만들기'));
    await tester.pumpAndSettle();

    appRouter.go(RoutePaths.groups);
    await tester.pumpAndSettle();

    expect(find.text('초대 테스트 모임'), findsOneWidget);
  });

  testWidgets('group home member count opens member list', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupDetail(_groupId));
    await tester.pumpAndSettle();

    expect(find.text('우리, 또 하나의 추억을 만들자'), findsOneWidget);
    await tester.tap(find.text('멤버 8명'));
    await tester.pumpAndSettle();

    expect(find.text('모임원'), findsOneWidget);
    expect(find.text('대학 동기 여행단 · 8명'), findsOneWidget);
    expect(find.text('멤버 검색'), findsOneWidget);
  });

  testWidgets('group home upcoming see all opens plan list', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupDetail(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('전체 보기').first);
    await tester.pumpAndSettle();

    expect(find.text('약속'), findsOneWidget);
    expect(find.text('모임 약속 검색'), findsOneWidget);
    expect(find.text('다가오는 약속'), findsWidgets);
    expect(find.text('날짜 오름차순'), findsOneWidget);
    expect(find.text('지난 약속'), findsWidgets);
  });

  testWidgets('plan itinerary date tabs can be selected', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planItinerary(_groupId, _planId));
    await tester.pumpAndSettle();

    final dateTabs = find.byWidgetPredicate((widget) {
      return widget is Text &&
          RegExp(r'^\d{1,2}/\d{1,2} [월화수목금토일]$').hasMatch(widget.data ?? '');
    });
    expect(dateTabs, findsNWidgets(3));

    await tester.tap(dateTabs.at(1));
    await tester.pumpAndSettle();

    final secondTabText = tester.widget<Text>(dateTabs.at(1));

    expect(secondTabText.style?.color, AppColors.primaryPink);
    expect(find.text('장소 동선'), findsWidgets);
  });

  testWidgets('draft plan can open the shared candidate list', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planDetail(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.text('장소 검색하기'), findsOneWidget);
    expect(find.text('후보 리스트 보기'), findsOneWidget);
    expect(find.text('제주도 일대'), findsOneWidget);
    expect(find.text('6.7 (금) 오전 10:00'), findsNothing);
    expect(find.text('일정이 없어요'), findsNothing);
    expect(find.text('약속 상태 알리기'), findsNothing);
    expect(find.text('출발'), findsNothing);
    expect(find.text('도착'), findsNothing);
    expect(find.text('지각'), findsNothing);
    await tester.scrollUntilVisible(find.text('일정 타임라인'), 160);
    expect(find.text('일정 타임라인'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('다운타우너 성수'), 160);
    expect(find.text('다운타우너 성수'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('장소 동선').first, 160);
    expect(find.text('방문 지도'), findsNothing);
    expect(find.text('장소 동선'), findsWidgets);
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('약속 메모'), findsOneWidget);
    expect(find.text('편한 복장으로 오기! 돗자리 챙기면 좋을 것 같아요.'), findsOneWidget);

    final searchButtonRect = tester.getRect(
      find.byKey(const ValueKey('plan-place-action-search')),
    );
    final candidateButtonRect = tester.getRect(
      find.byKey(const ValueKey('plan-place-action-candidates')),
    );
    expect(searchButtonRect.size, candidateButtonRect.size);

    await tester.tap(find.text('후보 리스트 보기'));
    await tester.pumpAndSettle();

    expect(find.text('장소 후보 리스트'), findsOneWidget);
  });

  testWidgets('plan detail edit flow returns home after save', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planDetail(_groupId, _planId));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('더보기'));
    await tester.pumpAndSettle();

    expect(find.text('약속 수정하기'), findsOneWidget);

    await tester.tap(find.text('약속 수정하기'));
    await tester.pumpAndSettle();

    expect(find.text('약속 수정하기'), findsOneWidget);
    expect(find.text('수정 완료'), findsOneWidget);
    expect(find.text('약속 이름'), findsOneWidget);
    expect(find.text('제주도 여행'), findsOneWidget);
    expect(find.text('제주도 일대'), findsOneWidget);
    expect(find.text('선택한 일정'), findsOneWidget);
    expect(find.text('추천 시간대 또는 직접 시간을 터치해서 선택'), findsNothing);
    expect(find.textContaining('~ 6월'), findsWidgets);

    expect(find.widgetWithText(TextFormField, '제주도 일대'), findsOneWidget);
    expect(find.byTooltip('지역 지우기'), findsOneWidget);

    await tester.ensureVisible(find.text('선택한 일정'));
    await tester.tap(find.text('선택한 일정'));
    await tester.pumpAndSettle();
    expect(find.text('날짜와 시간 선택'), findsOneWidget);
    expect(find.text('일반 추천'), findsWidgets);
    expect(find.text('직접 시간 지정'), findsNothing);
    expect(find.text('보통'), findsNothing);
    expect(find.text('저녁'), findsNothing);
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();
    if (find
        .text('해당 약속 시간에 참여가 힘든 멤버가 있어요. 그래도 진행할까요?')
        .evaluate()
        .isNotEmpty) {
      await tester.tap(find.widgetWithText(FilledButton, '예'));
      await tester.pumpAndSettle();
    }

    await tester.enterText(
      find.byKey(const ValueKey('plan-location-field')),
      '성수동',
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('지역 지우기'), findsOneWidget);
    await tester.dragUntilVisible(
      find.widgetWithText(TextFormField, '제주도 여행'),
      find.byType(Scrollable).last,
      const Offset(0, 120),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '제주도 여행'),
      '수정된 약속',
    );
    await tester.dragUntilVisible(
      find.text('참여 멤버'),
      find.byType(Scrollable).last,
      const Offset(0, -120),
    );
    expect(find.byTooltip('참여 멤버 추가'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '수정 완료'));
    await tester.pumpAndSettle();
    if (find
        .text('해당 약속 시간에 참여가 힘든 멤버가 있어요. 그래도 진행할까요?')
        .evaluate()
        .isNotEmpty) {
      await tester.tap(find.widgetWithText(FilledButton, '예'));
      await tester.pumpAndSettle();
    }

    expect(find.text('약속 수정하기'), findsNothing);
    expect(find.textContaining('안녕하세요,'), findsOneWidget);
    expect(find.text('오늘의 약속'), findsOneWidget);
  });

  testWidgets('new plan selected members can remove added members', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planNew(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('참여 멤버 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('민수').last);
    await tester.pumpAndSettle();

    expect(find.byTooltip('민수 제거'), findsOneWidget);

    await tester.tap(find.byTooltip('민수 제거'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('민수 제거'), findsNothing);
  });

  testWidgets('canonical plan edit route opens the edit screen', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planEdit(_groupId, 103));
    await tester.pumpAndSettle();

    expect(find.text('약속 수정하기'), findsOneWidget);
    expect(find.text('수정 완료'), findsOneWidget);
    expect(find.text('Page Not Found'), findsNothing);
  });

  testWidgets('canonical group and plan routes open operating screens', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupDetail(_groupId));
    await tester.pumpAndSettle();

    expect(find.text('대학 동기 여행단'), findsOneWidget);

    appRouter.go(RoutePaths.planDetail(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.text('제주도 여행'), findsOneWidget);
    expect(find.text('후보 리스트 보기'), findsOneWidget);

    appRouter.go(RoutePaths.planItinerary(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.text('장소 동선'), findsWidgets);
  });

  testWidgets('place candidate list is plan-scoped and supports actions', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceCandidates(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.text('6/7 토'), findsNothing);
    expect(find.text('6/8 일'), findsNothing);
    expect(find.text('6/9 월'), findsNothing);
    expect(find.text('투표 만들기'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsWidgets);
    expect(find.text('일정에 등록'), findsWidgets);
    expect(find.textContaining('하트를 눌러'), findsNothing);
    expect(find.textContaining('마음에 들면'), findsNothing);

    await tester.tap(find.text('카페'));
    await tester.pumpAndSettle();
    expect(find.text('무드카페'), findsOneWidget);
    expect(find.text('하루정원'), findsOneWidget);
    expect(find.text('온무식당'), findsNothing);

    await tester.tap(find.text('식사'));
    await tester.pumpAndSettle();
    expect(find.text('온무식당'), findsOneWidget);
    expect(find.text('무드카페'), findsNothing);

    await tester.tap(find.text('숙소'));
    await tester.pumpAndSettle();
    expect(find.text('아직 장소 후보 리스트가 비어있어요!'), findsOneWidget);

    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();
    expect(find.text('온무식당'), findsOneWidget);
    expect(find.text('무드카페'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('place candidate list shows an empty card placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placeRepositoryProvider.overrideWithValue(
            const _EmptyPlaceRepository(),
          ),
          planRepositoryProvider.overrideWithValue(
            const _CandidatePlanRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceCandidatePage(groupId: '1', planId: '101'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 장소 후보 리스트가 비어있어요!'), findsOneWidget);
    expect(find.text('후보를 추가하면 이 공간에 카드로 정리돼요.'), findsOneWidget);
    expect(find.text('일정에 등록'), findsNothing);
    final voteButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '투표 만들기'),
    );
    expect(voteButton.onPressed, isNull);
  });

  testWidgets('place vote creation screen opens from candidate list', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planVoteNew(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.text('투표 만들기'), findsWidgets);
    expect(find.text('제주도 여행 장소 투표'), findsOneWidget);
    expect(find.text('투표 방식'), findsNothing);
    expect(find.text('단일 선택'), findsNothing);
    expect(find.text('중복 선택'), findsNothing);
    expect(find.text('마감 날짜'), findsNothing);
    expect(find.text('마감 시간'), findsNothing);
    expect(find.text('마감 날짜와 시간'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '선택'));
    await tester.pumpAndSettle();
    expect(find.text('마감 날짜와 시간'), findsWidgets);
    expect(find.text('선택 완료'), findsOneWidget);
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('투표에 올릴 후보를 추가해 주세요.'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('투표에 올릴 후보를 추가해 주세요.'), findsOneWidget);

    await tester.tap(find.text('장소 후보 리스트에서 추가'));
    await tester.pumpAndSettle();

    expect(find.text('투표 후보 추가'), findsOneWidget);
    await tester.tap(find.text('온무식당').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('추가 완료'));
    await tester.pumpAndSettle();

    expect(find.text('투표에 올릴 후보를 추가해 주세요.'), findsNothing);
    expect(find.text('온무식당'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '투표 만들기').last);
    await tester.pumpAndSettle();

    expect(find.text('투표 보기'), findsOneWidget);
    expect(find.text('후보별 투표 현황'), findsOneWidget);
    expect(find.text('온무식당'), findsOneWidget);
  });

  testWidgets('place map candidate action saves and opens candidate list', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceSearch(_groupId, _planId));
    await tester.pumpAndSettle();

    final candidateAction = find.byKey(
      const ValueKey('place-action-204-candidate'),
    );
    final scheduleAction = find.byKey(
      const ValueKey('place-action-204-schedule'),
    );
    final sheetScrollable = find.descendant(
      of: find.byKey(const ValueKey('place-map-bottom-sheet')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.scrollUntilVisible(
      candidateAction,
      300,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle();

    expect(find.text('후보에 추가'), findsWidgets);
    expect(find.text('일정에 추가'), findsWidgets);
    expect(find.text('후보에 추가하기'), findsNothing);
    expect(find.text('일정에 바로 등록하기'), findsNothing);

    final candidateButtonRect = tester.getRect(candidateAction);
    final scheduleButtonRect = tester.getRect(scheduleAction);
    expect(candidateButtonRect.size, scheduleButtonRect.size);

    await tester.tap(candidateAction);
    await tester.pumpAndSettle();

    expect(find.text('장소 후보 리스트'), findsOneWidget);
    expect(find.text('후보 리스트 보러가기'), findsNothing);
    expect(find.text('확인'), findsNothing);
  });

  testWidgets('place map schedule action saves and opens itinerary', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceSearch(_groupId, _planId));
    await tester.pumpAndSettle();

    final scheduleAction = find.byKey(
      const ValueKey('place-action-201-schedule'),
    );
    final sheetScrollable = find.descendant(
      of: find.byKey(const ValueKey('place-map-bottom-sheet')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.scrollUntilVisible(
      scheduleAction,
      300,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(scheduleAction);
    await tester.pumpAndSettle();

    expect(find.text('방문 시간 설정'), findsOneWidget);
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    expect(find.text('장소 동선'), findsWidgets);
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('장소 검색하기'), findsOneWidget);
  });

  testWidgets('place map hides comparison source and score labels', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceSearch(_groupId, _planId));
    await tester.pumpAndSettle();

    final sheetScrollable = find.descendant(
      of: find.byKey(const ValueKey('place-map-bottom-sheet')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    final candidateAction = find.byKey(
      const ValueKey('place-action-201-candidate'),
    );
    await tester.scrollUntilVisible(
      candidateAction,
      300,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('place-comparison-signal-grid')),
      findsNothing,
    );
    expect(find.textContaining('비교'), findsNothing);
    expect(find.textContaining('추천 받기'), findsNothing);
    expect(find.textContaining('Kakao'), findsNothing);
    expect(find.textContaining('Naver'), findsNothing);
    expect(find.text('Provider'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('후보에 있음'), findsWidgets);
    expect(find.text('일정에 추가'), findsWidgets);
  });

  testWidgets(
    'place map recommendation card opens detail sheet and focuses map',
    (tester) async {
      await tester.pumpWidget(_testOnmuApp());
      await tester.pumpAndSettle(const Duration(milliseconds: 5000));

      appRouter.go(RoutePaths.planPlaceSearch(_groupId, _planId));
      await tester.pumpAndSettle();

      final candidateName = find.text('온무식당');
      final sheetScrollable = find.descendant(
        of: find.byKey(const ValueKey('place-map-bottom-sheet')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      await tester.scrollUntilVisible(
        candidateName,
        300,
        scrollable: sheetScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(candidateName);
      await tester.pumpAndSettle();

      expect(find.text('장소 검색하기'), findsOneWidget);
      expect(find.text('장소 상세'), findsWidgets);
      expect(find.text('리뷰 키워드'), findsOneWidget);
      expect(find.text('참여자 선호'), findsOneWidget);
      expect(find.byKey(const ValueKey('focused-place-pin-1')), findsOneWidget);
    },
  );

  testWidgets('place map search stays on map and shows sheet results', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceSearch(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.byTooltip('장소 옵션'), findsNothing);
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    final searchField = tester.widget<TextField>(find.byType(TextField));
    expect(searchField.decoration?.border, InputBorder.none);
    expect(searchField.decoration?.enabledBorder, InputBorder.none);
    expect(searchField.decoration?.focusedBorder, InputBorder.none);
    expect(searchField.decoration?.disabledBorder, InputBorder.none);
    expect(searchField.decoration?.errorBorder, InputBorder.none);
    expect(searchField.decoration?.focusedErrorBorder, InputBorder.none);
    expect(find.text('장소 검색하기'), findsOneWidget);
    expect(find.text('장소 후보 ✨'), findsOneWidget);
    expect(find.text('지도 화면에서 이어서 장소를 찾아요'), findsNothing);
    final candidateAction = find.byKey(
      const ValueKey('place-action-201-candidate'),
    );
    final sheetScrollable = find.descendant(
      of: find.byKey(const ValueKey('place-map-bottom-sheet')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.scrollUntilVisible(
      candidateAction,
      300,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle();
    expect(candidateAction, findsOneWidget);
    expect(find.text('후보에 있음'), findsWidgets);
    expect(find.text('일정에 추가'), findsWidgets);
  });

  testWidgets('place map category pills filter sheet results', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceSearch(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.text('음식점'), findsOneWidget);
    expect(find.text('한식'), findsWidgets);
    expect(find.text('양식'), findsOneWidget);
    expect(find.text('중식'), findsOneWidget);
    expect(find.text('일식'), findsOneWidget);
    expect(find.text('아시안식'), findsOneWidget);
    expect(find.text('카페'), findsOneWidget);
    expect(find.text('가볼만한곳'), findsOneWidget);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('place-category-pill-음식점')))
          .height,
      30,
    );
    final foodCategoryText = tester.widget<Text>(find.text('음식점'));
    expect(foodCategoryText.style?.height, 1);

    await tester.tap(
      find.byKey(const ValueKey('place-category-pill-가볼만한곳')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('공원'), findsOneWidget);
    expect(find.text('해수욕장'), findsOneWidget);
    expect(find.text('박물관'), findsOneWidget);
    expect(find.text('미술관'), findsOneWidget);
    expect(find.text('전망대'), findsOneWidget);
    expect(find.text('산책로'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('place-category-pill-카페')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('장소 후보 ✨'), findsOneWidget);
    expect(find.byKey(const ValueKey('place-category-pill-한식')), findsNothing);
    final cafeCandidateName = find.text('무드카페');
    final sheetScrollable = find.descendant(
      of: find.byKey(const ValueKey('place-map-bottom-sheet')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.scrollUntilVisible(
      cafeCandidateName,
      300,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle();
    expect(cafeCandidateName, findsOneWidget);
    expect(find.text('온무식당'), findsNothing);
  });

  testWidgets('place map back returns to the previous screen', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceCandidates(_groupId, _planId));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();

    expect(find.text('장소 후보 리스트'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();

    expect(find.text('제주도 여행'), findsOneWidget);
  });

  testWidgets('place vote back returns to candidate list', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceCandidates(_groupId, _planId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('투표 만들기'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();

    expect(find.text('장소 후보 리스트'), findsOneWidget);
    expect(find.text('투표 후보'), findsNothing);
  });

  testWidgets('place detail hides score source and risk copy', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(
      RoutePaths.planPlaceCandidateDetail(_groupId, _planId, _candidateId),
    );
    await tester.pumpAndSettle();

    expect(find.text('일정에 바로 등록하기'), findsOneWidget);
    expect(find.text('후보에 추가하기'), findsOneWidget);
    expect(find.textContaining('지도 위 바텀시트처럼'), findsNothing);
    expect(find.textContaining('운영 리스크'), findsNothing);
    expect(find.text('리스크'), findsNothing);
    expect(find.textContaining('점'), findsNothing);
    expect(find.textContaining('Kakao'), findsNothing);
    expect(find.textContaining('Naver'), findsNothing);
    expect(find.text('지도앱'), findsNothing);
  });

  testWidgets('place search hides external source labels', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceSearchResults(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kakao'), findsNothing);
    expect(find.textContaining('Naver'), findsNothing);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.text('일정에 바로 등록하기'), findsWidgets);
    expect(find.text('후보에 추가하기'), findsWidgets);
  });

  testWidgets('route review date tabs can be selected from plan dates', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planItinerary(_groupId, _planId));
    await tester.pumpAndSettle();

    final dateTabs = find.byWidgetPredicate((widget) {
      return widget is Text &&
          RegExp(r'^\d{1,2}/\d{1,2} [월화수목금토일]$').hasMatch(widget.data ?? '');
    });
    expect(dateTabs, findsNWidgets(3));

    await tester.tap(dateTabs.at(1));
    await tester.pumpAndSettle();

    final secondTabText = tester.widget<Text>(dateTabs.at(1));

    expect(secondTabText.style?.color, AppColors.primaryPink);
    expect(find.text('6/8 일'), findsNothing);
  });

  testWidgets('group memory detail screen renders', (tester) async {
    await tester.pumpWidget(
      onmuTestProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: GroupMemoryDetailPage(
            groupId: _groupId.toString(),
            memoryId: _memoryId.toString(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(find.text('분위기 좋은 카페 발견! 디저트도 너무 맛있었어요.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('댓글 0'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('댓글 0'), findsOneWidget);
    expect(find.text('분위기 좋다! 어디야?'), findsNothing);
    expect(find.text('다음에 같이 가자!'), findsNothing);
  });

  testWidgets('group chat input sends a visible message', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupChat(_groupId));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '확인 메시지');
    await tester.tap(find.byTooltip('전송'));
    await tester.pumpAndSettle();

    expect(find.text('확인 메시지'), findsOneWidget);
  });

  testWidgets('group chat renders input without vote or settlement cards', (
    tester,
  ) async {
    final store = InMemoryOnmuStore.seeded();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            _NoAuxGroupRepository(store),
          ),
          settlementRepositoryProvider.overrideWithValue(
            TestSettlementRepository(store),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const GroupChatPage(groupId: '1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('메시지를 입력해보세요'), findsOneWidget);
    expect(find.text('투표 보기'), findsNothing);
    expect(find.text('정산 확인하기'), findsNothing);
  });

  testWidgets('group chat action launcher shows core actions', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupChat(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('채팅 액션'));
    await tester.pumpAndSettle();

    expect(find.text('사진 첨부'), findsOneWidget);
    expect(find.text('약속 만들기'), findsOneWidget);
    expect(find.text('장소 후보 찾기'), findsOneWidget);
    expect(find.text('투표 만들기'), findsOneWidget);
    expect(find.text('정산 시작'), findsOneWidget);
  });

  testWidgets('group chat action launcher opens plan create', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupChat(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('채팅 액션'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('약속 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('약속 이름'), findsOneWidget);
  });

  testWidgets('group chat action launcher opens place search', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupChat(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('채팅 액션'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('장소 후보 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('장소 검색하기'), findsOneWidget);
  });

  testWidgets('group chat vote notice opens vote detail', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupChat(_groupId));
    await tester.pumpAndSettle();

    expect(find.text('후보 보기'), findsNothing);
    expect(find.text('투표 보기'), findsOneWidget);

    await tester.tap(find.text('투표 보기'));
    await tester.pumpAndSettle();

    expect(find.text('제주도 여행 장소 투표'), findsOneWidget);
    expect(find.text('후보별 투표 현황'), findsOneWidget);
    expect(find.text('온무식당'), findsOneWidget);
    expect(find.text('민서님 선택'), findsOneWidget);
  });

  testWidgets('settlement create screen uses compact item cards', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planSettlementNew(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.text('약속 정산 만들기'), findsOneWidget);
    expect(find.text('저녁'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('카페'), 240);
    expect(find.text('카페'), findsOneWidget);
    expect(find.text('개별 금액'), findsOneWidget);
    expect(find.text('최종 정산 미리보기'), findsOneWidget);
    expect(find.textContaining('참여자별'), findsNothing);
  });

  testWidgets('settlement item card opens target selection screen', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planSettlementNew(_groupId, _planId));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('카페'), 240);
    await tester.tap(find.text('카페'));
    await tester.pumpAndSettle();

    expect(find.text('정산 대상자 선택'), findsOneWidget);
    expect(find.text('직접 선택'), findsWidgets);
    expect(find.text('금액 다르게'), findsOneWidget);
    expect(find.text('선택 4명 · 직접 선택'), findsOneWidget);
    expect(find.text('이 항목 대상자 저장'), findsOneWidget);
  });

  testWidgets('settlement preview can create final settlement', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planSettlementNew(_groupId, _planId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('최종 정산 미리보기'));
    await tester.pumpAndSettle();

    expect(find.text('정산 미리보기'), findsOneWidget);
    expect(find.text('정산 만들기'), findsOneWidget);

    await tester.tap(find.text('정산 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('약속 정산'), findsOneWidget);
    expect(find.text('약속 상세'), findsOneWidget);
  });

  testWidgets('group chat settlement card opens settlement result', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupChat(_groupId));
    await tester.pumpAndSettle();

    expect(find.text('ONMU 정산'), findsOneWidget);

    await tester.tap(find.text('정산 확인하기'));
    await tester.pumpAndSettle();

    expect(find.text('약속 정산'), findsOneWidget);
    expect(find.text('내 정산 결과'), findsOneWidget);
  });

  testWidgets('group chat settlement activity card opens specific settlement', (
    tester,
  ) async {
    final store = InMemoryOnmuStore.seeded();
    final settlementRepository = _TrackingWidgetSettlementRepository(store);

    appRouter.go(RoutePaths.splash);
    await tester.pumpWidget(
      onmuTestProviderScope(
        groupRepository: _SettlementActivityGroupRepository(store),
        settlementRepository: settlementRepository,
        child: const app.OnmuMaterialApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupChat(_groupId));
    await tester.pumpAndSettle();

    expect(find.text('제주도 여행 정산이 공유됐어요.'), findsOneWidget);

    await tester.tap(find.text('정산 확인하기'));
    await tester.pumpAndSettle();

    expect(settlementRepository.fetchLatestCalls, isZero);
    expect(settlementRepository.fetchByIdCalls, ['1/101/301']);
    expect(find.text('특정 정산'), findsOneWidget);
    expect(find.text('내 정산 결과'), findsOneWidget);
  });

  testWidgets('home notification page shows API notifications only', (
    tester,
  ) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.homeNotifications);
    await tester.pumpAndSettle();

    expect(find.text('장소 후보가 추가됐어요'), findsOneWidget);
    expect(find.text('알림이 없어요.'), findsNothing);
    expect(find.text('주말 나들이 정산이 만들어졌어요'), findsNothing);
    expect(find.text('약속 정산'), findsNothing);
  });

  testWidgets('group chat menu opens vote list', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupChat(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('채팅 메뉴'));
    await tester.pumpAndSettle();

    expect(find.text('투표 목록'), findsOneWidget);

    await tester.tap(find.text('투표 목록'));
    await tester.pumpAndSettle();

    expect(find.text('대학 동기 여행단 · 모임 투표'), findsOneWidget);
    expect(find.text('진행 중인 투표'), findsOneWidget);
    expect(find.text('제주도 여행 장소 투표'), findsOneWidget);
  });

  testWidgets('group vote list opens vote detail', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupVotes(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('투표 확인하기'));
    await tester.pumpAndSettle();

    expect(find.text('투표 보기'), findsOneWidget);
    expect(find.text('후보별 투표 현황'), findsOneWidget);
  });

  testWidgets('group vote list filter shows closed votes', (tester) async {
    await tester.pumpWidget(_testOnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupVotes(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('마감'));
    await tester.pumpAndSettle();

    expect(find.text('지난 투표'), findsOneWidget);
    expect(find.text('한강 피크닉 메뉴'), findsOneWidget);
    expect(find.text('보드게임 모임 장소'), findsOneWidget);
    expect(find.text('제주도 여행 장소 투표'), findsNothing);
  });
}

class _NoAuxGroupRepository extends TestGroupRepository {
  _NoAuxGroupRepository(super.store);

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async => null;

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async => [];

  @override
  Future<List<VoteSummary>> fetchVotes(
    Object groupId, {
    String? targetType,
    Object? targetId,
  }) async => [];
}

class _SettlementActivityGroupRepository extends _NoAuxGroupRepository {
  _SettlementActivityGroupRepository(super.store);

  @override
  Future<GroupMessagePage> fetchMessagePage(
    Object groupId, {
    String? beforeCursor,
    int? limit,
  }) async {
    return const GroupMessagePage(
      messages: [
        GroupMessage(
          id: 'activity-settlement-301',
          sender: 'ONMU',
          message: '제주도 여행 정산이 공유됐어요.',
          timeLabel: '14:10',
          isMine: false,
          messageType: 'settlement_card',
          cardType: 'settlement_card',
          targetType: 'PLAN',
          targetId: '101',
          planId: '101',
          settlementId: '301',
        ),
      ],
    );
  }
}

class _TrackingWidgetSettlementRepository extends TestSettlementRepository {
  _TrackingWidgetSettlementRepository(super.store);

  final fetchByIdCalls = <String>[];
  var fetchLatestCalls = 0;

  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) async {
    fetchLatestCalls += 1;
    return const SettlementSummary(
      id: '999',
      planTitle: '최신 정산',
      totalAmountLabel: '0원',
      createdDateLabel: '',
      itemCountLabel: '결제 항목 0개',
      finalSummaryLabel: '정산 없음',
      mySummaryLabel: '정산 없음',
      paymentItems: [],
      memberResults: [],
      transfers: [],
      shareMessage: '',
    );
  }

  @override
  Future<SettlementSummary> fetchSettlementById({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  }) async {
    fetchByIdCalls.add('$groupId/$planId/$settlementId');
    return const SettlementSummary(
      id: '301',
      planTitle: '특정 정산',
      totalAmountLabel: '42,000원',
      createdDateLabel: '',
      itemCountLabel: '결제 항목 1개',
      finalSummaryLabel: '1건 송금',
      mySummaryLabel: '나는 0원 정산',
      paymentItems: [],
      memberResults: [],
      transfers: [],
      shareMessage: '',
    );
  }
}

class _EmptyPlaceRepository implements PlaceRepository {
  const _EmptyPlaceRepository();

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<PlaceCandidate> fetchCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlaceCandidate> createCandidate({
    required Object groupId,
    required Object planId,
    required PlaceCandidate candidate,
  }) async => candidate;

  @override
  Future<SchedulePlace> createSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required String name,
    DateTime? startsAt,
    DateTime? endsAt,
    String note = '',
  }) async => SchedulePlace(
    id: '701',
    groupId: groupId.toString(),
    planId: planId.toString(),
    candidateId: candidateId.toString(),
    name: name,
    startsAt: startsAt,
    endsAt: endsAt,
    note: note,
    sortOrder: 1,
  );

  @override
  Future<SchedulePlace> updateSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
    DateTime? startsAt,
    DateTime? endsAt,
    String note = '',
  }) async => SchedulePlace(
    id: schedulePlaceId.toString(),
    groupId: groupId.toString(),
    planId: planId.toString(),
    candidateId: '',
    name: '수정 장소',
    startsAt: startsAt,
    endsAt: endsAt,
    note: note,
    sortOrder: 1,
  );

  @override
  Future<PlaceCandidate> setCandidateHeart({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required bool hearted,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
  }) async {}

  @override
  Future<List<PlaceCandidate>> searchPlaces({
    required Object groupId,
    required Object planId,
    required String query,
    String? category,
    double? lat,
    double? lng,
    int? radius,
  }) async => const [];

  @override
  Future<List<PlaceRisk>> fetchRisks({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<PlaceVoteResult> fetchVoteResult({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }
}

class _CandidatePlanRepository implements PlanRepository {
  const _CandidatePlanRepository();

  static const _plan = Plan(
    id: 101,
    title: '장소 후보 테스트',
    dateTime: '일정 미정',
    location: '성수동',
    status: 'draft',
    memo: '',
    members: [],
    timeCandidates: [],
    visitPlan: [],
  );

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return _plan;
  }

  @override
  Future<Plan> createPlan(PlanCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}

class _SingleMemberGroupRepository implements GroupRepository {
  static const _group = GroupSummary(
    id: 4,
    name: '서버 단일 멤버 모임',
    description: '실제 서버가 멤버 1명만 내려주는 상태',
    members: ['지우'],
    lastMessage: '',
    unreadCount: 0,
    pinnedPlanTitle: '',
  );

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async => _group;

  @override
  Future<GroupSummary> createGroup(GroupCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<GroupSummary> updateGroup({
    required Object groupId,
    required String name,
    required String description,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupSummary>> fetchGroups() async => const [_group];

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async => null;

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async => const [];

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async => const [
    GroupMemberProfile(name: '지우', note: '서버 멤버', statusLabel: '참여 중'),
  ];

  @override
  Future<GroupMemberProfile> addMember({
    required Object groupId,
    required String userId,
  }) async => GroupMemberProfile(
    userId: userId,
    name: '초대 친구',
    note: '멤버',
    statusLabel: '참여 중',
  );

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async =>
      const [];

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async => const [];

  @override
  Future<GroupMessagePage> fetchMessagePage(
    Object groupId, {
    String? beforeCursor,
    int? limit,
  }) async {
    return const GroupMessagePage(messages: []);
  }

  @override
  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
    List<GroupMessageAttachment> attachments = const [],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> markMessagesRead({
    required Object groupId,
    String? lastReadMessageId,
  }) async {
    return 0;
  }

  @override
  Stream<GroupMessage> watchMessages(Object groupId, {String? afterCursor}) {
    return Stream<GroupMessage>.multi((_) {});
  }

  @override
  Future<List<VoteSummary>> fetchVotes(
    Object groupId, {
    String? targetType,
    Object? targetId,
  }) async => const [];

  @override
  Future<VoteSummary> createVote(VoteCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VoteCard> submitVote({
    required Object groupId,
    required Object voteId,
    required Object optionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) {
    throw UnimplementedError();
  }
}

class _UserCodeFriendRepository implements FriendRepository {
  final _candidate = const FriendProfile(
    userId: '00000000-0000-0000-0000-000000000099',
    publicId: 'friend-code',
    userCode: '1234567890',
    name: 'Code Friend',
    preferenceSummary: '',
    isFriend: false,
    memo: '',
  );

  String? lastSearchQuery;
  String? addedPublicId;

  @override
  Future<List<FriendProfile>> fetchFriends() async => const [];

  @override
  Future<List<FriendProfile>> searchFriends(String query) async {
    lastSearchQuery = query;
    return query.trim() == _candidate.userCode ? [_candidate] : const [];
  }

  @override
  Future<MyProfile> fetchFriendProfile(FriendProfile friend) async {
    return MyProfile(
      realName: friend.name,
      visibility: ProfileVisibility.friends,
      favoriteKeywords: const [],
      dislikedKeywords: const [],
      preferredTimes: const [],
      availableDays: const [],
      unavailableDates: const [],
      favoritePlaces: const [],
      wantToGoPlaces: const [],
      dislikedPlaces: const [],
    );
  }

  @override
  Future<FriendProfile> addFriend(String publicId, {String? memo}) async {
    addedPublicId = publicId;
    return _candidate.copyWith(isFriend: true, memo: memo);
  }

  @override
  Future<FriendProfile> updateFriend(
    FriendProfile friend, {
    String? memo,
    bool? favorite,
  }) async {
    return friend.copyWith(memo: memo, isFavorite: favorite);
  }

  @override
  Future<void> deleteFriend(FriendProfile friend) async {}
}
