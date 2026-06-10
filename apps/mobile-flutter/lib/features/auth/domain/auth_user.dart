class AuthUser {
  const AuthUser({
    required this.id,
    required this.provider,
    required this.displayName,
    this.publicId,
    this.email,
    this.profileImageUrl,
    this.onboardingStatus = 'PENDING',
  });

  final String id;
  final String? publicId;
  final String provider;
  final String displayName;
  final String? email;
  final String? profileImageUrl;
  final String onboardingStatus;

  bool get hasCompletedOnboarding => onboardingStatus == 'COMPLETED';
}
