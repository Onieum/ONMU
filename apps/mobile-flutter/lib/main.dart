import 'package:flutter/material.dart';

import 'features/launch/splash_page.dart';

void main() {
  runApp(const OnmuApp());
}

class OnmuApp extends StatelessWidget {
  const OnmuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONMU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        fontFamily: 'Pretendard',
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}
