import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';

class OnmuApp extends StatelessWidget {
  const OnmuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _OnmuMaterialApp());
  }
}

class _OnmuMaterialApp extends StatelessWidget {
  const _OnmuMaterialApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ONMU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
