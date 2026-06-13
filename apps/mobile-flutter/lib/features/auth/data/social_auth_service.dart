import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/oauth_provider_credential.dart';
import 'kakao_oauth_credential_loader.dart';
import 'naver_oauth_credential_loader.dart';

typedef OAuthCredentialLoader = Future<OAuthProviderCredential> Function();

class SocialAuthService {
  SocialAuthService({
    OAuthCredentialLoader? kakaoCredentialLoader,
    this.googleCredentialLoader,
    OAuthCredentialLoader? naverCredentialLoader,
  }) : _kakaoCredentialLoader =
           kakaoCredentialLoader ?? _defaultKakaoCredentialLoader,
       _naverCredentialLoader =
           naverCredentialLoader ?? _defaultNaverCredentialLoader;

  static const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  final OAuthCredentialLoader _kakaoCredentialLoader;
  final OAuthCredentialLoader? googleCredentialLoader;
  final OAuthCredentialLoader _naverCredentialLoader;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitializeFuture;

  bool get isGoogleConfigured {
    return !kIsWeb || _googleClientIdValue.isNotEmpty;
  }

  bool get canUseGoogleAppButton {
    if (!isGoogleConfigured) {
      return false;
    }
    try {
      return _googleSignIn.supportsAuthenticate();
    } on UnimplementedError {
      return false;
    }
  }

  Future<void> initializeGoogleSignIn() {
    final clientId = _emptyToNull(_googleClientIdValue);
    final serverClientId = _emptyToNull(_googleServerClientIdValue);

    return _googleInitializeFuture ??= _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  Stream<OAuthProviderCredential?> googleCredentialEvents() async* {
    await initializeGoogleSignIn();

    await for (final event in _googleSignIn.authenticationEvents) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          yield _credentialFromGoogleAccount(event.user);
        case GoogleSignInAuthenticationEventSignOut():
          yield null;
      }
    }
  }

  Future<void> attemptGoogleLightweightAuthentication() async {
    await initializeGoogleSignIn();
    unawaited(_googleSignIn.attemptLightweightAuthentication());
  }

  Future<OAuthProviderCredential> acquireKakaoCredential() {
    return _kakaoCredentialLoader();
  }

  Future<OAuthProviderCredential> acquireGoogleCredential() async {
    final loader = googleCredentialLoader;
    if (loader != null) {
      return loader();
    }

    await initializeGoogleSignIn();

    if (!isGoogleConfigured) {
      throw const GoogleSignInMissingClientIdException();
    }

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const GoogleSignInWebButtonRequiredException();
    }

    final account = await _googleSignIn.authenticate();
    return _credentialFromGoogleAccount(account);
  }

  Future<OAuthProviderCredential> acquireNaverCredential() {
    return _naverCredentialLoader();
  }

  Future<void> signOut() async {
    await initializeGoogleSignIn();
    await _googleSignIn.signOut();
  }

  OAuthProviderCredential _credentialFromGoogleAccount(
    GoogleSignInAccount account,
  ) {
    final idToken = account.authentication.idToken;
    if (!_hasText(idToken)) {
      throw const GoogleCredentialUnavailableException();
    }

    return OAuthProviderCredential(
      provider: 'google',
      providerIdToken: idToken,
      displayName: account.displayName ?? account.email,
      email: account.email,
      profileImageUrl: account.photoUrl,
    );
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String get _googleClientIdValue => _googleClientId.trim();

  static String get _googleServerClientIdValue => _googleServerClientId.trim();

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static Future<OAuthProviderCredential> _defaultKakaoCredentialLoader() async {
    return KakaoOAuthCredentialLoader().call();
  }

  static Future<OAuthProviderCredential> _defaultNaverCredentialLoader() async {
    return NaverOAuthCredentialLoader().call();
  }
}

class GoogleSignInWebButtonRequiredException implements Exception {
  const GoogleSignInWebButtonRequiredException();
}

class GoogleSignInMissingClientIdException implements Exception {
  const GoogleSignInMissingClientIdException();
}

class GoogleSpringOAuthUnavailableException implements Exception {
  const GoogleSpringOAuthUnavailableException();
}

class GoogleCredentialUnavailableException implements Exception {
  const GoogleCredentialUnavailableException();
}

class GoogleSignInTimeoutException implements Exception {
  const GoogleSignInTimeoutException();
}

class KakaoSignInUnavailableException implements Exception {
  const KakaoSignInUnavailableException();
}

class NaverSignInUnavailableException implements Exception {
  const NaverSignInUnavailableException();
}
