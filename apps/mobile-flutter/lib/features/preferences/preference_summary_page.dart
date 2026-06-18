import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_radius.dart';
import '../../features/preferences/view_model/preference_summary_controller.dart';
import '../../shared/models/preference_profile.dart';
import '../../shared/providers/state_providers.dart';
import '../../shared/widgets/grid_background.dart';
import '../../shared/widgets/onmu_button.dart';

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

class PreferenceSummaryPage extends ConsumerStatefulWidget {
  const PreferenceSummaryPage({super.key, required this.profile});

  static const _completedImageAsset =
      'assets/images/splash/investigation_completed.png';

  final PreferenceProfile profile;

  @override
  ConsumerState<PreferenceSummaryPage> createState() =>
      _PreferenceSummaryPageState();
}

class _PreferenceSummaryPageState extends ConsumerState<PreferenceSummaryPage> {
  static const _saveTimeout = Duration(seconds: 12);

  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = widget.profile;
    final willCompleteOnboarding =
        ref.watch(userCharacterProvider) != null ||
        ref.watch(skippedCharacterProvider);

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  children: [
                    const _PreferenceCompletedImage(
                      assetPath: PreferenceSummaryPage._completedImageAsset,
                    ),
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
                    const SizedBox(height: 24),
                    _SummaryList(profile: profile),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bgDefault,
                          foregroundColor: AppColors.textMain,
                          side: const BorderSide(color: AppColors.lineSoft),
                        ),
                        child: const Text('이전'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePreferenceProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.bgDefault,
                                ),
                              )
                            : Text(
                                willCompleteOnboarding
                                    ? '홈으로 가기'
                                    : '첫 설정 페이지로 돌아가기',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePreferenceProfile() async {
    setState(() => _isSaving = true);

    try {
      await ref
          .read(preferenceSummaryControllerProvider)
          .savePreferenceProfile(widget.profile, timeout: _saveTimeout);

      if (!mounted) {
        return;
      }
      context.go(RoutePaths.onboarding);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('취향 저장에 실패했어요. API 연결 상태를 확인해 주세요.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _PreferenceSummarySheet extends StatelessWidget {
  const _PreferenceSummarySheet({
    required this.profile,
    required this.scrollController,
  });

  final PreferenceProfile profile;
  final ScrollController scrollController;

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
                const _PreferenceCompletedImage(
                  assetPath: PreferenceSummaryPage._completedImageAsset,
                ),
                const SizedBox(height: 20),
                _SummaryList(profile: profile),
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

List<_SummaryEntry> _summaryEntries(PreferenceProfile profile) {
  return [
    _SummaryEntry(
      title: '선호 음식/메뉴',
      icon: Icons.local_dining_rounded,
      color: AppColors.primaryPink,
      values: [
        ...profile.favoriteFoodTags,
        if (profile.otherFavoriteFood.trim().isNotEmpty)
          profile.otherFavoriteFood.trim(),
      ],
    ),
    _SummaryEntry(
      title: '원하지 않는 음식/메뉴',
      icon: Icons.no_food_rounded,
      color: AppColors.accentOrange,
      values: [
        ...profile.dislikedFoodTags,
        if (profile.otherDislikedFood.trim().isNotEmpty)
          profile.otherDislikedFood.trim(),
      ],
    ),
    _SummaryEntry(
      title: '선호 장소/분위기',
      icon: Icons.place_rounded,
      color: AppColors.accentGreen,
      values: [
        ...profile.favoritePlaceTags,
        if (profile.otherFavoritePlace.trim().isNotEmpty)
          profile.otherFavoritePlace.trim(),
      ],
    ),
    _SummaryEntry(
      title: '원하지 않는 장소/분위기',
      icon: Icons.wrong_location_rounded,
      color: AppColors.primaryPurple,
      values: [
        ...profile.dislikedPlaceTags,
        if (profile.otherDislikedPlace.trim().isNotEmpty)
          profile.otherDislikedPlace.trim(),
      ],
    ),
    _SummaryEntry(
      title: '약속 스타일',
      icon: Icons.event_available_rounded,
      color: AppColors.accentRed,
      values: profile.planStyles,
    ),
    _SummaryEntry(
      title: '선호 요일',
      icon: Icons.calendar_month_rounded,
      color: AppColors.accentBlue,
      values: profile.preferredWeekdays,
    ),
    _SummaryEntry(
      title: '선호 시간대',
      icon: Icons.schedule_rounded,
      color: AppColors.primaryPurple,
      values: profile.preferredTimes,
    ),
  ];
}

class _SummaryEntry {
  const _SummaryEntry({
    required this.title,
    required this.icon,
    required this.color,
    required this.values,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> values;

  String get summaryText => values.isEmpty ? '선택 없음' : values.join(', ');
}

class _PreferenceCompletedImage extends StatelessWidget {
  const _PreferenceCompletedImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({required this.profile});

  final PreferenceProfile profile;

  @override
  Widget build(BuildContext context) {
    final entries = _summaryEntries(profile);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppColors.lineSoft),
        itemBuilder: (context, index) => _SummaryRow(entry: entries[index]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.entry});

  final _SummaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _showSummaryDetail(context, entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(entry.icon, color: entry.color, size: 19),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 148,
              child: Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textSub,
                  fontSize: 9.5,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 28,
              margin: const EdgeInsets.only(left: 8, right: 12),
              color: AppColors.lineSoft.withValues(alpha: 0.7),
            ),
            Expanded(
              child: Text(
                entry.summaryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

void _showSummaryDetail(BuildContext context, _SummaryEntry entry) {
  final textTheme = Theme.of(context).textTheme;

  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.bgDefault,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Row(
          children: [
            Icon(entry.icon, color: entry.color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.title,
                maxLines: 3,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: entry.values.isEmpty
            ? Text(
                '선택 없음',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.values.map((value) {
                  return Chip(
                    label: Text(value),
                    backgroundColor: entry.color.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: entry.color.withValues(alpha: 0.35),
                    ),
                    labelStyle: textTheme.labelMedium?.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      );
    },
  );
}
