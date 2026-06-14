import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers/auth_providers.dart';

enum OnboardingStatus {
  pending('PENDING'),
  preferenceReady('PREFERENCE_READY'),
  characterReady('CHARACTER_READY'),
  completed('COMPLETED');

  const OnboardingStatus(this.value);

  final String value;
}

OnboardingStatus deriveOnboardingStatus({
  required bool preferenceReady,
  required bool characterReady,
}) {
  if (preferenceReady && characterReady) {
    return OnboardingStatus.completed;
  }
  if (preferenceReady) {
    return OnboardingStatus.preferenceReady;
  }
  if (characterReady) {
    return OnboardingStatus.characterReady;
  }
  return OnboardingStatus.pending;
}

void syncAuthUserOnboardingStatus(WidgetRef ref, OnboardingStatus status) {
  final user = ref.read(authUserProvider);
  if (user == null || user.onboardingStatus == status.value) {
    return;
  }
  ref.read(authUserProvider.notifier).state = user.copyWith(
    onboardingStatus: status.value,
  );
}
