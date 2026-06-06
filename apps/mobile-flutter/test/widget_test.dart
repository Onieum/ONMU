import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:onmu_mobile/app/onmu_app.dart';
import 'package:onmu_mobile/core/routing/app_router.dart';
import 'package:onmu_mobile/core/routing/route_paths.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/home/home_page.dart';
import 'package:onmu_mobile/features/group/presentation/pages/group_memory_detail_page.dart';

const _groupId = 1;
const _planId = 101;
const _candidateId = 201;
const _memoryId = 1001;

void main() {
  testWidgets('starts with splash and opens login', (tester) async {
    await tester.pumpWidget(const app.OnmuApp());

    expect(find.text('약속을 잡고,\n함께한 순간을 기록해요'), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('구글로 시작하기'), findsOneWidget);
    expect(find.text('네이버로 시작하기'), findsOneWidget);
  });

  testWidgets('mock login opens onboarding and skip flow enters home', (
    tester,
  ) async {
    await tester.pumpWidget(const app.OnmuApp());

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

    expect(find.text('안녕하세요, 지우님'), findsOneWidget);
    expect(find.text('진행 중인 약속'), findsOneWidget);
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
    await tester.pumpWidget(const OnmuApp());
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

    await tester.enterText(find.byType(TextField), '테스트 캐릭터');
    await tester.tap(find.widgetWithText(ElevatedButton, '다음'));
    await tester.pumpAndSettle();

    expect(find.text('꾸미기 완료!'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '첫 설정 페이지로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.text('캐릭터 만들기'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    expect(find.text('다시 설정'), findsOneWidget);
  });

  testWidgets('onboarding saves preference completion from preference flow', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
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
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planNew(_groupId));
    await tester.pumpAndSettle();

    expect(find.text('약속 만들기'), findsWidgets);
    expect(find.text('약속 이름'), findsOneWidget);
    expect(find.text('참여 멤버'), findsOneWidget);
    expect(find.text('참여자 선택'), findsNothing);
  });

  testWidgets('home plan cards open plan detail when tapped', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.home);
    await tester.pumpAndSettle();

    expect(find.text('상세 보기'), findsNothing);

    await tester.tap(find.text('제주도 여행').first);
    await tester.pumpAndSettle();

    expect(find.text('제주도 여행'), findsOneWidget);
    expect(find.text('후보 리스트 보기'), findsOneWidget);
  });

  testWidgets(
    'home header shows ONMU logo and active card fits compact width',
    (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      await binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.lightTheme, home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ONMU'), findsOneWidget);
      expect(find.text('상세 보기'), findsNothing);
      expect(find.text('채팅'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('upcoming plan see all opens the full upcoming list', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.home);
    await tester.pumpAndSettle();

    await tester.tap(find.text('전체 보기').first);
    await tester.pumpAndSettle();

    expect(find.text('다가오는 약속'), findsOneWidget);
    expect(find.text('제주도 여행'), findsOneWidget);
    expect(find.text('한남 카페 투어'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('홍대 전시회 구경'), 320);
    expect(find.text('홍대 전시회 구경'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('성수 디저트 모임'), 320);
    expect(find.text('성수 디저트 모임'), findsOneWidget);
  });

  testWidgets('home notification bell opens stacked notifications', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.home);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('알림'));
    await tester.pumpAndSettle();

    expect(find.text('알림'), findsOneWidget);
    expect(find.text('성수 저녁 약속이 30분 뒤 시작돼요'), findsOneWidget);
    expect(find.text('투표 확인하기'), findsOneWidget);
  });

  testWidgets('home recent records see all opens record grid', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.home);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('최근 기록'), 320);
    await tester.pumpAndSettle();

    await tester.tap(find.text('전체 보기').last);
    await tester.pumpAndSettle();

    expect(find.text('최근 기록'), findsOneWidget);
    expect(find.text('성수동 카페'), findsWidgets);
    expect(find.text('제주 바다'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('기록 카드 만들기'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('기록 카드 만들기'), findsOneWidget);
  });

  testWidgets('group home uses create plan fab only', (tester) async {
    await tester.pumpWidget(const OnmuApp());
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

  testWidgets('group home create fab opens plan creation', (tester) async {
    await tester.pumpWidget(const OnmuApp());
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
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupDetail(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('전체 보기').first);
    await tester.pumpAndSettle();

    expect(find.text('약속'), findsOneWidget);
    expect(find.text('모임 약속 검색'), findsOneWidget);

    await tester.tap(find.text('제주도 여행').first);
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
    await tester.pumpWidget(const OnmuApp());
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

  testWidgets('group home member count opens member list', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupDetail(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('멤버 8명'));
    await tester.pumpAndSettle();

    expect(find.text('모임원'), findsOneWidget);
    expect(find.text('대학 동기 여행단 · 8명'), findsOneWidget);
    expect(find.text('멤버 검색'), findsOneWidget);
  });

  testWidgets('group home upcoming see all opens plan list', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupDetail(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('전체 보기').first);
    await tester.pumpAndSettle();

    expect(find.text('약속'), findsOneWidget);
    expect(find.text('모임 약속 검색'), findsOneWidget);
    expect(find.text('다가오는 약속'), findsOneWidget);
  });

  testWidgets('plan itinerary date tabs can be selected', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planItinerary(_groupId, _planId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('6/8 일'));
    await tester.pumpAndSettle();

    final secondTabText = tester.widget<Text>(find.text('6/8 일'));

    expect(secondTabText.style?.color, AppColors.primaryPink);
    expect(find.text('장소 동선'), findsOneWidget);
  });

  testWidgets('draft plan can open the shared candidate list', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planDetail(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.text('장소 검색하기'), findsOneWidget);
    expect(find.text('후보 리스트 보기'), findsOneWidget);
    expect(find.text('제주도 일대'), findsOneWidget);
    expect(find.text('6.7 (금) 오전 10:00'), findsNothing);
    expect(find.text('일정이 없어요'), findsNothing);
    expect(find.text('일정 타임라인'), findsOneWidget);
    expect(find.text('다운타우너 성수'), findsOneWidget);

    await tester.tap(find.text('6/8 일'));
    await tester.pumpAndSettle();

    expect(find.text('협재 해수욕장'), findsOneWidget);
    expect(find.text('다운타우너 성수'), findsNothing);

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

  testWidgets('plan detail more menu opens edit flow', (tester) async {
    await tester.pumpWidget(const OnmuApp());
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
  });

  testWidgets('canonical group and plan routes open operating screens', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
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

    expect(find.text('장소 동선'), findsOneWidget);
  });

  testWidgets('place candidate list is plan-scoped and supports actions', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('place vote creation screen opens from candidate list', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceCandidates(_groupId, _planId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('투표 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('투표 만들기'), findsWidgets);
    expect(find.text('제주도 여행 장소 투표'), findsOneWidget);
    expect(find.text('단일 선택'), findsOneWidget);
    expect(find.text('중복 선택'), findsOneWidget);
    expect(find.text('마감 날짜'), findsOneWidget);
    expect(find.text('마감 시간'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '투표 만들기').last);
    await tester.pumpAndSettle();

    expect(find.text('투표 보기'), findsOneWidget);
    expect(find.text('후보별 투표 현황'), findsOneWidget);
    expect(find.text('온무식당'), findsOneWidget);
  });

  testWidgets('place map actions show confirmation without navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceSearch(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.text('후보에 추가'), findsWidgets);
    expect(find.text('일정에 추가'), findsWidgets);
    expect(find.text('후보에 추가하기'), findsNothing);
    expect(find.text('일정에 바로 등록하기'), findsNothing);

    final candidateButtonRect = tester.getRect(
      find.byKey(const ValueKey('place-action-201-candidate')),
    );
    final scheduleButtonRect = tester.getRect(
      find.byKey(const ValueKey('place-action-201-schedule')),
    );
    expect(candidateButtonRect.size, scheduleButtonRect.size);

    await tester.tap(find.text('후보에 추가').first);
    await tester.pumpAndSettle();

    expect(find.text('후보에 추가되었어요!'), findsOneWidget);
    expect(find.text('후보 리스트 보러가기'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('장소 검색하기'), findsOneWidget);
    expect(find.text('장소 후보 리스트'), findsNothing);

    await tester.tap(find.text('일정에 추가').first);
    await tester.pumpAndSettle();

    expect(find.text('일정에 등록되었어요!'), findsOneWidget);
    expect(find.text('일정 보러가기'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('장소 검색하기'), findsOneWidget);
    expect(find.text('일정 타임라인'), findsNothing);
  });

  testWidgets('place map confirmation ctas navigate to target pages', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceSearch(_groupId, _planId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('후보에 추가').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('후보 리스트 보러가기'));
    await tester.pumpAndSettle();

    expect(find.text('장소 후보 리스트'), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('장소 검색하기'), findsOneWidget);

    appRouter.go(RoutePaths.planPlaceSearch(_groupId, _planId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('일정에 추가').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('일정 보러가기'));
    await tester.pumpAndSettle();

    expect(find.text('장소 동선'), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('장소 검색하기'), findsOneWidget);
  });

  testWidgets(
    'place map recommendation card opens detail sheet and focuses map',
    (tester) async {
      await tester.pumpWidget(const OnmuApp());
      await tester.pumpAndSettle(const Duration(milliseconds: 5000));

      appRouter.go(RoutePaths.planPlaceSearch(_groupId, _planId));
      await tester.pumpAndSettle();

      await tester.tap(find.text('온무식당'));
      await tester.pumpAndSettle();

      expect(find.text('장소 검색하기'), findsOneWidget);
      expect(find.text('장소 상세'), findsWidgets);
      expect(find.text('리뷰 키워드'), findsOneWidget);
      expect(find.text('참여자 선호'), findsOneWidget);
      expect(find.byKey(const ValueKey('focused-place-pin-1')), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('place-map-bottom-sheet')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      final sheetRect = tester.getRect(
        find.byKey(const ValueKey('place-map-bottom-sheet')),
      );
      expect(sheetRect.top, lessThan(90));
    },
  );

  testWidgets('place map search stays on map and shows sheet results', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
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
    expect(find.text('검색 결과'), findsOneWidget);
    expect(find.text('지도 화면에서 이어서 장소를 찾아요'), findsNothing);
    expect(find.bySemanticsLabel('온무식당 대표 사진'), findsOneWidget);
    expect(find.text('후보에 추가'), findsWidgets);
    expect(find.text('일정에 추가'), findsWidgets);
  });

  testWidgets('place map category pills filter sheet results', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceSearch(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.text('전체'), findsOneWidget);
    expect(find.text('한식'), findsWidgets);
    expect(find.text('카페'), findsOneWidget);
    expect(find.text('전시'), findsOneWidget);
    expect(find.text('술집'), findsOneWidget);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('place-category-pill-전체')))
          .height,
      30,
    );
    final allCategoryText = tester.widget<Text>(find.text('전체'));
    expect(allCategoryText.style?.height, 1);

    await tester.tap(find.text('카페'));
    await tester.pumpAndSettle();

    expect(find.text('검색 결과'), findsOneWidget);
    expect(find.text('무드카페'), findsOneWidget);
    expect(find.text('온무식당'), findsNothing);
  });

  testWidgets('place map back returns to the previous screen', (tester) async {
    await tester.pumpWidget(const OnmuApp());
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
    await tester.pumpWidget(const OnmuApp());
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
    await tester.pumpWidget(const OnmuApp());
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
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planPlaceSearchResults(_groupId, _planId));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kakao'), findsNothing);
    expect(find.textContaining('Naver'), findsNothing);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.text('일정에 바로 등록하기'), findsWidgets);
    expect(find.text('후보에 추가하기'), findsWidgets);
  });

  testWidgets('route review date tabs can be selected', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.planItinerary(_groupId, _planId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('6/8 일'));
    await tester.pumpAndSettle();

    final secondTabText = tester.widget<Text>(find.text('6/8 일'));

    expect(secondTabText.style?.color, AppColors.primaryPink);
  });

  testWidgets('group memory detail screen renders', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
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
  });

  testWidgets('group chat input sends a visible message', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupChat(_groupId));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '확인 메시지');
    await tester.tap(find.byTooltip('전송'));
    await tester.pumpAndSettle();

    expect(find.text('확인 메시지'), findsOneWidget);
  });

  testWidgets('group chat vote notice opens vote detail', (tester) async {
    await tester.pumpWidget(const OnmuApp());
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
    await tester.pumpWidget(const OnmuApp());
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
    await tester.pumpWidget(const OnmuApp());
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
    await tester.pumpWidget(const OnmuApp());
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
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupChat(_groupId));
    await tester.pumpAndSettle();

    expect(find.text('ONMU 정산'), findsOneWidget);

    await tester.tap(find.text('정산 확인하기'));
    await tester.pumpAndSettle();

    expect(find.text('약속 정산'), findsOneWidget);
    expect(find.text('내 정산 결과'), findsOneWidget);
  });

  testWidgets('home notification settlement card opens settlement result', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.homeNotifications);
    await tester.pumpAndSettle();

    expect(find.text('정산'), findsWidgets);
    expect(find.text('주말 나들이 정산이 만들어졌어요'), findsOneWidget);

    await tester.ensureVisible(find.text('주말 나들이 정산이 만들어졌어요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주말 나들이 정산이 만들어졌어요'));
    await tester.pumpAndSettle();

    expect(find.text('약속 정산'), findsOneWidget);
    expect(find.text('내 정산 결과'), findsOneWidget);
  });

  testWidgets('group chat menu opens vote list', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupChat(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('채팅 메뉴'));
    await tester.pumpAndSettle();

    expect(find.text('투표 목록'), findsOneWidget);

    await tester.tap(find.text('투표 목록'));
    await tester.pumpAndSettle();

    expect(find.text('대학 동기 여행단 · 채팅에서 만든 투표'), findsOneWidget);
    expect(find.text('진행 중인 투표'), findsOneWidget);
    expect(find.text('제주도 여행 장소 투표'), findsOneWidget);
  });

  testWidgets('group vote list opens vote detail', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.groupVotes(_groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('투표 확인하기'));
    await tester.pumpAndSettle();

    expect(find.text('투표 보기'), findsOneWidget);
    expect(find.text('후보별 투표 현황'), findsOneWidget);
  });

  testWidgets('group vote list filter shows closed votes', (tester) async {
    await tester.pumpWidget(const OnmuApp());
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
