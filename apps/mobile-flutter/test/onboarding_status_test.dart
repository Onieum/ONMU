import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/onboarding/onboarding_status.dart';

void main() {
  group('deriveOnboardingStatus', () {
    test('returns PENDING when nothing is ready', () {
      expect(
        deriveOnboardingStatus(preferenceReady: false, characterReady: false),
        OnboardingStatus.pending,
      );
    });

    test('returns PREFERENCE_READY when only preference is ready', () {
      expect(
        deriveOnboardingStatus(preferenceReady: true, characterReady: false),
        OnboardingStatus.preferenceReady,
      );
    });

    test('returns CHARACTER_READY when only character is ready', () {
      expect(
        deriveOnboardingStatus(preferenceReady: false, characterReady: true),
        OnboardingStatus.characterReady,
      );
    });

    test('returns COMPLETED when both steps are ready', () {
      expect(
        deriveOnboardingStatus(preferenceReady: true, characterReady: true),
        OnboardingStatus.completed,
      );
    });
  });
}
