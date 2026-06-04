import 'package:flutter/material.dart';

import '../../shared/models/preference_profile.dart';
import '../../shared/onmu_design.dart';
import 'preference_flow_widgets.dart';
import 'preference_food_page.dart';

class PreferenceIntroPage extends StatelessWidget {
  final PreferenceProfile profile;

  const PreferenceIntroPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return PreferencePageFrame(
      currentStep: 1,
      stepCount: 5,
      title: '취향을 알려주세요',
      buttonLabel: '시작하기',
      onNext: () => pushOnmuPage(context, PreferenceFoodPage(profile: profile)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnmuCharacterHero(),
          SizedBox(height: 24),
          PaperNote(
            title: '간단한 취향만 조사할게요.',
            body: '음식, 장소 분위기, 약속 스타일과 선호하는 약속 요일 및 시간대를 저장해요. 수정 가능합니다.',
            icon: Icons.tune,
          ),
        ],
      ),
    );
  }
}
