import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../notifications/repository/device_push_token_repository.dart';
import '../data/auth_token_store.dart';
import '../data/social_auth_service.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import '../domain/oauth_provider_credential.dart';
import '../repository/auth_repository.dart';

final socialAuthServiceProvider = Provider<SocialAuthService>((ref) {
  return SocialAuthService();
});

final authUserProvider = StateProvider<AuthUser?>((ref) => null);

final authBootstrapProvider = FutureProvider<AuthBootstrapResult>((ref) async {
  final existingUser = ref.read(authUserProvider);
  if (existingUser != null) {
    return AuthBootstrapResult(user: existingUser);
  }

  final storedTokens = await ref.watch(authTokenStoreProvider).read();
  if (storedTokens != null) {
    ref.read(onmuApiClientProvider).setAccessToken(storedTokens.accessToken);
  }

  final repository = ref.watch(authRepositoryProvider);
  final user = await repository.fetchCurrentUser();
  if (user == null && storedTokens != null) {
    await ref.read(authTokenStoreProvider).clear();
    ref.read(onmuApiClientProvider).clearAccessToken();
  }
  ref.read(authUserProvider.notifier).state = user;
  if (user != null) {
    await ref
        .read(pushTokenRegistrationCoordinatorProvider)
        .registerCurrentDevice();
  }
  return AuthBootstrapResult(user: user);
});

final authActionProvider = Provider<AuthActionController>((ref) {
  return AuthActionController(ref);
});

final googleSignInTimeoutProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 25);
});

class AuthBootstrapResult {
  const AuthBootstrapResult({required this.user});

  final AuthUser? user;

  bool get isAuthenticated => user != null;
}

class AuthActionController {
  const AuthActionController(this._ref);

  final Ref _ref;

  Future<void> signInWithKakao() async {
    final credential = await _ref
        .read(socialAuthServiceProvider)
        .acquireKakaoCredential();
    await _completeOAuthLogin(credential);
  }

  Future<void> signInWithGoogle() async {
    final timeout = _ref.read(googleSignInTimeoutProvider);
    final credential = await _ref
        .read(socialAuthServiceProvider)
        .acquireGoogleCredential()
        .timeout(
          timeout,
          onTimeout: () {
            debugPrint('Google sign-in timed out before credential exchange.');
            throw const GoogleSignInTimeoutException();
          },
        );
    await _completeOAuthLogin(credential);
  }

  Future<void> initializeGoogleSignIn() {
    return _ref.read(socialAuthServiceProvider).initializeGoogleSignIn();
  }

  Future<void> attemptGoogleLightweightAuthentication() {
    return _ref
        .read(socialAuthServiceProvider)
        .attemptGoogleLightweightAuthentication();
  }

  Future<bool> applyGoogleCredential(
    OAuthProviderCredential? credential,
  ) async {
    if (credential == null) {
      await _ref.read(authTokenStoreProvider).clear();
      _ref.read(onmuApiClientProvider).clearAccessToken();
      _ref.read(authUserProvider.notifier).state = null;
      return true;
    }
    await _completeOAuthLogin(credential);
    return true;
  }

  bool get isGoogleConfigured {
    return _ref.read(socialAuthServiceProvider).isGoogleConfigured;
  }

  bool get canUseGoogleAppButton {
    return _ref.read(socialAuthServiceProvider).canUseGoogleAppButton;
  }

  Future<void> signInWithNaver() async {
    final credential = await _ref
        .read(socialAuthServiceProvider)
        .acquireNaverCredential();
    await _completeOAuthLogin(credential);
  }

  Future<void> signOut() async {
    await _ref
        .read(pushTokenRegistrationCoordinatorProvider)
        .deactivateCurrentDevice();
    await _ref.read(socialAuthServiceProvider).signOut();
    await _ref.read(authTokenStoreProvider).clear();
    _ref.read(onmuApiClientProvider).clearAccessToken();
    _ref.read(authUserProvider.notifier).state = null;
  }

  Future<void> _completeOAuthLogin(OAuthProviderCredential credential) async {
    final session = await _ref
        .read(authRepositoryProvider)
        .exchangeOAuthLogin(credential);
    await _applySpringSession(session);
  }

  Future<void> _applySpringSession(AuthSession session) async {
    await _ref.read(authTokenStoreProvider).save(session.tokens);
    _ref.read(onmuApiClientProvider).setAccessToken(session.tokens.accessToken);
    var user = session.user;
    try {
      user =
          await _ref.read(authRepositoryProvider).fetchCurrentUser() ??
          session.user;
    } catch (_) {
      user = session.user;
    }
    _ref.read(authUserProvider.notifier).state = user;
    await _ref
        .read(pushTokenRegistrationCoordinatorProvider)
        .registerCurrentDevice();
  }
}
