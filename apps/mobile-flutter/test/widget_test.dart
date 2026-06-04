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
    expect(find.text('약속 만들기'), findsNothing);
    expect(find.text('전체 보기'), findsOneWidget);
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

  testWidgets('home meetup cards open meetup detail when tapped', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.home);
    await tester.pumpAndSettle();

    expect(find.text('상세 보기'), findsNothing);

    await tester.tap(find.text('성수 저녁 약속'));
    await tester.pumpAndSettle();

    expect(find.text('제주도 여행'), findsOneWidget);
    expect(find.text('후보 리스트 보기'), findsOneWidget);
  });

  testWidgets('upcoming meetup see all opens the full upcoming list', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.home);
    await tester.pumpAndSettle();

    await tester.tap(find.text('전체 보기').first);
    await tester.pumpAndSettle();

    expect(find.text('다가오는 약속 전체'), findsOneWidget);
    expect(find.text('한남 카페 투어'), findsOneWidget);
    expect(find.text('홍대 전시회 구경'), findsOneWidget);
    expect(find.text('북촌 소품샵 산책'), findsOneWidget);
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

  testWidgets('draft meetup can open the shared candidate list', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.onmoimMeetupDetail('friends', 'demo'));
    await tester.pumpAndSettle();

    expect(find.text('장소 검색하기'), findsOneWidget);
    expect(find.text('후보 리스트 보기'), findsOneWidget);

    await tester.tap(find.text('후보 리스트 보기'));
    await tester.pumpAndSettle();

    expect(find.text('장소 후보 리스트'), findsOneWidget);
  });

  testWidgets('confirmed meetup still exposes the shared candidate list', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(
      '${RoutePaths.onmoimMeetupDetail('friends', 'demo')}?place=confirmed',
    );
    await tester.pumpAndSettle();

    expect(find.text('후보 리스트 보기'), findsOneWidget);
  });

  testWidgets('place candidate list is meetup-scoped and supports actions', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.onmoimMeetupPlaces('friends', 'demo'));
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

    appRouter.go(RoutePaths.onmoimMeetupPlaces('friends', 'demo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('투표 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('투표 만들기'), findsWidgets);
    expect(find.text('제주도 여행 장소 투표'), findsOneWidget);
    expect(find.text('단일 선택'), findsOneWidget);
    expect(find.text('중복 선택'), findsOneWidget);
    expect(find.text('마감 날짜'), findsOneWidget);
    expect(find.text('마감 시간'), findsOneWidget);
  });

  testWidgets('place map actions show confirmation without navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    appRouter.go(RoutePaths.onmoimMeetupPlaceMap('friends', 'demo'));
    await tester.pumpAndSettle();

    expect(find.text('후보에 추가'), findsWidgets);
    expect(find.text('일정에 추가'), findsWidgets);
    expect(find.text('후보에 추가하기'), findsNothing);
    expect(find.text('일정에 바로 등록하기'), findsNothing);

    final candidateButtonRect = tester.getRect(
      find.byKey(const ValueKey('place-action-onmu-diner-candidate')),
    );
    final scheduleButtonRect = tester.getRect(
      find.byKey(const ValueKey('place-action-onmu-diner-schedule')),
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

    appRouter.go(RoutePaths.onmoimMeetupPlaceMap('friends', 'demo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('후보에 추가').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('후보 리스트 보러가기'));
    await tester.pumpAndSettle();

    expect(find.text('장소 후보 리스트'), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('장소 검색하기'), findsOneWidget);

    appRouter.go(RoutePaths.onmoimMeetupPlaceMap('friends', 'demo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('일정에 추가').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('일정 보러가기'));
    await tester.pumpAndSettle();

    expect(find.text('제주도 여행'), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('장소 검색하기'), findsOneWidget);
  });

  testWidgets(
    'place map recommendation card opens detail sheet and focuses map',
    (tester) async {
      await tester.pumpWidget(const OnmuApp());
      await tester.pumpAndSettle(const Duration(milliseconds: 5000));

      appRouter.go(RoutePaths.onmoimMeetupPlaceMap('friends', 'demo'));
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

    appRouter.go(RoutePaths.onmoimMeetupPlaceMap('friends', 'demo'));
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

    appRouter.go(RoutePaths.onmoimMeetupPlaceMap('friends', 'demo'));
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

    appRouter.go(RoutePaths.onmoimMeetupPlaces('friends', 'demo'));
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

    appRouter.go(RoutePaths.onmoimMeetupPlaces('friends', 'demo'));
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
      RoutePaths.onmoimMeetupPlaceDetail('friends', 'demo', 'onmu-diner'),
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

    appRouter.go(RoutePaths.onmoimMeetupPlaceSearch('friends', 'demo'));
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
