import 'package:flutter/material.dart';

import '../../shared/onmu_design.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: OnmuColors.bgDefault,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 26, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ONMU',
                style: TextStyle(
                  color: OnmuColors.purple,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 14),
              Text(
                '오늘 약속 추천을\n취향 기준으로 준비했어요',
                style: TextStyle(
                  color: OnmuColors.textMain,
                  fontSize: 27,
                  height: 1.22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 24),
              PaperNote(
                title: '취향 프로필 연결 완료',
                body: '좋아하는 메뉴, 피하고 싶은 조건, 편한 시간이 추천 카드에 반영됩니다.',
                icon: Icons.check_circle_outline,
              ),
              SizedBox(height: 12),
              PaperNote(
                title: '다음 작업 연결 지점',
                body: '약속 만들기와 장소 추천 화면에서 PreferenceProfile mock 데이터를 붙이면 됩니다.',
                icon: Icons.route_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
