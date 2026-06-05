import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_paths.dart';
import '../../core/theme/app_radius.dart';
import '../../shared/models/preference_profile.dart';
import '../../shared/onmu_design.dart';
import '../../shared/providers/state_providers.dart';

Future<void> showPreferenceSummaryBottomSheet(
  BuildContext context,
  PreferenceProfile profile,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) {
          return _PreferenceSummarySheet(
            profile: profile,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class PreferenceSummaryPage extends ConsumerWidget {
  final PreferenceProfile profile;

  const PreferenceSummaryPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                children: [
                  const OnmuCharacterHero(compact: true),
                  const SizedBox(height: 20),
                  Text(
                    '취향 선택 완료',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '이제 약속 추천에 취향을 반영할 준비가 끝났어요.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ..._summaryCards(profile),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OnmuSecondaryButton(
                      label: '이전',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: OnmuPrimaryButton(
                      label: '시작하기',
                      onPressed: () {
                        ref.read(preferenceProfileProvider.notifier).state =
                            profile;
                        ref.read(skippedPreferenceProvider.notifier).state =
                            false;
                        context.go(RoutePaths.onboarding);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSummarySheet extends StatelessWidget {
  final PreferenceProfile profile;
  final ScrollController scrollController;

  const _PreferenceSummarySheet({
    required this.profile,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lineSoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '취향 요약',
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const OnmuCharacterHero(compact: true),
                const SizedBox(height: 24),
                ..._summaryCards(profile),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: OnmuPrimaryButton(
              label: '닫기',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _summaryCards(PreferenceProfile profile) {
  return [
    _SummaryCard(
      title: '선호 음식/메뉴',
      values: [
        ...profile.favoriteFoodTags,
        if (profile.otherFavoriteFood.trim().isNotEmpty)
          profile.otherFavoriteFood.trim(),
      ],
    ),
    const SizedBox(height: 12),
    _SummaryCard(
      title: '피하고 싶은 음식/메뉴',
      values: [
        ...profile.dislikedFoodTags,
        if (profile.otherDislikedFood.trim().isNotEmpty)
          profile.otherDislikedFood.trim(),
      ],
    ),
    const SizedBox(height: 12),
    _SummaryCard(
      title: '선호 장소/분위기',
      values: [
        ...profile.favoritePlaceTags,
        if (profile.otherFavoritePlace.trim().isNotEmpty)
          profile.otherFavoritePlace.trim(),
      ],
    ),
    const SizedBox(height: 12),
    _SummaryCard(
      title: '피하고 싶은 장소/분위기',
      values: [
        ...profile.dislikedPlaceTags,
        if (profile.otherDislikedPlace.trim().isNotEmpty)
          profile.otherDislikedPlace.trim(),
      ],
    ),
    const SizedBox(height: 12),
    _SummaryCard(title: '약속 스타일', values: profile.planStyles),
    const SizedBox(height: 12),
    _SummaryCard(title: '선호 요일', values: profile.preferredWeekdays),
    const SizedBox(height: 12),
    _SummaryCard(title: '선호 시간대', values: profile.preferredTimes),
  ];
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<String> values;

  const _SummaryCard({required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelMedium?.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 8),
          Text(
            values.isEmpty ? '선택 없음' : values.join(', '),
            style: textTheme.titleSmall?.copyWith(color: AppColors.textMain),
          ),
        ],
      ),
    );
  }
}
