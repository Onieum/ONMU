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
      stepCount: 6,
      title: '취향을 알려주세요',
      buttonLabel: '시작하기',
      onNext: () => pushOnmuPage(context, PreferenceFoodPage(profile: profile)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnmuCharacterHero(),
          SizedBox(height: 22),
          PaperNote(
            title: '약속 추천을 위한 간단한 조사',
            body: '음식, 장소 분위기, 약속 스타일, 시간대, 불가능한 요일을 mock state로만 담아둘게요.',
            icon: Icons.tune,
          ),
          SizedBox(height: 12),
          PaperNote(
            title: '지금은 Smoke Flow',
            body: '백엔드 저장 없이 화면 이동과 선택 상태 유지가 자연스럽게 보이는 데 집중합니다.',
            icon: Icons.route_outlined,
          ),
        ],
      ),
    );
  }
}
