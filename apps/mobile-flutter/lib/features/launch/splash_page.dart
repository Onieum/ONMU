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
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const _SplashCharacterGroup(),
                      const SizedBox(height: 18),
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

  static const _leftCharacter = CharacterDraft(
    gender: 'female',
    skinToneIndex: 0,
    eyeShapeIndex: 0,
    eyeColorIndex: 1,
    hairColorIndex: 1,
    hairStyleIndex: 2,
    topStyleIndex: 0,
  );

  static const _centerCharacter = CharacterDraft(
    gender: 'male',
    skinToneIndex: 1,
    eyeShapeIndex: 2,
    eyeColorIndex: 0,
    hairColorIndex: 0,
    hairStyleIndex: 3,
    topStyleIndex: 1,
  );

  static const _rightCharacter = CharacterDraft(
    gender: 'female',
    skinToneIndex: 2,
    eyeShapeIndex: 1,
    eyeColorIndex: 0,
    hairColorIndex: 1,
    hairStyleIndex: 4,
    topStyleIndex: 2,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: const [
          Positioned(
            left: 58,
            bottom: -6,
            child: PixelCharacterWidget(character: _leftCharacter, size: 74),
          ),
          Positioned(
            right: 58,
            bottom: -6,
            child: PixelCharacterWidget(character: _rightCharacter, size: 74),
          ),
          Positioned(
            bottom: -4,
            child: PixelCharacterWidget(character: _centerCharacter, size: 82),
          ),
        ],
      ),
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
