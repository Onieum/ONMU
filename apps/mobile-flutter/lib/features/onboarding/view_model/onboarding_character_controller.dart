import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/character_model.dart';
import '../../../shared/providers/state_providers.dart';
import '../../character/repository/character_repository.dart';
import '../../my/repository/my_repository.dart';
import '../onboarding_status.dart';

final onboardingCharacterControllerProvider =
    Provider<OnboardingCharacterController>(
      (ref) => OnboardingCharacterController(ref),
    );

class OnboardingCharacterController {
  const OnboardingCharacterController(this._ref);

  final Ref _ref;

  Future<void> saveCharacter(CharacterDraft draft) async {
    final saved = await _ref
        .read(characterRepositoryProvider)
        .saveMyCharacter(draft);
    final onboardingStatus = deriveOnboardingStatus(
      preferenceReady:
          _ref.read(preferenceProfileProvider) != null ||
          _ref.read(skippedPreferenceProvider),
      characterReady: true,
    );

    await _ref
        .read(myRepositoryProvider)
        .updateOnboardingStatus(onboardingStatus.value);
    _ref.read(userCharacterProvider.notifier).state = saved;
    _ref.read(skippedCharacterProvider.notifier).state = false;
    syncAuthUserOnboardingStatusFromRef(_ref, onboardingStatus);
    _ref.invalidate(characterProfileProvider);
    _ref.invalidate(myProfileProvider);
  }
}
