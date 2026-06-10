import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/api/onmu_api_client.dart';
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
  return AuthBootstrapResult(user: user);
});

final authActionProvider = Provider<AuthActionController>((ref) {
  return AuthActionController(ref);
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
    throw const GoogleSpringOAuthUnavailableException();
  }

  Future<void> initializeGoogleSignIn() {
    return _ref.read(socialAuthServiceProvider).initializeGoogleSignIn();
  }

  Future<void> attemptGoogleLightweightAuthentication() {
    return _ref
        .read(socialAuthServiceProvider)
        .attemptGoogleLightweightAuthentication();
  }

  bool applyGoogleAuthUser(AuthUser? user) {
    if (user == null) {
      _ref.read(authUserProvider.notifier).state = null;
      return true;
    }
    return false;
  }

  bool get isGoogleConfigured {
    return _ref.read(socialAuthServiceProvider).isGoogleConfigured;
  }

  bool get canUseGoogleAppButton {
    return _ref.read(socialAuthServiceProvider).canUseGoogleAppButton;
  }

  bool get shouldUseGoogleWebButton {
    return _ref.read(socialAuthServiceProvider).shouldUseGoogleWebButton;
  }

  Future<void> signInWithNaver() async {
    final credential = await _ref
        .read(socialAuthServiceProvider)
        .acquireNaverCredential();
    await _completeOAuthLogin(credential);
  }

  Future<void> signOut() async {
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
    _ref.read(authUserProvider.notifier).state = session.user;
  }
}
