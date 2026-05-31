import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class OnmuScaffold extends StatelessWidget {
  const OnmuScaffold({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.bottom,
    this.useGridBackground = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final List<Widget> children;
  final Widget? bottom;
  final bool useGridBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: useGridBackground ? AppColors.bgGrid : AppColors.bgWarm,
      appBar: AppBar(leading: leading, title: Text(title), actions: actions),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            if (subtitle != null) ...[
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
            ],
            ...children,
          ],
        ),
      ),
      bottomNavigationBar: bottom,
    );
  }
}
