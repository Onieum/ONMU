import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_paths.dart';
import '../../shared/models/preference_profile.dart';
import '../../shared/onmu_design.dart';
import 'preference_flow_widgets.dart';
import 'preference_food_page.dart';

class PreferenceIntroPage extends StatelessWidget {
  final PreferenceProfile profile;

  const PreferenceIntroPage({super.key, required this.profile});

  static const _selectImageAsset = 'assets/images/splash/preference_survey.png';

  @override
  Widget build(BuildContext context) {
    return PreferencePageFrame(
      currentStep: 1,
      stepCount: 5,
      title: '취향을 알려주세요',
      subtitle: '나에게 딱 맞는 추천을 위해\n몇 가지를 물어볼게요!',
      titleAlign: TextAlign.center,
      buttonLabel: '시작하기',
      onReturnToStart: () => context.go(RoutePaths.onboarding),
      onNext: () => pushOnmuPage(context, PreferenceFoodPage(profile: profile)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PreferenceIntroImage(assetPath: _selectImageAsset),
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

class _PreferenceIntroImage extends StatelessWidget {
  const _PreferenceIntroImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
