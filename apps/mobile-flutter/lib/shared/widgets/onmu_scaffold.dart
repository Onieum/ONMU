import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'onmu_top_bar.dart';

class OnmuScaffold extends StatelessWidget {
  const OnmuScaffold({
    required this.children,
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.showBackButton = false,
    this.onBack,
    this.action,
    this.bottom,
    this.floatingActionButton,
    this.scrollController,
    this.useGridBackground = false,
    this.useWarmBackground = true,
  });

  final List<Widget> children;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? action;
  final Widget? bottom;
  final Widget? floatingActionButton;
  final ScrollController? scrollController;
  final bool useGridBackground;
  final bool useWarmBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: useGridBackground
          ? AppColors.bgGrid
          : useWarmBackground
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
                showBackButton: showBackButton || leading != null,
                onBack: onBack,
                action:
                    action ?? (actions.isEmpty ? null : Row(children: actions)),
              ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
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
    );
  }
}
