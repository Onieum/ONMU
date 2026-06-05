import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../shared/models/character_model.dart';
import '../../shared/widgets/pixel_character.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onTimeout;

  const SplashPage({super.key, required this.onTimeout});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
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
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: _complete,
      child: Scaffold(
        backgroundColor: AppColors.bgWarm,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned(left: 12, top: 18, child: _TapeSticker()),
              Positioned(
                right: -20,
                bottom: -12,
                child: Transform.rotate(
                  angle: -0.32,
                  child: const _PaperCorner(),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ONMU',
                        style: textTheme.displayLarge?.copyWith(
                          letterSpacing: 1.5,
                          color: AppColors.primaryPink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _SplashCharacterGroup(),
                      const SizedBox(height: 20),
                      const _HeartSpeechBubble(),
                      const SizedBox(height: 14),
                      Text(
                        '약속을 잡고,',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '함께한 순간을 기록해요',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _HandDrawnUnderline(),
                      const SizedBox(height: 38),
                      SizedBox(
                        width: 158,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: const LinearProgressIndicator(
                            minHeight: 10,
                            value: 0.58,
                            backgroundColor: AppColors.bgDefault,
                            color: AppColors.primaryPink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashCharacterGroup extends StatelessWidget {
  const _SplashCharacterGroup();

  static const _topLeftCharacter = CharacterDraft(
    gender: 'male',
    skinToneIndex: 0,
    eyeShapeIndex: 0,
    eyeColorIndex: 1,
    hairColorIndex: 0,
    hairStyleIndex: 1,
    topStyleIndex: 0,
  );

  static const _topRightCharacter = CharacterDraft(
    gender: 'female',
    skinToneIndex: 1,
    eyeShapeIndex: 0,
    eyeColorIndex: 0,
    hairColorIndex: 2,
    hairStyleIndex: 5,
    topStyleIndex: 1,
  );

  static const _bottomLeftCharacter = CharacterDraft(
    gender: 'male',
    skinToneIndex: 2,
    eyeShapeIndex: 1,
    eyeColorIndex: 0,
    hairColorIndex: 1,
    hairStyleIndex: 4,
    topStyleIndex: 2,
  );

  static const _bottomRightCharacter = CharacterDraft(
    gender: 'female',
    skinToneIndex: 0,
    eyeShapeIndex: 1,
    eyeColorIndex: 1,
    hairColorIndex: 0,
    hairStyleIndex: 3,
    topStyleIndex: 2,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: const [
          Positioned(left: 38, top: 36, child: _Sparkle(size: 9)),
          Positioned(right: 48, top: 34, child: _Sparkle(size: 7)),
          Positioned(left: 34, bottom: 72, child: _Sparkle(size: 8)),
          Positioned(right: 32, bottom: 70, child: _Sparkle(size: 8)),
          Positioned.fill(child: _HeartOrbit()),
          Positioned(
            left: 42,
            top: 4,
            child: _FriendlyCharacter(character: _topLeftCharacter, size: 96),
          ),
          Positioned(
            right: 42,
            top: 4,
            child: _FriendlyCharacter(character: _topRightCharacter, size: 96),
          ),
          Positioned(
            left: 38,
            bottom: 2,
            child: _FriendlyCharacter(
              character: _bottomLeftCharacter,
              size: 94,
            ),
          ),
          Positioned(
            right: 42,
            bottom: 2,
            child: _FriendlyCharacter(
              character: _bottomRightCharacter,
              size: 94,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendlyCharacter extends StatelessWidget {
  final CharacterDraft character;
  final double size;

  const _FriendlyCharacter({required this.character, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PixelCharacterWidget(character: character, size: size),
          IgnorePointer(child: CustomPaint(painter: _SmilePainter())),
        ],
      ),
    );
  }
}

class _HeartOrbit extends StatelessWidget {
  const _HeartOrbit();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HeartOrbitPainter());
  }
}

class _Sparkle extends StatelessWidget {
  final double size;

  const _Sparkle({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SparklePainter()),
    );
  }
}

class _HeartSpeechBubble extends StatelessWidget {
  const _HeartSpeechBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: const Icon(
        Icons.favorite_rounded,
        size: 13,
        color: AppColors.primaryPink,
      ),
    );
  }
}

class _TapeSticker extends StatelessWidget {
  const _TapeSticker();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.34,
      child: Container(
        width: 56,
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.primaryPinkSoft,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            5,
            (_) =>
                Container(width: 3, height: 18, color: AppColors.primaryPink),
          ),
        ),
      ),
    );
  }
}

class _PaperCorner extends StatelessWidget {
  const _PaperCorner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _HandDrawnUnderline extends StatelessWidget {
  const _HandDrawnUnderline();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      height: 14,
      child: CustomPaint(painter: _UnderlinePainter()),
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryPink
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final first = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.2,
        size.width * 0.48,
        size.height * 0.58,
      );
    final second = Path()
      ..moveTo(size.width * 0.55, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.24,
        size.width,
        size.height * 0.5,
      );
    canvas.drawPath(first, paint);
    canvas.drawPath(second, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeartOrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + 6),
      width: size.width * 0.58,
      height: size.height * 0.48,
    );
    final paint = Paint()
      ..color = AppColors.primaryPink.withValues(alpha: 0.58)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const dashCount = 24;
    for (var i = 0; i < dashCount; i++) {
      if (i.isOdd) continue;
      final start = i * 2 * 3.141592653589793 / dashCount;
      final sweep = 3.141592653589793 / dashCount;
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryPink.withValues(alpha: 0.64)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cheekPaint = Paint()
      ..color = AppColors.primaryPink.withValues(alpha: 0.36)
      ..style = PaintingStyle.fill;
    final smilePaint = Paint()
      ..color = AppColors.textMain.withValues(alpha: 0.72)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final faceY = size.height * 0.43;
    final centerX = size.width * 0.5;
    final cheekRadius = size.width * 0.035;

    canvas.drawCircle(
      Offset(size.width * 0.38, faceY + size.height * 0.028),
      cheekRadius,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, faceY + size.height * 0.028),
      cheekRadius,
      cheekPaint,
    );

    final smile = Path()
      ..moveTo(centerX - size.width * 0.035, faceY + size.height * 0.05)
      ..quadraticBezierTo(
        centerX,
        faceY + size.height * 0.078,
        centerX + size.width * 0.035,
        faceY + size.height * 0.05,
      );
    canvas.drawPath(smile, smilePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lineSoft
      ..strokeWidth = 0.8;

    for (var offset = 12.0; offset < size.width; offset += 14) {
      canvas.drawLine(Offset(offset, 0), Offset(offset, size.height), paint);
      canvas.drawLine(Offset(0, offset), Offset(size.width, offset), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
