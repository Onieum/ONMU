import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../shared/onmu_design.dart';

class PreferencePageFrame extends StatelessWidget {
  final int currentStep;
  final int stepCount;
  final String title;
  final Widget child;
  final String buttonLabel;
  final VoidCallback? onNext;

  const PreferencePageFrame({
    super.key,
    required this.currentStep,
    required this.stepCount,
    required this.title,
    required this.child,
    required this.buttonLabel,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / stepCount;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: AppColors.primaryPurpleSoft,
                            color: AppColors.primaryPink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$currentStep/$stepCount',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (currentStep > 1) ...[
                    Expanded(
                      child: OnmuSecondaryButton(
                        label: '이전',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: currentStep == 1 ? 1 : 2,
                    child: OnmuPrimaryButton(
                      label: buttonLabel,
                      onPressed: onNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreferenceOptionSection extends StatelessWidget {
  final String title;
  final String caption;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;
  final bool isDislike;

  const PreferenceOptionSection({
    super.key,
    required this.title,
    required this.caption,
    required this.options,
    required this.selected,
    required this.onTap,
    this.isDislike = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textMain,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          caption,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return PreferenceChip(
              label: option,
              selected: selected.contains(option),
              isDislike: isDislike,
              onTap: () => onTap(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class PreferenceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDislike;
  final VoidCallback onTap;

  const PreferenceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.isDislike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDislike
        ? AppColors.primaryPink
        : AppColors.primaryPurple;
    final activeBg = isDislike
        ? AppColors.primaryPinkSoft
        : AppColors.primaryPurpleSoft;

    return Material(
      color: selected ? activeBg : AppColors.bgWarm,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? activeColor : AppColors.lineSoft,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? activeColor : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreferenceTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const PreferenceTextField({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.bgWarm,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.lineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primaryPurple),
        ),
      ),
    );
  }
}

void pushOnmuPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
