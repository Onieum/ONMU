import 'package:flutter/material.dart';

import '../../shared/models/preference_profile.dart';
import '../../shared/onmu_design.dart';
import '../preferences/preference_intro_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnmuColors.bgDefault,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ONMU',
                style: AppTextStyles.displayMedium.copyWith(
                  color: OnmuColors.purple,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '오늘의 약속과 취향을\n귀여운 기록으로 연결해요',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: OnmuColors.textMain,
                  height: 1.22,
                ),
              ),
              SizedBox(height: 20),
              Expanded(child: OnmuCharacterHero()),
              SizedBox(height: 20),
              const PaperNote(
                title: '처음 시작하기 전에',
                body: '음식, 장소, 약속 스타일을 먼저 담아두면 추천 흐름이 더 자연스러워져요.',
                icon: Icons.favorite_border,
              ),
              SizedBox(height: 16),
              OnmuPrimaryButton(
                label: '취향 입력 시작하기',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PreferenceIntroPage(
                        profile: PreferenceProfile.empty(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
