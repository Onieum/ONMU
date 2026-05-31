import 'package:flutter/material.dart';

import '../../shared/onmu_design.dart';
import 'start_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const StartPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: OnmuColors.bgDefault,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Text(
                'ONMU',
                style: TextStyle(
                  color: OnmuColors.purple,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 18),
              OnmuCharacterHero(compact: true),
              SizedBox(height: 18),
              Text(
                '오늘의 취향을 불러오는 중',
                style: TextStyle(
                  color: OnmuColors.textSub,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 24),
              LinearProgressIndicator(
                minHeight: 7,
                borderRadius: BorderRadius.all(Radius.circular(8)),
                backgroundColor: OnmuColors.purpleSoft,
                color: OnmuColors.pink,
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
