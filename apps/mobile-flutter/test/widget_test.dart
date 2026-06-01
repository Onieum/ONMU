import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/app/onmu_app.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/meetup/presentation/pages/meetup_complete_page.dart';
import 'package:onmu_mobile/features/meetup/presentation/pages/meetup_member_select_page.dart';

void main() {
  testWidgets('renders integrated mobile shell', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    expect(find.text('안녕하세요, 지우님'), findsOneWidget);
    expect(find.text('진행 중인 약속'), findsOneWidget);
    expect(find.text('홈'), findsWidgets);
    expect(find.text('약속'), findsWidgets);
    expect(find.text('온챗'), findsWidgets);
    expect(find.text('기록'), findsWidgets);
    expect(find.text('마이'), findsWidgets);
  });

  testWidgets('기존 하단 마이 탭에서 마이페이지가 열린다', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();

    expect(find.text('김온무'), findsOneWidget);
    expect(find.text('프로필 수정'), findsOneWidget);
    expect(find.text('선호 키워드'), findsOneWidget);
    expect(find.text('좋아하는 장소'), findsOneWidget);
  });

  testWidgets('마이페이지 친구 탭에서 친구 추가를 할 수 있다', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('친구').first);
    await tester.pumpAndSettle();

    expect(find.text('최민준'), findsOneWidget);
    expect(find.text('이지수'), findsNothing);

    await tester.tap(find.text('친구 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '지수');
    await tester.pumpAndSettle();

    expect(find.text('이지수'), findsOneWidget);
    await tester.tap(find.text('추가하기'));
    await tester.pumpAndSettle();

    expect(find.text('이지수'), findsOneWidget);
    expect(find.text('추가하기'), findsNothing);
  });

  testWidgets('마이페이지 친구 탭에서 친구 메모를 저장할 수 있다', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('친구').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('최민준 메모 편집'));
    await tester.pumpAndSettle();

    expect(find.text('친구 메모'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).last).maxLength, 30);

    await tester.enterText(find.byType(EditableText).last, '전시 전에 조용한 카페 선호');
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('전시 전에 조용한 카페 선호'), findsOneWidget);
    expect(find.text('조용한 밥집과 전시 약속을 선호해요'), findsOneWidget);
  });

  testWidgets('약속 참여자 선택 화면에서 약속 이름 입력 진입점을 보이지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const MeetupMemberSelectPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('참여자 선택'), findsOneWidget);
    expect(find.text('약속 이름 입력'), findsNothing);
    expect(find.text('자동 이름 생성'), findsNothing);
    expect(find.text('다음 단계로'), findsOneWidget);
  });

  testWidgets('약속 완료 화면에서 자동 생성된 약속 이름을 수정할 수 있다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const MeetupCompletePage(meetupId: 'weekend-outing'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('주말 나들이'), findsNothing);
    expect(find.text('5월 26일 (일) · 오후 1:00 · 지영, 민수, 하린'), findsOneWidget);

    await tester.tap(find.byTooltip('약속 이름 수정'));
    await tester.pumpAndSettle();

    expect(find.text('약속 이름 수정'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).last, '성수 산책 모임');
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('성수 산책 모임'), findsOneWidget);
  });

  testWidgets('날짜 시간 선택 화면에서 캘린더 보기 페이지로 이동할 수 있다', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('약속').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('약속 만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음 단계로'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('캘린더 보기'));
    await tester.pumpAndSettle();

    expect(find.text('약속 캘린더'), findsOneWidget);
    expect(find.text('5월 2026'), findsOneWidget);
    expect(find.text('선택 완료'), findsOneWidget);
  });

  testWidgets('장소 선택 이후 약속 완료 화면으로 이동해 자동 생성 이름을 확인할 수 있다', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('약속').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('약속 만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음 단계로'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('장소 선택'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+ 후보 비교'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('온무식당 선택하기'));
    await tester.pumpAndSettle();

    expect(find.text('동선 확인'), findsOneWidget);
    await tester.tap(find.text('약속 완료'));
    await tester.pumpAndSettle();

    expect(find.text('약속 만들기 완료!'), findsOneWidget);
    expect(find.text('5월 26일 (일) · 오후 1:00 · 지영, 민수, 하린'), findsOneWidget);
  });

  testWidgets('불가능한 날짜는 달력에서 여러 날짜를 선택할 수 있다', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();

    final unavailableSection = find.ancestor(
      of: find.text('불가능한 날짜'),
      matching: find.byType(Column),
    );
    await tester.tap(
      find.descendant(of: unavailableSection.first, matching: find.text('수정')),
    );
    await tester.pumpAndSettle();

    expect(find.text('불가능한 날짜 선택'), findsOneWidget);
    expect(find.text('6월 2026'), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.tap(find.text('22'));
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('6월 15일'), findsOneWidget);
    expect(find.text('6월 22일'), findsOneWidget);
  });

  testWidgets('가능 요일은 요일 버튼으로 여러 개 선택할 수 있다', (tester) async {
    await tester.pumpWidget(const OnmuApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    final availableSection = find.ancestor(
      of: find.text('가능 요일'),
      matching: find.byType(Column),
    );
    await tester.tap(
      find.descendant(of: availableSection.first, matching: find.text('수정')),
    );
    await tester.pumpAndSettle();

    expect(find.text('가능 요일 선택'), findsOneWidget);
    await tester.tap(find.text('월'));
    await tester.tap(find.text('금'));
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('월'), findsOneWidget);
    expect(find.text('금'), findsOneWidget);
  });
}
