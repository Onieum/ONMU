class OAuthProviderCredential {
  const OAuthProviderCredential({
    required this.provider,
    this.authorizationCode,
    this.providerAccessToken,
    this.state,
    this.devVerifiedSubject,
    this.displayName,
    this.email,
    this.profileImageUrl,
  });

  final String provider;
  final String? authorizationCode;
  final String? providerAccessToken;
  final String? state;
  final String? devVerifiedSubject;
  final String? displayName;
  final String? email;
  final String? profileImageUrl;

  Map<String, Object?> toRequestBody() {
    return {
      if (_hasText(authorizationCode)) 'authorizationCode': authorizationCode,
      if (_hasText(providerAccessToken))
        'providerAccessToken': providerAccessToken,
      if (_hasText(state)) 'state': state,
      if (_hasText(devVerifiedSubject))
        'devVerifiedSubject': devVerifiedSubject,
      if (_hasText(displayName)) 'displayName': displayName,
      if (_hasText(email)) 'email': email,
      if (_hasText(profileImageUrl)) 'profileImageUrl': profileImageUrl,
    };
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
