import 'package:flutter/material.dart';

import '../../main_shell.dart';
import '../../shared/models/preference_profile.dart';
import '../../shared/onmu_design.dart';
import 'preference_flow_widgets.dart';

class PreferenceSummaryPage extends StatelessWidget {
  final PreferenceProfile profile;

  const PreferenceSummaryPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return PreferencePageFrame(
      currentStep: 6,
      stepCount: 6,
      title: '취향 입력이 끝났어요',
      buttonLabel: '홈으로 가기',
      onNext: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const MainShell()),
          (_) => false,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnmuCharacterHero(compact: true),
          const SizedBox(height: 20),
          _SummaryCard(
            title: '선호 음식/메뉴',
            values: [
              ...profile.favoriteFoodTags,
              if (profile.otherFavoriteFood.trim().isNotEmpty)
                profile.otherFavoriteFood.trim(),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryCard(
            title: '비선호 음식/메뉴',
            values: [
              ...profile.dislikedFoodTags,
              if (profile.otherDislikedFood.trim().isNotEmpty)
                profile.otherDislikedFood.trim(),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryCard(
            title: '선호 장소/분위기',
            values: [
              ...profile.favoritePlaceTags,
              if (profile.otherFavoritePlace.trim().isNotEmpty)
                profile.otherFavoritePlace.trim(),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryCard(
            title: '비선호 장소/분위기',
            values: [
              ...profile.dislikedPlaceTags,
              if (profile.otherDislikedPlace.trim().isNotEmpty)
                profile.otherDislikedPlace.trim(),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryCard(title: '약속 스타일', values: profile.meetupStyles),
          const SizedBox(height: 10),
          _SummaryCard(title: '선호 시간대', values: profile.preferredTimes),
          const SizedBox(height: 10),
          _SummaryCard(
            title: '이번 주 불가능한 요일',
            values: profile.unavailableWeekdays,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<String> values;

  const _SummaryCard({required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OnmuColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OnmuColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: OnmuColors.textSub,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            values.isEmpty ? '선택 안 함' : values.join(', '),
            style: const TextStyle(
              color: OnmuColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
