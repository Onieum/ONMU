import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/grid_background.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onTimeout;

  const SplashPage({
    super.key,
    required this.onTimeout,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // 1.5초 후 자동 다음 화면 이동
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onTimeout();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTimeout, // 터치 시 즉시 건너뛰기
      child: Scaffold(
        backgroundColor: AppColors.bgWarm,
        body: GridBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Accent (Heart Sticker style)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPinkSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 80,
                    color: AppColors.primaryPink,
                  ),
                ),
                const SizedBox(height: 24),
                
                // App Logo Title
                const Text(
                  'ONMU',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryPurple,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  '오늘의 코디와 일상을 픽셀로 기록해요',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Subtle loading indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.0,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
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
