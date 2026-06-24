import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/oauth_provider_credential.dart';
import 'kakao_oauth_credential_loader.dart';
import 'naver_oauth_credential_loader.dart';

typedef OAuthCredentialLoader = Future<OAuthProviderCredential> Function();
typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

class SocialAuthService {
  SocialAuthService({
    OAuthCredentialLoader? kakaoCredentialLoader,
    this.googleCredentialLoader,
    OAuthCredentialLoader? naverCredentialLoader,
    ExternalUrlLauncher? externalUrlLauncher,
  }) : _kakaoCredentialLoader =
           kakaoCredentialLoader ?? _defaultKakaoCredentialLoader,
       _naverCredentialLoader =
           naverCredentialLoader ?? _defaultNaverCredentialLoader,
       _externalUrlLauncher = externalUrlLauncher ?? _launchExternalUrl;

  static const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  final OAuthCredentialLoader _kakaoCredentialLoader;
  final OAuthCredentialLoader? googleCredentialLoader;
  final OAuthCredentialLoader _naverCredentialLoader;
  final ExternalUrlLauncher _externalUrlLauncher;
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

    final eventCredential = _googleSignIn.authenticationEvents
        .where((event) => event is GoogleSignInAuthenticationEventSignIn)
        .cast<GoogleSignInAuthenticationEventSignIn>()
        .map((event) => _credentialFromGoogleAccount(event.user))
        .first;
    final accountCredential = _googleSignIn.authenticate().then(
      _credentialFromGoogleAccount,
    );
    return Future.any([accountCredential, eventCredential]);
  }

  Future<OAuthProviderCredential> acquireNaverCredential() {
    return _naverCredentialLoader();
  }

  Future<void> signOut({String? provider, String? onmuApiBaseUrl}) async {
    switch (provider?.trim().toLowerCase()) {
      case 'google':
        await _signOutGoogle();
        return;
      case 'kakao':
        await _signOutKakao(onmuApiBaseUrl);
        return;
      default:
        return;
    }
  }

  Future<void> _signOutGoogle() async {
    try {
      await initializeGoogleSignIn();
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('Google provider sign-out skipped: $error');
    }
  }

  Future<void> _signOutKakao(String? onmuApiBaseUrl) async {
    final baseUri = _parseHttpUri(onmuApiBaseUrl);
    if (baseUri == null) {
      return;
    }
    final logoutUri = baseUri.resolve('/api/v1/auth/oauth/kakao/logout');
    final launched = await _externalUrlLauncher(logoutUri);
    if (!launched) {
      debugPrint('Kakao provider sign-out launch unavailable.');
    }
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
      providerProfileName: account.displayName ?? account.email,
      email: account.email,
      profileImageUrl: account.photoUrl,
    );
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Uri? _parseHttpUri(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
      return null;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }
    return uri;
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

  static Future<bool> _launchExternalUrl(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
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
