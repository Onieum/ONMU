import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/grid_background.dart';

class PreferencePageFrame extends StatelessWidget {
  const PreferencePageFrame({
    super.key,
    required this.currentStep,
    required this.stepCount,
    required this.title,
    required this.child,
    required this.buttonLabel,
    required this.onNext,
    this.subtitle,
    this.titleAlign = TextAlign.start,
    this.onReturnToStart,
  });

  final int currentStep;
  final int stepCount;
  final String title;
  final String? subtitle;
  final TextAlign titleAlign;
  final Widget child;
  final String buttonLabel;
  final VoidCallback? onNext;
  final VoidCallback? onReturnToStart;

  bool get _isStart => currentStep == 1;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: _isStart
          ? null
          : AppBar(
              backgroundColor: AppColors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textMain,
                  size: 20,
                ),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              if (!_isStart) _PreferenceStepIndicator(currentStep: currentStep),
              Padding(
                padding: EdgeInsets.fromLTRB(24, _isStart ? 28 : 8, 24, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        title,
                        textAlign: titleAlign,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          subtitle!,
                          textAlign: titleAlign,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textSub,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: child,
                ),
              ),
              _PreferenceBottomCta(
                isStart: _isStart,
                buttonLabel: buttonLabel,
                onNext: onNext,
                onReturnToStart: onReturnToStart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceStepIndicator extends StatelessWidget {
  const _PreferenceStepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final labels = ['음식', '장소', '약속', '요일'];
    final active = (currentStep - 2).clamp(0, labels.length - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(labels.length, (index) {
          final step = index + 1;
          final isActive = active == index;
          final isPassed = active > index;

          return Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isActive
                        ? AppColors.primaryPink
                        : isPassed
                        ? AppColors.primaryPinkSoft
                        : AppColors.bgWarm,
                    child: Text(
                      step.toString(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isActive
                            ? AppColors.textInverse
                            : isPassed
                            ? AppColors.primaryPink
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    style: AppTextStyles.tiny.copyWith(
                      color: isActive
                          ? AppColors.textMain
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              if (index < labels.length - 1)
                Container(
                  width: 28,
                  height: 1.5,
                  margin: const EdgeInsets.only(bottom: 12, left: 5, right: 5),
                  color: isPassed ? AppColors.primaryPink : AppColors.lineSoft,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _PreferenceBottomCta extends StatelessWidget {
  const _PreferenceBottomCta({
    required this.isStart,
    required this.buttonLabel,
    required this.onNext,
    required this.onReturnToStart,
  });

  final bool isStart;
  final String buttonLabel;
  final VoidCallback? onNext;
  final VoidCallback? onReturnToStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (!isStart) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgDefault,
                      foregroundColor: AppColors.textMain,
                      side: const BorderSide(color: AppColors.lineSoft),
                    ),
                    child: const Text('이전'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isStart
                        ? AppColors.primaryPink
                        : AppColors.primaryPurple,
                  ),
                  child: Text(buttonLabel),
                ),
              ),
            ],
          ),
          if (isStart && onReturnToStart != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onReturnToStart,
              child: Text(
                '첫 설정 페이지로 돌아가기',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSub,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PreferenceOptionSection extends StatelessWidget {
  const PreferenceOptionSection({
    super.key,
    required this.title,
    required this.caption,
    required this.options,
    required this.selected,
    required this.onTap,
    this.isDislike = false,
  });

  final String title;
  final String caption;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;
  final bool isDislike;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(color: AppColors.textMain),
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
  const PreferenceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.isDislike,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDislike;
  final VoidCallback onTap;

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
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.textMain),
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
  const PreferenceTextField({
    super.key,
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

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
