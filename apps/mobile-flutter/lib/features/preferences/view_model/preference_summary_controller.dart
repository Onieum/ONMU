import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/preference_profile.dart';
import '../../../shared/providers/state_providers.dart';
import '../../my/repository/my_repository.dart';
import '../../onboarding/onboarding_status.dart';

final preferenceSummaryControllerProvider =
    Provider<PreferenceSummaryController>(
      (ref) => PreferenceSummaryController(ref),
    );

class PreferenceSummaryController {
  const PreferenceSummaryController(this._ref);

  final Ref _ref;

  Future<void> savePreferenceProfile(
    PreferenceProfile profile, {
    required Duration timeout,
  }) async {
    final onboardingStatus = deriveOnboardingStatus(
      preferenceReady: true,
      characterReady:
          _ref.read(userCharacterProvider) != null ||
          _ref.read(skippedCharacterProvider),
    );
    final currentProfile = await _ref
        .read(myProfileProvider.future)
        .timeout(timeout);
    final updatedProfile = currentProfile.copyWith(
      favoriteFoodTags: _withOther(
        profile.favoriteFoodTags,
        profile.otherFavoriteFood,
      ),
      dislikedFoodTags: _withOther(
        profile.dislikedFoodTags,
        profile.otherDislikedFood,
      ),
      favoritePlaceTags: _withOther(
        profile.favoritePlaceTags,
        profile.otherFavoritePlace,
      ),
      dislikedPlaceTags: _withOther(
        profile.dislikedPlaceTags,
        profile.otherDislikedPlace,
      ),
      planStyles: profile.planStyles,
      preferredWeekdays: profile.preferredWeekdays,
      preferredTimes: profile.preferredTimes,
    );

    await _ref
        .read(myRepositoryProvider)
        .updateMyProfile(
          updatedProfile,
          onboardingStatus: onboardingStatus.value,
        )
        .timeout(timeout);
    _ref.read(preferenceProfileProvider.notifier).state = profile;
    _ref.read(skippedPreferenceProvider.notifier).state = false;
    syncAuthUserOnboardingStatusFromRef(_ref, onboardingStatus);
    _ref.invalidate(myProfileProvider);
  }
}

List<String> _withOther(List<String> values, String other) {
  final cleanOther = other.trim();
  if (cleanOther.isEmpty) {
    return values;
  }
  return [...values, cleanOther];
}
