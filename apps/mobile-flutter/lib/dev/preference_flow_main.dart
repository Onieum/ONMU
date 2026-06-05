import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/launch/splash_page.dart';
import '../features/preferences/preference_intro_page.dart';
import '../shared/models/preference_profile.dart';

void main() {
  runApp(const ProviderScope(child: PreferenceFlowPreviewApp()));
}

class PreferenceFlowPreviewApp extends StatelessWidget {
  const PreferenceFlowPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONMU Preference Flow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const PreferenceFlowPreviewHome(),
    );
  }
}

class PreferenceFlowPreviewHome extends StatefulWidget {
  const PreferenceFlowPreviewHome({super.key});

  @override
  State<PreferenceFlowPreviewHome> createState() =>
      _PreferenceFlowPreviewHomeState();
}

class _PreferenceFlowPreviewHomeState extends State<PreferenceFlowPreviewHome> {
  bool _showPreferenceFlow = false;

  @override
  Widget build(BuildContext context) {
    if (_showPreferenceFlow) {
      return PreferenceIntroPage(profile: PreferenceProfile.empty());
    }

    return SplashPage(
      onTimeout: () {
        setState(() {
          _showPreferenceFlow = true;
        });
      },
    );
  }
}
