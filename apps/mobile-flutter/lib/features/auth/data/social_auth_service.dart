import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_user.dart';

class SocialAuthService {
  SocialAuthService();

  static const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitializeFuture;

  bool get isGoogleConfigured {
    return !kIsWeb || _googleClientId.trim().isNotEmpty;
  }

  bool get canUseGoogleAppButton {
    return isGoogleConfigured && _googleSignIn.supportsAuthenticate();
  }

  bool get shouldUseGoogleWebButton {
    return kIsWeb && isGoogleConfigured && !canUseGoogleAppButton;
  }

  Future<void> initializeGoogleSignIn() {
    final clientId = _emptyToNull(_googleClientId);
    final serverClientId = _emptyToNull(_googleServerClientId);

    return _googleInitializeFuture ??= _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  Stream<AuthUser?> googleAuthUserEvents() async* {
    await initializeGoogleSignIn();

    await for (final event in _googleSignIn.authenticationEvents) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          yield _authUserFromGoogleAccount(event.user);
        case GoogleSignInAuthenticationEventSignOut():
          yield null;
      }
    }
  }

  Future<void> attemptGoogleLightweightAuthentication() async {
    await initializeGoogleSignIn();
    unawaited(_googleSignIn.attemptLightweightAuthentication());
  }

  Future<AuthUser> signInWithKakao() =>
      _mockSignIn(provider: 'kakao', displayName: '카카오 친구');

  Future<AuthUser> signInWithGoogle() async {
    await initializeGoogleSignIn();

    if (!isGoogleConfigured) {
      throw const GoogleSignInMissingClientIdException();
    }

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const GoogleSignInWebButtonRequiredException();
    }

    final account = await _googleSignIn.authenticate();
    return _authUserFromGoogleAccount(account);
  }

  Future<AuthUser> signInWithNaver() =>
      _mockSignIn(provider: 'naver', displayName: '네이버 친구');

  Future<void> signOut() async {
    await initializeGoogleSignIn();
    await _googleSignIn.signOut();
  }

  Future<AuthUser> _mockSignIn({
    required String provider,
    required String displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));

    return AuthUser(
      id: 'mock-$provider-user',
      provider: provider,
      displayName: displayName,
      email: '$provider-user@example.com',
    );
  }

  AuthUser _authUserFromGoogleAccount(GoogleSignInAccount account) {
    return AuthUser(
      id: account.id,
      provider: 'google',
      displayName: account.displayName ?? account.email,
      email: account.email,
      profileImageUrl: account.photoUrl,
    );
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class GoogleSignInWebButtonRequiredException implements Exception {
  const GoogleSignInWebButtonRequiredException();
}

class GoogleSignInMissingClientIdException implements Exception {
  const GoogleSignInMissingClientIdException();
}
