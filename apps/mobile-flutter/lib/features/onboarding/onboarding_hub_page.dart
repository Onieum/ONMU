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
    final displayName = user?.displayName ?? '온뮤 친구';
    final completedCount = [
      hasCharacter,
      hasPreference,
    ].where((completed) => completed).length;
    final title = switch (completedCount) {
      0 => '$displayName님,\n기록 준비를 해볼까요?',
      1 => '$displayName님,\n하나 완료했어요.\n남은 설정도 해볼까요?',
      _ => '$displayName님,\n준비가 끝났어요!',
    };
    final description = switch (completedCount) {
      0 => '캐릭터와 취향은 지금 설정해도 좋고, 나중에 천천히 채워도 괜찮아요.',
      1 => '남은 항목은 지금 이어서 해도 좋고, 나중에 천천히 채워도 괜찮아요.',
      _ => '캐릭터와 취향 설정이 모두 준비됐어요. 이제 ONMU를 시작해볼까요?',
    };

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
                    title,
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
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
                    primaryLabel: _taskButtonLabel(
                      completed: hasCharacter,
                      skipped: skippedCharacter,
                    ),
                    onPrimary: () => context.go(RoutePaths.characterStart),
                  ),
                  const SizedBox(height: 12),
                  _OnboardingTaskCard(
                    title: '취향 선택',
                    description: '음식, 장소, 약속 스타일 추천에 쓸 취향을 골라요.',
                    icon: Icons.tune,
                    state: _TaskState.from(hasPreference, skippedPreference),
                    primaryLabel: _taskButtonLabel(
                      completed: hasPreference,
                      skipped: skippedPreference,
                    ),
                    onPrimary: () => context.go(RoutePaths.preferenceIntro),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: OnmuPrimaryButton(
                label: '홈으로 가기',
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

String _taskButtonLabel({required bool completed, required bool skipped}) {
  if (completed) return '다시 설정';
  if (skipped) return '설정하기';
  return '시작하기';
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
  });

  final String title;
  final String description;
  final IconData icon;
  final _TaskState state;
  final String primaryLabel;
  final VoidCallback onPrimary;

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
          OnmuSecondaryButton(label: primaryLabel, onPressed: onPrimary),
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
