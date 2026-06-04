import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_paths.dart';
import '../../core/theme/app_radius.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../shared/onmu_design.dart';
import '../../shared/providers/state_providers.dart';

class OnboardingHubPage extends ConsumerWidget {
  const OnboardingHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(authUserProvider);
    final hasCharacter = ref.watch(userCharacterProvider) != null;
    final hasPreference = ref.watch(preferenceProfileProvider) != null;
    final skippedCharacter = ref.watch(skippedCharacterProvider);
    final skippedPreference = ref.watch(skippedPreferenceProvider);
    final characterReady = hasCharacter || skippedCharacter;
    final preferenceReady = hasPreference || skippedPreference;
    final canEnterHome = characterReady && preferenceReady;

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                children: [
                  Text(
                    '${user?.displayName ?? '온뮤 친구'}님,\n기록 준비를 해볼까요?',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '캐릭터와 취향은 지금 설정해도 좋고, 나중에 천천히 채워도 괜찮아요.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSub,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const OnmuCharacterHero(compact: true),
                  const SizedBox(height: 24),
                  _OnboardingTaskCard(
                    title: '캐릭터 만들기',
                    description: 'OOTD 기록에 함께할 픽셀 캐릭터를 꾸며요.',
                    icon: Icons.face_retouching_natural_outlined,
                    state: _TaskState.from(hasCharacter, skippedCharacter),
                    primaryLabel: hasCharacter ? '다시 설정' : '시작하기',
                    onPrimary: () => context.go(RoutePaths.characterStart),
                    onSkip: characterReady
                        ? null
                        : () {
                            ref.read(skippedCharacterProvider.notifier).state =
                                true;
                          },
                  ),
                  const SizedBox(height: 12),
                  _OnboardingTaskCard(
                    title: '취향 선택',
                    description: '음식, 장소, 약속 스타일 추천에 쓸 취향을 골라요.',
                    icon: Icons.tune,
                    state: _TaskState.from(hasPreference, skippedPreference),
                    primaryLabel: hasPreference ? '다시 설정' : '시작하기',
                    onPrimary: () => context.go(RoutePaths.preferenceIntro),
                    onSkip: preferenceReady
                        ? null
                        : () {
                            ref.read(skippedPreferenceProvider.notifier).state =
                                true;
                          },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: OnmuPrimaryButton(
                label: canEnterHome ? '홈으로 가기' : '나중에 할게요',
                onPressed: () {
                  if (!characterReady) {
                    ref.read(skippedCharacterProvider.notifier).state = true;
                  }
                  if (!preferenceReady) {
                    ref.read(skippedPreferenceProvider.notifier).state = true;
                  }
                  context.go(RoutePaths.home);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TaskState {
  incomplete('미완료', AppColors.textMuted, AppColors.lineSoft),
  completed('완료', AppColors.accentGreen, AppColors.accentGreen),
  skipped('스킵됨', AppColors.accentOrange, AppColors.accentOrange);

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

class _OnboardingTaskCard extends StatelessWidget {
  const _OnboardingTaskCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.state,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onSkip,
  });

  final String title;
  final String description;
  final IconData icon;
  final _TaskState state;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryPinkSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: AppColors.primaryPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSub,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(state: state),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OnmuSecondaryButton(
                  label: primaryLabel,
                  onPressed: onPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: onSkip,
                  child: const Text('나중에 할게요'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final _TaskState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: state.borderColor),
      ),
      child: Text(
        state.label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: state.color),
      ),
    );
  }
}
