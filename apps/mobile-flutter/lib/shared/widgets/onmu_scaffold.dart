import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'onmu_top_bar.dart';

class OnmuScaffold extends StatelessWidget {
  const OnmuScaffold({
    required this.children,
    this.title,
    this.showBackButton = false,
    this.onBack,
    this.action,
    this.bottom,
    this.floatingActionButton,
    this.useWarmBackground = true,
    super.key,
  });

  final List<Widget> children;
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? action;
  final Widget? bottom;
  final Widget? floatingActionButton;
  final bool useWarmBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: useWarmBackground
          ? AppColors.bgWarm
          : AppColors.bgDefault,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            if (title != null)
              OnmuTopBar(
                title: title!,
                showBackButton: showBackButton,
                onBack: onBack,
                action: action,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: children,
              ),
            ),
            if (bottom != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: bottom,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
