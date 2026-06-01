import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/grid_background.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      body: GridBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '홈 탭',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'TODO: 홈 화면 개발 예정',
                style: TextStyle(fontSize: 13, color: AppColors.textSub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
