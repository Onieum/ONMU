import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/asset_crop_image.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onTimeout;

  const SplashPage({super.key, required this.onTimeout});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _splashLogoAsset =
      'assets/images/splash/ONMU_splash_logo.png';
  static const _splashImageSize = Size(1341, 1173);
  static const _logoCrop = Rect.fromLTWH(420, 130, 520, 270);
  static const _characterCrop = Rect.fromLTWH(180, 380, 980, 710);

  bool _completed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 4800), _complete);
  }

  void _complete() {
    if (!mounted || _completed) {
      return;
    }

    _completed = true;
    widget.onTimeout();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _complete,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFCF8),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = _SplashLayout.from(constraints);

              return Stack(
                children: [
                  const Positioned.fill(child: _SplashBackground()),
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
                    top: layout.messageTop,
                    left: 24,
                    right: 24,
                    child: const _SplashMessage(),
                  ),
                  Positioned(
                    top: layout.progressTop,
                    left: 0,
                    right: 0,
                    child: const Center(child: _SplashProgress()),
                  ),
                  Positioned(
                    top: layout.progressTop + 28,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Loading...',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: const Color(0xFFFF7288),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashLayout {
  const _SplashLayout({
    required this.logoTop,
    required this.logoWidth,
    required this.characterTop,
    required this.characterWidth,
    required this.messageTop,
    required this.progressTop,
  });

  final double logoTop;
  final double logoWidth;
  final double characterTop;
  final double characterWidth;
  final double messageTop;
  final double progressTop;

  static _SplashLayout from(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final compact = height < 720;
    final logoWidth = (width * 0.7).clamp(220.0, compact ? 250.0 : 310.0);
    final characterWidth = (width * 0.92).clamp(
      300.0,
      compact ? 360.0 : 430.0,
    );

    return _SplashLayout(
      logoTop: (height * 0.07).clamp(34.0, 72.0),
      logoWidth: logoWidth,
      characterTop: height * (compact ? 0.28 : 0.32),
      characterWidth: characterWidth,
      messageTop: height * (compact ? 0.66 : 0.68),
      progressTop: height * (compact ? 0.82 : 0.84),
    );
  }
}

class _SplashMessage extends StatelessWidget {
  const _SplashMessage();

  @override
  Widget build(BuildContext context) {
    return Text(
      '약속을 잡고,\n함께한 순간을 기록해요',
      textAlign: TextAlign.center,
      style: AppTextStyles.titleMedium.copyWith(
        color: const Color(0xFF8A6F63),
        height: 1.45,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      height: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFECE7E3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 0.62,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFF637B),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SplashBackgroundPainter());
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.bgPaper.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;

    final upper = Path()
      ..moveTo(0, size.height * 0.38)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.32,
        size.width * 0.64,
        size.height * 0.31,
        size.width * 0.86,
        size.height * 0.39,
      )
      ..cubicTo(
        size.width * 1.05,
        size.height * 0.46,
        size.width * 0.96,
        size.height * 0.56,
        size.width * 0.74,
        size.height * 0.56,
      )
      ..lineTo(size.width * 0.16, size.height * 0.56)
      ..cubicTo(
        size.width * -0.02,
        size.height * 0.56,
        size.width * -0.07,
        size.height * 0.44,
        0,
        size.height * 0.38,
      )
      ..close();

    final lower = Path()
      ..moveTo(size.width, size.height * 0.78)
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.75,
        size.width * 0.76,
        size.height * 0.88,
        size.width * 0.52,
        size.height * 0.87,
      )
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.86,
        size.width * 0.18,
        size.height * 0.76,
        0,
        size.height * 0.81,
      )
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(upper, paint);
    canvas.drawPath(lower, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
