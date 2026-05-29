import 'package:flutter/material.dart';
import 'shared/widgets/onmu_bottom_nav_bar.dart';
import 'features/home/home_page.dart';
import 'features/meetup/meetup_list_page.dart';
import 'features/onchat/onchat_list_page.dart';
import 'features/ootd/ootd_list_page.dart';
import 'features/my/my_page.dart';

/// 앱 전체 탭 Shell
///
/// 하단 탭 구성 (mobile-prototype-weekend-plan.md 섹션 6):
///   0 홈     /home         features/home
///   1 약속   /meetups      features/meetup
///   2 온챗   /onchat       features/onchat
///   3 기록   /ootd/list    features/ootd + features/memory
///   4 마이   /my           features/my + features/preferences
///
/// 각 담당자는 자기 features/* 안에서만 화면을 확장한다.
/// 공통 위젯(OnmuBottomNavBar 등)을 바꿔야 하면 팀에 먼저 공유한다.
///
/// go_router StatefulShellRoute 전환 준비:
///   pubspec.yaml에 go_router가 추가되어 있다.
///   월요일 통합 시 core/routing/app_router.dart로 라우팅을 분리한다.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    HomePage(),        // 0 홈     — TODO(홈팀)
    MeetupListPage(),  // 1 약속   — TODO(약속팀)
    OnChatListPage(),  // 2 온챗   — TODO(온챗팀)
    OotdListPage(),    // 3 기록   — TODO(기록팀)
    MyPage(),          // 4 마이   — TODO(마이팀)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // bg.default
      body: _pages[_currentIndex],
      bottomNavigationBar: OnmuBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
