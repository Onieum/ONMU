import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/state_providers.dart';
import '../../../../shared/utils/onmu_display_name.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../view_model/onboarding_hub_controller.dart';

class OnboardingHubPage extends ConsumerStatefulWidget {
  const OnboardingHubPage({super.key});

  static const _selectScreenAsset = 'assets/images/splash/Select_Screen.png';

  @override
  ConsumerState<OnboardingHubPage> createState() => _OnboardingHubPageState();
}

class _OnboardingHubPageState extends ConsumerState<OnboardingHubPage> {
  var _isSavingHomeStatus = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider);
    final hasCharacter = ref.watch(userCharacterProvider) != null;
    final hasPreference = ref.watch(preferenceProfileProvider) != null;
    final skippedCharacter = ref.watch(skippedCharacterProvider);
    final skippedPreference = ref.watch(skippedPreferenceProvider);
    final nickname = resolveOnmuDisplayName([
      user?.nickname,
    ], fallback: '카카오 친구');

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      body: SafeArea(
        child: GridBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = _OnboardingLayout.from(constraints);

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  layout.compact ? 24 : 42,
                  24,
                  28,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight - (layout.compact ? 52 : 70),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: layout.contentWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _OnboardingTitle(
                            nickname: nickname,
                            compact: layout.compact,
                          ),
                          SizedBox(height: layout.compact ? 20 : 28),
                          Text(
                            '캐릭터와 취향은 지금 설정해도 좋고,\n나중에 천천히 채워도 괜찮아요.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF8A6F63),
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: layout.compact ? 17 : 25),
                          Image.asset(
                            OnboardingHubPage._selectScreenAsset,
                            width: layout.imageWidth,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                          ),
                          SizedBox(height: layout.compact ? 10 : 14),
                          _OnboardingTaskCard(
                            compact: layout.compact,
                            title: '캐릭터 만들기',
                            description: '프로필에 사용할 캐릭터를 만들어요.',
                            icon: Icons.face_retouching_natural_outlined,
                            state: _TaskState.from(
                              hasCharacter,
                              skippedCharacter,
                            ),
                            primaryLabel: _taskButtonLabel(
                              completed: hasCharacter,
                              skipped: skippedCharacter,
                            ),
                            onPrimary: () =>
                                context.go(RoutePaths.onboardingCharacter),
                          ),
                          SizedBox(height: layout.compact ? 12 : 14),
                          _OnboardingTaskCard(
                            compact: layout.compact,
                            title: '취향 선택',
                            description: '음식, 장소, 약속 스타일\n추천에 쓸 취향을 골라요.',
                            icon: Icons.tune_rounded,
                            state: _TaskState.from(
                              hasPreference,
                              skippedPreference,
                            ),
                            primaryLabel: _taskButtonLabel(
                              completed: hasPreference,
                              skipped: skippedPreference,
                            ),
                            onPrimary: () =>
                                context.go(RoutePaths.onboardingPreferences),
                          ),
                          SizedBox(height: layout.compact ? 22 : 28),
                          SizedBox(
                            width: layout.homeWidth,
                            child: _HomeButton(
                              compact: layout.compact,
                              isSaving: _isSavingHomeStatus,
                              onPressed: _isSavingHomeStatus
                                  ? null
                                  : () => _saveSkipStatusAndGoHome(
                                      hasCharacter: hasCharacter,
                                      hasPreference: hasPreference,
                                      skippedCharacter: skippedCharacter,
                                      skippedPreference: skippedPreference,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _saveSkipStatusAndGoHome({
    required bool hasCharacter,
    required bool hasPreference,
    required bool skippedCharacter,
    required bool skippedPreference,
  }) async {
    setState(() => _isSavingHomeStatus = true);
    try {
      await ref
          .read(onboardingHubControllerProvider)
          .saveSkipStatus(
            hasCharacter: hasCharacter,
            hasPreference: hasPreference,
            skippedCharacter: skippedCharacter,
            skippedPreference: skippedPreference,
          );

      if (!mounted) {
        return;
      }
      context.go(RoutePaths.home);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('온보딩 상태 저장에 실패했어요. 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingHomeStatus = false);
      }
    }
  }
}

String _taskButtonLabel({required bool completed, required bool skipped}) {
  if (completed) return '다시 설정';
  if (skipped) return '설정하기';
  return '시작하기';
}

enum _TaskState {
  incomplete('미완료', AppColors.primaryPurple, AppColors.primaryPinkSoft),
  completed('완료', AppColors.accentGreen, AppColors.accentGreen),
  skipped('건너뜀', AppColors.accentOrange, AppColors.accentOrange);

  const _TaskState(this.label, this.color, this.borderColor);

  final String label;
  final Color color;
  final Color borderColor;

  static _TaskState from(bool completed, bool skipped) {
    if (completed) return _TaskState.completed;
    if (skipped) return _TaskState.skipped;
    return _TaskState.incomplete;
  }
}

class _OnboardingLayout {
  const _OnboardingLayout({
    required this.compact,
    required this.contentWidth,
    required this.homeWidth,
    required this.imageWidth,
  });

  final bool compact;
  final double contentWidth;
  final double homeWidth;
  final double imageWidth;

  static _OnboardingLayout from(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final compact = height < 720;
    final contentWidth = (width - 48).clamp(300.0, 386.0);

    return _OnboardingLayout(
      compact: compact,
      contentWidth: contentWidth,
      homeWidth: (contentWidth * 0.7).clamp(230.0, 280.0),
      imageWidth: width.clamp(210.0, compact ? 238.0 : 290.0),
    );
  }
}

class _OnboardingTitle extends StatelessWidget {
  const _OnboardingTitle({required this.nickname, required this.compact});

  final String nickname;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        (compact ? AppTextStyles.titleLarge : AppTextStyles.headlineMedium)
            .copyWith(
              color: const Color(0xFF4D3930),
              fontWeight: FontWeight.w900,
              height: 1.25,
            );

    return Column(
      children: [
        Text(
          '$nickname님,',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: titleStyle,
        ),
        RichText(
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: titleStyle,
            children: const [
              TextSpan(
                text: '기록 준비',
                style: TextStyle(color: Color(0xFFFF637B)),
              ),
              TextSpan(text: '를 해볼까요?'),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingTaskCard extends StatelessWidget {
  const _OnboardingTaskCard({
    required this.compact,
    required this.title,
    required this.description,
    required this.icon,
    required this.state,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final bool compact;
  final String title;
  final String description;
  final IconData icon;
  final _TaskState state;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 42.0 : 50.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 13,
        vertical: compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143A2A23),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2E8),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFFF637B),
                  size: compact ? 23 : 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            softWrap: false,
                            style:
                                (compact
                                        ? AppTextStyles.titleMedium
                                        : AppTextStyles.titleLarge)
                                    .copyWith(
                                      color: const Color(0xFF4D3930),
                                      fontWeight: FontWeight.w900,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(state: state, compact: compact),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF8A6F63),
                        height: compact ? 1.18 : 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 14),
          SizedBox(
            height: compact ? 38 : 44,
            child: OutlinedButton.icon(
              onPressed: onPrimary,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              label: Text(primaryLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF637B),
                side: const BorderSide(color: Color(0xFFFFB4C0), width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state, required this.compact});

  final _TaskState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: state.borderColor),
      ),
      child: Text(
        state.label,
        style: AppTextStyles.labelMedium.copyWith(
          color: state.color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({
    required this.onPressed,
    required this.compact,
    required this.isSaving,
  });

  final VoidCallback? onPressed;
  final bool compact;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 48 : 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textInverse,
                ),
              )
            : const Icon(Icons.home_rounded, size: 24),
        label: Text(isSaving ? '저장 중' : '홈으로 가기'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFF637B),
          foregroundColor: AppColors.textInverse,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 6,
          shadowColor: const Color(0x66FF637B),
          textStyle: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
