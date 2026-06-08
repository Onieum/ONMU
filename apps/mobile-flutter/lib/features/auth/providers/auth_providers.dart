import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/social_auth_service.dart';
import '../domain/auth_user.dart';

final socialAuthServiceProvider = Provider<SocialAuthService>((ref) {
  return SocialAuthService();
});

final authUserProvider = StateProvider<AuthUser?>((ref) => null);

final authActionProvider = Provider<AuthActionController>((ref) {
  return AuthActionController(ref);
});

class AuthActionController {
  const AuthActionController(this._ref);

  final Ref _ref;

  Future<void> signInWithKakao() async {
    final user = await _ref.read(socialAuthServiceProvider).signInWithKakao();
    _ref.read(authUserProvider.notifier).state = user;
  }

  Future<void> signInWithGoogle() async {
    final user = await _ref.read(socialAuthServiceProvider).signInWithGoogle();
    _ref.read(authUserProvider.notifier).state = user;
  }

  Future<void> initializeGoogleSignIn() {
    return _ref.read(socialAuthServiceProvider).initializeGoogleSignIn();
  }

  Future<void> attemptGoogleLightweightAuthentication() {
    return _ref
        .read(socialAuthServiceProvider)
        .attemptGoogleLightweightAuthentication();
  }

  void applyGoogleAuthUser(AuthUser? user) {
    _ref.read(authUserProvider.notifier).state = user;
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
    final user = await _ref.read(socialAuthServiceProvider).signInWithNaver();
    _ref.read(authUserProvider.notifier).state = user;
  }

  Future<void> signOut() async {
    await _ref.read(socialAuthServiceProvider).signOut();
    _ref.read(authUserProvider.notifier).state = null;
  }
}
