import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_paths.dart';
import '../../core/theme/app_radius.dart';
import '../../shared/onmu_design.dart';
import '../../shared/widgets/asset_crop_image.dart';
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
  static const _splashLogoAsset = 'assets/images/splash/ONMU_splash_logo.png';
  static const _splashImageSize = Size(1341, 1173);
  static const _logoCrop = Rect.fromLTWH(420, 130, 520, 270);
  static const _characterCrop = Rect.fromLTWH(180, 380, 980, 710);

  _SocialProvider? _loadingProvider;
  String? _errorMessage;
  StreamSubscription<AuthUser?>? _googleAuthSubscription;
  bool _redirectScheduled = false;

  bool get _isLoading => _loadingProvider != null;

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
    final authBootstrap = ref.watch(authBootstrapProvider);
    final authenticatedUser = authBootstrap.asData?.value.user;
    if (authenticatedUser != null) {
      _redirectAuthenticatedUser(authenticatedUser);
      return const Scaffold(
        backgroundColor: Color(0xFFFFFCF8),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (authBootstrap.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFCF8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _LoginLayout.from(constraints);

            return Stack(
              children: [
                const Positioned.fill(child: _LoginBackground()),
                Positioned(
                  top: layout.logoTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AssetCropImage(
                      assetPath: _splashLogoAsset,
                      imageSize: _splashImageSize,
                      cropRect: _logoCrop,
                      width: layout.logoWidth,
                    ),
                  ),
                ),
                Positioned(
                  top: layout.characterTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AssetCropImage(
                      assetPath: _splashLogoAsset,
                      imageSize: _splashImageSize,
                      cropRect: _characterCrop,
                      width: layout.characterWidth,
                    ),
                  ),
                ),
                Positioned(
                  top: layout.buttonsTop,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      _LoginButton(
                        width: layout.buttonWidth,
                        height: layout.buttonHeight,
                        label: '카카오로 시작하기',
                        backgroundColor: AppColors.bgDefault,
                        foregroundColor: Colors.black,
                        borderColor: const Color(0xFFFF9CAD),
                        iconAsset: 'assets/images/auth/kakao_logo.png',
                        fallbackIconLabel: 'TALK',
                        fallbackIconBackground: const Color(0xFFFEE500),
                        fallbackIconForeground: const Color(0xFF371D1E),
                        isLoading: _loadingProvider == _SocialProvider.kakao,
                        onPressed: () => _signIn(_SocialProvider.kakao),
                      ),
                      SizedBox(height: layout.buttonGap),
                      _buildGoogleSignInArea(layout),
                      SizedBox(height: layout.buttonGap),
                      _LoginButton(
                        width: layout.buttonWidth,
                        height: layout.buttonHeight,
                        label: '네이버로 시작하기',
                        backgroundColor: AppColors.bgDefault,
                        foregroundColor: Colors.black,
                        borderColor: const Color(0xFF8FE0A8),
                        iconAsset: 'assets/images/auth/naver_logo.png',
                        fallbackIconLabel: 'N',
                        fallbackIconBackground: Colors.transparent,
                        fallbackIconForeground: const Color(0xFF03C75A),
                        isLoading: _loadingProvider == _SocialProvider.naver,
                        onPressed: () => _signIn(_SocialProvider.naver),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_errorMessage != null)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 96,
                    child: _ErrorMessage(message: _errorMessage!),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _redirectAuthenticatedUser(AuthUser user) {
    if (_redirectScheduled) {
      return;
    }

    _redirectScheduled = true;
    final route = user.hasCompletedOnboarding
        ? RoutePaths.home
        : RoutePaths.onboarding;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(route);
      }
    });
  }

  Future<void> _signIn(_SocialProvider provider) async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _loadingProvider = provider;
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
      if (mounted) {
        context.go(RoutePaths.onboarding);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageForSignInError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingProvider = null;
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
            final accepted = actions.applyGoogleAuthUser(user);
            if (!accepted && mounted) {
              setState(() {
                _errorMessage = _messageForSignInError(
                  const GoogleSpringOAuthUnavailableException(),
                );
              });
            }
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

  Widget _buildGoogleSignInArea(_LoginLayout layout) {
    final actions = ref.read(authActionProvider);

    if (!actions.isGoogleConfigured) {
      return _LoginButton(
        width: layout.buttonWidth,
        height: layout.buttonHeight,
        label: '구글로 시작하기',
        backgroundColor: AppColors.bgDefault,
        foregroundColor: Colors.black,
        borderColor: const Color(0xFFE2DAD5),
        iconAsset: 'assets/images/auth/google_logo.png',
        fallbackIconLabel: 'G',
        fallbackIconForeground: AppColors.primaryPurple,
        isLoading: _loadingProvider == _SocialProvider.google,
        onPressed: () {
          if (_isLoading) {
            return;
          }

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
          width: layout.buttonWidth,
          height: layout.buttonHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: _LoginButton(
                  width: layout.buttonWidth,
                  height: layout.buttonHeight,
                  label: '구글로 시작하기',
                  backgroundColor: AppColors.bgDefault,
                  foregroundColor: Colors.black,
                  borderColor: const Color(0xFFE2DAD5),
                  iconAsset: 'assets/images/auth/google_logo.png',
                  fallbackIconLabel: 'G',
                  fallbackIconForeground: AppColors.primaryPurple,
                  isLoading: _loadingProvider == _SocialProvider.google,
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
      width: layout.buttonWidth,
      height: layout.buttonHeight,
      label: '구글로 시작하기',
      backgroundColor: AppColors.bgDefault,
      foregroundColor: Colors.black,
      borderColor: const Color(0xFFE2DAD5),
      iconAsset: 'assets/images/auth/google_logo.png',
      fallbackIconLabel: 'G',
      fallbackIconForeground: AppColors.primaryPurple,
      isLoading: _loadingProvider == _SocialProvider.google,
      onPressed: () => _signIn(_SocialProvider.google),
    );
  }

  String _messageForSignInError(Object error) {
    if (error is KakaoSignInUnavailableException) {
      return 'Kakao OAuth 설정이 아직 연결되지 않았어요. SDK 설정 후 다시 시도해 주세요.';
    }
    if (error is GoogleSignInMissingClientIdException) {
      return 'Google Client ID가 설정되지 않았어요. GOOGLE_CLIENT_ID 값을 넣고 다시 실행해 주세요.';
    }
    if (error is GoogleSignInWebButtonRequiredException) {
      return '웹에서는 Google 공식 로그인 버튼으로 진행해 주세요.';
    }
    if (error is GoogleSpringOAuthUnavailableException) {
      return 'Google 로그인은 Spring idToken 검증이 연결된 뒤 사용할 수 있어요.';
    }
    return '로그인을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.';
  }
}

enum _SocialProvider { kakao, google, naver }

class _LoginLayout {
  const _LoginLayout({
    required this.logoTop,
    required this.logoWidth,
    required this.taglineTop,
    required this.characterTop,
    required this.characterWidth,
    required this.buttonsTop,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.buttonGap,
  });

  final double logoTop;
  final double logoWidth;
  final double taglineTop;
  final double characterTop;
  final double characterWidth;
  final double buttonsTop;
  final double buttonWidth;
  final double buttonHeight;
  final double buttonGap;

  static _LoginLayout from(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final compact = height < 720;
    final logoWidth = (width * 0.7).clamp(220.0, compact ? 250.0 : 310.0);
    final characterWidth = (width * 0.92).clamp(300.0, compact ? 360.0 : 430.0);

    return _LoginLayout(
      logoTop: (height * 0.07).clamp(34.0, 72.0),
      logoWidth: logoWidth,
      taglineTop: height * (compact ? 0.24 : 0.22),
      characterTop: height * (compact ? 0.28 : 0.32),
      characterWidth: characterWidth,
      buttonsTop: height * (compact ? 0.68 : 0.66),
      buttonWidth: (width - 56).clamp(280.0, 338.0),
      buttonHeight: compact ? 46.0 : 54.0,
      buttonGap: compact ? 8.0 : 12.0,
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    required this.width,
    required this.height,
    this.borderColor,
    this.iconAsset,
    this.fallbackIconLabel,
    this.fallbackIconBackground,
    this.fallbackIconForeground,
    this.isLoading = false,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final Color? borderColor;
  final String? iconAsset;
  final String? fallbackIconLabel;
  final Color? fallbackIconBackground;
  final Color? fallbackIconForeground;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final iconSize = height <= 48 ? 24.0 : 28.0;
    final effectiveBackgroundColor = isLoading
        ? AppColors.primaryPinkSoft
        : backgroundColor;
    final effectiveBorderColor = isLoading
        ? AppColors.primaryPink
        : borderColor ?? backgroundColor;

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: width,
        height: height,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: foregroundColor,
            disabledBackgroundColor: effectiveBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
              side: BorderSide(color: effectiveBorderColor, width: 1.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: iconSize,
                  child: _LoginButtonIcon(
                    iconAsset: iconAsset,
                    fallbackLabel: fallbackIconLabel,
                    fallbackBackground: fallbackIconBackground,
                    fallbackForeground: fallbackIconForeground,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
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
          width: 24,
          height: 24,
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
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: background ?? Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label!,
          style: AppTextStyles.micro.copyWith(
            color: foreground ?? AppColors.textMain,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryPinkSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.linePink),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMain),
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SoftBackgroundPainter());
  }
}

class _SoftBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.bgPaper.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromLTWH(-56, 8, size.width * 0.48, size.height * 0.1),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.74,
        size.height * 0.9,
        size.width * 0.38,
        size.height * 0.1,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
