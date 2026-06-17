import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/preference_profile.dart';
import '../../shared/widgets/onmu_button.dart';
import '../../shared/widgets/onmu_character_hero.dart';
import '../../shared/widgets/onmu_paper_note.dart';
import '../preferences/presentation/pages/preference_intro_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ONMU',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.primaryPurple,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '오늘의 약속과 취향을\n귀여운 기록으로 연결해요',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textMain,
                  height: 1.22,
                ),
              ),
              SizedBox(height: 20),
              Expanded(child: OnmuCharacterHero()),
              SizedBox(height: 20),
              const OnmuPaperNote(
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
