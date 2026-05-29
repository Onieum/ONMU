import 'package:flutter/material.dart';

/// ONMU 하단 탭 내비게이션
///
/// 탭 구성 (v2 계획서 섹션 6 기준):
///   0 홈     /home     features/home
///   1 약속   /meetups  features/meetup
///   2 온챗   /onchat   features/onchat
///   3 기록   /ootd     features/ootd, features/memory
///   4 마이   /my       features/my, features/preferences
///
/// 색상은 docs/design/DESIGN.md 토큰을 따른다.
///   활성:   primary.purple #8B5CF6
///   비활성: text.muted     #A9948A
///   구분선: line.soft      #EAD8CC
class OnmuBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const OnmuBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // DESIGN.md 토큰
  static const _purple   = Color(0xFF8B5CF6); // primary.purple
  static const _muted    = Color(0xFFA9948A); // text.muted
  static const _lineSoft = Color(0xFFEAD8CC); // line.soft
  static const _bgWhite  = Color(0xFFFFFFFF); // bg.default

  static const _items = [
    _NavItem(label: '홈',  outlined: Icons.home_outlined,            filled: Icons.home),
    _NavItem(label: '약속', outlined: Icons.calendar_today_outlined,  filled: Icons.calendar_today),
    _NavItem(label: '온챗', outlined: Icons.chat_bubble_outline,      filled: Icons.chat_bubble),
    _NavItem(label: '기록', outlined: Icons.menu_book_outlined,       filled: Icons.menu_book),
    _NavItem(label: '마이', outlined: Icons.person_outline,           filled: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bgWhite,
        border: Border(
          top: BorderSide(color: _lineSoft, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = i == currentIndex;
              final item = _items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.filled : item.outlined,
                        color: selected ? _purple : _muted,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? _purple : _muted,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData outlined;
  final IconData filled;
  const _NavItem({required this.label, required this.outlined, required this.filled});
}
