import 'package:flutter/material.dart';

import '../../shared/onmu_design.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnmuColors.bgDefault,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '마이 ONMU',
                style: TextStyle(
                  color: OnmuColors.textMain,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              const OnmuCharacterHero(compact: true),
              const SizedBox(height: 18),
              const PaperNote(
                title: '취향 데이터',
                body: '파스타, 브런치, 저녁 약속 선호가 저장되어 있어요.',
                icon: Icons.favorite_border,
              ),
              const SizedBox(height: 12),
              OnmuSecondaryButton(
                label: '취향 다시 입력하기',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
