class OAuthProviderCredential {
  const OAuthProviderCredential({
    required this.provider,
    this.authorizationCode,
    this.providerAccessToken,
    this.providerIdToken,
    this.state,
    this.devVerifiedSubject,
    this.providerProfileName,
    this.email,
    this.profileImageUrl,
  });

  final String provider;
  final String? authorizationCode;
  final String? providerAccessToken;
  final String? providerIdToken;
  final String? state;
  final String? devVerifiedSubject;
  final String? providerProfileName;
  final String? email;
  final String? profileImageUrl;

  Map<String, Object?> toRequestBody() {
    return {
      if (_hasText(authorizationCode)) 'authorizationCode': authorizationCode,
      if (_hasText(providerAccessToken))
        'providerAccessToken': providerAccessToken,
      if (_hasText(providerIdToken)) 'providerIdToken': providerIdToken,
      if (_hasText(state)) 'state': state,
      if (_hasText(devVerifiedSubject))
        'devVerifiedSubject': devVerifiedSubject,
      if (_hasText(providerProfileName))
        'providerProfileName': providerProfileName,
      if (_hasText(email)) 'email': email,
      if (_hasText(profileImageUrl)) 'profileImageUrl': profileImageUrl,
    };
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
