import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_radius.dart';
import '../../shared/onmu_design.dart';
import 'data/social_auth_service.dart';
import 'domain/auth_user.dart';
import 'providers/auth_providers.dart';
import 'widgets/google_sign_in_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthUser?>? _googleAuthSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_connectGoogleSignIn());
  }

  @override
  void dispose() {
    unawaited(_googleAuthSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          children: [
            Text(
              'ONMU',
              textAlign: TextAlign.center,
              style: textTheme.displayMedium?.copyWith(
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '오늘의 코디와 약속 기록을\n귀여운 픽셀 캐릭터로 남겨봐요.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSub,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            const OnmuCharacterHero(compact: true),
            const SizedBox(height: 28),
            _LoginButton(
              label: '카카오로 시작하기',
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: AppColors.textMain,
              iconAsset: 'assets/images/auth/kakao_logo.png',
              fallbackIconLabel: 'T',
              fallbackIconBackground: const Color(0xFF371D1E),
              fallbackIconForeground: const Color(0xFFFEE500),
              onPressed: _isLoading
                  ? null
                  : () => _signIn(_SocialProvider.kakao),
            ),
            const SizedBox(height: 12),
            _buildGoogleSignInArea(context),
            const SizedBox(height: 12),
            _LoginButton(
              label: '네이버로 시작하기',
              backgroundColor: const Color(0xFF03C75A),
              foregroundColor: AppColors.textInverse,
              iconAsset: 'assets/images/auth/naver_logo.png',
              fallbackIconLabel: 'N',
              fallbackIconBackground: const Color(0xFF03C75A),
              fallbackIconForeground: Colors.white,
              onPressed: _isLoading
                  ? null
                  : () => _signIn(_SocialProvider.naver),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryPinkSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.linePink),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _signIn(_SocialProvider provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final actions = ref.read(authActionProvider);
      switch (provider) {
        case _SocialProvider.kakao:
          await actions.signInWithKakao();
        case _SocialProvider.google:
          await actions.signInWithGoogle();
        case _SocialProvider.naver:
          await actions.signInWithNaver();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageForSignInError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _connectGoogleSignIn() async {
    final service = ref.read(socialAuthServiceProvider);
    final actions = ref.read(authActionProvider);

    if (!actions.isGoogleConfigured) {
      return;
    }

    try {
      _googleAuthSubscription = service.googleAuthUserEvents().listen(
        (user) {
          if (user != null) {
            actions.applyGoogleAuthUser(user);
          }
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _errorMessage = _messageForSignInError(error);
          });
        },
      );
      await actions.attemptGoogleLightweightAuthentication();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageForSignInError(error);
      });
    }
  }

  Widget _buildGoogleSignInArea(BuildContext context) {
    final actions = ref.read(authActionProvider);

    if (!actions.isGoogleConfigured) {
      return _LoginButton(
        label: '구글로 시작하기',
        backgroundColor: AppColors.bgDefault,
        foregroundColor: AppColors.textMain,
        borderColor: AppColors.lineSoft,
        iconAsset: 'assets/images/auth/google_logo.png',
        fallbackIconLabel: 'G',
        fallbackIconForeground: AppColors.primaryPurple,
        onPressed: _isLoading
            ? null
            : () {
                setState(() {
                  _errorMessage =
                      'Google Client ID가 설정되지 않았어요. GOOGLE_CLIENT_ID 값을 넣고 다시 실행해 주세요.';
                });
              },
      );
    }

    if (actions.shouldUseGoogleWebButton) {
      return Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: _LoginButton.width,
          height: _LoginButton.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: _LoginButton(
                  label: '구글로 시작하기',
                  backgroundColor: AppColors.bgDefault,
                  foregroundColor: AppColors.textMain,
                  borderColor: AppColors.lineSoft,
                  iconAsset: 'assets/images/auth/google_logo.png',
                  fallbackIconLabel: 'G',
                  fallbackIconForeground: AppColors.primaryPurple,
                  onPressed: () {},
                ),
              ),
              Opacity(opacity: 0.01, child: buildGoogleSignInButton()),
            ],
          ),
        ),
      );
    }

    return _LoginButton(
      label: '구글로 시작하기',
      backgroundColor: AppColors.bgDefault,
      foregroundColor: AppColors.textMain,
      borderColor: AppColors.lineSoft,
      iconAsset: 'assets/images/auth/google_logo.png',
      fallbackIconLabel: 'G',
      fallbackIconForeground: AppColors.primaryPurple,
      onPressed: _isLoading ? null : () => _signIn(_SocialProvider.google),
    );
  }

  String _messageForSignInError(Object error) {
    if (error is GoogleSignInMissingClientIdException) {
      return 'Google Client ID가 설정되지 않았어요. GOOGLE_CLIENT_ID 값을 넣고 다시 실행해 주세요.';
    }
    if (error is GoogleSignInWebButtonRequiredException) {
      return '웹에서는 Google 공식 로그인 버튼으로 진행해 주세요.';
    }
    return '로그인을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.';
  }
}

enum _SocialProvider { kakao, google, naver }

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.borderColor,
    this.iconAsset,
    this.fallbackIconLabel,
    this.fallbackIconBackground,
    this.fallbackIconForeground,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final String? iconAsset;
  final String? fallbackIconLabel;
  final Color? fallbackIconBackground;
  final Color? fallbackIconForeground;

  static const double width = 240;
  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: foregroundColor,
      fontWeight: FontWeight.w700,
    );

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: width,
        height: height,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            disabledBackgroundColor: AppColors.lineSoft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: borderColor ?? backgroundColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: _LoginButtonIcon(
                  iconAsset: iconAsset,
                  fallbackLabel: fallbackIconLabel,
                  fallbackBackground: fallbackIconBackground,
                  fallbackForeground: fallbackIconForeground,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButtonIcon extends StatelessWidget {
  const _LoginButtonIcon({
    required this.iconAsset,
    required this.fallbackLabel,
    required this.fallbackBackground,
    required this.fallbackForeground,
  });

  final String? iconAsset;
  final String? fallbackLabel;
  final Color? fallbackBackground;
  final Color? fallbackForeground;

  @override
  Widget build(BuildContext context) {
    if (iconAsset != null) {
      return Center(
        child: Image.asset(
          iconAsset!,
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return _FallbackBrandIcon(
              label: fallbackLabel,
              background: fallbackBackground,
              foreground: fallbackForeground,
            );
          },
        ),
      );
    }

    return _FallbackBrandIcon(
      label: fallbackLabel,
      background: fallbackBackground,
      foreground: fallbackForeground,
    );
  }
}

class _FallbackBrandIcon extends StatelessWidget {
  const _FallbackBrandIcon({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String? label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: background ?? Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label!,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground ?? AppColors.textMain,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
