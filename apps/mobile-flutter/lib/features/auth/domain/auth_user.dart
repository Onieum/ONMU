class AuthUser {
  const AuthUser({
    required this.id,
    required this.provider,
    required this.displayName,
    this.email,
    this.profileImageUrl,
  });

  final String id;
  final String provider;
  final String displayName;
  final String? email;
  final String? profileImageUrl;
}
