import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'grid_background.dart';
import 'onmu_top_bar.dart';

class OnmuScaffold extends StatelessWidget {
  const OnmuScaffold({
    required this.children,
    super.key,
    this.title,
    this.titleSubtitle,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.showBackButton = false,
    this.onBack,
    this.action,
    this.pinnedHeader,
    this.bottom,
    this.floatingActionButton,
    this.scrollController,
    this.useGridBackground = true,
    this.useWarmBackground = true,
  });

  final List<Widget> children;
  final String? title;
  final Widget? titleSubtitle;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? action;
  final Widget? pinnedHeader;
  final Widget? bottom;
  final Widget? floatingActionButton;
  final ScrollController? scrollController;
  final bool useGridBackground;
  final bool useWarmBackground;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        children: [
          if (title != null)
            OnmuTopBar(
              title: title!,
              subtitle: titleSubtitle,
              showBackButton: showBackButton || leading != null,
              onBack: onBack,
              action:
                  action ?? (actions.isEmpty ? null : Row(children: actions)),
            ),
          ?pinnedHeader,
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
    );

    return Scaffold(
      backgroundColor: useGridBackground
          ? AppColors.bgDefault
          : useWarmBackground
          ? AppColors.bgWarm
          : AppColors.bgDefault,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: useGridBackground ? GridBackground(child: content) : content,
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
