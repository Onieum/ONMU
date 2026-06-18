class AuthUser {
  const AuthUser({
    required this.id,
    required this.provider,
    required this.nickname,
    this.publicId,
    this.email,
    this.profileImageUrl,
    this.onboardingStatus = 'PENDING',
  });

  final String id;
  final String? publicId;
  final String provider;
  final String nickname;
  final String? email;
  final String? profileImageUrl;
  final String onboardingStatus;

  bool get hasCompletedOnboarding => onboardingStatus == 'COMPLETED';

  AuthUser copyWith({
    String? id,
    String? publicId,
    String? provider,
    String? nickname,
    String? email,
    String? profileImageUrl,
    String? onboardingStatus,
  }) {
    return AuthUser(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      provider: provider ?? this.provider,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
    );
  }
}
