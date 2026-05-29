import 'package:flutter/material.dart';
import 'main_shell.dart';

void main() {
  runApp(const OnmuApp());
}

/// 앱 진입점. 초기화와 테마 설정만 담당한다.
/// 라우팅과 화면은 main_shell.dart → features/* 에서 관리한다.
class OnmuApp extends StatelessWidget {
  const OnmuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONMU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6), // primary.purple
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF), // bg.default
        fontFamily: 'Pretendard',
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}
