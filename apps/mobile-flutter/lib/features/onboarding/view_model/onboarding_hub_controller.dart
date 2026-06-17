import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/state_providers.dart';
import '../../my/repository/my_repository.dart';
import '../onboarding_status.dart';

final onboardingHubControllerProvider = Provider<OnboardingHubController>(
  (ref) => OnboardingHubController(ref),
);

class OnboardingHubController {
  const OnboardingHubController(this._ref);

  final Ref _ref;

  Future<void> saveSkipStatus({
    required bool hasCharacter,
    required bool hasPreference,
    required bool skippedCharacter,
    required bool skippedPreference,
  }) async {
    final nextSkippedCharacter = skippedCharacter || !hasCharacter;
    final nextSkippedPreference = skippedPreference || !hasPreference;
    final onboardingStatus = deriveOnboardingStatus(
      preferenceReady: hasPreference || nextSkippedPreference,
      characterReady: hasCharacter || nextSkippedCharacter,
    );

    await _ref
        .read(myRepositoryProvider)
        .updateOnboardingStatus(onboardingStatus.value);
    _ref.read(skippedCharacterProvider.notifier).state = nextSkippedCharacter;
    _ref.read(skippedPreferenceProvider.notifier).state = nextSkippedPreference;
    syncAuthUserOnboardingStatusFromRef(_ref, onboardingStatus);
    _ref.invalidate(myProfileProvider);
  }
}
